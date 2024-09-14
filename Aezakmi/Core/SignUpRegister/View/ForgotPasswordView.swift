//
//  ForgotPasswordView.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 13.09.2024.
//

import SwiftUI

struct ForgotPasswordView: View {
    @StateObject private var vmSignIn = SignInEmailViewModel()
    @State private var errorMessage: String? = nil
    @State private var showAlert: Bool = false
    @State var passwordReset: Bool = false
    @State var isSecure: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView(showsIndicators: false) {
                    VStack {
                        Text("Don’t worry! It happens. Please enter the email associated with your account.")
                            .foregroundStyle(Color.gray)
                            .padding(.all)

                        TextFieldSecureInput(description: "Email address", title: "example@gmail.com", text: $vmSignIn.email, isAction: $isSecure, icone: "checkmark.circle.fill")

                        Button(action: {
                            if vmSignIn.isEmailValid {
                                Task {
                                    do {
                                        try await vmSignIn.forgotPassword(email: vmSignIn.email)
                                        passwordReset = true
                                    } catch {
                                        errorMessage = "Failed to initiate password reset: \(error.localizedDescription)"
                                        print(error.localizedDescription)
                                        showAlert = true
                                    }
                                }
                            } else {
                                errorMessage = "Invalid email format."
                                showAlert = true
                            }
                        }) {
                            Text("Send code")
                                .foregroundStyle(Color.theme.Colorwhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.theme.Colorblack)
                                .clipShape(.rect(cornerRadius: 10))
                                .padding(.all)
                        }
                        .disabled(vmSignIn.email.isEmpty)
                        .alert(isPresented: $passwordReset) {
                            Alert(
                                title: Text("PASSWORD RESET"),
                                message: Text("We have sent a password reset email to \(vmSignIn.email)."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
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
            .navigationTitle("Forgot password?")
            .navigationBarTitleDisplayMode(.automatic)
        }
    }
}

#Preview {
    ForgotPasswordView()
}
