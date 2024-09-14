//
//  SignUpView.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import SwiftUI
import GoogleSignInSwift

struct SignUpView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @StateObject private var vmSignIn = SignInEmailViewModel()
    
    @State var isShowpassword: Bool = false
    @State var isSecure: Bool = false
    
    @State private var errorMessage: String? = nil
    @State private var showAlert: Bool = false
    
    @Binding var showRegister: Bool
    @Binding var showSignInView: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack {

                        TextFieldSecureInput(description: "Email address", title: "example@gmail.com", text: $vmSignIn.email, isAction: $isSecure, icone: "checkmark.circle.fill")
                        
                        VStack(alignment: .trailing){
                            
                            TextFieldPasswordInput(description: "Password", title: "12345678", text: $vmSignIn.password, isAction: $isShowpassword,icone: "eye", icone2: "eye.slash")
                            
                            NavigationLink {
                                ForgotPasswordView()
                            } label: {
                                Text("Forgot password ?")
                                    .font(.system(size: 10))
                                    .padding(.horizontal)
                                    .foregroundStyle(Color.theme.Colorblack)
                            }
                        }
                        
                        Button(action: {
                            Task {
                                do {
                                    try await vmSignIn.signIn()
                                    showSignInView = false
                                } catch {
                                    errorMessage = "Failed to sign in: \(error.localizedDescription)"
                                    showAlert = true
                                }
                            }
                        }){
                            Text("Sign in")
                                .foregroundStyle(Color.theme.Colorwhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.theme.Colorblack)
                                .clipShape(.rect(cornerRadius: 10))
                                .padding(.all)
                        }.padding(.top,38)
                            .disabled(vmSignIn.email.isEmpty && vmSignIn.password.isEmpty)
                        
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(Color.gray)
                            Text("Or Login with")
                                .font(.system(size: 10, weight: .regular))
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(Color.gray)
                        }.padding(.all)
                        
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
                        }.padding(.horizontal)
                        
                        Button {
                            withAnimation(.easeInOut){
                                showRegister.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Already have an account? ")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundStyle(Color.gray)
                                Text("Log in")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.theme.Colorblack)
                            }
                            
                        }.padding(.all)
                        
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage ?? "An unknown error occurred."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationTitle("Sign in").navigationBarTitleDisplayMode(.automatic)

        }
        .ignoresSafeArea(.keyboard)
        
    }
}

#Preview {
    SignUpView(showRegister: .constant(false), showSignInView: .constant(false))
        .environmentObject(ProfileViewModel())
}



