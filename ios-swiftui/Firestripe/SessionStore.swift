//
//  SessionStore.swift
//  Firestripe
//
//  Created by Thorsten Schaeff on 3/11/21.
//

import Foundation
import SwiftUI
import Firebase

class SessionStore : ObservableObject {
		@Published var user: User?
		var handle: AuthStateDidChangeListenerHandle?

		func listen () {
				// monitor authentication changes using firebase
				handle = Auth.auth().addStateDidChangeListener { (auth, user) in
						if let user = user {
								// if we have a user, create a new user model
							print("Got user: \(user.uid)")
								self.user = User(
										uid: user.uid,
										displayName: user.displayName,
										email: user.email
								)
						} else {
								// if we don't have a user, set our session to nil
								self.user = nil
						}
				}
		}

		func signUp(
				email: String,
				password: String,
				handler: @escaping AuthDataResultCallback
				) {
				Auth.auth().createUser(withEmail: email, password: password, completion: handler)
		}

		func signIn(
				email: String,
				password: String,
				handler: @escaping AuthDataResultCallback
				) {
				Auth.auth().signIn(withEmail: email, password: password, completion: handler)
		}

		func signOut () {
				do {
						try Auth.auth().signOut()
						self.user = nil
				} catch {
					print("Logout failed for: \(self.user!.uid)")
						self.user = nil
				}
		}
	
		func unbind () {
				if let handle = handle {
						Auth.auth().removeStateDidChangeListener(handle)
				}
		}
}
