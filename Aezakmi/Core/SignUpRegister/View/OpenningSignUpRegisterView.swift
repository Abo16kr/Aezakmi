//
//  OpenningSignUpRegisterView.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import SwiftUI

struct OpenningSignUpRegisterView: View {
    
    @StateObject var vmProfile = ProfileViewModel()
    @Binding var showSignInView: Bool
    
    @State var showRegister: Bool = false
    
    var body: some View {
        ZStack {
            Color.theme.Colorbackground.ignoresSafeArea(.all)
            SignUpView(showRegister: $showRegister, showSignInView: $showSignInView)
                .fullScreenCover(isPresented: $showRegister) {
                    RegisterView(showSignInView: $showSignInView,showRegister: $showRegister)
                }
        }
    }
}

#Preview {
    OpenningSignUpRegisterView(showSignInView: .constant(false))
        .environmentObject(ProfileViewModel())
}
