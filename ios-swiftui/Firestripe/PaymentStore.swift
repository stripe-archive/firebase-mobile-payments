//
//  PaymentStore.swift
//  Firestripe
//
//  Created by Thorsten Schaeff on 3/11/21.
//

import Foundation
import Firebase
import Stripe

class PaymentStore : ObservableObject {
	@Published var paymentSheet: PaymentSheet?
	@Published var paymentResult: PaymentResult?
	@Published var isLoading = false
	
	func preparePayment(uid: String, amount: Int, currency: String) {
		self.paymentSheet = nil
		self.paymentResult = nil
		self.isLoading = true
		// Add a new document with a generated ID
		var ref: DocumentReference? = nil
		ref = db!.collection("stripe_customers").document(uid).collection("payments").addDocument(data: [
			"currency": currency,
			"amount": amount
		]) { err in
			if let err = err {
				print("Error adding document: \(err)")
			} else {
				print("Document added with ID: \(ref!.documentID)")
			}
		}
		ref?.addSnapshotListener { documentSnapshot, error in
			guard let document = documentSnapshot else {
				print("Error fetching document: \(error!)")
				return
			}
			guard let data = document.data() else {
				print("Document data was empty.")
				return
			}
			print("Current data: \(data)")
			
			let customer = data["customer"]
			let ephemeralKey = data["ephemeralKey"]
			let clientSecret = data["client_secret"]
			
			if (customer != nil && ephemeralKey != nil && clientSecret != nil) {
				// MARK: Create a PaymentSheet instance
				var configuration = PaymentSheet.Configuration()
				configuration.merchantDisplayName = "Example, Inc."
				configuration.customer = .init(id: customer as! String, ephemeralKeySecret: ephemeralKey as! String)
				
				DispatchQueue.main.async {
					self.paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret as! String, configuration: configuration)
					self.isLoading = false
				}
			}
		}
	}
	
	func onPaymentCompletion(result: PaymentResult) {
		self.paymentSheet = nil
		self.paymentResult = result
	}
}
