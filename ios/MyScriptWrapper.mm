//
//  MyScriptWrapper.mm
//  its-algebra
//
//  Objective-C++ wrapper implementation for MyScript Interactive Ink SDK
//

#import "MyScriptWrapper.h"

// Direct include - ensure PODS_ROOT/MyScriptInteractiveInk-Runtime/include is in HEADER_SEARCH_PATHS
#import <iink/IINK.h>

@interface MyScriptWrapper () <IINKEditorDelegate>

@property (nonatomic, strong, nullable) IINKEngine *engine;
@property (nonatomic, strong, nullable) IINKEditor *editor;
@property (nonatomic, strong, nullable) IINKContentPackage *package;
@property (nonatomic, strong, nullable) IINKContentPart *part;
@property (nonatomic, assign) BOOL initialized;

@end

@implementation MyScriptWrapper

+ (instancetype)sharedInstance {
    static MyScriptWrapper *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _initialized = NO;
    }
    return self;
}

- (BOOL)initializeWithCertificate:(const void *)certificateBytes
                           length:(size_t)certificateLength {
    if (_initialized) {
        return YES;
    }
    
    @try {
        // Create certificate data
        NSData *certData = [NSData dataWithBytes:certificateBytes length:certificateLength];
        
        // Initialize engine
        _engine = [[IINKEngine alloc] initWithCertificate:certData];
        
        if (!_engine) {
            NSLog(@"❌ Failed to create IINKEngine");
            return NO;
        }
        
        NSLog(@"✅ MyScript Engine initialized successfully");
        _initialized = YES;
        return YES;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception initializing MyScript: %@", exception);
        return NO;
    }
}

- (BOOL)isInitialized {
    return _initialized && _engine != nil;
}

- (BOOL)createMathEditor {
    if (!_initialized || !_engine) {
        NSLog(@"❌ Engine not initialized");
        return NO;
    }
    
    @try {
        // Get temporary directory for package
        NSString *tempDir = NSTemporaryDirectory();
        NSString *packagePath = [tempDir stringByAppendingPathComponent:@"math_recognition.iink"];
        
        // Remove old package if exists
        [[NSFileManager defaultManager] removeItemAtPath:packagePath error:nil];
        
        // Create package with error handling
        NSError *error = nil;
        _package = [_engine createPackage:packagePath error:&error];
        if (!_package || error) {
            NSLog(@"❌ Failed to create package: %@", error.localizedDescription);
            return NO;
        }
        
        // Create a Math content part with error handling
        _part = [_package createPart:@"Math" error:&error];
        if (!_part || error) {
            NSLog(@"❌ Failed to create Math part: %@", error.localizedDescription);
            return NO;
        }
        
        // Create renderer (required for editor)
        NSError *rendererError = nil;
        IINKRenderer *renderer = [_engine createRendererWithDpiX:96.0 dpiY:96.0 target:nil error:&rendererError];
        if (!renderer || rendererError) {
            NSLog(@"❌ Failed to create renderer: %@", rendererError.localizedDescription);
            return NO;
        }
        
        // Create editor with renderer
        _editor = [_engine createEditor:renderer withToolController:nil];
        if (!_editor) {
            NSLog(@"❌ Failed to create editor");
            return NO;
        }
        
        // Set delegate
        _editor.delegate = self;
        
        // Assign the part to the editor with error handling
        BOOL setPartSuccess = [_editor setPart:_part error:&error];
        if (!setPartSuccess || error) {
            NSLog(@"❌ Failed to set part: %@", error.localizedDescription);
            return NO;
        }
        
        NSLog(@"✅ Math editor created successfully");
        return YES;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception creating editor: %@", exception);
        return NO;
    }
}

- (nullable NSString *)processDrawing:(PKDrawing *)drawing {
    if (!_editor || !_part) {
        NSLog(@"❌ Editor not initialized");
        return nil;
    }
    
    @try {
        // Clear previous content
        NSError *error = nil;
        BOOL clearSuccess = [_editor clearWithError:&error];
        if (!clearSuccess || error) {
            NSLog(@"⚠️ Failed to clear: %@", error.localizedDescription);
        }
        
        // Convert PencilKit strokes to MyScript pointer events
        int pointerId = 0;
        for (PKStroke *pkStroke in drawing.strokes) {
            pointerId++;
            PKStrokePath *path = pkStroke.path;
            if (path.count == 0) continue;
            
            // Get first point - access properties directly to avoid struct allocation issue
            CGPoint point = [path pointAtIndex:0].location;
            int64_t timestamp = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
            float force = [path pointAtIndex:0].force > 0 ? [path pointAtIndex:0].force : 0.5;
            
            // Start stroke with pointerDown
            NSError *pointerError = nil;
            [_editor pointerDown:point at:timestamp force:force type:IINKPointerTypePen pointerId:pointerId error:&pointerError];
            if (pointerError) {
                NSLog(@"⚠️ pointerDown error: %@", pointerError.localizedDescription);
            }
            
            // Add move events for remaining points - access properties directly
            for (NSUInteger i = 1; i < path.count; i++) {
                CGPoint movePoint = [path pointAtIndex:i].location;
                int64_t moveTime = timestamp + (int64_t)([path pointAtIndex:i].timeOffset * 1000);
                float moveForce = [path pointAtIndex:i].force > 0 ? [path pointAtIndex:i].force : 0.5;
                
                pointerError = nil;
                [_editor pointerMove:movePoint at:moveTime force:moveForce type:IINKPointerTypePen pointerId:pointerId error:&pointerError];
                if (pointerError) {
                    NSLog(@"⚠️ pointerMove error: %@", pointerError.localizedDescription);
                }
            }
            
            // End stroke with pointerUp - access properties directly
            CGPoint upPoint = [path pointAtIndex:path.count - 1].location;
            int64_t upTime = timestamp + (int64_t)([path pointAtIndex:path.count - 1].timeOffset * 1000);
            
            pointerError = nil;
            [_editor pointerUp:upPoint at:upTime force:0.0 type:IINKPointerTypePen pointerId:pointerId error:&pointerError];
            if (pointerError) {
                NSLog(@"⚠️ pointerUp error: %@", pointerError.localizedDescription);
            }
        }
        
        // Wait a bit for recognition
        [NSThread sleepForTimeInterval:0.2];
        
        // Get recognized text from JIIX export
        error = nil;
        NSString *jiixString = [_editor export_:nil mimeType:IINKMimeTypeJIIX error:&error];
        if (jiixString && !error) {
            // Parse JIIX to get label (recognized text)
            NSData *data = [jiixString dataUsingEncoding:NSUTF8StringEncoding];
            if (data) {
                NSDictionary *jiix = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSString *label = jiix[@"label"];
                if (label && label.length > 0) {
                    NSLog(@"✅ Recognition result: %@", label);
                    return label;
                }
            }
        }
        
        return nil;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception processing drawing: %@", exception);
        return nil;
    }
}

- (nullable NSString *)getLatexOutput {
    if (!_editor || !_part) {
        NSLog(@"❌ Editor not initialized");
        return nil;
    }
    
    @try {
        // Export as LaTeX
        NSError *error = nil;
        NSString *latex = [_editor export_:nil mimeType:IINKMimeTypeLaTeX error:&error];
        if (error) {
            NSLog(@"⚠️ Error exporting LaTeX: %@", error.localizedDescription);
            return nil;
        }
        return latex;
        
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception getting LaTeX: %@", exception);
        return nil;
    }
}

- (void)clear {
    @try {
        if (_editor) {
            NSError *error = nil;
            [_editor clearWithError:&error];
            if (error) {
                NSLog(@"⚠️ Error clearing: %@", error.localizedDescription);
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception clearing: %@", exception);
    }
}

- (void)cleanup {
    @try {
        if (_editor) {
            _editor.delegate = nil;
            _editor = nil;
        }
        if (_part) {
            _part = nil;
        }
        if (_package) {
            // Packages don't have a close method - just release
            _package = nil;
        }
        _initialized = NO;
    } @catch (NSException *exception) {
        NSLog(@"❌ Exception cleaning up: %@", exception);
    }
}

- (void)dealloc {
    [self cleanup];
}

#pragma mark - IINKEditorDelegate

- (void)contentChanged:(nonnull IINKEditor *)editor blockIds:(nonnull NSArray<NSString *> *)blockIds {
    // Content changed - recognition updated
    NSLog(@"📝 Content changed in blocks: %@", blockIds);
}

- (void)partChanging:(nonnull IINKEditor *)editor {
    // Part is about to change
}

- (void)partChanged:(nonnull IINKEditor *)editor {
    // Part changed
}

- (void)onError:(nonnull IINKEditor *)editor blockId:(nonnull NSString *)blockId message:(nonnull NSString *)message {
    NSLog(@"❌ MyScript error in block %@: %@", blockId, message);
}

@end
