#!/bin/bash

echo "🔧 Fixing Xcode project configuration..."
echo ""

cd /Users/hudsonmitchell-pullman/its-algebra

# 1. Clean derived data
echo "1️⃣ Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/its-algebra-*
echo "✅ Cleaned"

# 2. Clean build folder
echo ""
echo "2️⃣ Cleaning build artifacts..."
xcodebuild clean -project its-algebra.xcodeproj 2>/dev/null
echo "✅ Cleaned"

# 3. Create .gitignore to exclude problematic files from Xcode
echo ""
echo "3️⃣ Creating proper .gitignore..."
cat > .gitignore << 'EOF'
# Xcode
DerivedData/
*.xcuserstate
xcuserdata/

# Data files
*.txt
data/

# Python
__pycache__/
*.py[cod]
*.log
server.log

# JSON data
kcs.json
feedback.json
mistakes.json

# Don't include Helix source in app bundle
*.rs
*.toml
Cargo.lock

# Keep these specific files
!helix.toml
!pyproject.toml
EOF
echo "✅ Created .gitignore"

# 4. Instructions for manual fix
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 MANUAL STEPS NEEDED IN XCODE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open Xcode: open its-algebra.xcodeproj"
echo ""
echo "2. Select 'its-algebra' target in left sidebar"
echo ""
echo "3. Go to 'Build Phases' tab"
echo ""
echo "4. Expand 'Copy Bundle Resources'"
echo ""
echo "5. Remove these file types:"
echo "   - All .rs files (Rust source)"
echo "   - All .toml files except your app config"
echo "   - Cargo.lock"
echo "   - All .hx files (schema/queries)"
echo "   - README.md files"
echo "   - docker-compose.yml"
echo ""
echo "6. Keep ONLY:"
echo "   - .swift files"
echo "   - Assets.xcassets"
echo "   - Info.plist"
echo "   - Any actual app resources (images, sounds, etc.)"
echo ""
echo "7. Clean build: Cmd+Shift+K"
echo ""
echo "8. Build: Cmd+B"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 5. Alternative: Create minimal project
echo ""
echo "🔄 ALTERNATIVE: Want me to recreate a minimal Xcode project?"
echo "   This will create a clean project with just the Swift files."
echo ""
echo "   Run: ./setup-xcode-project.sh"
echo ""

echo "✅ Done! Follow the manual steps above to fix the build."

