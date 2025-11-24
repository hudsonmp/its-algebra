#!/bin/bash

# MyScript SDK Installation via CocoaPods
# This is MUCH easier than manual download!

set -e

PROJECT_ROOT="/Users/hudsonmitchell-pullman/its-algebra"

echo "🚀 Installing MyScript SDK via CocoaPods"
echo "========================================="
echo ""

cd "$PROJECT_ROOT"

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    echo "❌ CocoaPods not found!"
    echo ""
    echo "Installing CocoaPods..."
    sudo gem install cocoapods
    echo "✅ CocoaPods installed!"
    echo ""
fi

echo "📦 Installing MyScript SDK..."
pod install

echo ""
echo "✅ MyScript SDK installed successfully!"
echo ""
echo "⚠️  IMPORTANT: From now on, open the .xcworkspace file, NOT .xcodeproj!"
echo ""
echo "Next steps:"
echo "1. Open: open its-algebra.xcworkspace"
echo "2. Select your team for signing (Xcode → Target → Signing & Capabilities)"
echo "3. Build and run on your iPad Air!"
echo ""
echo "The hardcoded fake data is gone - you'll get real handwriting recognition! 🎉"

