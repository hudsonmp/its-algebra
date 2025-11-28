import Foundation

enum Config {
    // Mathpix API - Get keys at https://mathpix.com/ocr
    static let mathpixAppId: String = ProcessInfo.processInfo.environment["MATHPIX_APP_ID"] ?? ""
    static let mathpixAppKey: String = ProcessInfo.processInfo.environment["MATHPIX_APP_KEY"] ?? ""
}
