//
//  ProfileView.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 13.09.2024.
//

import SwiftUI

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
    @Binding var showSignInView: Bool
    @State private var url: URL? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List {
                        if let user = viewModel.user {
                            Text("UserId: \(user.userId)")
                            Text("Email: \(user.email ?? "")")
                            
                            if let isAnonymous = user.isAnonymous {
                                Text("Is Anonymous: \(isAnonymous.description.capitalized)")
                            }
                            
                        }
                    }
                }
                    
            }
            .overlay(alignment: .bottom, content: {
                Button(action: {
                    Task {
                        do {
                            try viewModel.signOut()
                            showSignInView = true
                        } catch {
                            print(error)
                        }
                    }
                }){
                    Text("Log Out")
                        .foregroundStyle(Color.red)
                }
            })
            .task {
                try? await viewModel.loadCurrentUser()
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(showSignInView: .constant(false))
    }
}
