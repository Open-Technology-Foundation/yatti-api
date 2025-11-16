# YaTTi API Client

Command-line interface for the YaTTi REST API - RAG (Retrieval Augmented Generation) for querying knowledgebases using various LLMs.

## Quick Start

### Linux/macOS

```bash
# Install
sudo curl -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download
sudo chmod +x /usr/local/bin/yatti-api

# Configure
yatti-api configure

# Use
yatti-api query seculardharma "What is mindfulness?"
```

---

## Features

- **Query knowledgebases** using RAG with multiple LLM models
- **Manage knowledgebases** - list, get info, sync
- **Secure API key** management with proper file permissions
- **Query history** - view past queries and results
- **Multiple output formats** - pretty-print or JSON
- **Self-updating** - check for and install updates automatically
- **Context control** - retrieve source contexts without AI response
- **Configurable** - temperature, top_k, models, templates
- **Bash completion** - tab completion for all commands
- **Built-in documentation** - access user/API/technical docs

---

## Installation

### Linux/macOS

**Download and install:**
```bash
sudo curl -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download
sudo chmod +x /usr/local/bin/yatti-api
```

**Configure API key:**
```bash
yatti-api configure
```

**Verify:**
```bash
yatti-api version
```

### Windows (WSL)

WSL (Windows Subsystem for Linux) provides a complete Linux environment on Windows. Once installed, use the Linux instructions above.

#### Step 1: Install WSL

Open PowerShell as Administrator and run:

```powershell
wsl --install
```

Restart your computer when prompted.

#### Step 2: Complete WSL Setup

After restart:
1. Open "Ubuntu" from the Start menu
2. Create a username and password when prompted
3. Wait for installation to complete

#### Step 3: Install Dependencies

In the WSL terminal (Ubuntu):

```bash
sudo apt-get update && sudo apt-get install -y curl jq
```

#### Step 4: Install yatti-api

In the WSL terminal:

```bash
sudo curl -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download
sudo chmod +x /usr/local/bin/yatti-api
yatti-api configure
```

#### Step 5: Verify Installation

```bash
yatti-api version
```

**Note:** Always use the WSL terminal (Ubuntu) to run yatti-api commands. The script runs natively in the Linux environment provided by WSL.

#### Troubleshooting WSL

**WSL not available:**
- Requires Windows 10 version 2004+ or Windows 11
- Enable WSL in Windows Features if `wsl --install` fails

**Ubuntu won't start:**
- Check Windows Features: Virtual Machine Platform and WSL are enabled
- Run `wsl --update` in PowerShell as Administrator

**Permission issues:**
```bash
sudo chmod +x /usr/local/bin/yatti-api
```

---

## Usage

### Basic Commands

```bash
# Show help
yatti-api help

# Check status
yatti-api status

# List knowledgebases
yatti-api kb list

# Query a knowledgebase
yatti-api query seculardharma "What is mindfulness?"

# View query history
yatti-api history

# Configure API key
yatti-api configure

# Check for updates
yatti-api update --check

# View documentation
yatti-api docs
```

### Query Examples

**Basic query:**
```bash
yatti-api query seculardharma "What is mindfulness?"
```

**With options:**
```bash
yatti-api query -K jakartapost \
  -q "Who is Soeharto?" \
  --model gpt-4o \
  --top-k 10 \
  --temperature 0.7
```

**Context only (no AI response):**
```bash
yatti-api query -K wikipedia -q "Python programming" -c
```

**Scholarly style with more tokens:**
```bash
yatti-api query -K arxiv \
  -q "Explain quantum computing" \
  -p scholarly \
  -M 2000
```

### Query Options

- `-K, --knowledgebase NAME` - Knowledgebase to query (required)
- `-q, --query TEXT` - Query text (required)
- `-k, --top-k NUM` - Number of contexts (default: 5)
- `-t, --temperature NUM` - LLM temperature 0.0-2.0 (default: 0.0)
- `-m, --model NAME` - LLM model (default: gpt-4o)
- `-s, --context-scope NUM` - Context segments per result (default: 3)
- `-c, --context-only` - Return only context without AI response
- `-M, --max-tokens NUM` - Maximum response tokens
- `-p, --prompt-template NAME` - Prompt style (default, instructive, scholarly, concise, analytical, conversational, technical)
- `-f, --force-refresh` - Skip cache and force new query
- `--cache-ttl SECONDS` - Cache TTL in seconds (default: 86400)
- `--timeout SECONDS` - Query timeout in seconds (default: 60, max: 600)

### Other Commands

**Knowledgebases:**
```bash
yatti-api kb list                    # List all knowledgebases
yatti-api kb get seculardharma       # Get info about a KB
yatti-api kb sync                    # Sync from filesystem
```

**History:**
```bash
yatti-api history                    # Last 20 queries
yatti-api history 50                 # Last 50 queries
yatti-api history 20 jakartapost     # Last 20 from specific KB
yatti-api get-query q_abc123         # Get specific query by ID
```

**Documentation:**
```bash
yatti-api docs                       # User guide
yatti-api docs api                   # API documentation
yatti-api docs technical             # Developer docs
yatti-api docs user raw              # Markdown format
yatti-api docs user html             # Open in browser
```

**Updates:**
```bash
yatti-api update --check             # Check for updates
yatti-api update                     # Install update if available
yatti-api update --force             # Force reinstall
```

**Status:**
```bash
yatti-api status                     # Basic status
yatti-api status health              # Health check
yatti-api status info                # System info
```

---

## Configuration

### API Key

**Interactive configuration:**
```bash
yatti-api configure
```

**Environment variable:**
```bash
export YATTI_API_KEY="your_api_key_here"
```

**File location:**
- Linux/macOS: `~/.config/yatti-api/api_key`
- Windows (WSL): `/home/<username>/.config/yatti-api/api_key`

### Environment Variables

```bash
# API key (alternative to config file)
export YATTI_API_KEY="your_key"

# API base URL (default: https://yatti.id/v1)
export YATTI_API_BASE="https://custom.yatti.id/v1"

# Verbose output (0=quiet, 1=verbose)
export VERBOSE=1

# Output format (pretty or json)
export OUTPUT_FORMAT=json
```

---

## Available Models

Latest LLMs from:
- **OpenAI:** gpt-4o, gpt-4o-mini, gpt-4-turbo
- **Anthropic:** claude-3-opus, claude-3-5-sonnet, claude-3-haiku
- **Google:** gemini-pro, gemini-ultra

---

## Bash Completion

For bash completion support:

```bash
# Source the completion file
source yatti-api.bash_completion

# Or install system-wide:
sudo cp yatti-api.bash_completion /etc/bash_completion.d/yatti-api
```

Then you can tab-complete commands, options, and even knowledgebase names!

---

## Requirements

### Linux/macOS/Windows (WSL)
- Bash 5.2+
- curl
- jq (for JSON parsing)

---

## Development

### Structure

```
yatti-api                       # Main bash script (~850 lines)
yatti-api.bash_completion       # Bash completion
tests/                          # Test suite
  ├── unit/                     # Unit tests
  ├── integration/              # Integration tests
  ├── helpers/                  # Test utilities
  ├── fixtures/                 # Mock data
  └── run_tests.sh              # Test runner
```

### Testing

```bash
# Run all tests
./tests/run_tests.sh

# Run specific suite
./tests/run_tests.sh unit
./tests/run_tests.sh integration

# Run with options
./tests/run_tests.sh -f pretty -p
```

See [tests/README.md](tests/README.md) for complete testing documentation.

### Code Quality

- ✓ ShellCheck: 0 warnings
- ✓ BCS (Bash Coding Standard): 100% compliant
- ✓ Test Coverage: ~85%
- ✓ Security Audit: Passed

See [AUDIT-BASH.md](AUDIT-BASH.md) for detailed audit report.

---

## Troubleshooting

### Linux/macOS

**Permission denied:**
```bash
sudo chmod +x /usr/local/bin/yatti-api
```

**curl or jq not found:**
```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get install curl jq

# CentOS/RHEL
sudo yum install curl jq
```

**API key not found:**
```bash
yatti-api configure
```

---

## Support

- **Documentation:** Run `yatti-api help` or `yatti-api docs`
- **API Docs:** https://yatti.id/admin/
- **Issues:** https://github.com/anthropics/claude-code/issues

---

## Version

Current version: **1.3.6**

Check for updates:
```bash
yatti-api update --check
```

---

## License

See project repository for license information.

---

## Contributing

Contributions welcome! Especially:
- Bug reports and fixes
- Documentation improvements
- New features
- Testing and feedback

---

Visit https://yatti.id for more information.

