import Foundation

enum Config {
    // Mathpix API - Get keys at https://mathpix.com/ocr
    // Environment variables are automatically loaded from Xcode scheme configuration
    static let mathpixAppId: String = {
        let id = ProcessInfo.processInfo.environment["MATHPIX_APP_ID"] ?? ""
        if id.isEmpty {
            print("⚠️ MATHPIX_APP_ID not found in environment")
        } else {
            print("✅ MATHPIX_APP_ID loaded: \(id.prefix(10))...")
        }
        return id
    }()
    
    static let mathpixAppKey: String = {
        let key = ProcessInfo.processInfo.environment["MATHPIX_APP_KEY"] ?? ""
        if key.isEmpty {
            print("⚠️ MATHPIX_APP_KEY not found in environment")
        } else {
            print("✅ MATHPIX_APP_KEY loaded: \(key.prefix(10))...")
        }
        return key
    }()
}
