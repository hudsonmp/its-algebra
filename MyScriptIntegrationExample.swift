//
//  MyScriptIntegrationExample.swift
//  its-algebra
//
//  Example showing how to integrate MyScript recognition into DrawingCanvasView
//  This is a reference implementation - integrate these changes into DrawingCanvasView.swift
//

import SwiftUI
import PencilKit

// MARK: - Example: Enhanced DrawingCanvasView with MyScript

struct DrawingCanvasViewWithMyScript: View {
    @State private var studentCanvasDrawing = PKDrawing()
    @State private var testCanvasDrawing = PKDrawing()
    @State private var selectedTool: DrawingTool = .pen
    @State private var zoomScale: CGFloat = 1.0
    @State private var studentCanvasUndoManager: UndoManager?
    
    // MyScript integration state
    @State private var myScriptService: MyScriptService?
    @State private var recognizedText: String = ""
    @State private var isRecognizing: Bool = false
    @State private var recognitionError: String?
    @State private var recognitionTimer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Student work area - 2/3 of screen
                StudentWorkArea(
                    drawing: $studentCanvasDrawing,
                    selectedTool: $selectedTool,
                    zoomScale: $zoomScale,
                    undoManager: $studentCanvasUndoManager
                )
                .frame(width: geometry.size.width * 2/3)
                
                Divider()
                
                // Recognition results area - 1/3 of screen
                RecognitionResultsArea(
                    recognizedText: $recognizedText,
                    isRecognizing: $isRecognizing,
                    error: $recognitionError,
                    onRecognize: {
                        recognizeDrawing()
                    }
                )
                .frame(width: geometry.size.width * 1/3)
            }
            .overlay(
                ToolbarViewWithRecognition(
                    selectedTool: $selectedTool,
                    zoomScale: $zoomScale,
                    isRecognizing: isRecognizing,
                    onUndo: {
                        studentCanvasUndoManager?.undo()
                    },
                    onRedo: {
                        studentCanvasUndoManager?.redo()
                    },
                    onRecognize: {
                        recognizeDrawing()
                    }
                ),
                alignment: .top
            )
        }
        .onAppear {
            initializeMyScript()
        }
        .onChange(of: studentCanvasDrawing) { _ in
            // Optional: Auto-recognize after user stops drawing (debounced)
            scheduleAutoRecognition()
        }
    }
    
    // MARK: - MyScript Integration Methods
    
    private func initializeMyScript() {
        // Initialize MyScript service
        myScriptService = MyScriptService()
        
        // Verify credentials are set
        if MyScriptConfig.applicationKey == "YOUR_APPLICATION_KEY_HERE" {
            recognitionError = "Please configure MyScript credentials in MyScriptConfig"
        }
    }
    
    private func recognizeDrawing() {
        guard let service = myScriptService else { return }
        guard !studentCanvasDrawing.strokes.isEmpty else {
            recognitionError = "No strokes to recognize"
            return
        }
        
        isRecognizing = true
        recognitionError = nil
        
        // Recognize as text (for algebra, you might want to use recognizeMath instead)
        service.recognizeText(from: studentCanvasDrawing) { result in
            DispatchQueue.main.async {
                isRecognizing = false
                
                switch result {
                case .success(let text):
                    recognizedText = text
                    recognitionError = nil
                    print("Recognized: \(text)")
                    
                case .failure(let error):
                    recognitionError = error.localizedDescription
                    print("Recognition error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func recognizeMath() {
        guard let service = myScriptService else { return }
        guard !studentCanvasDrawing.strokes.isEmpty else {
            recognitionError = "No strokes to recognize"
            return
        }
        
        isRecognizing = true
        recognitionError = nil
        
        // Recognize as math expression
        service.recognizeMath(from: studentCanvasDrawing) { result in
            DispatchQueue.main.async {
                isRecognizing = false
                
                switch result {
                case .success(let math):
                    recognizedText = math
                    recognitionError = nil
                    print("Recognized math: \(math)")
                    
                case .failure(let error):
                    recognitionError = error.localizedDescription
                    print("Recognition error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Debounced auto-recognition (recognizes 1 second after user stops drawing)
    private func scheduleAutoRecognition() {
        recognitionTimer?.invalidate()
        recognitionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            // Only auto-recognize if there are strokes
            if !studentCanvasDrawing.strokes.isEmpty {
                recognizeDrawing()
            }
        }
    }
}

// MARK: - Recognition Results Area

struct RecognitionResultsArea: View {
    @Binding var recognizedText: String
    @Binding var isRecognizing: Bool
    @Binding var error: String?
    let onRecognize: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Recognition Results")
                    .font(.headline)
                Spacer()
                Button(action: onRecognize) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                }
                .disabled(isRecognizing)
            }
            .padding()
            
            Divider()
            
            // Recognition status
            if isRecognizing {
                HStack {
                    ProgressView()
                    Text("Recognizing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Error display
            if let error = error {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                    }
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            // Recognized text display
            ScrollView {
                if recognizedText.isEmpty {
                    VStack {
                        Image(systemName: "hand.draw")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No recognition yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Draw on the canvas and tap recognize")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    Text(recognizedText)
                        .font(.body)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .background(Color.gray.opacity(0.05))
    }
}

// MARK: - Enhanced Toolbar with Recognition Button

struct ToolbarViewWithRecognition: View {
    @Binding var selectedTool: DrawingTool
    @Binding var zoomScale: CGFloat
    let isRecognizing: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onRecognize: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                // Pen/Pencil button
                Button(action: {
                    selectedTool = .pen
                }) {
                    Image(systemName: "pencil")
                        .font(.title2)
                        .foregroundColor(selectedTool == .pen ? .blue : .gray)
                        .padding()
                        .background(selectedTool == .pen ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                
                // Eraser button
                Button(action: {
                    selectedTool = .eraser
                }) {
                    Image(systemName: "eraser")
                        .font(.title2)
                        .foregroundColor(selectedTool == .eraser ? .blue : .gray)
                        .padding()
                        .background(selectedTool == .eraser ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                
                Divider()
                    .frame(height: 30)
                
                // Undo button
                Button(action: onUndo) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // Redo button
                Button(action: onRedo) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                Divider()
                    .frame(height: 30)
                
                // Recognition button
                Button(action: onRecognize) {
                    HStack {
                        if isRecognizing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Recognize")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .disabled(isRecognizing)
                
                Divider()
                    .frame(height: 30)
                
                // Zoom out button
                Button(action: {
                    withAnimation {
                        zoomScale = max(0.5, zoomScale - 0.25)
                    }
                }) {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // Zoom in button
                Button(action: {
                    withAnimation {
                        zoomScale = min(5.0, zoomScale + 0.25)
                    }
                }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .padding()
                }
                
                // Reset zoom button
                Button(action: {
                    withAnimation {
                        zoomScale = 1.0
                    }
                }) {
                    Text("1:1")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(radius: 5)
            
            Spacer()
        }
        .padding()
    }
}

