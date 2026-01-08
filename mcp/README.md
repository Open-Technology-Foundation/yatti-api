# YaTTi API MCP Server

MCP server providing RAG query tools for YaTTi knowledgebases.

## Overview

This MCP server wraps the `yatti-api` CLI to expose knowledgebase query capabilities to Claude Code and other MCP clients.

## Tools

| Tool | Purpose |
|------|---------|
| `yatti_query` | Query a knowledgebase with RAG |
| `yatti_query_context_only` | Get raw sources without AI generation |
| `yatti_list_knowledgebases` | List available KBs |
| `yatti_kb_info` | Get KB details |
| `yatti_status` | Check API health |
| `yatti_history` | View query history |

## Available Knowledgebases

| KB | Domain |
|----|--------|
| appliedanthropology | Applied anthropology research |
| seculardharma | Secular Buddhist philosophy |
| jakartapost | Indonesian news archives (1994-2005) |
| peraturan | Indonesian laws and regulations |
| okusiassociates | Indonesian business operations |
| prosocial | Social evolution research |
| wayang | Indonesian wayang culture |
| okusimail | Email correspondence |
| okusiresearch | Investment research |
| ollama | Ollama documentation |
| uv | Full-stack programming |
| openai_docs | OpenAI API documentation |
| smi | SMI domain research |

## Installation

The MCP server is included in the yatti-api repository under `mcp/`.

```bash
# Install dependencies
cd /ai/scripts/yatti-api/mcp
uv sync
```

## Configuration

Add to `/etc/claude-code/managed-mcp.json`:

```json
{
  "mcpServers": {
    "yatti": {
      "command": "uv",
      "args": ["run", "--directory", "/ai/scripts/yatti-api/mcp", "python", "-m", "mcp_server.server"],
      "env": {}
    }
  }
}
```

## Requirements

- Python 3.12+
- `yatti-api` CLI installed and in PATH
- Valid YaTTi API key configured (`~/.config/yatti-api/api_key` or `YATTI_API_KEY` env var)

## Testing

```bash
cd /ai/scripts/yatti-api/mcp

# Test module import
uv run python -c "import mcp_server; print('OK')"

# Test CLI directly
yatti-api query seculardharma "What is mindfulness?"
```

## Deployment

Deployed on:
- okusi (development)
- ok0, ok1, ok2, ok3 (production)

## Version

1.0.0

#fin
