# MyScript SDK Setup for iPad Air On-Device Recognition

This guide will help you set up MyScript Interactive Ink SDK for real-time handwriting recognition on iPad Air.

## What You Need

1. **MyScript Developer Account**: Register at https://developer.myscript.com
2. **MyScript Certificate**: Already included in `MyScriptCertificate/MyCertificate.c`
3. **MyScript Interactive Ink SDK**: Download from MyScript

## Step 1: Download MyScript SDK

### Option A: Download from MyScript Website (Recommended)
1. Go to https://developer.myscript.com/
2. Sign in to your account
3. Navigate to Downloads section
4. Download **MyScript Interactive Ink SDK for iOS** (version 2.x or later)
5. Extract the downloaded file

### Option B: Use CocoaPods
Add to your `Podfile`:
```ruby
pod 'MyScriptInteractiveInk-Framework', '~> 2.0'
```

Then run:
```bash
pod install
```

## Step 2: Add SDK to Project (Manual Installation)

1. Copy the `iink.framework` from the downloaded SDK to the Frameworks directory:
```bash
cd /Users/hudsonmitchell-pullman/its-algebra
mkdir -p Frameworks
cp -R /path/to/downloaded/iink.framework ./Frameworks/
```

2. Open the Xcode project:
```bash
open config/its-algebra.xcodeproj
```

3. In Xcode, add the framework:
   - Select your project in the navigator (top-level "its-algebra")
   - Select the "its-algebra" target
   - Go to "General" tab
   - Scroll to "Frameworks, Libraries, and Embedded Content"
   - Click the "+" button
   - Click "Add Other..." → "Add Files..."
   - Navigate to `/Users/hudsonmitchell-pullman/its-algebra/Frameworks/`
   - Select `iink.framework`
   - Set it to "Embed & Sign"

4. Configure Signing (Required for iPad):
   - Still in the target settings, go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your development team from the dropdown
   - If you don't have a team, you'll need to add your Apple ID in Xcode Preferences → Accounts

## Step 3: Verify Integration

The app should now properly use MyScript SDK for recognition instead of hardcoded data.

### Test Recognition:
1. Build and run on iPad Air
2. Draw simple digits like "1", "2", "3"
3. The app should recognize actual handwriting instead of showing hardcoded formulas

### If you see "MyScript SDK not initialized":
- Check that `iink.framework` is in the `Frameworks/` directory
- Verify your certificate file is valid
- Check Xcode build logs for framework loading errors

## Step 4: Configuration (Advanced)

### Math Recognition Mode
The app is configured to use Math recognition mode for better equation recognition. This is set in `MyScriptManager.swift`:

```swift
editor = try engine.createEditor(contentType: "Math")
```

### Supported Content Types:
- `"Text"` - Basic text recognition
- `"Math"` - Mathematical expressions
- `"Diagram"` - Shapes and diagrams
- `"Raw Content"` - Raw ink data

## Troubleshooting

### Framework Not Found Error
```bash
# Check if framework exists
ls -la Frameworks/iink.framework

# If missing, download and copy it again
```

### Certificate Error
```bash
# Verify certificate file exists
ls -la MyScriptCertificate/MyCertificate.c

# If certificate is invalid, request a new one from MyScript
```

### Linker Error / Framework Not Found
The app is designed to build WITHOUT the framework (it will just show "MyScript SDK not initialized"). 
If you're getting linker errors:
1. Make sure you added the framework in Xcode (see Step 2)
2. Check that framework is set to "Embed & Sign" in General → Frameworks, Libraries, and Embedded Content
3. Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)
4. If still failing, you can build without the framework - it just won't recognize handwriting

### Signing Error
To fix "requires a development team":
1. In Xcode, select your target
2. Go to "Signing & Capabilities" tab
3. Check "Automatically manage signing"
4. Select your Team (add your Apple ID in Xcode → Preferences → Accounts if needed)
5. You need a free Apple Developer account to test on iPad

### Recognition Not Working
- Make sure you're testing on a real iPad (not simulator)
- MyScript SDK requires actual device for full functionality
- Check that your MyScript license supports on-device recognition

## Additional Resources

- **MyScript Documentation**: https://developer.myscript.com/docs
- **iOS Examples**: https://github.com/MyScript/interactive-ink-examples-ios
- **API Reference**: https://developer.myscript.com/refguides/interactive-ink/ios/2.0/

## Current Status

✅ Mock data removed  
✅ Real MyScript SDK integration implemented  
✅ Certificate file included  
✅ Project configured for framework  
⏳ Need to download and add `iink.framework`  

Once you add the framework, the app will perform real handwriting recognition!
