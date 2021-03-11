'use strict';

const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();
const { Logging } = require('@google-cloud/logging');
const logging = new Logging({
  projectId: process.env.GCLOUD_PROJECT,
});
const stripe = require('stripe')(functions.config().stripe.secret, {
  apiVersion: '2020-03-02',
});

/**
 * When a user is created, create a Stripe customer object for them.
 */
exports.createStripeCustomer = functions.auth.user().onCreate(async (user) => {
  const customer = await stripe.customers.create({
    email: user.email,
    metadata: { firebaseUID: user.uid },
  });

  await admin.firestore().collection('stripe_customers').doc(user.uid).set({
    customer_id: customer.id,
  });
  return;
});

/**
 * Set up an ephemeral key.
 *
 * @see https://stripe.com/docs/mobile/android/basic#set-up-ephemeral-key
 * @see https://stripe.com/docs/mobile/ios/basic#ephemeral-key
 */
exports.createEphemeralKey = functions.https.onCall(async (data, context) => {
  // Checking that the user is authenticated.
  if (!context.auth) {
    // Throwing an HttpsError so that the client gets the error details.
    throw new functions.https.HttpsError(
      'failed-precondition',
      'The function must be called while authenticated!'
    );
  }
  const uid = context.auth.uid;
  try {
    if (!uid) throw new Error('Not authenticated!');
    // Get stripe customer id
    const customer = (
      await admin.firestore().collection('stripe_customers').doc(uid).get()
    ).data().customer_id;
    const key = await stripe.ephemeralKeys.create(
      { customer },
      { apiVersion: data.api_version }
    );
    return key;
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

/**
 * When a payment document is written on the client,
 * this function is triggered to create the PaymentIntent in Stripe.
 *
 * @see https://stripe.com/docs/mobile/android/basic#complete-the-payment
 */
exports.createStripePayment = functions.firestore
  .document('stripe_customers/{userId}/payments/{pushId}')
  .onCreate(async (snap, context) => {
    const { amount, currency } = snap.data();
    try {
      // Look up the Stripe customer id.
      const customer = (await snap.ref.parent.parent.get()).data().customer_id;
      const ephemeralKey = await stripe.ephemeralKeys.create(
        { customer },
        { apiVersion: '2020-08-27' }
      );
      // Create a charge using the pushId as the idempotency key
      // to protect against double charges.
      const idempotencyKey = context.params.pushId;
      const payment = await stripe.paymentIntents.create(
        {
          amount,
          currency,
          customer,
        },
        { idempotencyKey }
      );
      payment.ephemeralKey = ephemeralKey.secret;
      // If the result is successful, write it back to the database.
      await snap.ref.set(payment);
    } catch (error) {
      // We want to capture errors and render them in a user-friendly way, while
      // still logging an exception with StackDriver
      console.log(error);
      await snap.ref.set({ error: userFacingMessage(error) }, { merge: true });
      await reportError(error, { user: context.params.userId });
    }
  });

/**
 * Helper function to update a payment record in Cloud Firestore.
 */
const updatePaymentRecord = async (id) => {
  // Retrieve the payment object to make sure we have an up to date status.
  const payment = await stripe.paymentIntents.retrieve(id);
  const customerId = payment.customer;
  // Get customer's doc in Firestore.
  const customersSnap = await admin
    .firestore()
    .collection('stripe_customers')
    .where('customer_id', '==', customerId)
    .get();
  if (customersSnap.size !== 1) throw new Error('User not found!');
  // Update record in Firestore
  const paymentsSnap = await customersSnap.docs[0].ref
    .collection('payments')
    .where('id', '==', payment.id)
    .get();
  if (paymentsSnap.size !== 1) throw new Error('Payment not found!');
  await paymentsSnap.docs[0].ref.set(payment);
};

/**
 * A webhook handler function for the relevant Stripe events.
 * @see https://stripe.com/docs/payments/handling-payment-events?lang=node#build-your-own-webhook
 */
exports.handleWebhookEvents = functions.https.onRequest(async (req, resp) => {
  const relevantEvents = new Set([
    'payment_intent.succeeded',
    'payment_intent.processing',
    'payment_intent.payment_failed',
    'payment_intent.canceled',
  ]);

  let event;

  // Instead of getting the `Stripe.Event`
  // object directly from `req.body`,
  // use the Stripe webhooks API to make sure
  // this webhook call came from a trusted source
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      req.headers['stripe-signature'],
      functions.config().stripe.webhooksecret
    );
  } catch (error) {
    console.error('❗️ Webhook Error: Invalid Secret');
    resp.status(401).send('Webhook Error: Invalid Secret');
    return;
  }

  if (relevantEvents.has(event.type)) {
    try {
      switch (event.type) {
        case 'payment_intent.succeeded':
        case 'payment_intent.processing':
        case 'payment_intent.payment_failed':
        case 'payment_intent.canceled':
          const id = event.data.object.id;
          await updatePaymentRecord(id);
          break;
        default:
          throw new Error('Unhandled relevant event!');
      }
    } catch (error) {
      console.error(
        `❗️ Webhook error for [${event.data.object.id}]`,
        error.message
      );
      resp.status(400).send('Webhook handler failed. View Function logs.');
      return;
    }
  }

  // Return a response to Stripe to acknowledge receipt of the event.
  resp.json({ received: true });
});

/**
 * When a user deletes their account, clean up after them.
 */
exports.cleanupUser = functions.auth.user().onDelete(async (user) => {
  const dbRef = admin.firestore().collection('stripe_customers');
  const customer = (await dbRef.doc(user.uid).get()).data();
  await stripe.customers.del(customer.customer_id);
  // Delete the customers payments & payment methods in firestore.
  const snapshot = await dbRef
    .doc(user.uid)
    .collection('payment_methods')
    .get();
  snapshot.forEach((snap) => snap.ref.delete());
  await dbRef.doc(user.uid).delete();
  return;
});

/**
 * To keep on top of errors, we should raise a verbose error report with Stackdriver rather
 * than simply relying on console.error. This will calculate users affected + send you email
 * alerts, if you've opted into receiving them.
 */

// [START reporterror]

function reportError(err, context = {}) {
  // This is the name of the StackDriver log stream that will receive the log
  // entry. This name can be any valid log stream name, but must contain "err"
  // in order for the error to be picked up by StackDriver Error Reporting.
  const logName = 'errors';
  const log = logging.log(logName);

  // https://cloud.google.com/logging/docs/api/ref_v2beta1/rest/v2beta1/MonitoredResource
  const metadata = {
    resource: {
      type: 'cloud_function',
      labels: { function_name: process.env.FUNCTION_NAME },
    },
  };

  // https://cloud.google.com/error-reporting/reference/rest/v1beta1/ErrorEvent
  const errorEvent = {
    message: err.stack,
    serviceContext: {
      service: process.env.FUNCTION_NAME,
      resourceType: 'cloud_function',
    },
    context: context,
  };

  // Write the error log entry
  return new Promise((resolve, reject) => {
    log.write(log.entry(metadata, errorEvent), (error) => {
      if (error) {
        return reject(error);
      }
      return resolve();
    });
  });
}

// [END reporterror]

/**
 * Sanitize the error message for the user.
 */
function userFacingMessage(error) {
  return error.type
    ? error.message
    : 'An error occurred, developers have been alerted';
}
