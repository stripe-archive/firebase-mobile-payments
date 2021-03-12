//
//  FirestripeApp.swift
//  Firestripe
//
//  Created by Thorsten Schaeff on 3/11/21.
//

import SwiftUI
import Firebase
import Stripe

var db: Firestore?

@main
struct FirestripeApp: App {
	init() {
		FirebaseApp.configure()
		db = Firestore.firestore()
		StripeAPI.defaultPublishableKey = "pk_test_xxxxx"
	}
	
	var body: some Scene {
		WindowGroup {
			ContentView()
		}
	}
}
