//
//  MyScriptWrapper.h
//  its-algebra
//
//  Objective-C wrapper for MyScript Interactive Ink SDK
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PencilKit/PencilKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyScriptWrapper : NSObject

/// Shared instance
+ (instancetype)sharedInstance;

/// Initialize the MyScript SDK with certificate
- (BOOL)initializeWithCertificate:(const void *)certificateBytes 
                           length:(size_t)certificateLength
    NS_SWIFT_NAME(initialize(withCertificate:length:));

/// Check if SDK is initialized
- (BOOL)isInitialized;

/// Create editor for math recognition
- (BOOL)createMathEditor NS_SWIFT_NAME(createMathEditor());

/// Process PKDrawing for recognition
- (nullable NSString *)processDrawing:(PKDrawing *)drawing 
    NS_SWIFT_NAME(processDrawing(_:));

/// Get LaTeX output
- (nullable NSString *)getLatexOutput NS_SWIFT_NAME(getLatexOutput());

/// Clear current content
- (void)clear;

/// Cleanup
- (void)cleanup;

@end

NS_ASSUME_NONNULL_END

