package com.example.firebasemobilepayments

import android.app.Activity
import android.content.Intent
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import com.firebase.ui.auth.AuthUI
import com.firebase.ui.auth.IdpResponse
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase
import com.stripe.android.*
import com.stripe.android.model.ConfirmPaymentIntentParams
import com.stripe.android.model.PaymentMethod
import com.stripe.android.view.BillingAddressFields
import kotlinx.android.synthetic.main.activity_main.*


var RC_SIGN_IN = 1
class MainActivity : AppCompatActivity() {
    private var currentUser: FirebaseUser? = null
    private lateinit var paymentSession: PaymentSession
    private lateinit var selectedPaymentMethod: PaymentMethod
    private val stripe: Stripe by lazy { Stripe(applicationContext, PaymentConfiguration.getInstance(applicationContext).publishableKey) }



    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)


        loginButton.setOnClickListener {
            // login to firebase
            val providers = arrayListOf(
                AuthUI.IdpConfig.EmailBuilder().build())

            startActivityForResult(
                AuthUI.getInstance()
                    .createSignInIntentBuilder()
                    .setAvailableProviders(providers)
                    .build(),
                RC_SIGN_IN
            )
        }

        payButton.setOnClickListener {
            confirmPayment(selectedPaymentMethod.id!!)
        }

        paymentmethod.setOnClickListener {
            // Create the customer session and kick start the payment flow
            paymentSession.presentPaymentMethodSelection()
        }

        showUI()
    }

    private fun confirmPayment(paymentMethodId: String) {
        payButton.isEnabled = false

        val paymentCollection = Firebase.firestore
            .collection("stripe_customers").document(currentUser?.uid?:"")
            .collection("payments")

        // Add a new document with a generated ID
        paymentCollection.add(hashMapOf(
            "amount" to 8800,
            "currency" to "hkd"
        ))
            .addOnSuccessListener { documentReference ->
                Log.d("payment", "DocumentSnapshot added with ID: ${documentReference.id}")
                documentReference.addSnapshotListener { snapshot, e ->
                    if (e != null) {
                        Log.w("payment", "Listen failed.", e)
                        return@addSnapshotListener
                    }

                    if (snapshot != null && snapshot.exists()) {
                        Log.d("payment", "Current data: ${snapshot.data}")
                        val clientSecret = snapshot.data?.get("client_secret")
                        Log.d("payment", "Create paymentIntent returns $clientSecret")
                        clientSecret?.let {
                            stripe.confirmPayment(this, ConfirmPaymentIntentParams.createWithPaymentMethodId(
                                paymentMethodId,
                                (it as String)
                            ))

                            checkoutSummary.text = "Thank you for your payment"
                            Toast.makeText(applicationContext, "Payment Done!!", Toast.LENGTH_LONG).show()
                        }
                    } else {
                        Log.e("payment", "Current payment intent : null")
                        payButton.isEnabled = true
                    }
                }
            }
            .addOnFailureListener { e ->
                Log.w("payment", "Error adding document", e)
                payButton.isEnabled = true
            }
    }

    private fun showUI() {
        currentUser?.let {
            loginButton.visibility = View.INVISIBLE

            greeting.visibility = View.VISIBLE
            checkoutSummary.visibility = View.VISIBLE
            payButton.visibility = View.VISIBLE
            paymentmethod.visibility = View.VISIBLE

            greeting.text = "Hello ${it.displayName}"

            setupPaymentSession()
        }?: run {
            // User does not login
            loginButton.visibility = View.VISIBLE

            greeting.visibility = View.INVISIBLE
            checkoutSummary.visibility = View.INVISIBLE
            paymentmethod.visibility = View.INVISIBLE
            payButton.visibility = View.INVISIBLE
            payButton.isEnabled = false

        }
    }

    private fun setupPaymentSession () {
        // Setup Customer Session
        CustomerSession.initCustomerSession(this, FirebaseEphemeralKeyProvider())
        // Setup a payment session
        paymentSession = PaymentSession(this, PaymentSessionConfig.Builder()
            .setShippingInfoRequired(false)
            .setShippingMethodsRequired(false)
            .setBillingAddressFields(BillingAddressFields.None)
            .setShouldShowGooglePay(true)
            .build())

        paymentSession.init(
            object: PaymentSession.PaymentSessionListener {
                override fun onPaymentSessionDataChanged(data: PaymentSessionData) {
                    Log.d("PaymentSession", "PaymentSession has changed: $data")
                    Log.d("PaymentSession", "${data.isPaymentReadyToCharge} <> ${data.paymentMethod}")

                    if (data.isPaymentReadyToCharge) {
                        Log.d("PaymentSession", "Ready to charge");
                        payButton.isEnabled = true

                        data.paymentMethod?.let {
                            Log.d("PaymentSession", "PaymentMethod $it selected")
                            paymentmethod.text = "${it.card?.brand} card ends with ${it.card?.last4}"
                            selectedPaymentMethod = it
                        }
                    }
                }

                override fun onCommunicatingStateChanged(isCommunicating: Boolean) {
                    Log.d("PaymentSession",  "isCommunicating $isCommunicating")
                }

                override fun onError(errorCode: Int, errorMessage: String) {
                    Log.e("PaymentSession",  "onError: $errorCode, $errorMessage")
                }
            }
        )

    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == RC_SIGN_IN) {
            val response = IdpResponse.fromResultIntent(data)

            if (resultCode == Activity.RESULT_OK) {
                currentUser = FirebaseAuth.getInstance().currentUser

                Log.d("Login", "User ${currentUser?.displayName} has signed in.")
                Toast.makeText(applicationContext, "Welcome ${currentUser?.displayName}", Toast.LENGTH_SHORT).show()
                showUI()
            } else {
                Log.d("Login", "Signing in failed!")
                Toast.makeText(applicationContext, response?.error?.message?:"Sign in failed", Toast.LENGTH_LONG).show()
            }
        } else {
            paymentSession.handlePaymentData(requestCode, resultCode, data ?: Intent())
        }
    }
}