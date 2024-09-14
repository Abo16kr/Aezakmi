//
//  AezakmiApp.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//
import SwiftUI
import Firebase
import GoogleSignIn

@main
struct AezakmiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var showLaunchView: Bool = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if !showLaunchView {
                    ContentView()
                } else {
                    LaunchView(showLaunchView: $showLaunchView)
                }
            } .preferredColorScheme(.dark)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
