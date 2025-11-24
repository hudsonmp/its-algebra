# Quick Start Guide

## Setup Everything

Run the setup script to initialize Helix and start Docker services:

```bash
./scripts/setup.sh
```

This script will:
1. ✅ Stop any existing containers (quickly)
2. ✅ Setup Helix (if installed)
3. ✅ Copy KC data files to services/rag/
4. ✅ Build Docker images
5. ✅ Start all services

## Manual Setup

If you prefer to set things up manually:

### 1. Extract KC Data (if not already done)

```bash
cd backend
python extract_kcs.py
cp kcs.json feedback.json mistakes.json ../services/rag/
```

### 2. Setup Helix (optional)

```bash
helix init
helix push dev
```

### 3. Start Docker Services

```bash
docker-compose up -d
```

## iOS App Setup

For handwriting recognition on iPad:

```bash
./scripts/setup_myscript.sh
```

Then follow instructions in `MYSCRIPT_SETUP.md` to download and add the MyScript SDK framework.

## Services

- **RAG Server**: http://localhost:8080
  - Endpoints: `/get_hints`, `/search_kc`, `/stats`
  
- **Helix DB**: http://localhost:6969 (if configured)

## Project Structure

```
its-algebra/
├── services/
│   ├── rag/              # RAG server with KC data
│   └── helix/            # Helix configuration
├── scripts/              # Utility scripts
├── data/                 # Data files
├── db/                   # Database schemas
└── docker-compose.yml    # Docker orchestration
```

## Troubleshooting

### KC files missing
```bash
cd backend
python extract_kcs.py
cp kcs.json feedback.json mistakes.json ../services/rag/
```

### Docker containers not starting
```bash
docker-compose logs
docker-compose down
docker-compose up -d
```

### Helix not working
Helix is optional. The RAG server works without it.

