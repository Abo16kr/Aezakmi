//
//  ProfileViewModel.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth

class ProfileViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published private(set) var user: DBUser? = nil
    
    func loadCurrentUser() async {
        isLoading = true
        
        do {
            let authDataResult = try await AuthenticationManager.shared.getAuthenticatedUser()
            user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        } catch {
            print("Error loading current user: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
