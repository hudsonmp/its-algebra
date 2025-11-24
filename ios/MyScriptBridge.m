//
//  MyScriptBridge.m
//  its-algebra
//
//  Objective-C wrapper implementation for MyScript Interactive Ink SDK
//

#import "MyScriptBridge.h"
#import <iink/IINK.h>

@interface MyScriptBridge ()

@property (nonatomic, strong, nullable) IINKEngine *engine;
@property (nonatomic, strong, nullable) IINKContentPackage *package;
@property (nonatomic, strong, nullable) IINKContentPart *part;
@property (nonatomic, strong, nullable) IINKEditor *editor;
@property (nonatomic, strong, nullable) IINKRenderer *renderer;
@property (nonatomic, assign) BOOL initialized;

@end

@implementation MyScriptBridge

+ (instancetype)shared {
    static MyScriptBridge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _initialized = NO;
    }
    return self;
}

- (BOOL)initializeWithCertificateBytes:(const char *)bytes size:(size_t)size error:(NSError **)error {
    if (self.initialized) {
        return YES;
    }
    
    // Create certificate data from bytes
    NSData *certificateData = [NSData dataWithBytes:bytes length:size];
    
    // Initialize MyScript engine
    self.engine = [[IINKEngine alloc] initWithCertificate:certificateData];
    
    if (!self.engine) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyScriptBridge"
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to initialize MyScript engine"}];
        }
        return NO;
    }
    
    self.initialized = YES;
    NSLog(@"✅ MyScript SDK initialized successfully via Objective-C bridge");
    
    return YES;
}

- (BOOL)isInitialized {
    return self.initialized;
}

- (BOOL)createPackageWithType:(NSString *)contentType error:(NSError **)error {
    if (!self.initialized || !self.engine) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyScriptBridge"
                                         code:1002
                                     userInfo:@{NSLocalizedDescriptionKey: @"Engine not initialized"}];
        }
        return NO;
    }
    
    // Create a temporary package file path
    NSString *tempDir = NSTemporaryDirectory();
    NSString *packagePath = [tempDir stringByAppendingPathComponent:@"math_package.iink"];
    
    // Remove existing package if any
    [[NSFileManager defaultManager] removeItemAtPath:packagePath error:nil];
    
    // Create package
    NSError *packageError = nil;
    self.package = [self.engine createPackage:packagePath error:&packageError];
    
    if (!self.package || packageError) {
        if (error) {
            *error = packageError ?: [NSError errorWithDomain:@"MyScriptBridge"
                                                          code:1003
                                                      userInfo:@{NSLocalizedDescriptionKey: @"Failed to create package"}];
        }
        return NO;
    }
    
    // Create a part with specified content type
    NSError *partError = nil;
    self.part = [self.package createPart:contentType error:&partError];
    
    if (!self.part || partError) {
        if (error) {
            *error = partError ?: [NSError errorWithDomain:@"MyScriptBridge"
                                                       code:1004
                                                   userInfo:@{NSLocalizedDescriptionKey: @"Failed to create part"}];
        }
        return NO;
    }
    
    // Create a simple renderer (we won't actually render, just need it for the editor)
    self.renderer = [self.engine createRendererWithDpiX:96
                                                   dpiY:96
                                         renderTarget:nil];
    
    if (!self.renderer) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyScriptBridge"
                                         code:1005
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create renderer"}];
        }
        return NO;
    }
    
    // Create editor
    self.editor = [self.engine createEditor:self.renderer withToolController:nil];
    
    if (!self.editor) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyScriptBridge"
                                         code:1006
                                     userInfo:@{NSLocalizedDescriptionKey: @"Failed to create editor"}];
        }
        return NO;
    }
    
    // Set the part on the editor
    [self.editor setPart:self.part];
    
    NSLog(@"✅ MyScript editor created with content type: %@", contentType);
    
    return YES;
}

- (nullable NSString *)recognizeDrawing:(NSArray<NSValue *> *)strokes error:(NSError **)error {
    if (!self.editor || !self.part) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyScriptBridge"
                                         code:1007
                                     userInfo:@{NSLocalizedDescriptionKey: @"Editor not initialized"}];
        }
        return nil;
    }
    
    // Clear previous content
    [self.editor clear];
    
    // Process each stroke
    for (NSValue *strokeValue in strokes) {
        NSArray *points = (NSArray *)strokeValue.nonretainedObjectValue;
        
        // Convert points to pointer events
        for (NSInteger i = 0; i < points.count; i++) {
            NSValue *pointValue = points[i];
            CGPoint point = [pointValue CGPointValue];
            
            IINKPointerEvent *event = [[IINKPointerEvent alloc] init];
            event.x = point.x;
            event.y = point.y;
            event.t = i;
            event.f = 1.0;
            
            if (i == 0) {
                event.eventType = IINKPointerEventTypeDown;
            } else if (i == points.count - 1) {
                event.eventType = IINKPointerEventTypeUp;
            } else {
                event.eventType = IINKPointerEventTypeMove;
            }
            
            [self.editor pointerEvent:event];
        }
    }
    
    // Get recognized text
    IINKContentBlock *rootBlock = [self.editor rootBlock];
    if (rootBlock) {
        NSString *text = [self.editor export_:rootBlock mimeType:IINKMimeTypeText];
        return text;
    }
    
    return nil;
}

- (nullable NSString *)exportAsLaTeX:(NSError **)error {
    if (!self.editor || !self.part) {
        if (error) {
            *error = [NSError errorWithDomain:@"MyScriptBridge"
                                         code:1008
                                     userInfo:@{NSLocalizedDescriptionKey: @"Editor not initialized"}];
        }
        return nil;
    }
    
    IINKContentBlock *rootBlock = [self.editor rootBlock];
    if (rootBlock) {
        NSString *latex = [self.editor export_:rootBlock mimeType:IINKMimeTypeLATEX];
        return latex;
    }
    
    return nil;
}

- (void)clear {
    if (self.editor) {
        [self.editor clear];
    }
}

- (void)dealloc {
    [self clear];
    self.editor = nil;
    self.renderer = nil;
    self.part = nil;
    self.package = nil;
    self.engine = nil;
}

@end

