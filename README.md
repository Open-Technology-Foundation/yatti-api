# YaTTi API Client

**Access specialized knowledgebases with AI-powered queries**

YaTTi gives you command-line access to curated knowledge domains using RAG (Retrieval Augmented Generation). Ask questions, get answers backed by authoritative sources across multiple specialized fields.

## Available Knowledgebases

Query these specialized knowledge domains:

### Academic & Research
- **appliedanthropology** - Applied anthropology research and practice
- **prosocial.world** - Prosocial behavior and social evolution

### Regional & Cultural
- **jakartapost** - Indonesian news and current affairs (extensive archive)
- **peraturan.go.id** - Indonesian laws and regulations
- **wayang.net** - Indonesian shadow puppet theatre and culture

### Professional & Technical
- **okusiassociates** - Corporate services and Indonesian business operations

### Personal & Philosophy
- **seculardharma** - Secular Buddhist philosophy and mindfulness practice


---

## Quick Start

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/install.sh | bash
```

Or install manually:

```bash
sudo curl -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download
sudo chmod +x /usr/local/bin/yatti-api
```

### First Query

```bash
# Configure your API key
yatti-api configure

# Try a query
yatti-api query seculardharma "What is mindfulness meditation?"
```

### Windows Users

**Using Windows?** See the [Windows Installation Guide](#windows-installation-wsl) below for WSL setup instructions.

---

## Example Queries

### Ask About Indonesian Culture

```bash
# Explore wayang (shadow puppet) stories and characters
yatti-api query wayang.net "Who is Arjuna in wayang stories?"

# Current Indonesian news and analysis
yatti-api query jakartapost "What are current Indonesian economic trends?"

# Indonesian laws and regulations
yatti-api query peraturan.go.id "What are the requirements for foreign investment?"
```

### Research & Academia

```bash
# Applied anthropology methods
yatti-api query appliedanthropology "How is ethnography used in UX research?"

# Social evolution and cooperation
yatti-api query prosocial.world "What is multilevel selection theory?"
```

### Philosophy & Practice

```bash
# Buddhist philosophy and practice
yatti-api query seculardharma "How does Buddhism approach suffering?"
yatti-api query seculardharma "What is the difference between concentration and mindfulness?"
```

### Advanced Queries

**Control the AI response:**

```bash
# Use more context sources
yatti-api query jakartapost "Soeharto's legacy" --top-k 15

# Scholarly writing style with extended response
yatti-api query appliedanthropology "participant observation" -p scholarly -M 2000

# Get source context only (no AI summary)
yatti-api query peraturan.go.id "company formation" --context-only
```

**Note:** jakartapost is a very large knowledgebase - use longer timeouts for complex queries:

```bash
yatti-api query jakartapost "Jokowi presidency analysis" --timeout 300
```

---

## Features

### RAG Query Engine
- **Multiple LLM models** - OpenAI GPT, Anthropic Claude, Google Gemini
- **Context control** - Adjust how much source material informs answers
- **Source citation** - See exactly what informed the AI's response
- **Caching** - Fast repeated queries with configurable TTL

### Query Customization
- **Temperature control** (0.0-2.0) - Balance creativity vs. precision
- **Prompt templates** - scholarly, technical, conversational, concise, analytical
- **Token limits** - Control response length
- **Context-only mode** - Retrieve sources without AI interpretation

### Knowledgebase Management
- List available knowledgebases
- View metadata and statistics
- Sync updates from filesystem (admin)

### Developer-Friendly
- **JSON output** - Machine-readable responses
- **Query history** - Review past queries
- **Self-updating** - Automatic version management
- **Bash completion** - Tab-complete commands and KB names
- **Environment variables** - Scriptable configuration

---

## Installation

### Linux / macOS

**Option 1: One-liner install (recommended)**

```bash
curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/install.sh | bash
```

**Option 2: Manual install**

```bash
sudo curl -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download
sudo chmod +x /usr/local/bin/yatti-api
yatti-api configure
yatti-api version  # Verify installation
```

**Requirements:**
- Bash 5.2+
- curl
- jq (for JSON parsing)

**Installing dependencies:**

```bash
# macOS
brew install curl jq

# Ubuntu/Debian
sudo apt-get install curl jq

# CentOS/RHEL
sudo yum install curl jq
```

### Windows Installation (WSL)

Windows users should use WSL (Windows Subsystem for Linux) to run yatti-api. WSL provides a complete Linux environment on Windows.

#### Step 1: Install WSL

Open PowerShell as Administrator:

```powershell
wsl --install
```

Restart your computer when prompted.

#### Step 2: Complete WSL Setup

1. Open "Ubuntu" from the Start menu
2. Create a username and password when prompted
3. Wait for installation to complete

#### Step 3: Install Dependencies

In the WSL terminal (Ubuntu):

```bash
sudo apt-get update && sudo apt-get install -y curl jq
```

#### Step 4: Install yatti-api

Use the one-liner install:

```bash
curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/install.sh | bash
```

Or manual install:

```bash
sudo curl -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download
sudo chmod +x /usr/local/bin/yatti-api
yatti-api configure
```

#### Verify Installation

```bash
yatti-api version
```

#### Troubleshooting WSL

**WSL not available:**
- Requires Windows 10 version 2004+ or Windows 11
- Enable WSL in Windows Features if `wsl --install` fails

**Ubuntu won't start:**
- Check Windows Features: Virtual Machine Platform and WSL are enabled
- Run `wsl --update` in PowerShell as Administrator

**Always use the WSL terminal (Ubuntu) to run yatti-api commands.**

---

## Usage Reference

### Basic Commands

```bash
yatti-api help                    # Show help
yatti-api status                  # Check API status
yatti-api kb list                 # List knowledgebases
yatti-api query KB "question"     # Query a knowledgebase
yatti-api history                 # View query history
yatti-api configure               # Configure API key
yatti-api update --check          # Check for updates
yatti-api docs                    # View documentation
```

### Query Command

**Syntax:**

```bash
yatti-api query [OPTIONS] <knowledgebase> "<query text>"
# or
yatti-api query -K <knowledgebase> -q "<query text>" [OPTIONS]
```

**Options:**
- `-K, --knowledgebase NAME` - Knowledgebase to query (required)
- `-q, --query TEXT` - Query text (required)
- `-k, --top-k NUM` - Number of context sources (default: 5)
- `-t, --temperature NUM` - LLM temperature 0.0-2.0 (default: 0.0)
- `-m, --model NAME` - LLM model (default: gpt-5.1)
- `-s, --context-scope NUM` - Context segments per result (default: 3)
- `-c, --context-only` - Return only context without AI response
- `-M, --max-tokens NUM` - Maximum response tokens
- `-p, --prompt-template NAME` - Prompt style (default, instructive, scholarly, concise, analytical, conversational, technical)
- `-f, --force-refresh` - Skip cache, force new query
- `--cache-ttl SECONDS` - Cache TTL in seconds (default: 86400)
- `--timeout SECONDS` - Query timeout in seconds (default: 60, max: 600)

**Available Models:**
- **OpenAI:** gpt-5.1
- **Anthropic:** claude-haiku-4-5, claude-opus-4-1, claude-sonnet-4-5
- **Google:** gemini-pro, gemini-ultra

### Knowledgebase Commands

```bash
yatti-api kb list                    # List all knowledgebases
yatti-api kb get seculardharma       # Get KB info and stats
yatti-api kb sync                    # Sync from filesystem (admin)
```

### History Commands

```bash
yatti-api history                    # Last 20 queries
yatti-api history 50                 # Last 50 queries
yatti-api history 20 jakartapost     # Last 20 from specific KB
yatti-api get-query q_abc123         # Get specific query by ID
```

### Documentation

```bash
yatti-api docs                       # User guide (JSON)
yatti-api docs user raw              # User guide (markdown)
yatti-api docs user html             # Open in browser
yatti-api docs api                   # API documentation
yatti-api docs technical             # Developer docs
```

### Updates

```bash
yatti-api update --check             # Check for updates
yatti-api update                     # Install update
yatti-api update --force             # Force reinstall
```

---

## Configuration

### API Key

**Interactive setup:**

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

# Verbose output
export VERBOSE=1

# Output format (pretty or json)
export OUTPUT_FORMAT=json
```

### Bash Completion

Enable tab completion for commands, options, and knowledgebase names:

```bash
# Source the completion file
source yatti-api.bash_completion

# Or install system-wide:
sudo cp yatti-api.bash_completion /etc/bash_completion.d/yatti-api
```

---

## Troubleshooting

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

**Timeouts on large knowledgebases:**

```bash
# Use longer timeout for jakartapost
yatti-api query jakartapost "your query" --timeout 300
```

---

## Development

### Project Structure

```
yatti-api                       # Main bash script (~850 lines)
yatti-api.bash_completion       # Bash completion
install.sh                      # One-line installer
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

### Requirements

- Bash 5.2+
- curl
- jq (for JSON parsing)

---

## Contributing

Contributions welcome! We especially appreciate:
- Bug reports and fixes
- Documentation improvements
- New features
- Testing and feedback

**Repository:** https://github.com/Open-Technology-Foundation/yatti-api

**Issues:** https://github.com/Open-Technology-Foundation/yatti-api/issues

---

## Support

- **Documentation:** Run `yatti-api help` or `yatti-api docs`
- **API Docs:** https://yatti.id/admin/
- **Issues:** https://github.com/Open-Technology-Foundation/yatti-api/issues
- **Website:** https://yatti.id

---

## Version

Current version: **1.4.0**

Check for updates:

```bash
yatti-api update --check
```

---

## License

GPL-3. See LICENSE

---

Visit https://yatti.id for more information.
