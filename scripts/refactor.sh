#!/bin/bash
set -e

echo "📁 Refactoring project structure..."

# Create directory structure
mkdir -p services/rag
mkdir -p services/helix
mkdir -p scripts
mkdir -p data/raw
mkdir -p data/processed

# Move RAG server files
if [ -f "backend/rag_server.py" ]; then
    cp backend/rag_server.py services/rag/ 2>/dev/null || true
fi

# Move KC data files
if [ -f "backend/kcs.json" ]; then
    cp backend/kcs.json services/rag/ 2>/dev/null || true
fi
if [ -f "backend/feedback.json" ]; then
    cp backend/feedback.json services/rag/ 2>/dev/null || true
fi
if [ -f "backend/mistakes.json" ]; then
    cp backend/mistakes.json services/rag/ 2>/dev/null || true
fi

# Move extraction scripts to scripts/
if [ -f "backend/extract_kcs.py" ]; then
    cp backend/extract_kcs.py scripts/ 2>/dev/null || true
fi
if [ -f "backend/import_to_helix.py" ]; then
    cp backend/import_to_helix.py scripts/ 2>/dev/null || true
fi
if [ -f "backend/clean_its_data.py" ]; then
    cp backend/clean_its_data.py scripts/ 2>/dev/null || true
fi

echo "✅ Refactoring complete!"
echo ""
echo "New structure:"
echo "  services/rag/     - RAG server and KC data"
echo "  services/helix/   - Helix configuration"
echo "  scripts/          - Utility scripts"
echo "  data/             - Data files"
echo "  db/               - Database schemas"

