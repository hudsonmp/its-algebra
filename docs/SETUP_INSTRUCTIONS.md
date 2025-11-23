# Setup Instructions for iPad Testing

## Quick Start (macOS)

### Option 1: Using xcodegen (Recommended - Automated)

1. Install xcodegen (if not already installed):
   ```bash
   brew install xcodegen
   ```

2. Run the setup script:
   ```bash
   chmod +x setup-xcode-project.sh
   ./setup-xcode-project.sh
   ```

3. Open the project:
   ```bash
   open its-algebra.xcodeproj
   ```

4. Run on iPad Simulator:
   - In Xcode: Product → Destination → iPad Air (choose a model)
   - Press ⌘R or click Run

### Option 2: Manual Setup in Xcode

1. Open Xcode
2. File → New → Project (⌘⇧N)
3. Choose iOS → App
4. Configure:
   - Product Name: `its-algebra`
   - Team: Your Apple ID team
   - Organization Identifier: `com.itsalgebra`
   - Interface: SwiftUI
   - Language: Swift
5. Add your Swift files to the project
6. Configure for iPad:
   - Select project → Target → General
   - Devices: iPad
   - Minimum iOS: 14.0
7. Run on iPad Simulator

## Testing on Physical iPad Air

1. Connect iPad Air via USB
2. Trust computer on iPad when prompted
3. In Xcode: Product → Destination → Select your iPad
4. Sign with your Apple Developer account (free account works)
5. Run (⌘R)

## Available iPad Simulators

- iPad Air (4th generation)
- iPad Air (5th generation)
- iPad Pro (various sizes)

Choose any iPad Air model from Product → Destination menu.

