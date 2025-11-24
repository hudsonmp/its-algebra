//
//  MyScriptBridge.h
//  its-algebra
//
//  Objective-C wrapper for MyScript Interactive Ink SDK
//  This bridges the C/Objective-C SDK to Swift
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Objective-C wrapper for MyScript Interactive Ink SDK
 * Provides a simpler interface for Swift integration
 */
@interface MyScriptBridge : NSObject

/// Shared singleton instance
+ (instancetype)shared;

/// Initialize the MyScript engine with certificate data
- (BOOL)initializeWithCertificateBytes:(const char *)bytes size:(size_t)size error:(NSError **)error;

/// Check if the SDK is initialized
- (BOOL)isInitialized;

/// Create a new content package with specified type (e.g., "Math", "Text")
- (BOOL)createPackageWithType:(NSString *)contentType error:(NSError **)error;

/// Process a drawing and return recognized text
- (nullable NSString *)recognizeDrawing:(NSArray<NSValue *> *)strokes error:(NSError **)error;

/// Get LaTeX output from current content
- (nullable NSString *)exportAsLaTeX:(NSError **)error;

/// Clear all content
- (void)clear;

@end

NS_ASSUME_NONNULL_END

