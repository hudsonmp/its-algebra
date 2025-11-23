# MyScript SDK Integration Setup Guide

This guide explains how to complete the MyScript Interactive Ink SDK integration for real-time character recognition from stroke data on iPadOS.

## Prerequisites

1. **MyScript Developer Account**: Register at https://developer.myscript.com
2. **MyScript Certificate**: Your `MyCertificate.c` file is already in `MyScriptCertificate/` directory
3. **Xcode**: Latest version with iOS/iPadOS development support

## Step 1: Download MyScript SDK

1. Visit https://www.myscript.com/sdk/ or https://github.com/MyScript/interactive-ink-examples-ios
2. Download the MyScript Interactive Ink SDK for iOS
3. Extract the SDK framework files

## Step 2: Add SDK to Xcode Project

1. Open your project in Xcode
2. Right-click on your project in the navigator
3. Select "Add Files to [Project Name]..."
4. Navigate to the extracted SDK folder
5. Add the `iink` framework (or `MyScriptInteractiveInk.framework`)
6. Ensure "Copy items if needed" is checked
7. Ensure your target is selected

## Step 3: Configure Bridging Header

1. In Xcode, go to your target's Build Settings
2. Search for "Objective-C Bridging Header"
3. Set it to: `its-algebra-Bridging-Header.h`
4. Ensure the bridging header file exists in your project

## Step 4: Update MyScriptManager.swift

Replace the placeholder code in `MyScriptManager.swift` with actual MyScript SDK calls:

```swift
import iink

class MyScriptManager {
    private var engine: IINKEngine?
    private var editor: IINKEditor?
    
    func initialize() -> Bool {
        // Load certificate
        guard let certificatePath = Bundle.main.path(forResource: "MyCertificate", ofType: "c", inDirectory: "MyScriptCertificate"),
              let certificateData = try? Data(contentsOf: URL(fileURLWithPath: certificatePath)) else {
            return false
        }
        
        // Initialize engine with certificate
        do {
            engine = try IINKEngine(certificate: certificateData)
            return true
        } catch {
            print("Error initializing MyScript engine: \(error)")
            return false
        }
    }
    
    func createTextEditor() -> Bool {
        guard let engine = engine else { return false }
        
        do {
            editor = try engine.createEditor(contentType: "Text")
            return true
        } catch {
            print("Error creating editor: \(error)")
            return false
        }
    }
    
    func processStroke(_ stroke: PKStroke, from drawing: PKDrawing) -> String? {
        guard let editor = editor else { return nil }
        
        // Convert PKStroke to MyScript stroke format
        let points = stroke.path.interpolatedPoints(by: .distance(1.0))
        var strokePoints: [CGPoint] = []
        
        for point in points {
            strokePoints.append(point.location)
        }
        
        // Add stroke to editor
        do {
            try editor.addStroke(points: strokePoints)
            
            // Perform recognition
            let result = try editor.recognize()
            return result.text
        } catch {
            print("Error processing stroke: \(error)")
            return nil
        }
    }
}
```

## Step 5: Add Recognition Resources

1. Download recognition resources from MyScript Developer Portal
2. Add the resource files to your Xcode project
3. Ensure they're included in the app bundle

## Step 6: Update Project Settings

1. In Build Settings, ensure:
   - "Always Embed Swift Standard Libraries" is enabled
   - Framework search paths include the SDK location
   - Linker flags include required frameworks

## Step 7: Test Integration

1. Build and run the app on an iPad
2. Draw on the canvas
3. Verify that recognized text appears in the recognition display area

## Troubleshooting

- **Certificate errors**: Ensure `MyCertificate.c` is properly included in the bundle
- **Framework not found**: Check framework search paths in Build Settings
- **Recognition not working**: Verify SDK initialization and editor creation
- **Bridging header issues**: Ensure the header path is correct in Build Settings

## Additional Resources

- MyScript Developer Documentation: https://developer.myscript.com/docs
- iOS Examples: https://github.com/MyScript/interactive-ink-examples-ios
- API Reference: https://developer.myscript.com/doc/interactive-ink/

## Current Implementation Status

✅ Certificate file added  
✅ Integration structure created  
✅ Canvas integration with recognition hooks  
⏳ SDK framework needs to be added  
⏳ Actual SDK calls need to be implemented  

Once the SDK framework is added, update `MyScriptManager.swift` with the actual SDK API calls as shown above.

