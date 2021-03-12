//
//  ContentView.swift
//  Firestripe
//
//  Created by Thorsten Schaeff on 3/11/21.
//

import SwiftUI
import Stripe

struct ContentView: View {
	@ObservedObject var sessionStore = SessionStore()
	@ObservedObject var paymentStore = PaymentStore()
	
	func getUser () {
		sessionStore.listen()
	}
	
	var body: some View {
		VStack {
			if let user = sessionStore.user {
				VStack{
					Button("Sign out") {
						sessionStore.signOut()
					}
					Text(user.email!)
					if let paymentSheet = paymentStore.paymentSheet {
						PaymentSheet.PaymentButton(
							paymentSheet: paymentSheet,
							onCompletion: paymentStore.onPaymentCompletion
						) {
							Text("Buy")
						}.disabled(paymentStore.paymentResult != nil)
					} else {
						Button("Start") {
							paymentStore.preparePayment(uid: user.uid, amount: 1999, currency: "usd")
						}.disabled(paymentStore.isLoading)
					}
					if let result = paymentStore.paymentResult {
						VStack{
							switch result {
							case .completed(let pi):
								Text("Payment complete: (\(pi.stripeId))")
							case .failed(let error, _):
								Text("Payment failed: \(error.localizedDescription)")
							case .canceled(_):
								Text("Payment canceled.")
							}
						}
					}
				}
			} else {
				LoginView()
			}
		}.onAppear(perform: getUser)
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
