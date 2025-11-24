# Install MyScript SDK - Easy Way! 🚀

You already have the certificate (`MyCertificate.c`), so you're 90% done!

## Manual Install (MyScript SDK not on CocoaPods)

### Step 1: Download SDK from MyScript

1. Go to https://developer.myscript.com/
2. Sign in to your account
3. Navigate to **Downloads** → **Interactive Ink SDK for iOS**
4. Download version 2.1 or later
5. Extract the downloaded ZIP file

### Step 2: Copy Framework to Project

```bash
# Create Frameworks directory if it doesn't exist
mkdir -p /Users/hudsonmitchell-pullman/its-algebra/Frameworks

# Copy the framework (adjust path to your Downloads folder)
cp -R ~/Downloads/IInkSDK_*/iink.framework /Users/hudsonmitchell-pullman/its-algebra/Frameworks/
```

### Step 3: Add Framework in Xcode

```bash
# Open the Xcode project
open /Users/hudsonmitchell-pullman/its-algebra/config/its-algebra.xcodeproj
```

In Xcode:
1. Select **its-algebra** project (top of navigator)
2. Select **its-algebra** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click **+** button
6. Click **Add Other...** → **Add Files...**
7. Navigate to `/Users/hudsonmitchell-pullman/its-algebra/Frameworks/`
8. Select **iink.framework**
9. Set to **Embed & Sign**

### Step 4: Fix Signing

In Xcode:
1. Select "its-algebra" target
2. Go to "Signing & Capabilities" tab
3. Check "Automatically manage signing"
4. Select your Team (Apple ID)

### Step 5: Build & Test!

1. Connect your iPad Air
2. Select it as the build destination
3. Click Play (▶️) or press Cmd+R
4. Draw digits like **1, 2, 3** and watch them get recognized!

## What You Get

✅ **Real handwriting recognition** on-device  
✅ **No more hardcoded fake data** (integrals, square roots, etc. are gone!)  
✅ **Math expressions** support built-in  
✅ **LaTeX output** from your handwriting  

## Troubleshooting

### "Framework not found" error
1. Verify framework exists: `ls -la Frameworks/iink.framework`
2. Make sure you added it in Xcode and set to "Embed & Sign"
3. Clean build: Product → Clean Build Folder (Cmd+Shift+K)

### Still showing "SDK not initialized"
1. Check certificate: `ls -la MyScriptCertificate/MyCertificate.c`
2. Clean build folder (Cmd+Shift+K)
3. Check Xcode build logs for framework loading errors

### Signing Error
1. Select target → "Signing & Capabilities"
2. Check "Automatically manage signing"
3. Add your Apple ID in Xcode → Preferences → Accounts

---

**Once you download and add the framework, you'll have real handwriting recognition!** 🎉

