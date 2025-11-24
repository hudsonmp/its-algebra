#!/bin/bash
# Fix CocoaPods paths for worktree

echo "🔧 Fixing CocoaPods configuration..."

# Remove Xcode user data that may contain stale paths
echo "Cleaning Xcode user data..."
find . -type d -name "xcuserdata" -exec rm -rf {} + 2>/dev/null
find . -name "*.xcworkspace/xcuserdata" -type d -exec rm -rf {} + 2>/dev/null

# Check if pod command exists
if command -v pod &> /dev/null; then
    echo "Reinstalling CocoaPods..."
    pod deintegrate 2>/dev/null
    pod install
    echo "✅ CocoaPods reinstalled"
else
    echo "⚠️  CocoaPods not found. Please run:"
    echo "   pod install"
    echo ""
    echo "Or install CocoaPods first:"
    echo "   sudo gem install cocoapods"
fi

echo ""
echo "✅ Done! Now:"
echo "   1. Close Xcode completely"
echo "   2. Open its-algebra.xcworkspace (NOT .xcodeproj)"
echo "   3. Clean build folder (Shift+Cmd+K)"
echo "   4. Build (Cmd+B)"

