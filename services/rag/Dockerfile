FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY rag_server.py .
COPY kcs.json feedback.json mistakes.json ./

# Expose port
EXPOSE 8080

# Run the server
CMD ["python", "rag_server.py"]

