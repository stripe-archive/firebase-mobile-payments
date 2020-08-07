# Firebase mobile payments: Android & iOS with Cloud Functions for Firebase

This example includes Firebase [Cloud Functions](/functions) to create payments in native [Android](/android) and iOS (coming soon) applications.

**Features:**

- [Android client](/android)
- iOS client (coming soon)
- Functions
  - Create a customer object when a users signs up via Firebase Authentication and add a customer entry to Cloud Firestore: [createStripeCustomer](/functions/index.js#L32)
  - Callable functions to create a short-lived ephemeral keys for the SDK's prebuilt UI components: [createEphemeralKey](/functions/index.js#49)
  - Function to create a PaymentIntent when a new payment doc is added to Cloud Firestore: [createStripePayment](/functions/index.js#81)
  - Webhook handler function to keep Cloud Firestore in sync with Stripe: [handleWebhookEvents](/functions/index.js#137)
  - When a user is deleted from Firebase Authentication, delete thir data in Cloud Firestore and their customer object in Stripe: [cleanupUser](/functions/index.js#193)
  
<details open><summary><strong>Video tutorial: Android</strong></summary>
  <a href="https://www.youtube.com/watch?v=nw7rOijQKo8">
    <img src="https://img.youtube.com/vi/nw7rOijQKo8/0.jpg" alt="Link to video tutorial">
  </a>
</details>

## Recommended usage

Please note that when selling digital products or services **within** your app, (e.g. subscriptions, in-game currencies, game levels, access to premium content, or unlocking a full version), you must use the app store's in-app purchase APIs instead. See [Apple's](https://developer.apple.com/app-store/review/guidelines/#payments) and [Google's](https://support.google.com/googleplay/android-developer/answer/9858738?hl=en&ref_topic=9857752) guidelines for more information.

## Deploy and test

- Create a Firebase Project using the [Firebase Developer Console](https://console.firebase.google.com)
- Enable billing on your project by switching to the Blaze or Flame plan. See [pricing](https://firebase.google.com/pricing/) for more details. This is required to be able to do requests to non-Google services.
- Enable Google & Email sign-in in your [authentication provider settings](https://console.firebase.google.com/project/_/authentication/providers).
- Install [Firebase CLI Tools](https://github.com/firebase/firebase-tools) if you have not already and log in with `firebase login`.
- Configure this sample to use your project using `firebase use --add` and select your project.
- Install dependencies locally by running: `cd functions; npm install; cd -`
- [Add your Stripe API Secret Key](https://dashboard.stripe.com/account/apikeys) to Firebase config:
  ```bash
  firebase functions:config:set stripe.secret=<YOUR STRIPE SECRET KEY>
  ```
- Deploy your project using `cd functions; npm run deploy; cd -`

### Setting up webhooks

- Run `firebase open functions` to open the Firebase console.
- Copy the URL for the `handleWebhookEvents` functions (e.g. https://region-project-name.cloudfunctions.net/handleWebhookEvents)
- Create a new webhook endpoint with the URL in the [Stripe Dashboard](https://dashboard.stripe.com/webhooks)
- Copy the signing secret (whsec_xxx) and add it to Firebase config:
  ```bash
  firebase functions:config:set stripe.webhooksecret=<YOUR WEBHOOK SECRET>
  ```
- Redeploy the `handleWebhookEvents` function: `firebase deploy --only functions:handleWebhookEvents`

## Accepting live payments

Once you’re ready to go live, you will need to exchange your test keys for your live keys. See the [Stripe docs](https://stripe.com/docs/keys) for further details.

- Update your Stripe secret config:
  ```bash
  firebase functions:config:set stripe.secret=<YOUR STRIPE LIVE SECRET KEY>
  ```
- Set your [live publishable key](https://dashboard.stripe.com/account/apikeys) in your respective client integration.
- Follow the [Setting up webhooks](#Setting-up-webhooks) from above for live mode.
- Redeploy the functions for the changes to take effect `cd functions; npm run deploy; cd -`.

## Authors

- [@shengwei-stripe](https://twitter.com/wushengwei2000)
- [@thorsten-stripe](https://twitter.com/thorwebdev)
