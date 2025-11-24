# Install MyScript SDK - Easy Way! 🚀

You already have the certificate (`MyCertificate.c`), so you're 90% done!

## Quick Install via CocoaPods (Recommended)

### Step 1: Install CocoaPods (one-time setup)

```bash
sudo gem install cocoapods
```

It will ask for your Mac password. This is safe - CocoaPods is the standard way to install iOS frameworks.

### Step 2: Install MyScript SDK

```bash
cd /Users/hudsonmitchell-pullman/its-algebra
pod install
```

This will:
- Download the MyScript Interactive Ink SDK (v2.1)
- Create an `its-algebra.xcworkspace` file
- Set up everything automatically

### Step 3: Open Workspace (NOT Project!)

**IMPORTANT**: After running `pod install`, you must open the **.xcworkspace** file:

```bash
open its-algebra.xcworkspace
```

**DO NOT** open the `.xcodeproj` file anymore - use `.xcworkspace` instead!

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

### "Command not found: pod"
Run Step 1 to install CocoaPods first.

### "Framework not found" error after install
Make sure you're opening `.xcworkspace` not `.xcodeproj`

### Still showing "SDK not initialized"
1. Clean build: Product → Clean Build Folder (Cmd+Shift+K)
2. Make sure you're opening the workspace file
3. Check that `pod install` completed successfully

## Alternative: Manual Download

If CocoaPods doesn't work for some reason, see `MYSCRIPT_SETUP.md` for manual download instructions from developer.myscript.com.

---

**You're almost there!** Just run those two commands and you'll have real handwriting recognition working! 🎉

