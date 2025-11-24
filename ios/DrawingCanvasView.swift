//
//  DrawingCanvasView.swift
//  its-algebra
//
//  Main canvas view with split layout: 2/3 student work area, 1/3 PencilKit testing area
//

import SwiftUI
import PencilKit
import UIKit

// Notification names for MyScript recognition updates
extension Notification.Name {
    static let myScriptRecognitionUpdate = Notification.Name("myScriptRecognitionUpdate")
    static let myScriptProcessingStarted = Notification.Name("myScriptProcessingStarted")
}

struct DrawingCanvasView: View {
    @State private var studentCanvasDrawing = PKDrawing()
    @State private var testCanvasDrawing = PKDrawing()
    @State private var selectedTool: DrawingTool = .pen
    @State private var zoomScale: CGFloat = 1.0
    @State private var studentCanvasUndoManager: UndoManager?
    @State private var recognizedText: String = ""
    @State private var latexOutput: String = ""
    @State private var isMyScriptInitialized = false
    @State private var isFullscreen = false
    @State private var eraserMode: EraserMode = .object
    @State private var eraserSize: CGFloat = 20.0
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Recognized text display
                if !recognizedText.isEmpty {
                    HStack {
                        Text("Recognized: \(recognizedText)")
                            .font(.headline)
                            .padding()
                        Spacer()
                        Button("Clear") {
                            recognizedText = ""
                            MyScriptManager.shared.clear()
                        }
                        .padding()
                    }
                    .background(Color.yellow.opacity(0.2))
                }
                
                HStack(spacing: 0) {
                    // Student work area - 2/3 of screen
                    StudentWorkArea(
                        drawing: $studentCanvasDrawing,
                        selectedTool: $selectedTool,
                        zoomScale: $zoomScale,
                        undoManager: $studentCanvasUndoManager,
                        recognizedText: $recognizedText,
                        latexOutput: $latexOutput,
                        eraserMode: $eraserMode,
                        eraserSize: $eraserSize
                    )
                    .frame(width: geometry.size.width * 2/3)
                    
                    Divider()
                    
                // LaTeX output area - 1/3 of screen
                LaTeXOutputArea(latexOutput: $latexOutput)
                    .frame(width: geometry.size.width * 1/3)
                }
                .overlay(
                    ToolbarView(
                        selectedTool: $selectedTool,
                        zoomScale: $zoomScale,
                        isFullscreen: $isFullscreen,
                        eraserMode: $eraserMode,
                        eraserSize: $eraserSize,
                        onUndo: {
                            studentCanvasUndoManager?.undo()
                        },
                        onRedo: {
                            studentCanvasUndoManager?.redo()
                        }
                    ),
                    alignment: .top
                )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
        }
        .ignoresSafeArea(.all)
        .statusBarHidden(isFullscreen)
        .onAppear {
            // Initialize MyScript SDK
            if !isMyScriptInitialized {
                isMyScriptInitialized = MyScriptManager.shared.initialize()
                _ = MyScriptManager.shared.createTextEditor()
            }
        }
    }
}

// MARK: - Student Work Area

struct StudentWorkArea: View {
    @Binding var drawing: PKDrawing
    @Binding var selectedTool: DrawingTool
    @Binding var zoomScale: CGFloat
    @Binding var undoManager: UndoManager?
    @Binding var recognizedText: String
    @Binding var latexOutput: String
    @Binding var eraserMode: EraserMode
    @Binding var eraserSize: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                
                CanvasWrapper(
                    drawing: $drawing,
                    selectedTool: $selectedTool,
                    zoomScale: $zoomScale,
                    undoManager: $undoManager,
                    recognizedText: $recognizedText,
                    latexOutput: $latexOutput,
                    eraserMode: $eraserMode,
                    eraserSize: $eraserSize,
                    frame: CGRect(origin: .zero, size: geometry.size)
                )
            }
        }
    }
}

// MARK: - LaTeX Output Area

struct LaTeXOutputArea: View {
    @Binding var latexOutput: String
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.05)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("LaTeX Output")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.top)
                
                Divider()
                
                if latexOutput.isEmpty {
                    VStack {
                        Spacer()
                        Text("Draw on the canvas to see LaTeX output")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            // LaTeX code display
                            VStack(alignment: .leading, spacing: 5) {
                                Text("LaTeX Code:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(latexOutput)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            // Rendered preview (simplified)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Rendered:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(renderLatexPreview(latexOutput))
                                    .font(.title2)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private func renderLatexPreview(_ latex: String) -> String {
        // Simple preview rendering (actual LaTeX rendering would require MathJax or similar)
        var preview = latex
        
        // Remove LaTeX commands for basic preview
        preview = preview.replacingOccurrences(of: "\\frac{", with: "(")
        preview = preview.replacingOccurrences(of: "\\sqrt{", with: "√(")
        preview = preview.replacingOccurrences(of: "\\times", with: "×")
        preview = preview.replacingOccurrences(of: "\\div", with: "÷")
        preview = preview.replacingOccurrences(of: "\\leq", with: "≤")
        preview = preview.replacingOccurrences(of: "\\geq", with: "≥")
        preview = preview.replacingOccurrences(of: "\\neq", with: "≠")
        preview = preview.replacingOccurrences(of: "\\pi", with: "π")
        preview = preview.replacingOccurrences(of: "\\infty", with: "∞")
        preview = preview.replacingOccurrences(of: "}", with: ")")
        preview = preview.replacingOccurrences(of: "\\sum", with: "Σ")
        preview = preview.replacingOccurrences(of: "\\int", with: "∫")
        
        return preview
    }
}

// MARK: - Canvas Wrapper (Student Area)

struct CanvasWrapper: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var selectedTool: DrawingTool
    @Binding var zoomScale: CGFloat
    @Binding var undoManager: UndoManager?
    @Binding var recognizedText: String
    @Binding var latexOutput: String
    @Binding var eraserMode: EraserMode
    @Binding var eraserSize: CGFloat
    var frame: CGRect
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        // Create the canvas view
        let canvas = PKCanvasView()
        // Only allow Apple Pencil for drawing - fingers will be used for zoom/pan
        canvas.drawingPolicy = .pencilOnly
        canvas.tool = selectedTool.toPKTool(eraserMode: eraserMode, eraserSize: eraserSize)
        canvas.backgroundColor = .white
        canvas.drawing = drawing
        // Remove shadow/glow effects from strokes
        canvas.layer.shadowOpacity = 0
        canvas.layer.shadowRadius = 0
        
        // Apple Pencil Pro hover effects are enabled by default on iOS 17.5+
        // No explicit API needed - PKCanvasView handles it automatically
        
        // Enable undo/redo (PKCanvasView has built-in undoManager)
        let undoMgr = canvas.undoManager ?? UndoManager()
        
        // Create scroll view for zoom and pan (finger gestures)
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = zoomScale
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        // Enable pinch-to-zoom with fingers
        scrollView.pinchGestureRecognizer?.isEnabled = true
        
        // Set canvas frame to match scroll view bounds
        canvas.frame = CGRect(origin: .zero, size: frame.size)
        scrollView.addSubview(canvas)
        scrollView.contentSize = frame.size
        
        // Store references
        context.coordinator.scrollView = scrollView
        context.coordinator.canvas = canvas
        context.coordinator.undoManager = undoMgr
        
        // Update the binding with undo manager asynchronously to avoid state modification during view update
        DispatchQueue.main.async {
            undoManager = undoMgr
        }
        
        // Set canvas delegate to handle drawing changes
        canvas.delegate = context.coordinator
        
        // Set up Apple Pencil Pro support
        if #available(iOS 17.5, *) {
            context.coordinator.setupPencilProGestures(for: canvas)
        }
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Update zoom scale if changed externally
        if abs(scrollView.zoomScale - zoomScale) > 0.01 {
            scrollView.setZoomScale(zoomScale, animated: true)
        }
        
        // Update tool
        if let canvas = context.coordinator.canvas {
            // Always update tool when selected tool changes or eraser settings change
            canvas.tool = selectedTool.toPKTool(eraserMode: eraserMode, eraserSize: eraserSize)
            
            // Don't overwrite canvas drawing - let the delegate handle updates
            // The canvas maintains its own state, and we sync FROM canvas TO binding via delegate
        }
        
        // Update canvas frame to match scroll view bounds
        let bounds = scrollView.bounds
        if let canvas = context.coordinator.canvas {
            canvas.frame = CGRect(origin: .zero, size: bounds.size)
            scrollView.contentSize = bounds.size
        }
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate, PKCanvasViewDelegate {
        var parent: CanvasWrapper
        var scrollView: UIScrollView?
        var canvas: PKCanvasView?
        var undoManager: UndoManager?
        private var recognitionTimer: Timer?
        
        init(_ parent: CanvasWrapper) {
            self.parent = parent
        }
        
        deinit {
            recognitionTimer?.invalidate()
        }
        
        @available(iOS 17.5, *)
        func setupPencilProGestures(for canvas: PKCanvasView) {
            // Apple Pencil Pro features (hover, squeeze, barrel roll) are handled
            // automatically by PKCanvasView and PKToolPicker on iOS 17.5+
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return canvas
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            parent.zoomScale = scrollView.zoomScale
            // Update content size to allow scrolling when zoomed
            if let canvas = canvas {
                let frame = canvas.frame
                scrollView.contentSize = CGSize(width: frame.width * scrollView.zoomScale, 
                                               height: frame.height * scrollView.zoomScale)
            }
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            // Ensure content size is correct after zoom
            if let canvas = canvas {
                let frame = canvas.frame
                scrollView.contentSize = CGSize(width: frame.width * scale, 
                                               height: frame.height * scale)
            }
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Update the binding when drawing changes (including erasing)
            parent.drawing = canvasView.drawing
            
            // Process strokes for MyScript real-time recognition
            // This will trigger even when erasing (drawing changes)
            processStrokesForRecognition(canvasView.drawing)
        }
        
        // Apple Pencil Pro barrel roll and other features are handled automatically
        // by PKCanvasView on iOS 17.5+ - no additional delegate methods needed
        
        private func processStrokesForRecognition(_ drawing: PKDrawing) {
            // Cancel previous recognition timer
            recognitionTimer?.invalidate()
            
            // Notify processing started
            NotificationCenter.default.post(name: .myScriptProcessingStarted, object: nil)
            
            // Debounce recognition to avoid too frequent updates (300ms delay)
            recognitionTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] timer in
                self?.performRecognition(drawing)
                timer.invalidate()
            }
        }
        
        private func performRecognition(_ drawing: PKDrawing) {
            let strokeCount = drawing.strokes.count
            
            // Clear recognition if no strokes
            guard strokeCount > 0 else {
                DispatchQueue.main.async {
                    self.parent.recognizedText = ""
                    self.parent.latexOutput = ""
                }
                return
            }
            
            // Process the entire drawing context (MyScript works better with full context)
            guard let recognizedText = MyScriptManager.shared.processDrawing(drawing) else {
                // SDK not available or no recognition result
                DispatchQueue.main.async {
                    self.parent.recognizedText = "MyScript SDK not initialized"
                    self.parent.latexOutput = ""
                }
                return
            }
            
            // Convert to LaTeX format
            let latex = LaTeXFormatter.shared.formatAsLaTeX(recognizedText)
            
            // Update recognized text and LaTeX output on main thread
            DispatchQueue.main.async {
                self.parent.recognizedText = recognizedText
                self.parent.latexOutput = latex
            }
        }
    }
}

// MARK: - Test Canvas Wrapper

struct TestCanvasWrapper: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    
    func makeCoordinator() -> TestCoordinator {
        TestCoordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 15)
        canvas.backgroundColor = .white
        canvas.drawing = drawing
        
        // Apple Pencil Pro hover effects are enabled by default on iOS 17.5+
        // No explicit API needed - PKCanvasView handles it automatically
        
        canvas.delegate = context.coordinator
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
    
    class TestCoordinator: NSObject, PKCanvasViewDelegate {
        var parent: TestCanvasWrapper
        
        init(_ parent: TestCanvasWrapper) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Eraser Mode Enum

enum EraserMode {
    case object  // Erases entire strokes
    case pixel   // Erases pixels
    
    var pkEraserType: PKEraserTool.EraserType {
        switch self {
        case .object:
            return .vector
        case .pixel:
            return .bitmap
        }
    }
}

// MARK: - Drawing Tool Enum

enum DrawingTool {
    case pen
    case eraser
    
    func toPKTool(eraserMode: EraserMode = .object, eraserSize: CGFloat = 20.0) -> PKTool {
        switch self {
        case .pen:
            // Create pen tool without shadow/glow effect
            // Using a narrower width and ensuring no glow
            return PKInkingTool(.pen, color: .black, width: 2.0)
        case .eraser:
            // PKEraserTool(width:) is iOS 16.4+, use compatible version for iOS 14.0
            if #available(iOS 16.4, *) {
                return PKEraserTool(eraserMode.pkEraserType, width: eraserSize)
            } else {
                return PKEraserTool(eraserMode.pkEraserType)
            }
        }
    }
}

// MARK: - Toolbar View

struct ToolbarView: View {
    @Binding var selectedTool: DrawingTool
    @Binding var zoomScale: CGFloat
    @Binding var isFullscreen: Bool
    @Binding var eraserMode: EraserMode
    @Binding var eraserSize: CGFloat
    let onUndo: () -> Void
    let onRedo: () -> Void
    
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
                
                // Eraser mode selector (only visible when eraser is selected)
                if selectedTool == .eraser {
                    // Object eraser button
                    Button(action: {
                        eraserMode = .object
                    }) {
                        Image(systemName: "scribble.variable")
                            .font(.title3)
                            .foregroundColor(eraserMode == .object ? .blue : .gray)
                            .padding(8)
                            .background(eraserMode == .object ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                    }
                    
                    // Pixel eraser button
                    Button(action: {
                        eraserMode = .pixel
                    }) {
                        Image(systemName: "circle.fill")
                            .font(.title3)
                            .foregroundColor(eraserMode == .pixel ? .blue : .gray)
                            .padding(8)
                            .background(eraserMode == .pixel ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                    }
                    
                    // Eraser size slider
                    VStack(spacing: 2) {
                        Text("Size")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Slider(value: $eraserSize, in: 5...100, step: 1)
                            .frame(width: 100)
                    }
                    .padding(.horizontal, 8)
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
                
                Divider()
                    .frame(height: 30)
                
                // Fullscreen button
                Button(action: {
                    withAnimation {
                        isFullscreen.toggle()
                        toggleFullscreen()
                    }
                }) {
                    Image(systemName: isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.title2)
                        .foregroundColor(isFullscreen ? .blue : .gray)
                        .padding()
                        .background(isFullscreen ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
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
    
    private func toggleFullscreen() {
        // On iPad, "fullscreen" means hiding the status bar and maximizing the canvas
        // The status bar visibility is controlled by the isFullscreen state binding
        // which is used in the .statusBarHidden modifier
    }
}

