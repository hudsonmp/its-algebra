#!/bin/bash

# MyScript SDK Setup Script
# This script helps set up the MyScript Interactive Ink SDK for iOS

set -e

PROJECT_ROOT="/Users/hudsonmitchell-pullman/its-algebra"
FRAMEWORKS_DIR="$PROJECT_ROOT/Frameworks"
SDK_FRAMEWORK="iink.framework"

echo "🔧 MyScript SDK Setup"
echo "===================="
echo ""

# Check if Frameworks directory exists
if [ ! -d "$FRAMEWORKS_DIR" ]; then
    echo "Creating Frameworks directory..."
    mkdir -p "$FRAMEWORKS_DIR"
fi

# Check if framework already exists
if [ -d "$FRAMEWORKS_DIR/$SDK_FRAMEWORK" ]; then
    echo "✅ MyScript SDK framework already exists at:"
    echo "   $FRAMEWORKS_DIR/$SDK_FRAMEWORK"
    echo ""
    echo "Regenerating Xcode project..."
    cd "$PROJECT_ROOT/config"
    xcodegen generate
    echo "✅ Xcode project regenerated!"
    echo ""
    echo "You can now open the project in Xcode and build for iPad."
    exit 0
fi

echo "❌ MyScript SDK framework not found!"
echo ""
echo "To complete setup:"
echo "1. Download MyScript Interactive Ink SDK from:"
echo "   https://developer.myscript.com/"
echo ""
echo "2. Extract the download and locate iink.framework"
echo ""
echo "3. Copy it to:"
echo "   $FRAMEWORKS_DIR/$SDK_FRAMEWORK"
echo ""
echo "4. Run this script again to complete setup"
echo ""
echo "Or manually copy with:"
echo "   cp -R /path/to/iink.framework $FRAMEWORKS_DIR/"
echo ""
echo "See MYSCRIPT_SETUP.md for detailed instructions."
exit 1

