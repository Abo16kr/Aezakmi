//
//  TabbarView.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 13.09.2024.
//

import SwiftUI

struct TabbarView: View {
    @Binding var showSignInView: Bool
    var body: some View {
        TabView {
            PermissionsView(showSignInView: $showSignInView)
                .tabItem {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("PhotEditer")
                }
            
            ProfileView(showSignInView: $showSignInView)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
    }
}

struct TabbarView_Previews: PreviewProvider {
    static var previews: some View {
        TabbarView(showSignInView: .constant(false))
    }
}
