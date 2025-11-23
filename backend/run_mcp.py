#!/usr/bin/env python3
import os
import ollama
from dotenv import load_dotenv
from helix.client import Client
from helix_mcp import MCPServer, ToolConfig

load_dotenv()

class OllamaEmbedder:
    def __init__(self, model='qwen3-embedding:8b'):
        self.model = model

    def embed(self, text, **kwargs):
        result = ollama.embed(model=self.model, input=text)
        return result['embeddings'][0]

def main():
    client = Client(local=True, verbose=True)

    use_local = os.getenv("LOCAL", "true") == "true"
    embedder = None

    if use_local:
        embedder = OllamaEmbedder(model='qwen3-embedding:8b')

    tool_config = ToolConfig(
        search_vector=embedder is not None,
        search_vector_text=embedder is None,
    )

    server = MCPServer(
        name="helix-mcp-server",
        client=client,
        verbose=True,
        tool_config=tool_config,
        embedder=embedder,
    )

    server.run(transport="stdio")

if __name__ == "__main__":
    main()

