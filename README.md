# ITS Algebra

Swift app for iPad providing real-time AI tutoring for algebra using HelixDB.

## Project Structure

```
its-algebra/
├── ios/                    # iOS Swift app and Xcode project
├── backend/                # Python backend and data processing
│   ├── html/              # HTML test interfaces
│   ├── *.py               # Python scripts
│   └── *.json             # Data files (kcs, feedback, mistakes)
├── db/                     # Helix database files
│   ├── schema.hx          # Database schema
│   ├── queries.hx         # Database queries
│   └── import.hx          # Data import script
├── data/                   # Raw data files
├── config/                 # Configuration files
│   └── pyproject.toml     # Python dependencies
├── scripts/                # Setup and utility scripts
│   └── setup-helix.sh     # Main setup script
├── helix.toml             # Helix project config (root)
└── docs/                   # Documentation
```

## Quick Start

### Setup Helix Database

```bash
./scripts/setup-helix.sh
```

This script will:
- Kill any running Helix processes/containers
- Validate queries
- Build and start Helix on port 6969
- Prepare for data import

### Generate Import Script

```bash
cd backend
python3 import_to_helix.py
```

This generates `db/import.hx` from JSON data files.

### Start RAG Server

```bash
cd backend
python3 rag_server.py
```

Then open `backend/html/test_rag.html` in your browser.

## Helix RAG Query Syntax

See `docs/README.md` for query examples.

## Development

- **iOS App**: Open `ios/its-algebra.xcodeproj` in Xcode
- **Backend**: Python scripts in `backend/`
- **Database**: Helix queries in `db/`

## Documentation

- Setup: `docs/SETUP_INSTRUCTIONS.md`
- Testing: `docs/TESTING_GUIDE.md`
- Project Structure: `docs/PROJECT_STRUCTURE.md`
