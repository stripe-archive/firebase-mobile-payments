package com.example.firebasemobilepayments

import android.app.Application
import com.stripe.android.PaymentConfiguration

class FirebaseMobilePaymentsApp : Application(){
    override fun onCreate() {
        super.onCreate()
        PaymentConfiguration.init(applicationContext, BuildConfig.PublishableKey)
    }
}