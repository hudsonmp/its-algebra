#!/bin/bash
# Setup script for Helix database
# Kills running processes and sets up/imports data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Setting up Helix database..."

# Step 1: Kill any running Helix processes/containers
echo "📦 Stopping any running Helix containers..."
cd "$PROJECT_ROOT"

# Stop helix containers
if command -v docker &> /dev/null; then
    docker ps -a --filter "name=helix" --format "{{.ID}}" | xargs -r docker stop 2>/dev/null || true
    docker ps -a --filter "name=helix" --format "{{.ID}}" | xargs -r docker rm 2>/dev/null || true
    echo "✅ Cleaned up Docker containers"
fi

# Kill any helix processes
pkill -f helix || true
echo "✅ Killed running Helix processes"

# Step 2: Check if helix CLI is installed
if ! command -v helix &> /dev/null; then
    echo "❌ Helix CLI not found. Please install it first:"
    echo "   cargo install helix-cli"
    echo "   or visit: https://docs.helix-db.com"
    exit 1
fi

# Step 3: Validate queries
echo "🔍 Validating Helix queries..."
cd "$PROJECT_ROOT"
if helix check; then
    echo "✅ Queries validated successfully"
else
    echo "⚠️  Query validation had issues, but continuing..."
fi

# Step 4: Build and start Helix
echo "🏗️  Building Helix instance..."
if helix build dev; then
    echo "✅ Helix instance built"
else
    echo "⚠️  Build had issues, but continuing..."
fi

# Step 5: Start Helix
echo "🚀 Starting Helix..."
if helix start dev || helix push dev; then
    echo "✅ Helix started on port 6969"
else
    echo "⚠️  Could not start Helix, but continuing..."
fi

# Step 6: Wait for Helix to be ready
echo "⏳ Waiting for Helix to be ready..."
sleep 3

# Step 7: Generate import script if needed
if [ ! -f "$PROJECT_ROOT/db/import.hx" ]; then
    echo "📝 Generating import script..."
    cd "$PROJECT_ROOT/backend"
    if [ -f "import_to_helix.py" ]; then
        python3 import_to_helix.py
        echo "✅ Import script generated"
    else
        echo "⚠️  import_to_helix.py not found"
    fi
fi

# Step 8: Note about importing data
if [ -f "$PROJECT_ROOT/db/import.hx" ]; then
    echo "📥 Import file ready at db/import.hx"
    echo "   Use helix-py or the Helix API to execute the import queries"
fi

echo ""
echo "✅ Setup complete!"
echo "📋 Next steps:"
echo "   1. Helix should be running on http://localhost:6969"
echo "   2. Import data using: python3 backend/import_to_helix.py (if needed)"
echo "   3. Test queries using: helix check"
echo "   4. View status: helix status"

