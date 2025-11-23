#!/bin/bash

# Script to create Xcode project for its-algebra app
# Run this on macOS with Xcode installed

set -e

PROJECT_NAME="its-algebra"

echo "🚀 Setting up Xcode project for $PROJECT_NAME..."
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS with Xcode installed"
    exit 1
fi

# Check if xcodegen is installed
if command -v xcodegen &> /dev/null; then
    echo "✅ Found xcodegen - using it to generate project..."
    if [ -f "project.yml" ]; then
        xcodegen generate
        echo ""
        echo "✅ Xcode project created successfully!"
        echo ""
        echo "🎯 To test on iPad Simulator:"
        echo "   1. Open $PROJECT_NAME.xcodeproj in Xcode"
        echo "   2. Product → Destination → iPad Air (choose a model)"
        echo "   3. Product → Run (⌘R)"
        exit 0
    else
        echo "⚠️  project.yml not found, falling back to manual method..."
    fi
fi

# Manual method: Create project using Xcode command line
echo "📦 Creating Xcode project manually..."
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or xcodebuild is not in PATH"
    echo "   Please install Xcode from the App Store"
    exit 1
fi

echo "⚠️  Manual project creation requires Xcode GUI."
echo ""
echo "📝 Please follow these steps:"
echo ""
echo "   1. Open Xcode"
echo "   2. File → New → Project (or ⌘⇧N)"
echo "   3. Choose 'iOS' → 'App'"
echo "   4. Click 'Next'"
echo "   5. Configure:"
echo "      - Product Name: its-algebra"
echo "      - Team: Select your team (or None)"
echo "      - Organization Identifier: com.itsalgebra"
echo "      - Interface: SwiftUI"
echo "      - Language: Swift"
echo "      - Storage: None"
echo "   6. Click 'Next' and choose where to save"
echo "   7. After project is created:"
echo "      - Delete the default ContentView.swift if it exists"
echo "      - Right-click project → Add Files to 'its-algebra'"
echo "      - Select: its-algebraApp.swift, ContentView.swift, DrawingCanvasView.swift"
echo "      - Check 'Copy items if needed'"
echo "   8. Configure for iPad:"
echo "      - Select project (blue icon) in navigator"
echo "      - Select 'its-algebra' target"
echo "      - General tab → Deployment Info:"
echo "        • Devices: iPad"
echo "        • Minimum iOS: 14.0"
echo ""
echo "🎯 To test on iPad Simulator:"
echo "   1. Product → Destination → iPad Air (choose a model)"
echo "   2. Product → Run (⌘R)"
echo ""
echo "💡 Tip: Install xcodegen for automated setup:"
echo "   brew install xcodegen"
echo "   Then run this script again!"
