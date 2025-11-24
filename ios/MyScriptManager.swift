//
//  MyScriptManager.swift
//  its-algebra
//
//  MyScript Interactive Ink SDK integration for real-time character recognition
//

import Foundation
import UIKit
import PencilKit

// Note: This requires the MyScript Interactive Ink SDK framework to be added to the project
// Add via: https://github.com/MyScript/interactive-ink-examples-ios
// Once the SDK framework is added to the project, uncomment the line below:
// import iink

#if canImport(iink)
import iink
#endif

class MyScriptManager {
    static let shared = MyScriptManager()
    
    // MyScript SDK types (uncomment once SDK is added):
    // private var engine: IINKEngine?
    // private var editor: IINKEditor?
    private var engine: Any?
    private var editor: Any?
    private var isInitialized = false
    
    private init() {}
    
    /// Initialize MyScript SDK with certificate
    func initialize() -> Bool {
        guard !isInitialized else { return true }
        
        // Load certificate from MyCertificate.c
        guard let certificatePath = Bundle.main.path(forResource: "MyCertificate", ofType: "c", inDirectory: "MyScriptCertificate"),
              let certificateData = try? Data(contentsOf: URL(fileURLWithPath: certificatePath)) else {
            print("Error: Could not load MyScript certificate")
            return false
        }
        
        // Initialize MyScript Engine with certificate
        // Once SDK is added, uncomment and use:
        /*
        do {
            engine = try IINKEngine(certificate: certificateData)
            isInitialized = true
            print("MyScript SDK initialized successfully")
            return true
        } catch {
            print("Error initializing MyScript engine: \(error)")
            return false
        }
        */
        
        // Initialize MyScript Engine with certificate
        #if canImport(iink)
        do {
            engine = try IINKEngine(certificate: certificateData)
            isInitialized = true
            print("MyScript SDK initialized successfully")
            return true
        } catch {
            print("Error initializing MyScript engine: \(error)")
            return false
        }
        #else
        print("MyScript SDK framework not found. Please add the iink framework to your project.")
        print("See MYSCRIPT_SETUP.md for instructions.")
        // Mark as initialized for testing, but recognition won't work
        isInitialized = true
        return true
        #endif
    }
    
    /// Create an editor for text recognition
    func createTextEditor() -> Bool {
        guard isInitialized else {
            print("Error: MyScript SDK not initialized")
            return false
        }
        
        #if canImport(iink)
        guard let engine = engine as? IINKEngine else {
            print("Error: MyScript engine not available")
            return false
        }
        
        do {
            // Create editor with Math content type for better math recognition
            editor = try engine.createEditor(contentType: "Math")
            print("MyScript editor created successfully")
            return true
        } catch {
            print("Error creating MyScript editor: \(error)")
            // Fallback to Text content type
            do {
                editor = try engine.createEditor(contentType: "Text")
                print("MyScript editor created with Text content type")
                return true
            } catch {
                print("Error creating Text editor: \(error)")
                return false
            }
        }
        #else
        print("MyScript SDK framework not available")
        return false
        #endif
    }
    
    /// Process entire drawing for recognition using MyScript SDK
    func processDrawing(_ drawing: PKDrawing) -> String? {
        guard isInitialized else {
            print("Error: Recognition not initialized")
            return nil
        }
        
        guard !drawing.strokes.isEmpty else {
            return nil
        }
        
        #if canImport(iink)
        guard let editor = editor as? IINKEditor else {
            print("Error: MyScript editor not available")
            return nil
        }
        
        do {
            // Clear previous content
            try editor.clear()
            
            // Add all strokes to the editor
            for stroke in drawing.strokes {
                // Convert PKStroke to MyScript stroke format
                let points = stroke.path.interpolatedPoints(by: .distance(1.0))
                var strokePoints: [CGPoint] = []
                
                for point in points {
                    strokePoints.append(point.location)
                }
                
                if !strokePoints.isEmpty {
                    // Add stroke to editor
                    try editor.addStroke(points: strokePoints)
                }
            }
            
            // Perform recognition
            let result = try editor.recognize()
            
            // Get recognized text
            if let text = result.text, !text.isEmpty {
                return text
            }
            
            // If no text, try to get LaTeX/MathML
            if let latex = result.latex, !latex.isEmpty {
                return latex
            }
            
            return nil
        } catch {
            print("Error processing drawing with MyScript: \(error)")
            return nil
        }
        #else
        print("MyScript SDK not available - cannot perform recognition")
        return nil
        #endif
    }
    
    /// Process stroke data from PencilKit for real-time recognition (deprecated - use processDrawing instead)
    func processStroke(_ stroke: PKStroke, from drawing: PKDrawing) -> String? {
        // Process the entire drawing instead of individual strokes for better accuracy
        return processDrawing(drawing)
    }
    
    /// Get recognized text from current content
    func getRecognizedText() -> String? {
        guard isInitialized, editor != nil else {
            return nil
        }
        
        // Get text from editor
        // Note: Actual implementation requires MyScript SDK framework
        // Example: return editor.getText()
        
        return nil // Placeholder - requires actual SDK
    }
    
    /// Get LaTeX output from math expressions
    func getLatexOutput(from drawing: PKDrawing) -> String? {
        guard isInitialized else {
            return nil
        }
        
        #if canImport(iink)
        guard let editor = editor as? IINKEditor else {
            return nil
        }
        
        do {
            // Export as LaTeX
            let latex = try editor.export(format: .latex)
            return latex
        } catch {
            print("Error exporting LaTeX: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
    
    /// Clear current content
    func clear() {
        guard isInitialized else { return }
        
        #if canImport(iink)
        guard let editor = editor as? IINKEditor else {
            return
        }
        
        do {
            try editor.clear()
        } catch {
            print("Error clearing editor: \(error)")
        }
        #endif
    }
    
    deinit {
        // Cleanup SDK resources
        engine = nil
        editor = nil
    }
}

