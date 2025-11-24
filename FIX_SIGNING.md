# Fix Signing Error - 2 Minute Guide

## The Error
```
Signing for "its-algebra" requires a development team.
Select a development team in the Signing & Capabilities editor.
```

## The Fix (Do This Once)

### Step 1: Open Xcode
```bash
open config/its-algebra.xcodeproj
```

### Step 2: Add Your Apple ID (If Not Already Added)
1. In Xcode menu bar → **Xcode** → **Settings** (or **Preferences**)
2. Click **Accounts** tab
3. If you don't see your Apple ID:
   - Click the **+** button (bottom left)
   - Select **Apple ID**
   - Sign in with your Apple ID (free, no developer account needed)
4. Close the Settings window

### Step 3: Select Signing Team
1. In Xcode, click **its-algebra** in the left sidebar (the blue icon at the top)
2. Under **TARGETS**, click **its-algebra**
3. Click the **Signing & Capabilities** tab (top of the main area)
4. Check the box: ☑️ **Automatically manage signing**
5. Under **Team**, select your name/Apple ID from the dropdown

### Step 4: Build
1. Connect your iPad Air via USB
2. At the top of Xcode, click the device selector (next to play button)
3. Select your iPad Air
4. Click the **Play** button (▶️) or press **Cmd+R**

## Done!

The app will now build and run on your iPad. 

**Note**: You'll see "MyScript SDK not initialized" when drawing because the framework isn't installed yet. This is expected! No more hardcoded fake data.

To add handwriting recognition, follow `MYSCRIPT_SETUP.md` to download and install the MyScript SDK.

