//
//  SignInEmailViewModel.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 13.09.2024.
//

import Foundation

@MainActor
final class SignInEmailViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""

    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Z|a-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    private func isEmailValid2(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Z0-9a-z.-]+\\.[A-Z|a-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isPasswordValid: Bool {
        // Password must be at least 6 characters long
        return password.count >= 6
    }

    func signUp() async throws {
        guard isEmailValid else {
            throw ValidationError.invalidEmail
        }
        
        guard isPasswordValid else {
            throw ValidationError.invalidPassword
        }
        
        guard password == confirmPassword else {
            throw ValidationError.passwordMismatch
        }
        
        let authDataResult = try await AuthenticationManager.shared.createUser(email: email, password: password)
        let user = DBUser(auth: authDataResult)
        try await UserManager.shared.createNewUser(user: user)
    }
    
    func signIn() async throws {
        guard isEmailValid else {
            throw ValidationError.invalidEmail
        }
        
        guard isPasswordValid else {
            throw ValidationError.invalidPassword
        }
        
        try await AuthenticationManager.shared.signInUser(email: email, password: password)
    }

    func forgotPassword(email: String) async throws {
         guard isEmailValid2(email) else {
             throw ValidationError.invalidEmail
         }
         
         try await AuthenticationManager.shared.resetPassword(email: email)
     }
}

enum ValidationError: Error {
    case invalidEmail
    case invalidPassword
    case passwordMismatch
    
    var localizedDescription: String {
        switch self {
        case .invalidEmail:
            return "The email address is invalid."
        case .invalidPassword:
            return "Password must be at least 6 characters long."
        case .passwordMismatch:
            return "Passwords do not match."
        }
    }
}
