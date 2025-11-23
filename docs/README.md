image.png# its-algebra
Swift app for an ipad for realtime AI tutoring for algebra

## Helix RAG Query Syntax

```hx
// Get KC by name
N::KnowledgeComponent(KCName == "'v-N+N=N")

// Get feedback for a KC
N::KnowledgeComponent(KCName == "'v-N+N=N") -[E::HasFeedback]-> N::Feedback

// Get common mistakes for a KC
N::KnowledgeComponent(KCName == "'v-N+N=N") -[E::HasMistake]-> N::Mistake

// Find easy KCs
N::KnowledgeComponent(Difficulty == "Easy")

// Get all Transformation KCs
N::KnowledgeComponent(KCCategory == "Transformation")

// Find prerequisites
N::KnowledgeComponent(KCName == "'v-N=N") -[E::Prerequisite]-> N::KnowledgeComponent
```

## Testing RAG Workflow

**Start the server:**
```bash
python3 rag_server.py
```

**Open the test interface:**
```bash
open test_rag.html
```

The interface lets you:
- Enter algebra problems (e.g., "x - 7 + 3 = 5")
- Get real-time hints from the knowledge base
- See common mistakes students make
- View KC difficulty and success rates

## Data Files
- `kcs.json` - 1,018 Knowledge Components with success rates
- `feedback.json` - Tutoring feedback by KC
- `mistakes.json` - Common student errors by KC
- `helix_import.hx` - Helix database import script
- `test_rag.html` - Interactive RAG testing interface
- `rag_server.py` - Flask backend for RAG queries
