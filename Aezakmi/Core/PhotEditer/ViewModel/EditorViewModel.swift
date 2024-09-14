//
//  EditorViewModel.swift
//  Aezakmi
//
//  Created by Abobakr Al Zain  on 14.09.2024.
//

import SwiftUI
import PencilKit
import AVKit
import Photos
import Combine

class EditorViewModel: ObservableObject {
    // Published properties to update the view
    @Published var canvas = Canvas()
    @Published var mlCanvas = MLCanvas()
    @Published var toolPicker: PKToolPicker?
    @Published var canvasController: CanvasViewController<Canvas>?
    
    @Published var mode: DrawingMode = .draw
    @Published var fontSize: Float = 50.0
    @Published var infoText: String = "Tap to add text"
    @Published var textAlignment: NSTextAlignment = .center
    
    @Published var canUndo = false
    @Published var selectedTextView: UIView?
    @Published var isTextVisible = true
    @Published var isProcessing = false
    @Published var isDismissAlertPresented = false
    
    @Published var mediaSize: CGSize?
    @Published var imageView = UIImageView()
    @Published var contentMode: ContentMode = .fit
    
    @Published var fillColor: UIColor = .white
    @Published var textStyle: TextBackground = .none
    @Published var font: TextFont = .system
    
    @Published var selectedFilter: CIFilter? = nil
    
    // Camera presentation
    @Published var showingCamera = false
    
    // The media item being edited
    @Published var media: MediaItem
    
    // Callback when editing is done or canceled
    var onClose: () -> Void
    
    private var undoObserver: AnyCancellable?
    
    // Text alignments mapping
    let textAlignments: [NSTextAlignment: String] = [
        .center: "text.aligncenter",
        .left: "text.alignleft",
        .right: "text.alignright"
    ]
    
    // Fill and text colors
    let fillColors: [UIColor] = [
        .white, UIColor.dark, .systemYellow, .systemGreen, .systemBlue, .systemPurple, .systemPink, .systemRed, .systemOrange,
    ]
    
    let textColors: [UIColor: UIColor] = [
        .white: UIColor.dark,
        UIColor.dark: .white,
        .systemYellow: .white,
        .systemGreen: .white,
        .systemBlue: .white,
        .systemPurple: .white,
        .systemPink: .white,
        .systemRed: .white,
        .systemOrange: .white,
    ]
    
    init(media: MediaItem, onClose: @escaping () -> Void) {
        self.media = media
        self.onClose = onClose
        
        // Configure UI Appearance
        UIPickerView.appearance().backgroundColor = UIColor(red: 17/255, green: 16/255, blue: 14/255, alpha: 1.0)
        
        let appearance = UISegmentedControl.appearance()
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.dark], for: .selected)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.light], for: .normal)
        UISegmentedControl.appearance().backgroundColor = UIColor(red: 21/255, green: 21/255, blue: 17/255, alpha: 1.0)
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1.0)
        
        // Observe undo manager
        undoObserver = NotificationCenter.default.publisher(for: .NSUndoManagerCheckpoint)
            .sink { [weak self] _ in
                self?.canUndo = self?.canvas.undoManager?.canUndo ?? false
            }
    }
    
    // MARK: - Camera Handling
    
    func takePhoto() {
        // Check camera availability
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showingCamera = true
        } else {
            // Handle the absence of a camera, possibly show an alert
            // For simplicity, we'll just print an error
            print("Camera not available on this device.")
        }
    }
    
    func handleCapturedImage(_ image: UIImage) {
        // Update the media with the captured image
        self.media = MediaItem(type: .image, image: image, video: nil, videoUrl: nil)
        // Recalculate image size if needed
        // Assuming you have a method to do so
    }
    
    // MARK: - Core Editing Functions
    
    func undo() {
        canvas.undoManager?.undo()
        canvas.previous = canvas.drawing
        
        // Clear for cases when some of drawings were persisted on temporary canvas
        mlCanvas.drawing = PKDrawing()
        
        resetSelection()
    }
    
    func hideTextViews() {
        isTextVisible.toggle()
        changeTextsVisibility(visible: isTextVisible)
        resetSelection()
    }
    
    func clearAll() {
        let labels: [UIView] = canvasController?.view.subviews.filter { $0 is UILabel } ?? []
        
        if (canvas.drawing.strokes.isEmpty && labels.isEmpty) {
            // Empty canvas
            return
        }
        
        // Commented out to preserve undo actions for clearing all
        let original = canvas.drawing
        canvas.undoManager?.registerUndo(withTarget: canvas, handler: { targetCanvas in
            targetCanvas.drawing = original
            for label in labels {
                self.canvasController?.view.addSubview(label)
            }
        })
        canvas.drawing = PKDrawing()
        mlCanvas.drawing = PKDrawing()
        
        for label in labels {
            label.removeFromSuperview()
        }
        
        resetSelection()
    }
    
    func addText() {
        if canvasController == nil {
            canvasController = canvas.parentViewController as? CanvasViewController<Canvas>
        }
        
        canvasController?.showTextAlert(title: "Add text", text: nil, actionTitle: "Add") { text in
            self.addTextView(text)
        }
    }
    
    func addTextView(_ text: String) {
        guard let controller = canvasController else { return }
        let label = TextLabel(frame: CGRect(x: controller.view.center.x - 128, y: controller.view.center.y - 64, width: 256, height: 128))
        label.accessibilityIdentifier = "textview_\(Int.random(in: 0..<65536))"
        label.numberOfLines = 0
        
        label.text = text
        label.textColor = .white
        label.textAlignment = .center

        let labelSize = label.intrinsicContentSize
        label.bounds.size = CGSize(width: labelSize.width + 32, height: labelSize.height + 24)
        
        label.layer.cornerRadius = 16
        label.layer.borderWidth = 3
        label.layer.borderColor = UIColor.white.cgColor
        label.tag = 1
        label.layer.masksToBounds = true
        label.styledLayer = label.layer.copied

        label.isHidden = !isTextVisible

        // Enable multiple touch and user interaction
        label.isUserInteractionEnabled = true
        label.isMultipleTouchEnabled = true
                
        canvas.undoManager?.registerUndo(withTarget: canvas, handler: { _ in
            label.removeFromSuperview()
        })
        
        controller.registerGestures(for: label)
        controller.view.addSubview(label)
        
        resetSelection()
        controller.selectSubview(label)
        
        if !isTextVisible {
            isTextVisible = true
            changeTextsVisibility(visible: true)
        }
    }
    
    func colorTapped() {
        guard let label = selectedTextView as? TextLabel, let old = fillColors.firstIndex(where: {
            switch textStyle {
            case .none, .border:
                return label.textColor == $0
            case .fill:
                return label.layer.backgroundColor == $0.cgColor
            }
        }) else { return }
        
        let index = (old + 1) < fillColors.count ? old + 1 : 0
        switch textStyle {
        case .none:
            label.textColor = fillColors[index]
            label.backgroundColor = .clear
            label.layer.backgroundColor = UIColor.clear.cgColor
        case .border:
            label.textColor = fillColors[index]
            label.backgroundColor = .clear
            label.layer.backgroundColor = UIColor.clear.cgColor
            label.layer.borderColor = fillColors[index].cgColor
            label.styledLayer.borderColor = fillColors[index].cgColor
        case .fill:
            let color = fillColors[index]
            label.backgroundColor = color
            label.layer.backgroundColor = color.cgColor
            label.textColor = textColors[color] ?? .white
        }
        
        fillColor = fillColors[index]
    }
    
    func onFontChanged(_ value: TextFont) {
        guard let label = selectedTextView as? TextLabel else { return }
        let size = label.font.pointSize
        switch value {
        case .system:
            label.font = .systemFont(ofSize: size)
        case .montserrat:
            label.font = UIFont(name: "Montserrat", size: size) ?? .systemFont(ofSize: size)
        case .pacifico:
            label.font = UIFont(name: "Pacifico-Regular", size: size) ?? .systemFont(ofSize: size)
        }
        
        // Resize
        let labelSize = label.intrinsicContentSize
        label.bounds.size = CGSize(width: labelSize.width + 32, height: labelSize.height + 24)
    }
    
    func onFontSizeChanged(_ value: Float) {
        guard let label = selectedTextView as? UILabel else { return }
        
        // Font size from 12 to 64
        label.font = label.font.withSize(CGFloat(value * 52.0) / 100.0 + 12.0)
        
        // Resize
        let labelSize = label.intrinsicContentSize
        label.bounds.size = CGSize(width: labelSize.width + 32, height: labelSize.height + 24)
    }
    
    func alignTextTapped() {
        guard let label = selectedTextView as? UILabel else { return }
        switch textAlignment {
        case .left:
            textAlignment = .center
        case .center:
            textAlignment = .right
        case .right:
            textAlignment = .left
        default:
            return
        }
        label.textAlignment = textAlignment
    }
    
    func textStyleTapped() {
        guard let label = selectedTextView as? TextLabel else { return }
        
        switch textStyle {
        case .none:
            textStyle = .border
            // Border
            label.backgroundColor = .clear
            label.layer.backgroundColor = UIColor.clear.cgColor
            label.layer.borderWidth = 3
            label.layer.borderColor = label.textColor.cgColor
            label.tag = 1
            fillColor = label.textColor
        case .border:
            textStyle = .fill
            // Fill
            label.textColor = textColors[.white] ?? .white
            label.backgroundColor = .white
            label.layer.backgroundColor = UIColor.white.cgColor
            label.layer.borderWidth = 0
            label.tag = 2
            fillColor = .white
        case .fill:
            textStyle = .none
            // Simple
            label.layer.backgroundColor = UIColor.clear.cgColor
            label.backgroundColor = .clear
            label.layer.borderWidth = 0
            label.tag = 0
            fillColor = label.textColor
        }
        label.styledLayer = label.layer.copied
    }
    
    func export() {
        withAnimation {
            isProcessing = true
        }

        if canvasController == nil {
            canvasController = canvas.parentViewController as? CanvasViewController<Canvas>
        }
        guard let canvasController = canvasController else { return }

        // Render the controller view (contains drawing and text views)
        let renderer = UIGraphicsImageRenderer(size: canvasController.view.bounds.size)
        let markup = renderer.image { ctx in
            canvasController.view.drawHierarchy(in: canvasController.view.bounds, afterScreenUpdates: true)
        }

        // Export image or video with filter applied if available
        if media.type == .image, let image = media.image {
            // Check if a filter is selected and apply it before exporting
            var finalImage = image
            
            if let filter = selectedFilter, let ciImage = CIImage(image: image) {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                if let outputImage = filter.outputImage {
                    let context = CIContext()
                    if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                        finalImage = UIImage(cgImage: cgImage)
                    }
                }
            }
            
            // Export image with markup and filtered image
            MediaProcessor.exportImage(image: finalImage, markup: markup, contentMode: contentMode, imageView: imageView)
            
            withAnimation { isProcessing = false }
            close()
        } else if media.type == .video, let videoUrl = media.videoUrl {
            // Export video with markup (for now, no filters applied to video)
            let sketchLayer = CALayer()
            sketchLayer.contents = markup.cgImage
            sketchLayer.frame = CGRect(x: 0, y: 0, width: markup.size.width, height: markup.size.height)
            
            MediaProcessor.exportVideo(url: videoUrl, layer: sketchLayer, onSuccess: {
                withAnimation { self.isProcessing = false }
                self.close()
            }, onError: {
                withAnimation { self.isProcessing = false }
            })
        }
    }
    
    func close() {
        defer { onClose() }
        mode = .draw
        
        toolPicker?.isRulerActive = false
        toolPicker?.setVisible(false, forFirstResponder: canvas)
        canvas.isUserInteractionEnabled = false
        mlCanvas.isUserInteractionEnabled = false
        
        contentMode = .fit
        isTextVisible = true
        mediaSize = nil

        let labels: [UIView] = canvasController?.view.subviews.filter { $0 is UILabel } ?? []
        
        if (canvas.drawing.strokes.isEmpty && labels.isEmpty) {
            // Empty canvas
            return
        }
        
        canvas.drawing = PKDrawing()
        mlCanvas.drawing = PKDrawing()
        canvas.undoManager?.removeAllActions()
        
        for label in labels {
            label.removeFromSuperview()
        }
        
        resetSelection()
    }
    
    func modeChanged(_ selected: DrawingMode) {
        if canvasController == nil {
            canvasController = canvas.parentViewController as? CanvasViewController<Canvas>
        }
        if toolPicker == nil {
            toolPicker = canvasController?.toolPicker
        }
        
        // Show/hide PKToolPicker
        if selected == .text {
            toolPicker?.isRulerActive = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.toolPicker?.setVisible(false, forFirstResponder: self.canvas)
                self.canvas.isUserInteractionEnabled = false
                self.mlCanvas.isUserInteractionEnabled = false
            }
            
            let labels: [UIView] = canvasController?.view.subviews.filter { $0 is UILabel } ?? []
            infoText = labels.isEmpty ? "Tap to add text" : "Tap any text to customize"
            
            canvasController?.selectionEnabled = true
        } else {
            activateCanvas()
            
            canvas.isUserInteractionEnabled = true
            mlCanvas.isUserInteractionEnabled = true
            toolPicker?.setVisible(true, forFirstResponder: canvas)
            
            activateCanvas()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.activateCanvas()
            }
            
            canvasController?.selectionEnabled = false
        }
        resetSelection()
    }
    
    func activateCanvas() {
        canvas.becomeFirstResponder()
        canvas.resignFirstResponder()
        canvas.becomeFirstResponder()
    }
    
    func resetSelection() {
        if let view = selectedTextView {
            canvasController?.deselectSubview(view)
        }
        textAlignment = .center
    }
    
    func selectionChanged(_ view: UIView?) {
        selectedTextView = view
                                    
        let label = view as? UILabel

        let pointSize = Float(label?.font.pointSize ?? 17.0)
        fontSize = ((pointSize - 12.0) * 100.0) / 52.0
        
        textAlignment = label?.textAlignment ?? .center
        
        guard let index = label?.tag, index >= 0, index < TextBackground.allValues.count else { return }
        textStyle = TextBackground.allValues[index]
        
        switch textStyle {
        case .none, .border:
            fillColor = label?.textColor ?? .white
        case .fill:
            fillColor = label?.backgroundColor ?? .white
        }
        
        // Font
        switch label?.font.fontName {
        case TextFont.montserrat.rawValue:
            font = .montserrat
        case TextFont.pacifico.rawValue:
            font = .pacifico
        default:
            font = .system
        }
        
        infoText = "Tap any text to customize"
    }
    
    // MARK: - Helper Methods
    
    func changeTextsVisibility(visible: Bool) {
        for view in canvasController?.view.subviews ?? [] {
            if view is UILabel {
                view.isHidden = !visible
            }
        }
    }
    
    func calculateCanvasSize(bounds: CGSize) -> CGSize {
        if media.type == .image {
            if contentMode == .fill {
                return bounds
            } else {
                return imageView.aspectFitSize
            }
        }
        
        // Video
        return CGSize(
            width: mediaSize?.width ?? bounds.width,
            height: mediaSize?.height ?? bounds.height
        )
    }
    
    func calculateImageSize(_ frame: CGRect) {
        guard media.type == .image && contentMode == .fit else { return }
        
        guard let image = media.image else { return }
        
        let size = image.size
        
        var newWidth: CGFloat
        var newHeight: CGFloat

        if size.height >= size.width {
            newHeight = frame.size.height
            newWidth = (size.width / size.height) * newHeight

            if newWidth > frame.size.width {
                let diff = frame.size.width - newWidth
                newHeight += diff / newHeight * newHeight
                newWidth = frame.size.width
            }
        } else {
            newWidth = frame.size.width
            newHeight = (size.height / size.width) * newWidth

            if newHeight > frame.size.height {
                let diff = frame.size.height - newHeight
                newWidth += CGFloat(diff) / newWidth * newWidth
                newHeight = frame.size.height
            }
        }

        mediaSize = CGSize(width: newWidth, height: newHeight)
    }
}
