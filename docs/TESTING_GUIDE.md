# RAG Testing Guide

## Quick Start

### Option 1: Automated Test
```bash
./test_server.sh
```

### Option 2: Manual Setup

**1. Start the server:**
```bash
python3 rag_server.py
```

You should see:
```
🚀 ITS Algebra RAG Server Starting...
📊 Loaded 1018 Knowledge Components
💬 Loaded 500 feedback entries
❌ Loaded 284 mistake patterns
🌐 Server running at: http://localhost:5000
```

**2. Open the test interface:**
```bash
open test_rag.html
```

Or manually open `test_rag.html` in your browser.

**3. Test with sample problems:**
- Click any sample problem button
- Or type your own: `x - 7 + 3 = 5`
- Click "Get Hints"

## Sample Problems to Try

| Problem | Expected KC | Difficulty |
|---------|-------------|------------|
| `x - 7 + 3 = 5` | 'v-N+N=N | Hard |
| `3y + 9 = 13` | 'Nv+N=N | Medium |
| `2x = 10` | 'Nv=N | Easy |
| `x + 5 = 10` | 'v+N=N | Medium |
| `-5 - 11w = -8 - 8w` | '-N-Nv=-N-Nv | Hard |

## What You'll See

The interface will show:
1. **KC Information**
   - Pattern name
   - Category (Transformation/Typein)
   - Difficulty level
   - Success rate from training data

2. **Hints**
   - Specific feedback from the dataset
   - Generic guidance based on KC type
   - Categorized by type (HINT, ERROR, EXPLANATION)

3. **Common Mistakes**
   - What students typically enter wrong
   - Helps avoid known pitfalls

## API Endpoints

### GET /
Health check
```bash
curl http://localhost:5000/
```

### POST /get_hints
Get hints for a problem
```bash
curl -X POST http://localhost:5000/get_hints \
  -H "Content-Type: application/json" \
  -d '{"problem": "x - 7 + 3 = 5", "step_type": ""}'
```

### GET /search_kc?q=term
Search for KCs
```bash
curl http://localhost:5000/search_kc?q=v-N
```

### GET /stats
Get database statistics
```bash
curl http://localhost:5000/stats
```

## Troubleshooting

**Server won't start:**
```bash
pip3 install flask flask-cors
```

**Port already in use:**
```bash
# Find and kill the process
lsof -ti:5000 | xargs kill -9
```

**Can't connect from HTML:**
- Make sure server is running
- Check browser console for CORS errors
- Verify URL is http://localhost:5000

## Next Steps

Once tested, integrate into your iPad app:
1. Replace Flask backend with actual Helix database queries
2. Use the same pattern matching logic
3. Connect via your Swift app's network layer
4. Implement real-time hint delivery based on student input

## Architecture

```
Student Input → Pattern Matching → KC Identification → Helix Query → Hints
     ↓
test_rag.html → rag_server.py → kcs.json/feedback.json → Response
                                     ↓
                                 (Replace with actual Helix DB)
```

