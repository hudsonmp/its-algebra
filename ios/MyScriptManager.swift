//
//  MyScriptManager.swift
//  its-algebra
//
//  MyScript Interactive Ink SDK integration for real-time character recognition
//

import Foundation
import PencilKit

class MyScriptManager {
    static let shared = MyScriptManager()
    
    private var wrapper: MyScriptWrapper?
    private var isInitialized = false
    private var hasAttemptedInitialization = false
    
    private init() {}
    
    /// Initialize MyScript SDK with certificate
    func initialize() -> Bool {
        // Don't try to initialize multiple times if already attempted
        if isInitialized || hasAttemptedInitialization {
            return isInitialized
        }
        
        hasAttemptedInitialization = true
        
        // Get wrapper instance
        wrapper = MyScriptWrapper.sharedInstance()
        
        // Initialize with certificate
        guard let certBytes = myCertificate.bytes else {
            print("❌ Certificate bytes are nil")
            return false
        }
        let certLength = myCertificate.length
        
        guard let wrapper = wrapper else {
            print("❌ Failed to get MyScriptWrapper instance")
            return false
        }
        
        let initSuccess = wrapper.initialize(withCertificate: certBytes, length: certLength)
        
        if initSuccess {
            isInitialized = true
        }
        
        return initSuccess
    }
    
    /// Create an editor for math recognition
    func createTextEditor() -> Bool {
        guard isInitialized, let wrapper = wrapper else {
            print("⚠️ SDK not initialized")
            return false
        }
        
        return wrapper.createMathEditor()
    }
    
    /// Process entire drawing for recognition using MyScript SDK
    func processDrawing(_ drawing: PKDrawing) -> String? {
        guard isInitialized, let wrapper = wrapper else {
            return nil
        }
        
        return wrapper.processDrawing(drawing)
    }
    
    /// Process stroke data from PencilKit for real-time recognition (deprecated - use processDrawing instead)
    func processStroke(_ stroke: PKStroke, from drawing: PKDrawing) -> String? {
        // Process the entire drawing instead of individual strokes for better accuracy
        return processDrawing(drawing)
    }
    
    /// Get recognized text from current content
    func getRecognizedText() -> String? {
        // Recognition happens inline with processDrawing
        return nil
    }
    
    /// Get LaTeX output from math expressions
    func getLatexOutput(from drawing: PKDrawing) -> String? {
        guard isInitialized, let wrapper = wrapper else {
            return nil
        }
        
        return wrapper.getLatexOutput()
    }
    
    /// Clear current content
    func clear() {
        wrapper?.clear()
    }
}
