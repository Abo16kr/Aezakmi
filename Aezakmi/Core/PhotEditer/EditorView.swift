//
//  EditorView.swift
//  PhotoEditor
//
//  Created by Abobakr Al Zain  on 12.09.2024.
//

import SwiftUI
import PencilKit
import AVKit
import Photos

struct EditorView: View {
    @StateObject private var viewModel: EditorViewModel
    
    init(media: MediaItem, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: EditorViewModel(media: media, onClose: onClose))
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Toolbar
                ZStack(alignment: .center) {
                    // Font picker
                    if viewModel.canUndo && viewModel.selectedTextView != nil && viewModel.mode == .text {
                        Picker("Font", selection: $viewModel.font) {
                            Text("Default Font")
                                .font(.system(size: 20))
                                .tag(TextFont.system)
                            Text("Montserrat")
                                .font(Font.custom("Montserrat", size: 20))
                                .tag(TextFont.montserrat)
                            Text("Pacifico")
                                .font(Font.custom("Pacifico-Regular", size: 20))
                                .tag(TextFont.pacifico)
                        }
                        .pickerStyle(.wheel)
                        .labelsHidden()
                        .frame(width: UIScreen.main.bounds.width, height: 56)
                        .clipped()
                        .frame(width: 128, height: 32)
                        .clipped()
                        .onChange(of: viewModel.font, perform: viewModel.onFontChanged)
                    }
                    
                    HStack {
                        // Undo button
                        Button(action: viewModel.undo) {
                            CircleIcon(systemName: "arrow.uturn.backward", disabled: !viewModel.canUndo)
                                .padding(.all, 4)
                        }
                        .animation(.spring())
                        .disabled(!viewModel.canUndo)
                        
                        // Hide all text views button
                        if viewModel.mode == .text {
                            Button(action: viewModel.hideTextViews) {
                                CircleIcon(systemName: viewModel.isTextVisible ? "eye.slash" : "eye", disabled: !viewModel.canUndo)
                                    .padding(.all, 4)
                            }
                            .disabled(!viewModel.canUndo)
                        }
                        
                        Spacer()
                        
                        // Clear All button
                        Button(action: viewModel.clearAll) {
                            Text("Clear All")
                                .frame(height: 36)
                                .padding(.horizontal, 12)
                                .foregroundColor(viewModel.canUndo ? .light : .gray)
                                .background(viewModel.canUndo ? Color.darkHighlight : Color(red: 44/255, green: 44/255, blue: 44/255))
                                .clipShape(Rectangle())
                                .cornerRadius(36)
                                .padding(.all, 4)
                        }
                        .disabled(!viewModel.canUndo)
                    }
                    .padding(.all, 8)
                    .animation(.spring())
                    .disabled(!viewModel.canUndo)
                }
                .disabled(viewModel.isProcessing)
                       
                Spacer()
    
                GeometryReader { geometry in
                    let frame = geometry.frame(in: .local)
                    let size = viewModel.calculateCanvasSize(bounds: geometry.size)
                                        
                    Group {
                        if viewModel.media.type == .video, let video = viewModel.media.video {
                            PlayerView(asset: video, size: $viewModel.mediaSize)
                        } else if viewModel.media.type == .image, let image = viewModel.media.image {
                            ImageView(
                                image: Binding(get: {
                                    if let filter = viewModel.selectedFilter, let ciImage = CIImage(image: image) {
                                        filter.setValue(ciImage, forKey: kCIInputImageKey)
                                        if let outputImage = filter.outputImage {
                                            let context = CIContext()
                                            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                                                return UIImage(cgImage: cgImage)
                                            }
                                        }
                                    }
                                    return image
                                }, set: { _ in }),
                                imageView: viewModel.imageView,
                                contentMode: Binding(
                                    get: { viewModel.contentMode == .fit ? .scaleAspectFit : .scaleAspectFill },
                                    set: { _ in }
                                )
                            )
                            .onChange(of: viewModel.media) { media in
                                viewModel.calculateImageSize(frame)
                            }
                            .onAppear {
                                viewModel.calculateImageSize(frame)
                            }
                        }
                    }
                    .allowsHitTesting(false) // Required to passthrough touch events to ML Canvas
                    .background(
                        // ML canvas
                        CanvasView(canvas: $viewModel.mlCanvas, shouldBecameFirstResponder: false)
                            .frame(width: size.width, height: size.height)
                    )
                    .overlay(
                        // Main drawing canvas
                        CanvasView(canvas: $viewModel.canvas, onChanged: { drawing in }, onSelectionChanged: viewModel.selectionChanged)
                            .onAppear {
                                viewModel.mlCanvas.mainCanvas = viewModel.canvas
                                viewModel.canvas.mlCanvas = viewModel.mlCanvas
                            }
                            .frame(width: size.width, height: size.height)
                    )
                    
                    if viewModel.media.type == .image {
                        Picker("Select Filter", selection: $viewModel.selectedFilter) {
                            Text("None").tag(nil as CIFilter?)
                            Text("Sepia").tag(CIFilter(name: "CISepiaTone"))
                            Text("Monochrome").tag(CIFilter(name: "CIColorMonochrome"))
                            Text("Vignette").tag(CIFilter(name: "CIVignette"))
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                    }
                }
               
                Spacer()
                
                // Bottom tool bar
                VStack(spacing: 0) {
                    HStack {
                        Button(action: {
                            if viewModel.canUndo {
                                viewModel.isDismissAlertPresented = true
                            } else {
                                viewModel.close()
                            }
                        }) {
                            CircleIcon(systemName: "xmark").padding(.all, 4)
                        }
                        
                        // Mode switcher
                        Picker("Mode", selection: $viewModel.mode) {
                            Text("Draw").tag(DrawingMode.draw)
                            Text("Text").tag(DrawingMode.text)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: viewModel.mode, perform: viewModel.modeChanged)
        
                        // Save button
                        Button(action: viewModel.export) {
                            CircleIcon(systemName: "arrow.down", disabled: !viewModel.canUndo, hidden: viewModel.isProcessing)
                                .padding(.all, 4)
                                .overlay(
                                    viewModel.isProcessing ? ProgressView().foregroundColor(.light) : nil
                                )
                        }
                        .disabled(!viewModel.canUndo)
                    }
                    .frame(height: 50)
                    .padding(.horizontal, 8)
                    .background(Color.dark)
                    .disabled(viewModel.isProcessing)
                    
                    HStack {
                        if viewModel.mode == .draw {
                            viewModel.isDismissAlertPresented ? AnyView(Color.dark) : AnyView(
                                Color(red: 29/255, green: 28/255, blue: 30/255)
                                    .onTapGesture {
                                        viewModel.activateCanvas()
                                    }
                            )
                        } else {
                            ZStack(alignment: .center) {
                                Color.dark.blendMode(BlendMode.sourceAtop).edgesIgnoringSafeArea(.all)
                                if viewModel.selectedTextView != nil {
                                    HStack {
                                        // Text background color picker
                                        Button(action: viewModel.colorTapped) {
                                            Circle()
                                                .fill(Color(viewModel.fillColor))
                                                .frame(width: 33, height: 33)
                                                .overlay(
                                                    Circle().stroke(Color.light, lineWidth: 3)
                                                )
                                                .padding(.leading, 14)
                                                .padding(.trailing, 5)
                                        }
                                        // Text Background switcher
                                        Button(action: viewModel.textStyleTapped) {
                                            Image(systemName: "character")
                                                .frame(width: 34, height: 34)
                                                .foregroundColor(viewModel.textStyle == .fill ? .dark : .light)
                                                .background(viewModel.textStyle == .fill ? Color.light : Color.darkHighlight)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle().stroke(viewModel.textStyle == .none ? Color.darkHighlight : Color.light, lineWidth: 2)
                                                )
                                        }
                                        .padding(.vertical, 4)
                                        
                                        // Brush size slider
                                        FontSlider(
                                            progress: $viewModel.fontSize,
                                            foregroundColor: .light,
                                            backgroundColor: .darkHighlight
                                        )
                                        .frame(height: 36)
                                        .onChange(of: viewModel.fontSize, perform: viewModel.onFontSizeChanged)
                                        
                                        Spacer()
                                        
                                        // Alignment switcher
                                        Button(action: viewModel.alignTextTapped) {
                                            CircleIcon(systemName: viewModel.textAlignments[viewModel.textAlignment] ?? "text.aligncenter")
                                                .padding(.all, 4)
                                        }
                                        
                                        Button(action: viewModel.addText) {
                                            CircleIcon(systemName: "plus")
                                        }
                                        .padding(.leading, 4)
                                        .padding(.trailing, 14)
                                    }
                                } else {
                                    // Text hint
                                    Text(!viewModel.isTextVisible ? "Hide text mode is active" : viewModel.infoText)
                                        .fontWeight(.bold)
                                        .foregroundColor(.light)
                                        .onTapGesture {
                                            if viewModel.isTextVisible { viewModel.addText() }
                                        }
                                }
                            }
                        }
                    }
                    .frame(height: 75.0)
                    .animation(viewModel.mode == .draw ? .easeIn(duration: 0.05).delay(viewModel.mode == .text ? 0.0 : 0.4) : nil, value: viewModel.mode)
                }
            }
            .background(Color.dark.edgesIgnoringSafeArea(.all))
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .alert(isPresented: $viewModel.isDismissAlertPresented) {
            // Cancellation alert
            Alert(
                title: Text("Are you sure?"),
                message: Text("Changes will not be saved"),
                primaryButton: .cancel(Text("Cancel")),
                secondaryButton: .destructive(Text("Leave"), action: {
                    viewModel.close()
                })
            )
        }
        // Present CameraView as a sheet
        .sheet(isPresented: $viewModel.showingCamera) {
            CameraView { image in
                viewModel.handleCapturedImage(image)
            }
        }
    }
}


struct EditorView_Previews: PreviewProvider {
    static var previews: some View {
        EditorView(media: MediaItem(type: .image, image: UIImage(named: "venice")!, video: nil, videoUrl: nil), onClose: { })
    }
}


/// Editing mode
enum DrawingMode: String, CaseIterable, Identifiable {
    case draw, text
    var id: Self { self }
}

/// Available fonts
enum TextFont: String, CaseIterable, Identifiable {
    case system, montserrat = "Montserrat-Black", pacifico = "Pacifico-Regular"
    var id: Self { self }
}

/// Text background mode
enum TextBackground: String  {
    case none = "character", border = "a.square", fill = "a.square.fill"
    static let allValues: [TextBackground] = [.none, .border, .fill]
}



import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onImageCaptured: (UIImage) -> Void

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView

        init(parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
