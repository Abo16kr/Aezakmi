//
//  ContentView.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct ContentView: View {
    @State private var showSignInView: Bool = false
    
    var body: some View {
        ZStack {
            if !showSignInView { TabbarView(showSignInView: $showSignInView) }
        }.onAppear {
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            self.showSignInView = authUser == nil
            print(authUser ?? "no authUser")
        }
        .fullScreenCover(isPresented: $showSignInView) {
            OpenningSignUpRegisterView(showSignInView: $showSignInView)
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


