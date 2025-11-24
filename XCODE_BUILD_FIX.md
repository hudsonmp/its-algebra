# Quick Fix for Xcode Build Errors

## Current Errors You're Seeing

1. ❌ Framework 'iink' not found
2. ❌ Signing requires a development team

## Fix #1: Signing (Do This First)

The app needs to be signed to run on iPad. Here's how:

1. **Open Xcode**:
   ```bash
   open config/its-algebra.xcodeproj
   ```

2. **Select the target**:
   - Click "its-algebra" project in the navigator (left sidebar)
   - Click "its-algebra" target under TARGETS

3. **Configure Signing**:
   - Go to "Signing & Capabilities" tab
   - Check ✅ "Automatically manage signing"
   - Under "Team", select your Apple ID
   
4. **If you don't see your Team**:
   - Go to Xcode menu → Preferences (Cmd+,)
   - Click "Accounts" tab
   - Click "+" to add your Apple ID
   - Sign in with your Apple ID
   - Close preferences and select your team in target settings

## Fix #2: Framework (Optional - App Will Build Without It)

The app is designed to build WITHOUT the MyScript framework. It will just show "MyScript SDK not initialized" instead of recognizing handwriting.

### Option A: Build Without Framework (Fastest)
Just click "Build" in Xcode. The app will compile and run, but won't recognize handwriting (will show error message instead of hardcoded data).

### Option B: Add Framework for Real Recognition
Follow the full instructions in `MYSCRIPT_SETUP.md` to:
1. Download MyScript SDK
2. Add `iink.framework` to the project
3. Rebuild

## Quick Test

After fixing signing:

1. **Connect your iPad Air**
2. **Select it as the build destination** in Xcode (top toolbar)
3. **Click the Play button** (Cmd+R) to build and run
4. **Try drawing digits** - you'll see "MyScript SDK not initialized" until you add the framework

## Summary

**To just get the app running on iPad:**
- Fix signing (add your Apple ID/Team)
- Build and run
- App works, but no handwriting recognition (shows error instead)

**To get handwriting recognition working:**
- Fix signing first
- Then follow `MYSCRIPT_SETUP.md` to add the MyScript SDK framework
- Rebuild

The hardcoded fake data (integrals, square roots, etc.) is completely removed, so you won't see that anymore! 🎉

