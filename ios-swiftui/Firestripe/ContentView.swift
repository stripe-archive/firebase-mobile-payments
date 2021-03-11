//
//  ContentView.swift
//  Firestripe
//
//  Created by Thorsten Schaeff on 3/11/21.
//

import SwiftUI

struct ContentView: View {
		@ObservedObject var sessionStore = SessionStore()
	
		func getUser () {
				sessionStore.listen()
		}
	
    var body: some View {
			VStack {
				if let user = sessionStore.user {
					VStack{
						Text(user.email!)
						Button("Sign out") {
								sessionStore.signOut()
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
