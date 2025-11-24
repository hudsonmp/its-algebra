//
//  GeminiService.swift
//  its-algebra
//
//  Gemini API integration for real-time feedback
//

import Foundation

class GeminiService {
    static let shared = GeminiService()
    
    // API key from .env file - in production, use Info.plist or secure storage
    private let apiKey = "AIzaSyCyW815Eh3UwEHfbnQhJnmlZz6BNo3MoW"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
    
    private init() {}
    
    /// Get feedback on student's work
    func getFeedback(problem: String, studentWork: String, latex: String) async -> String? {
        guard !apiKey.isEmpty else {
            print("❌ Gemini API key not configured")
            return nil
        }
        
        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("❌ Invalid Gemini API URL")
            return nil
        }
        
        // Build prompt
        let prompt = """
        You are a helpful algebra tutor. The student is working on this problem:
        
        Problem: \(problem)
        
        Their current work (recognized text): \(studentWork)
        LaTeX representation: \(latex)
        
        Provide brief, encouraging feedback on their progress. Keep it under 50 words. Focus on:
        - What they're doing correctly
        - A gentle hint if they're stuck
        - Next steps if they're on track
        
        Be supportive and educational.
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            print("❌ Error encoding request: \(error)")
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                return nil
            }
            
            guard httpResponse.statusCode == 200 else {
                print("❌ Gemini API error: \(httpResponse.statusCode)")
                if let errorData = String(data: data, encoding: .utf8) {
                    print("Error details: \(errorData)")
                }
                return nil
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let firstPart = parts.first,
                  let text = firstPart["text"] as? String else {
                print("❌ Invalid response format")
                return nil
            }
            
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
            
        } catch {
            print("❌ Error calling Gemini API: \(error)")
            return nil
        }
    }
}

