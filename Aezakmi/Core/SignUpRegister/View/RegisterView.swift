//
//  RegisterView.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import SwiftUI
import GoogleSignInSwift
import GoogleSignIn
import Firebase

struct RegisterView: View {
    @StateObject private var vmSignIn = SignInEmailViewModel()

    @State var isSecure: Bool = false
    @StateObject private var viewModel = AuthenticationViewModel()
    @Binding var showSignInView: Bool
    @Binding var showRegister: Bool
    
    @State private var errorMessage: String? = nil
    @State private var showAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        TextFieldSecureInput(description: "Email address", title: "example@gmail.com", text: $vmSignIn.email, isAction: $isSecure, icone: "checkmark.circle.fill")
                        
                        VStack(alignment: .trailing){
                            TextFieldPasswordInput(description: "Password", title: "12345678", text: $vmSignIn.password, isAction: $isSecure, icone: "eye", icone2: "eye.slash")
                            
                            TextFieldPasswordInput(description: "Password", title: "12345678", text: $vmSignIn.confirmPassword, isAction: $isSecure, icone: "eye", icone2: "eye.slash")
                        }
                        
                        Button(action: {
                            Task {
                                do {
                                    try await vmSignIn.signUp()
                                    showSignInView = false
                                    showRegister = false
                                } catch {
                                    errorMessage = (error as? ValidationError)?.localizedDescription ?? "An unknown error occurred."
                                    showAlert = true
                                }
                            }
                        }){
                            Text("Register")
                                .foregroundStyle(Color.theme.Colorwhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.theme.Colorblack)
                                .clipShape(.rect(cornerRadius: 10))
                                .padding(.all)
                        }
                        .padding(.top, 38)
                        .disabled(!vmSignIn.isEmailValid || !vmSignIn.isPasswordValid)
                        
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(Color.gray)
                            Text("Or Login with")
                                .font(.system(size: 10, weight: .regular))
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(Color.gray)
                        }
                        .padding(.all)
                        
                        GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                            Task {
                                do {
                                    try await viewModel.signInGoogle()
                                    showSignInView = false
                                } catch {
                                    errorMessage = "Failed to sign in with Google: \(error.localizedDescription)"
                                    showAlert = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button {
                            withAnimation(.easeInOut) { showRegister.toggle() }
                        } label: {
                            HStack {
                                Text("Don’t have an account?")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color.gray)
                                
                                Text("Sign up")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.theme.Colorblack)
                            }
                        }
                        .padding(.all)
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage ?? "An unknown error occurred."),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .navigationTitle("Register")
                .navigationBarTitleDisplayMode(.automatic)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    RegisterView(showSignInView: .constant(false), showRegister: .constant(false))
        .environmentObject(ProfileViewModel())
}

