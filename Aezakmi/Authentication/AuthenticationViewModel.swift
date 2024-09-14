//
//  AuthenticationViewModel.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 13.09.2024.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore


@MainActor
final class AuthenticationViewModel: ObservableObject {
        
    
    func signInGoogle() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        let authDataResult = try await AuthenticationManager.shared.signInWithGoogle(tokens: tokens)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }

}


