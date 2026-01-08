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

Run the installer to copy MCP server files to `/usr/local/share/yatti/yatti-api-mcp/`:

```bash
# From the repository
sudo ./mcp/install.sh

# Or directly from GitHub
curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/mcp/install.sh | sudo bash
```

## Configuration

Add to `~/.claude/settings.local.json` or `/etc/claude-code/managed-mcp.json`.

**If installed with uv:**
```json
{
  "mcpServers": {
    "yatti": {
      "command": "uv",
      "args": ["run", "--directory", "/usr/local/share/yatti/yatti-api-mcp", "python", "-m", "mcp_server.server"],
      "env": {}
    }
  }
}
```

**If installed with pip:**
```json
{
  "mcpServers": {
    "yatti": {
      "command": "/usr/local/share/yatti/yatti-api-mcp/.venv/bin/python",
      "args": ["-m", "mcp_server.server"],
      "env": {}
    }
  }
}
```

## Requirements

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) (preferred) or pip
- `yatti-api` CLI installed and in PATH
- Valid YaTTi API key configured (`~/.config/yatti-api/api_key` or `YATTI_API_KEY` env var)

## Testing

```bash
cd /usr/local/share/yatti/yatti-api-mcp

# Test module import
uv run python -c "import mcp_server; print('OK')"

# Test CLI directly
yatti-api query seculardharma "What is mindfulness?"
```

## Okusi Development

For Okusi internal servers (okusi, ok0-3), the MCP server runs from the repository:

```bash
# Path
/ai/scripts/yatti-api/mcp

# Configuration
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

## Version

1.0.0

#fin
