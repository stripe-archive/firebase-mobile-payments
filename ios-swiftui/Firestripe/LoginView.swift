//
//  LoginView.swift
//  Firestripe
//
//  Created by Thorsten Schaeff on 3/11/21.
//

import SwiftUI

struct LoginView: View {
		@ObservedObject var sessionStore = SessionStore()
		@State var email: String = ""
		@State var password: String = ""
		@State var loading = false
		@State var error = false

    var body: some View {
				VStack {
						TextField("Enter email...", text: $email)
							.autocapitalization(.none)
							.disableAutocorrection(true)
							.border(Color(UIColor.separator))
						SecureField("Password", text: $password)
							.border(Color(UIColor.separator))
						if (error) {
							Text("Error signing in!")
						}
					HStack{
						Button("Sign in") {
								loading = true
								error = false
								sessionStore.signIn(email: email, password: password) { (result, error) in
										self.loading = false
										if error != nil {
												self.error = true
										} else {
												self.password = ""
										}
								}
						}
						Button("Sign up") {
								loading = true
								error = false
								sessionStore.signUp(email: email, password: password) { (result, error) in
										self.loading = false
										if error != nil {
												self.error = true
										} else {
												self.password = ""
										}
								}
						}
					}
				}
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
