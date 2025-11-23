# MyScript API Integration Guide for iOS Canvas

## Overview
This guide outlines how to integrate MyScript Interactive Ink API with your PencilKit-based canvas for handwriting recognition in your algebra tutoring app.

## MyScript API Overview

### What is MyScript?
MyScript Interactive Ink (iink) SDK provides handwriting recognition for:
- **TEXT**: Handwritten text recognition
- **MATH**: Mathematical expressions recognition
- **DIAGRAM**: Shape and diagram recognition

### API Architecture
- **Protocols**: REST API or WebSocket
- **Authentication**: Application Key + HMAC Key
- **Server**: `https://cloud.myscript.com/api/v4.0/iink/`
- **Input Format**: Stroke data (x, y coordinates with timestamps)

## Integration Approaches for iOS

### Option 1: REST API (Recommended for Start)
- **Pros**: Simple, no SDK dependencies, works with any HTTP client
- **Cons**: Requires manual stroke conversion, no real-time recognition
- **Best for**: Batch recognition, simple integration

### Option 2: Native iOS SDK
- **Pros**: Optimized, real-time recognition, better performance
- **Cons**: Requires SDK integration, larger app size
- **Best for**: Production apps, real-time feedback

## Step-by-Step Integration Plan

### Phase 1: Setup and Authentication

#### 1.1 Register for MyScript Developer Account
1. Go to https://developer.myscript.com/
2. Create a developer account
3. Create a new application
4. Obtain credentials:
   - `applicationKey`: Your app identifier
   - `hmacKey`: Secret key for authentication

#### 1.2 Store Credentials Securely
```swift
// Create a Config.swift file (add to .gitignore)
struct MyScriptConfig {
    static let applicationKey = "YOUR_APPLICATION_KEY"
    static let hmacKey = "YOUR_HMAC_KEY"
    static let apiBaseURL = "https://cloud.myscript.com/api/v4.0/iink"
}
```

### Phase 2: Convert PKDrawing to MyScript Format

#### 2.1 Understanding Stroke Format
MyScript API expects strokes in this format:
```json
{
  "x": [100, 105, 110, ...],
  "y": [200, 205, 210, ...],
  "t": [0, 50, 100, ...]  // timestamps in milliseconds
}
```

#### 2.2 Extract Strokes from PKDrawing
```swift
extension PKDrawing {
    func toMyScriptStrokes() -> [[String: [Double]]] {
        var strokes: [[String: [Double]]] = []
        
        for stroke in self.strokes {
            var xPoints: [Double] = []
            var yPoints: [Double] = []
            var timestamps: [Double] = []
            
            let points = stroke.path.interpolatedPoints(by: .distance(1.0))
            let startTime = Date().timeIntervalSince1970 * 1000
            
            for (index, point) in points.enumerated() {
                xPoints.append(Double(point.location.x))
                yPoints.append(Double(point.location.y))
                timestamps.append(startTime + Double(index * 16)) // ~60fps
            }
            
            strokes.append([
                "x": xPoints,
                "y": yPoints,
                "t": timestamps
            ])
        }
        
        return strokes
    }
}
```

### Phase 3: API Communication

#### 3.1 Create MyScript Service
```swift
import Foundation

class MyScriptService {
    private let applicationKey: String
    private let hmacKey: String
    private let baseURL = "https://cloud.myscript.com/api/v4.0/iink"
    
    init(applicationKey: String, hmacKey: String) {
        self.applicationKey = applicationKey
        self.hmacKey = hmacKey
    }
    
    // Recognize text from strokes
    func recognizeText(strokes: [[String: [Double]]], 
                      completion: @escaping (Result<String, Error>) -> Void) {
        recognize(strokes: strokes, type: "TEXT", completion: completion)
    }
    
    // Recognize math from strokes
    func recognizeMath(strokes: [[String: [Double]]],
                      completion: @escaping (Result<String, Error>) -> Void) {
        recognize(strokes: strokes, type: "MATH", completion: completion)
    }
    
    private func recognize(strokes: [[String: [Double]]],
                          type: String,
                          completion: @escaping (Result<String, Error>) -> Void) {
        // Build request payload
        let payload: [String: Any] = [
            "applicationKey": applicationKey,
            "hmacKey": hmacKey,
            "type": type,
            "strokes": strokes
        ]
        
        // Create URL request
        guard let url = URL(string: "\(baseURL)/batch") else {
            completion(.failure(MyScriptError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        // Perform request
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(MyScriptError.noData))
                return
            }
            
            // Parse response
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let result = json?["result"] as? String {
                    completion(.success(result))
                } else {
                    completion(.failure(MyScriptError.invalidResponse))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum MyScriptError: Error {
    case invalidURL
    case noData
    case invalidResponse
}
```

### Phase 4: Integrate with Canvas

#### 4.1 Add Recognition to DrawingCanvasView
```swift
// Add to DrawingCanvasView
@State private var myScriptService: MyScriptService?
@State private var recognizedText: String = ""

// Initialize service
.onAppear {
    myScriptService = MyScriptService(
        applicationKey: MyScriptConfig.applicationKey,
        hmacKey: MyScriptConfig.hmacKey
    )
}

// Add recognition button to toolbar
Button("Recognize") {
    recognizeDrawing()
}

func recognizeDrawing() {
    let strokes = studentCanvasDrawing.toMyScriptStrokes()
    myScriptService?.recognizeText(strokes: strokes) { result in
        switch result {
        case .success(let text):
            recognizedText = text
            // Display or process recognized text
        case .failure(let error):
            print("Recognition error: \(error)")
        }
    }
}
```

### Phase 5: Real-time Recognition (Advanced)

#### 5.1 WebSocket Integration
For real-time recognition as user draws:
- Use WebSocket connection to MyScript
- Send strokes incrementally
- Receive recognition updates in real-time

#### 5.2 Debounced Recognition
```swift
@State private var recognitionTimer: Timer?

func scheduleRecognition() {
    recognitionTimer?.invalidate()
    recognitionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
        recognizeDrawing()
    }
}

// Call scheduleRecognition() when drawing changes
```

## Complete Implementation Checklist

### Setup Phase
- [ ] Register MyScript developer account
- [ ] Obtain applicationKey and hmacKey
- [ ] Create Config.swift with credentials
- [ ] Add Config.swift to .gitignore

### Core Integration
- [ ] Create MyScriptService class
- [ ] Implement PKDrawing extension for stroke conversion
- [ ] Add error handling
- [ ] Test API connection

### UI Integration
- [ ] Add recognition button to toolbar
- [ ] Create recognition result display area
- [ ] Add loading indicator during recognition
- [ ] Handle recognition errors gracefully

### Advanced Features
- [ ] Implement real-time recognition (WebSocket)
- [ ] Add math recognition support
- [ ] Cache recognition results
- [ ] Add recognition history

## API Endpoints Reference

### Batch Recognition (REST)
- **URL**: `POST https://cloud.myscript.com/api/v4.0/iink/batch`
- **Content-Type**: `application/json`
- **Body**:
```json
{
  "applicationKey": "your-key",
  "hmacKey": "your-hmac",
  "type": "TEXT",
  "strokes": [
    {
      "x": [100, 105, 110],
      "y": [200, 205, 210],
      "t": [0, 50, 100]
    }
  ]
}
```

### WebSocket (Real-time)
- **URL**: `wss://cloud.myscript.com/api/v4.0/iink/ws`
- **Protocol**: WebSocket
- **Messages**: JSON format for strokes and results

## Recognition Types

### TEXT
- Recognizes handwritten text
- Returns: Plain text, LaTeX, or JIIX format
- Best for: General handwriting

### MATH
- Recognizes mathematical expressions
- Returns: LaTeX, MathML, or JIIX
- Best for: Algebra equations, formulas

### DIAGRAM
- Recognizes shapes and diagrams
- Returns: SVG or JIIX
- Best for: Geometric shapes, flowcharts

## Testing Strategy

1. **Unit Tests**
   - Test stroke conversion
   - Test API request formatting
   - Test response parsing

2. **Integration Tests**
   - Test with sample drawings
   - Test error scenarios
   - Test network failures

3. **User Testing**
   - Test with real handwriting
   - Test math recognition accuracy
   - Test performance on iPad

## Resources

- **MyScript Developer Portal**: https://developer.myscript.com/
- **API Documentation**: https://developer.myscript.com/doc/interactive-ink/
- **iOS SDK** (if available): Check MyScript developer portal
- **Sample Projects**: GitHub repositories from MyScript

## Next Steps

1. Start with REST API integration (simpler)
2. Test with sample strokes
3. Integrate into your canvas
4. Add UI for recognition results
5. Consider upgrading to WebSocket for real-time recognition

