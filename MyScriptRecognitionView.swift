//
//  MyScriptRecognitionView.swift
//  its-algebra
//
//  SwiftUI view that integrates MyScript real-time recognition with PencilKit
//

import SwiftUI
import PencilKit
import UIKit

struct MyScriptRecognitionView: View {
    @State private var drawing = PKDrawing()
    @State private var recognizedText: String = ""
    @State private var isRecognizing = false
    
    var body: some View {
        VStack {
            // Recognized text display
            if !recognizedText.isEmpty {
                Text("Recognized: \(recognizedText)")
                    .padding()
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Canvas with MyScript integration
            MyScriptCanvasWrapper(
                drawing: $drawing,
                recognizedText: $recognizedText,
                isRecognizing: $isRecognizing
            )
        }
        .onAppear {
            // Initialize MyScript SDK on appear
            _ = MyScriptManager.shared.initialize()
            _ = MyScriptManager.shared.createTextEditor()
        }
    }
}

struct MyScriptCanvasWrapper: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var recognizedText: String
    @Binding var isRecognizing: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 15)
        canvas.backgroundColor = .white
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: MyScriptCanvasWrapper
        private var recognitionTimer: Timer?
        
        init(_ parent: MyScriptCanvasWrapper) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            
            // Process strokes for real-time recognition
            processStrokesForRecognition(canvasView.drawing)
        }
        
        private func processStrokesForRecognition(_ drawing: PKDrawing) {
            // Cancel previous recognition timer
            recognitionTimer?.invalidate()
            
            // Debounce recognition to avoid too frequent updates
            recognitionTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                self?.performRecognition(drawing)
            }
        }
        
        private func performRecognition(_ drawing: PKDrawing) {
            guard !parent.isRecognizing else { return }
            
            parent.isRecognizing = true
            
            // Process all strokes in the drawing
            var allRecognizedText: [String] = []
            
            for stroke in drawing.strokes {
                if let text = MyScriptManager.shared.processStroke(stroke, from: drawing) {
                    allRecognizedText.append(text)
                }
            }
            
            // Update recognized text
            DispatchQueue.main.async {
                self.parent.recognizedText = allRecognizedText.joined(separator: " ")
                self.parent.isRecognizing = false
            }
        }
    }
}

