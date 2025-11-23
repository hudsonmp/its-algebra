//
//  MyScriptService.swift
//  its-algebra
//
//  MyScript API integration service for handwriting recognition
//

import Foundation
import PencilKit

// MARK: - MyScript Configuration
// TODO: Replace with your actual credentials from https://developer.myscript.com/
struct MyScriptConfig {
    static let applicationKey = "YOUR_APPLICATION_KEY_HERE"
    static let hmacKey = "YOUR_HMAC_KEY_HERE"
    static let apiBaseURL = "https://cloud.myscript.com/api/v4.0/iink"
}

// MARK: - MyScript Service

class MyScriptService {
    private let applicationKey: String
    private let hmacKey: String
    private let baseURL: String
    
    init(applicationKey: String = MyScriptConfig.applicationKey,
         hmacKey: String = MyScriptConfig.hmacKey,
         baseURL: String = MyScriptConfig.apiBaseURL) {
        self.applicationKey = applicationKey
        self.hmacKey = hmacKey
        self.baseURL = baseURL
    }
    
    // MARK: - Public Recognition Methods
    
    /// Recognize text from PKDrawing
    func recognizeText(from drawing: PKDrawing,
                      completion: @escaping (Result<String, MyScriptError>) -> Void) {
        let strokes = drawing.toMyScriptStrokes()
        recognize(strokes: strokes, type: "TEXT", completion: completion)
    }
    
    /// Recognize math expressions from PKDrawing
    func recognizeMath(from drawing: PKDrawing,
                      completion: @escaping (Result<String, MyScriptError>) -> Void) {
        let strokes = drawing.toMyScriptStrokes()
        recognize(strokes: strokes, type: "MATH", completion: completion)
    }
    
    /// Recognize text from raw strokes
    func recognizeText(strokes: [[String: [Double]]],
                      completion: @escaping (Result<String, MyScriptError>) -> Void) {
        recognize(strokes: strokes, type: "TEXT", completion: completion)
    }
    
    /// Recognize math from raw strokes
    func recognizeMath(strokes: [[String: [Double]]],
                      completion: @escaping (Result<String, MyScriptError>) -> Void) {
        recognize(strokes: strokes, type: "MATH", completion: completion)
    }
    
    // MARK: - Private Recognition Implementation
    
    private func recognize(strokes: [[String: [Double]]],
                          type: String,
                          completion: @escaping (Result<String, MyScriptError>) -> Void) {
        guard !strokes.isEmpty else {
            completion(.failure(.emptyStrokes))
            return
        }
        
        // Build request payload
        let payload: [String: Any] = [
            "applicationKey": applicationKey,
            "hmacKey": hmacKey,
            "type": type,
            "strokes": strokes
        ]
        
        // Create URL request
        guard let url = URL(string: "\(baseURL)/batch") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30.0
        
        // Serialize request body
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(.serializationError(error)))
            return
        }
        
        // Perform request
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle network errors
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                    return
                }
            }
            
            // Parse response data
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            self.parseRecognitionResponse(data: data, completion: completion)
        }.resume()
    }
    
    // MARK: - Response Parsing
    
    private func parseRecognitionResponse(data: Data,
                                         completion: @escaping (Result<String, MyScriptError>) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            // Try to extract recognized text
            if let result = json?["result"] as? String {
                completion(.success(result))
            } else if let exports = json?["exports"] as? [String: Any],
                      let text = exports["text/plain"] as? String {
                completion(.success(text))
            } else if let text = json?["text"] as? String {
                completion(.success(text))
            } else {
                // Log full response for debugging
                print("MyScript API Response: \(json ?? [:])")
                completion(.failure(.invalidResponse))
            }
        } catch {
            completion(.failure(.parsingError(error)))
        }
    }
}

// MARK: - MyScript Errors

enum MyScriptError: Error, LocalizedError {
    case invalidURL
    case emptyStrokes
    case noData
    case invalidResponse
    case networkError(Error)
    case httpError(statusCode: Int)
    case serializationError(Error)
    case parsingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .emptyStrokes:
            return "No strokes provided for recognition"
        case .noData:
            return "No data received from API"
        case .invalidResponse:
            return "Invalid response format from API"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .serializationError(let error):
            return "Serialization error: \(error.localizedDescription)"
        case .parsingError(let error):
            return "Parsing error: \(error.localizedDescription)"
        }
    }
}

// MARK: - PKDrawing Extension

extension PKDrawing {
    /// Convert PKDrawing to MyScript stroke format
    func toMyScriptStrokes() -> [[String: [Double]]] {
        var strokes: [[String: [Double]]] = []
        
        for stroke in self.strokes {
            var xPoints: [Double] = []
            var yPoints: [Double] = []
            var timestamps: [Double] = []
            
            // Get interpolated points from stroke path
            let path = stroke.path
            let startTime = Date().timeIntervalSince1970 * 1000
            
            // Sample points with minimum distance to avoid too many points
            let minDistance: CGFloat = 2.0
            let interpolatedPoints = path.interpolatedPoints(minDistance: minDistance)
            
            // Convert points to MyScript format
            // Estimate timestamps based on point index (assuming ~60fps capture rate)
            let timeStep: Double = 16.67 // milliseconds per point at 60fps
            
            for (index, point) in interpolatedPoints.enumerated() {
                let location = point.location
                
                xPoints.append(Double(location.x))
                yPoints.append(Double(location.y))
                timestamps.append(startTime + Double(index) * timeStep)
            }
            
            // Ensure we have at least 2 points
            if xPoints.count >= 2 {
                strokes.append([
                    "x": xPoints,
                    "y": yPoints,
                    "t": timestamps
                ])
            }
        }
        
        return strokes
    }
    
    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        let dx = to.x - from.x
        let dy = to.y - from.y
        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - PKStrokePath Extension Helper

extension PKStrokePath {
    /// Get interpolated points along the path with minimum distance
    func interpolatedPoints(minDistance: CGFloat = 1.0) -> [PKStrokePoint] {
        var points: [PKStrokePoint] = []
        var lastPoint: PKStrokePoint?
        
        for point in self {
            if let last = lastPoint {
                let distance = sqrt(pow(point.location.x - last.location.x, 2) +
                                   pow(point.location.y - last.location.y, 2))
                
                if distance >= minDistance {
                    points.append(point)
                    lastPoint = point
                }
            } else {
                points.append(point)
                lastPoint = point
            }
        }
        
        // Always include the last point
        if let last = self.last, points.last?.location != last.location {
            points.append(last)
        }
        
        return points.isEmpty ? Array(self) : points
    }
}

