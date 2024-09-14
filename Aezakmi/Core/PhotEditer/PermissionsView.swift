//
//  PermissionsView.swift
//  PhotoEditor
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import SwiftUI
import Photos
import _AVKit_SwiftUI

/// Permissions prompting view, the permissions (except the saving one) are NOT required due to using the UIImagePicker for media selection
struct PermissionsView: View {
            
    /// Image picker visibility
    @State private var isPickerPresented: Bool = false
    /// Camera picker visibility
    @State private var isCameraPresented: Bool = false
    /// Currently selected media item
    @State private var selectedItem: MediaItem?
    
    /// Current permissions status
    @State var status: Bool? = {
        switch PHPhotoLibrary.authorizationStatus() {
        case .notDetermined:
            return nil
        case .authorized, .limited:
            return true
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }()
       
    @Binding var showSignInView: Bool
    @State private var animationsRunning = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            
                            HStack {
                                Image(systemName: "square.stack.3d.up")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .symbolEffect(.variableColor.iterative, options: .repeating, value: animationsRunning)
                             }
                            
                            Text(self.status == true ? "Edit Your Photos and Camera" : "Access Your Photos and Camera")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.light)
                                .padding(.bottom, 8)
                            
                            VStack {
                                
                                Button(action: {
                                    self.isCameraPresented = true
                                    PHPhotoLibrary.requestAuthorization { newStatus in
                                        DispatchQueue.main.async {
                                            if newStatus == .authorized || newStatus == .limited {
                                                self.isCameraPresented = true
                                            }
                                        }
                                    }
                                }) {
                                    Text("Camera")
                                        .fixedSize()
                                        .frame(width: geometry.size.width - 96)
                                        .font(.system(size: 17, weight: .bold))
                                        .padding()
                                        .background(self.status == false ? Color.permissionsBackground : Color.blue)
                                        .cornerRadius(8)
                                        .foregroundColor(.light)
                                    
                                }
                                
                                Button(action: {
                                    if self.status == true {
                                        isPickerPresented = true
                                    } else if self.status == nil {
                                        PHPhotoLibrary.requestAuthorization { status in
                                            if status == .authorized || status == .limited {
                                                self.status = true
                                                return
                                            }
                                            self.status = false
                                        }
                                    }
                                }, label: {
                                    Group {
                                        if !isPickerPresented {
                                            Text(self.status == true ? "Continue" : "Grant Permissions")
                                        } else {
                                            ProgressView().foregroundColor(.light)
                                        }
                                    }
                                    .fixedSize()
                                    .frame(width: geometry.size.width - 96)
                                    .font(.system(size: 17, weight: .bold))
                                    .padding()
                                    .background(self.status == false ? Color.permissionsBackground : Color.blue)
                                    .cornerRadius(8)
                                    .foregroundColor(.light)
                                })
                                .disabled(self.status == false)
                                
                            }
                        }
                    }
                    
                    if let media = selectedItem {
                        EditorView(media: media, onClose: {
                            selectedItem = nil
                        })
                    }
                }
                .navigationTitle("Photo Editer")
                .sheet(isPresented: $isPickerPresented) {
                    ImagePicker(didFinishSelection: { media in
                        selectedItem = media
                        isPickerPresented = false
                    })
                    .edgesIgnoringSafeArea(.all)
                }
                .sheet(isPresented: $isCameraPresented) {
                    CameraView { image in
                        selectedItem = MediaItem(type: .image, image: image, video: nil, videoUrl: nil)
                    }
                    .edgesIgnoringSafeArea(.all)
                }
            }
            .onAppear {
                withAnimation(.easeInOut){
                    animationsRunning.toggle()
                }
            }
        }
    }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView(showSignInView: .constant(false))
    }
}

