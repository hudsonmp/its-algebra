#!/bin/bash

echo "🧪 Testing RAG Server Setup..."
echo ""

# Check if JSON files exist
if [ ! -f "kcs.json" ] || [ ! -f "feedback.json" ] || [ ! -f "mistakes.json" ]; then
    echo "❌ Data files missing. Run: python3 extract_kcs.py"
    exit 1
fi

echo "✅ Data files found"

# Test Python imports
python3 -c "import flask, flask_cors" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "❌ Flask not installed. Run: pip3 install flask flask-cors"
    exit 1
fi

echo "✅ Flask installed"

# Start server
echo ""
echo "🚀 Starting RAG server..."
python3 rag_server.py &
SERVER_PID=$!

sleep 3

# Test endpoint
echo ""
echo "🧪 Testing /get_hints endpoint..."
RESPONSE=$(curl -s -X POST http://localhost:8080/get_hints \
  -H "Content-Type: application/json" \
  -d '{"problem": "x - 7 + 3 = 5"}')

if echo "$RESPONSE" | grep -q "kc"; then
    echo "✅ Server responding correctly!"
    echo ""
    echo "Sample response:"
    echo "$RESPONSE" | python3 -m json.tool | head -15
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✨ Success! Now open test_rag.html in your browser"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo "❌ Server not responding correctly"
    kill $SERVER_PID 2>/dev/null
    exit 1
fi

# Keep server running
echo ""
echo "Server is running at http://localhost:8080"
echo "Press Ctrl+C to stop..."
wait $SERVER_PID

