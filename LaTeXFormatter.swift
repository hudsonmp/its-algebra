//
//  LaTeXFormatter.swift
//  its-algebra
//
//  Formats recognized text as LaTeX for math expressions
//

import Foundation

class LaTeXFormatter {
    static let shared = LaTeXFormatter()
    
    private init() {}
    
    /// Convert recognized text to LaTeX format
    func formatAsLaTeX(_ text: String) -> String {
        // Basic conversions for common math symbols
        var latex = text
        
        // Replace common operators and symbols
        latex = latex.replacingOccurrences(of: "×", with: "\\times ")
        latex = latex.replacingOccurrences(of: "÷", with: "\\div ")
        latex = latex.replacingOccurrences(of: "≠", with: "\\neq ")
        latex = latex.replacingOccurrences(of: "≤", with: "\\leq ")
        latex = latex.replacingOccurrences(of: "≥", with: "\\geq ")
        latex = latex.replacingOccurrences(of: "∞", with: "\\infty ")
        latex = latex.replacingOccurrences(of: "π", with: "\\pi ")
        latex = latex.replacingOccurrences(of: "α", with: "\\alpha ")
        latex = latex.replacingOccurrences(of: "β", with: "\\beta ")
        latex = latex.replacingOccurrences(of: "θ", with: "\\theta ")
        
        // Handle fractions (pattern: a/b -> \frac{a}{b})
        latex = formatFractions(latex)
        
        // Handle exponents (pattern: x^2 -> x^{2})
        latex = formatExponents(latex)
        
        // Handle square roots (pattern: √x -> \sqrt{x})
        latex = formatSquareRoots(latex)
        
        return latex
    }
    
    /// Mock recognition for testing - generates LaTeX from simple patterns
    func mockRecognize(strokeCount: Int) -> String {
        let samples = [
            "x^2 + 2x + 1",
            "\\frac{a}{b} + c",
            "\\sqrt{x} = y",
            "2x + 3 = 7",
            "y = mx + b",
            "a^2 + b^2 = c^2",
            "\\int x dx",
            "\\sum_{i=1}^{n} i"
        ]
        
        // Return different samples based on stroke count
        let index = strokeCount % samples.count
        return samples[index]
    }
    
    private func formatFractions(_ text: String) -> String {
        // Simple pattern matching for fractions
        let pattern = #"(\w+)\s*/\s*(\w+)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = text as NSString
        let matches = regex?.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        var result = text
        matches?.reversed().forEach { match in
            if match.numberOfRanges == 3 {
                let numerator = nsString.substring(with: match.range(at: 1))
                let denominator = nsString.substring(with: match.range(at: 2))
                let replacement = "\\frac{\(numerator)}{\(denominator)}"
                result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
            }
        }
        
        return result
    }
    
    private func formatExponents(_ text: String) -> String {
        // Format single character exponents: x^2 -> x^{2}
        let pattern = #"\^(\w)"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = text as NSString
        let matches = regex?.matches(in: text, range: NSRange(location: 0, length: nsString.length))
        
        var result = text
        matches?.reversed().forEach { match in
            if match.numberOfRanges == 2 {
                let exponent = nsString.substring(with: match.range(at: 1))
                let replacement = "^{\(exponent)}"
                result = (result as NSString).replacingCharacters(in: match.range, with: replacement)
            }
        }
        
        return result
    }
    
    private func formatSquareRoots(_ text: String) -> String {
        var result = text
        
        // Handle √ symbol
        if result.contains("√") {
            result = result.replacingOccurrences(of: "√", with: "\\sqrt{")
            // Try to find the end of the expression
            // This is simplified - real implementation would need proper parsing
            result = result.replacingOccurrences(of: " ", with: "} ")
        }
        
        return result
    }
}

