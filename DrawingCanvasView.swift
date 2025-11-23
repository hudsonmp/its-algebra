//
//  DrawingCanvasView.swift
//  its-algebra
//
//  Main canvas view with split layout: 2/3 student work area, 1/3 PencilKit testing area
//

import SwiftUI
import PencilKit
import UIKit

struct DrawingCanvasView: View {
    @State private var studentCanvasDrawing = PKDrawing()
    @State private var testCanvasDrawing = PKDrawing()
    @State private var selectedTool: DrawingTool = .pen
    @State private var zoomScale: CGFloat = 1.0
    @State private var studentCanvasUndoManager: UndoManager?
    
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
                
                // PencilKit testing area - 1/3 of screen
                PencilKitTestArea(drawing: $testCanvasDrawing)
                    .frame(width: geometry.size.width * 1/3)
            }
            .overlay(
                ToolbarView(
                    selectedTool: $selectedTool,
                    zoomScale: $zoomScale,
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
    }
}

// MARK: - Student Work Area

struct StudentWorkArea: View {
    @Binding var drawing: PKDrawing
    @Binding var selectedTool: DrawingTool
    @Binding var zoomScale: CGFloat
    @Binding var undoManager: UndoManager?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                
                CanvasWrapper(
                    drawing: $drawing,
                    selectedTool: $selectedTool,
                    zoomScale: $zoomScale,
                    undoManager: $undoManager,
                    frame: CGRect(origin: .zero, size: geometry.size)
                )
            }
        }
    }
}

// MARK: - PencilKit Test Area

struct PencilKitTestArea: View {
    @Binding var drawing: PKDrawing
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
            
            TestCanvasWrapper(drawing: $drawing)
            
            VStack {
                Text("PencilKit Testing Area")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
        }
    }
}

// MARK: - Canvas Wrapper (Student Area)

struct CanvasWrapper: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var selectedTool: DrawingTool
    @Binding var zoomScale: CGFloat
    @Binding var undoManager: UndoManager?
    var frame: CGRect
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        // Create the canvas view
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput // Allow finger and Apple Pencil
        canvas.tool = selectedTool.toPKTool()
        canvas.backgroundColor = .white
        canvas.drawing = drawing
        
        // Enable undo/redo
        let undoMgr = UndoManager()
        canvas.undoManager = undoMgr
        
        // Create scroll view for zoom
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = zoomScale
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.bouncesZoom = true
        
        // Set canvas frame to match scroll view bounds
        canvas.frame = CGRect(origin: .zero, size: frame.size)
        scrollView.addSubview(canvas)
        scrollView.contentSize = frame.size
        
        // Store references
        context.coordinator.scrollView = scrollView
        context.coordinator.canvas = canvas
        context.coordinator.undoManager = undoMgr
        
        // Update the binding with undo manager
        undoManager = undoMgr
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Update zoom scale if changed externally
        if abs(scrollView.zoomScale - zoomScale) > 0.01 {
            scrollView.setZoomScale(zoomScale, animated: true)
        }
        
        // Update tool
        if let canvas = context.coordinator.canvas {
            canvas.tool = selectedTool.toPKTool()
            canvas.drawing = drawing
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
        
        init(_ parent: CanvasWrapper) {
            self.parent = parent
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
            // Update the binding when drawing changes
            parent.drawing = canvasView.drawing
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

// MARK: - Drawing Tool Enum

enum DrawingTool {
    case pen
    case eraser
    
    func toPKTool() -> PKTool {
        switch self {
        case .pen:
            return PKInkingTool(.pen, color: .black, width: 15)
        case .eraser:
            return PKEraserTool(.vector)
        }
    }
}

// MARK: - Toolbar View

struct ToolbarView: View {
    @Binding var selectedTool: DrawingTool
    @Binding var zoomScale: CGFloat
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

