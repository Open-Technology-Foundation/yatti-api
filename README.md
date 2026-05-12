# YaTTi API Client

**Query specialized knowledgebases with AI-powered RAG**

## Quick Start

**1. Install:**
```bash
curl -fsSL https://yatti.id/v1/client/install | bash
```
Or from source: `git clone https://github.com/Open-Technology-Foundation/yatti-api.git && cd yatti-api && sudo make install`

**2. Configure** your API key:
```bash
yatti-api configure
```

**3. Query** a knowledgebase:
```bash
yatti-api query seculardharma "What is mindfulness?"
```

> **Need more?** See [Available Knowledgebases](#available-knowledgebases) | [Example Queries](#example-queries) | [All Options](#usage-reference)

---

## Available Knowledgebases

Run `yatti-api kb list` for the complete list, or `kb list --long` for full descriptions. Popular domains:

| Knowledgebase | Description |
|---------------|-------------|
| seculardharma | Buddhist philosophy and mindfulness |
| jakartapost | Indonesian news archive (use `--timeout 300`) |
| peraturan.go.id | Indonesian laws and regulations |
| appliedanthropology | Anthropology research and practice |
| prosocial.world | Social evolution and cooperation |
| okusiassociates | Indonesian business operations |

---

## Table of Contents

- [Example Queries](#example-queries) - Practical query examples
- [Large Query Input](#large-query-input) - File and stdin support
- [Features](#features) - Full feature list
- [Installation](#installation) - Linux, macOS, Windows
- [Usage Reference](#usage-reference) - Commands and options
- [Configuration](#configuration) - API key, environment
- [Troubleshooting](#troubleshooting) - Common issues
- [Quick Reference](#quick-reference) - Use cases and tips
- [Development](#development) - Testing, contributing
- [Release Notes](#release-notes) - Version history

---

## Example Queries

### Ask About Indonesian Culture

```bash
# Current Indonesian news and analysis
yatti-api query jakartapost "Outline the economic conditions in Indonesian in 1997."

# Indonesian laws and regulations
yatti-api query peraturan.go.id "What are the current requirements for foreign direct investment?"
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
yatti-api query seculardharma "What is dharma?"
yatti-api query seculardharma "What is the difference between concentration and mindfulness?"
```

### Advanced Queries

**Control the AI response:**

```bash
# Use more context sources
yatti-api query jakartapost "Soeharto's legacy" --top-k 50  --timeout 300

# Scholarly writing style with extended response
yatti-api query appliedanthropology "participant observation" -p scholarly -M 2000

# Get source context only (no AI summary)
yatti-api query peraturan.go.id "company formation" --context-only
```

**Note:** jakartapost is a very large knowledgebase - use longer timeouts for complex queries.

---

## Large Query Input

The yatti-api client supports unlimited query sizes through file and stdin input methods. Command-line arguments are limited to ~128 KB, but these alternatives remove all size restrictions.

#### Input Methods Comparison

| Method | Size Limit | Use Case |
|--------|------------|----------|
| Command-line arg | ~128 KB | Short queries (default) |
| File input (`-Q`) | Unlimited | Large, reusable queries |
| Stdin (`-q -`) | Unlimited | Piped or scripted queries |
| Auto-detect stdin | Unlimited | Simple piping |

#### Method 1: File Input (Recommended for Large Queries)

**Best for:** Reusable queries, documentation, version control

```bash
# Create a query file
cat > research_query.txt <<'EOF'
Analyze the anthropological perspectives on gift economies
in traditional Indonesian societies, particularly focusing on:

1. Reciprocity patterns in Balinese village systems
2. The role of social obligation in Javanese communities
3. Comparative analysis with Western economic models
4. Impact of modernization on traditional exchange systems

Please provide scholarly references and cite specific examples
from ethnographic research conducted in the archipelago.
EOF

# Execute the query
yatti-api query -K appliedanthropology -Q research_query.txt

# With additional options
yatti-api query -K appliedanthropology -Q research_query.txt \
  --prompt-template scholarly \
  --max-tokens 3000 \
  --top-k 15
```

#### Method 2: Stdin with Explicit Flag

**Best for:** Heredocs, dynamic content, scripts

```bash
# Simple heredoc
yatti-api query seculardharma -q - <<'EOF'
What is the relationship between mindfulness
and metacognition in Buddhist psychology?
EOF

# Multi-paragraph with context
yatti-api query jakartapost -q - <<'EOF'
I'm researching Indonesian economic history for an academic paper.
Please provide a comprehensive analysis of:

- Economic conditions during the 1997-1998 Asian Financial Crisis
- Government policy responses under Soeharto and Habibie
- Social impacts on different economic classes
- Comparison with similar crises in other ASEAN nations

Focus on factual reporting from contemporary news sources.
EOF

# From another command's output
grep -h "^## Question" ./notes/*.md | yatti-api query seculardharma -q -

# From file via cat
cat complex_query.txt | yatti-api query peraturan.go.id -q -
```

#### Method 3: Auto-detect Stdin

**Best for:** Quick piping without flags

```bash
# Direct pipe from file
cat my_question.txt | yatti-api query -K seculardharma

# From echo
echo "Explain the concept of dependent origination" | yatti-api query -K seculardharma

# From command output
./generate_query.sh | yatti-api query -K jakartapost
```

#### Method 4: Traditional Command-line (Backward Compatible)

**Best for:** Short queries, interactive use

```bash
# Positional arguments (easiest)
yatti-api query seculardharma "What is mindfulness?"

# Flag-based (explicit)
yatti-api query -K jakartapost -q "Indonesian economic development"

# With options
yatti-api query -K appliedanthropology -q "ethnographic methods" \
  --temperature 0.2 --top-k 10
```

#### Practical Examples

**Example 1: Processing Multiple Queries from a File**

```bash
# Create multiple queries
cat > queries.txt <<'EOF'
What is the historical context of the Majapahit Empire?
---
Explain the Dutch colonial period in Indonesia.
---
Describe Indonesian independence movement.
EOF

# Process each query
while IFS= read -r query; do
  if [[ "$query" != "---" ]] && [[ -n "$query" ]]; then
    echo "Query: $query"
    echo "$query" | yatti-api query jakartapost -q -
    echo "---"
  fi
done < queries.txt
```

**Example 2: Combining with Text Processing**

```bash
# Extract questions from markdown and query them
grep "^Q:" research_notes.md | sed 's/^Q: //' | \
  yatti-api query -K appliedanthropology -q -
```

**Example 3: Large Document Analysis**

```bash
# Create a comprehensive query with document context
cat > analysis_query.txt <<'EOF'
Based on the following excerpt from a field research document,
analyze the social dynamics and provide anthropological insights:

[Long document text here - multiple pages...]

Please focus on:
1. Power structures
2. Cultural symbolism
3. Economic relationships
EOF

yatti-api query appliedanthropology -Q analysis_query.txt \
  --prompt-template analytical \
  --max-tokens 4000 \
  --timeout 120
```

#### Size Feedback

The tool provides automatic feedback for large queries:

| Query Size | Feedback |
|------------|----------|
| < 10 KB | Silent (standard processing) |
| 10-100 KB | Info: "Processing large query (X characters)..." |
| > 100 KB | Warning: "Very large query (X characters). Consider using --timeout for longer processing." |

**Note:** Very large queries (>100 KB) may require longer processing times. Use `--timeout` to prevent premature timeout:

```bash
# For very large queries
yatti-api query jakartapost -Q large_query.txt --timeout 300
```

#### Summary

| Feature | Capability |
|---------|------------|
| **Maximum query size** | Unlimited (with file/stdin input) |
| **Command-line limit** | ~128 KB (backward compatible) |
| **Input methods** | 4 (command-line, file, stdin, auto-detect) |
| **Size feedback** | Automatic for queries >10 KB |
| **Backward compatibility** | 100% - all existing commands work |

**Key Benefits:**
- ◉ No more "argument too long" errors
- ◉ Submit entire documents for analysis
- ◉ Process queries from version-controlled files
- ◉ Integrate seamlessly with shell scripts and pipelines
- ◉ Maintain existing workflow - all old commands still work

---

## Features

### RAG Query Engine
- **Multiple LLM models** - OpenAI GPT, Anthropic Claude, Google Gemini
- **Context control** - Adjust how much source material informs answers
- **Source citation** - See exactly what informed the AI's response
- **Caching** - Fast repeated queries with configurable TTL

### Query Input Methods ◉ **ENHANCED**
- **Command-line** - Quick queries up to ~128 KB
- **File input** - Unlimited size queries from files (`-Q`)
- **Stdin support** - Pipe queries from any source (`-q -`)
- **Auto-detection** - Automatic stdin handling for scripts
- **Size feedback** - Automatic warnings and suggestions for large queries

### Query Customization
- **Temperature control** (0.0-2.0) - Balance creativity vs. precision
- **Prompt templates** - scholarly, technical, conversational, concise, analytical
- **Token limits** - Control response length
- **Context-only mode** - Retrieve sources without AI interpretation
- **Timeout control** - Adjust processing time limits (60-600 seconds)

### Knowledgebase Management
- List available knowledgebases with `--long` for full descriptions
- View metadata and statistics
- Sync updates from filesystem (admin)

### Developer-Friendly
- **JSON output** - Machine-readable responses
- **Query history** - Review past queries
- **Self-updating** - Automatic version management
- **Bash completion** - Tab-complete commands and KB names
- **Environment variables** - Scriptable configuration
- **Pipe-friendly** - Stdin/stdout support for Unix workflows
- **Script integration** - File-based queries for automation

---

## Installation

### Linux / macOS

**Option 1: One-liner install**

```bash
curl -fsSL https://yatti.id/v1/client/install | bash
```

**Option 2: From source**

```bash
git clone https://github.com/Open-Technology-Foundation/yatti-api.git
cd yatti-api
sudo make install
make check
```

**Option 3: Direct download**

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

```bash
curl -fsSL https://yatti.id/v1/client/install | bash
```

Or from source / direct download:

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
yatti-api kb list --long          # List with full descriptions
yatti-api query KB "question"     # Query a knowledgebase
yatti-api history                 # View query history
yatti-api configure               # Configure API key
yatti-api update --check          # Check for updates
yatti-api docs                    # View documentation
man yatti-api                     # View man page (if installed)
```

### Query Command

The query command is the primary interface for interacting with knowledgebases. It supports multiple input methods for queries of any size.

**Basic Syntax:**

```bash
# Positional arguments (quick & easy)
yatti-api query <knowledgebase> "<query text>"

# Flag-based (explicit)
yatti-api query -K <knowledgebase> -q "<query text>" [OPTIONS]

# File input (unlimited size)
yatti-api query -K <knowledgebase> -Q <query-file> [OPTIONS]

# Stdin input (unlimited size)
yatti-api query -K <knowledgebase> -q - [OPTIONS]
```

**Query Input Options:**
- `-K, --knowledgebase NAME` - Knowledgebase to query (required)
- `-q, --query TEXT` - Query text (required, use `"-"` for stdin)
- `-Q, --query-file FILE` - Read query from file (unlimited size)

**Query Processing Options:**
- `-k, --top-k NUM` - Number of context sources (default: 5)
- `-t, --temperature NUM` - LLM temperature 0.0-2.0 (default: 0.0)
- `-m, --model NAME` - LLM model (default: claude-sonnet-4-6)
- `-s, --context-scope NUM` - Context segments per result (default: 3)
- `-c, --context-only` - Return only context without AI response
- `-M, --max-tokens NUM` - Maximum response tokens
- `-p, --prompt-template NAME` - Prompt style (`default`, `instructive`, `scholarly`, `concise`, `analytical`, `conversational`, `technical`)
- `-f, --force-refresh` - Skip cache, force new query
- `--cache-ttl SECONDS` - Cache TTL in seconds (default: 86400)
- `--timeout SECONDS` - Query timeout in seconds (default: 60, max: 600)

**Available Models:**
- **Anthropic:** claude-sonnet-4-6 (default), claude-opus-4-6, claude-opus-4-5, claude-sonnet-4-5, claude-haiku-4-5
- **OpenAI:** gpt-4o, gpt-4.1, and other GPT models
- **Google:** gemini-2.5-pro, gemini-2.5-flash

### Knowledgebase Commands

```bash
yatti-api kb list                    # List all knowledgebases
yatti-api kb list --long             # List with full descriptions
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
yatti-api docs technical             # Developer docs (aliases: dev, developer)
```

> Command aliases: `docs`, `doc`, `documentation` are interchangeable.

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
# Must match https://yatti.id (validated for security)
export YATTI_API_BASE="https://yatti.id/v1"

# Retry configuration
export YATTI_MAX_RETRIES=3         # Max retry attempts (default: 3, set to 1 to disable)
export YATTI_TIMEOUT=60            # Request timeout in seconds (default: 60)
export YATTI_CONNECT_TIMEOUT=10    # Connection timeout in seconds (default: 10)

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

**Rate limiting or server errors (429, 5xx):**

The client automatically retries transient failures with exponential backoff. To disable retries:

```bash
export YATTI_MAX_RETRIES=1
```

**Query too long (command-line limit exceeded):**

```bash
# Use file input for queries >128 KB
yatti-api query -K seculardharma -Q long_query.txt

# Or use stdin
cat long_query.txt | yatti-api query seculardharma -q -
```

---

## Development

### Project Structure

```
yatti-api                       # Main bash script (~1100 lines)
yatti-api.1                     # Man page documentation
yatti-api.bash_completion       # Bash completion
Makefile                        # Install, uninstall, test, lint
scripts/                        # Development scripts
  ├── install-hooks.sh          # Install git hooks
  └── hooks/                    # Git hook templates
      └── pre-commit            # Shellcheck on commit
tests/                          # Test suite (241 tests)
  ├── unit/                     # Unit tests (70 tests)
  │   ├── test_utils.bats       # Utility functions (1 test)
  │   ├── test_validation.bats  # URL/path validation (18 tests)
  │   ├── test_gpg_verification.bats # GPG signature verification (10 tests)
  │   ├── test_api_key.bats     # API key loading (4 tests)
  │   ├── test_large_payloads.bats   # Large query handling (8 tests)
  │   ├── test_unicode_handling.bats # Unicode/i18n support (15 tests)
  │   └── test_error_resilience.bats # Error handling (14 tests)
  ├── integration/              # Integration tests (171 tests)
  │   ├── test_cmd_configure.bats  # Configure command (19 tests)
  │   ├── test_cmd_query.bats   # Query command (22 tests)
  │   ├── test_cmd_users.bats   # Users command (20 tests)
  │   ├── test_cmd_docs.bats    # Documentation command (12 tests)
  │   ├── test_cmd_knowledgebases.bats # KB command (10 tests)
  │   ├── test_cmd_update.bats  # Update command (10 tests)
  │   ├── test_api_request.bats # API request handling (10 tests)
  │   ├── test_cmd_history.bats # History command (7 tests)
  │   ├── test_cmd_help.bats    # Help command (6 tests)
  │   ├── test_cmd_status.bats  # Status command (6 tests)
  │   ├── test_cmd_get_query.bats # Get query command (6 tests)
  │   ├── test_cmd_version.bats # Version command (5 tests)
  │   ├── test_retry_logic.bats # Retry mechanism (15 tests)
  │   └── test_stdin_autodetect.bats # Stdin auto-detection (23 tests)
  ├── helpers/                  # Test utilities
  │   ├── test_helpers.bash     # Common functions
  │   ├── mocks.bash            # Mock functions
  │   └── curl                  # Mock curl executable
  ├── fixtures/                 # Mock data
  │   └── api_responses.json    # API response fixtures
  └── run_tests.sh              # Test runner
mcp/                            # Python MCP server (separate sub-project)
  ├── mcp_server/server.py      # FastMCP wrapper around yatti-api CLI
  ├── pyproject.toml            # Python package metadata
  └── install.sh                # MCP install helper
shell/                          # Bwrap-sandboxed yatti-shell
  ├── yatti-shell-launcher      # Entry point
  ├── yatti-shell-gate          # Sandbox gate
  └── yatti-user-{add,del,list} # User management
docs/                           # Auxiliary documentation
```

### Setup for Contributors

```bash
# Install git hooks (runs shellcheck on commit)
./scripts/install-hooks.sh

# Install shellcheck (required for pre-commit hook)
sudo apt-get install shellcheck  # Ubuntu/Debian
brew install shellcheck          # macOS
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
- ✓ Test Coverage: 95%+ (241 tests)
- ✓ Security Audit: Passed (URL validation, GPG verification, path traversal prevention)

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

## Quick Reference

### Common Use Cases

**Research & Academic Work:**
```bash
# Scholarly analysis with extended output
yatti-api query appliedanthropology -Q research_question.txt \
  --prompt-template scholarly --max-tokens 3000

# Multiple sources with deep context
yatti-api query jakartapost -q "Indonesian history" \
  --top-k 20 --context-scope 5 --timeout 300
```

**Development & Documentation:**
```bash
# Get raw context for documentation
yatti-api query technical_kb "API design" --context-only

# JSON output for processing
OUTPUT_FORMAT=json yatti-api query kb "query" | jq '.data.response'
```

**Batch Processing:**
```bash
# Process multiple queries
for file in queries/*.txt; do
  yatti-api query kb -Q "$file" >> results.txt
done

# Extract and query from documents
grep "^Question:" notes.md | sed 's/Question: //' | \
  while read -r q; do
    echo "$q" | yatti-api query kb -q -
  done
```

**Large Document Analysis:**
```bash
# Analyze entire documents
cat research_paper.txt | yatti-api query appliedanthropology -q - \
  --prompt-template analytical --max-tokens 4000 --timeout 180
```

### Performance Tips

- Use `--timeout 300` for large knowledgebases (jakartapost)
- Use `--top-k 15-20` for comprehensive research
- Use `--context-only` to get just the sources
- Use `--cache-ttl 0` to force fresh results
- Set `VERBOSE=1` to see detailed processing info

### Integration Examples

**Git Commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit
git diff --staged | yatti-api query code-review -q - --context-only
```

**Documentation Generator:**
```bash
#!/bin/bash
for module in src/*.py; do
  grep -h "^def " "$module" | \
    yatti-api query python-docs -q - >> docs/api.md
done
```

**Research Assistant:**
```bash
#!/bin/bash
# research.sh - Interactive research assistant
while true; do
  read -rp "Research question: " question
  [[ -z "$question" ]] && break
  echo "$question" | yatti-api query appliedanthropology -q - \
    --prompt-template scholarly --top-k 15
done
```

---

## Release Notes

### v1.4.3 (Latest)

- **BCS compliance** fixes for medium-severity audit findings
- Warn function now displays unconditionally (regardless of VERBOSE)
- Arithmetic comparisons use `(( ))` consistently instead of `[[ ]]`
- Various code quality improvements

### v1.4.2

- **`kb list --long`** flag to display full knowledgebase descriptions
- **`kb get`** now includes `long_description` field in JSON output
- **API-based descriptions** - `kb --long` fetches from API (works on all servers)

### v1.4.1

- **Retry logic** with exponential backoff for transient failures (429, 5xx)
- **Man page** documentation (`man yatti-api`)
- **Security:** JSON input validation, GPG key pinning, read timeouts
- **XDG compliance** for config directory

### v1.4.0

- **Unlimited query size** via file input (`-Q`) and stdin (`-q -`)
- **Security:** URL validation, GPG signature verification, path traversal prevention
- **Masked API keys** in version output

Run `yatti-api update --check` to see available updates with changelog.

---

## Support

- **Documentation:** `yatti-api help` or `man yatti-api`
- **API Docs:** https://yatti.id/admin/
- **Issues:** https://github.com/Open-Technology-Foundation/yatti-api/issues
- **Website:** https://yatti.id

---

## Version

Current version: **1.4.3**

```bash
yatti-api update --check    # Check for updates
```

---

## License

GPL-3.0. See [LICENSE](LICENSE).

---

Visit https://yatti.id for more information.
