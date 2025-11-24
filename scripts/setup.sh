#!/bin/bash
set -e

echo "🚀 Setting up ITS Algebra project..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Stop existing containers quickly
info "Stopping existing containers..."
docker-compose down --timeout 5 2>/dev/null || true

# Setup Helix (optional - skip if not installed)
if command -v helix &> /dev/null; then
    info "Setting up Helix..."
    
    # Initialize Helix if not already done
    if [ ! -f ".helix/initialized" ]; then
        info "Initializing Helix project..."
        helix init 2>/dev/null || warn "Helix init failed (may already be initialized)"
        touch .helix/initialized 2>/dev/null || true
    fi
    
    # Deploy Helix dev instance
    info "Deploying Helix dev instance..."
    helix push dev 2>/dev/null || warn "Helix push failed (may already be deployed)"
else
    warn "Helix CLI not found. Skipping Helix setup."
    warn "Install Helix CLI to enable graph database features."
fi

# Ensure KC data files exist
info "Checking KC data files..."
if [ ! -f "services/rag/kcs.json" ]; then
    warn "KC files not found. Checking backend..."
    mkdir -p services/rag
    
    # Try to copy from backend
    if [ -f "backend/kcs.json" ]; then
        cp backend/kcs.json backend/feedback.json backend/mistakes.json services/rag/ 2>/dev/null || true
        info "Copied KC files from backend/"
    elif [ -f "data/kcs.json" ]; then
        cp data/kcs.json data/feedback.json data/mistakes.json services/rag/ 2>/dev/null || true
        info "Copied KC files from data/"
    else
        warn "KC files not found. You may need to run extract_kcs.py first."
        warn "Continuing anyway - RAG server will fail if files are missing."
    fi
fi

# Build and start Docker containers
info "Building Docker images..."
docker-compose build

info "Starting services..."
docker-compose up -d

# Wait for services to be healthy
info "Waiting for services to start..."
sleep 5

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    info "Services are running!"
    echo ""
    echo "📊 RAG Server: http://localhost:8080"
    echo "🗄️  Helix DB: http://localhost:6969"
    echo ""
    echo "To view logs: docker-compose logs -f"
    echo "To stop: docker-compose down"
else
    error "Some services failed to start. Check logs with: docker-compose logs"
    exit 1
fi

