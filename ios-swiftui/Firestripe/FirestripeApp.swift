//
//  FirestripeApp.swift
//  Firestripe
//
//  Created by Thorsten Schaeff on 3/11/21.
//

import SwiftUI
import Firebase

@main
struct FirestripeApp: App {
	init() {
		FirebaseApp.configure()
	}
	
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
