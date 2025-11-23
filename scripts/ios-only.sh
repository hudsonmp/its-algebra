#!/bin/bash
# Remove non-iOS files from Xcode project
cd /Users/hudsonmitchell-pullman/its-algebra
find . -name "*.rs" -delete
find . -name "Cargo.*" -delete
find . -name "*.hx" -delete
find . -name "docker-compose.yml" -delete
echo "✅ Cleaned. Only Swift files remain for iOS build."

