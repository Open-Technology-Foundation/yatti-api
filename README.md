# YaTTi API Client

**Access specialized knowledgebases with AI-powered queries**

YaTTi gives you command-line access to curated knowledge domains using sophisticated RAG (Retrieval Augmented Generation) powered by [customkb](https://github.com/Open-Technology-Foundation/customkb). Ask questions, get answers backed by authoritative sources across multiple specialized fields.

## Table of Contents

- [What's New in v1.4.0](#whats-new-in-v140) ◉ **Unlimited query sizes**
- [Available Knowledgebases](#available-knowledgebases)
- [Quick Start](#quick-start)
- [Example Queries](#example-queries)
- [Large Query Input](#large-query-input) - **File & stdin support**
- [Features](#features)
- [Installation](#installation)
- [Usage Reference](#usage-reference)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Contributing](#contributing)
- [Quick Reference](#quick-reference) - **Use cases & integration**
- [Support](#support)

---

## What's New in v1.4.0

### ◉ Unlimited Query Size Support

Previous versions were limited to ~128 KB for queries due to shell argument constraints. Version 1.4.0 removes this limitation entirely:

**New Features:**
- **File input** (`-Q`) - Read queries from files of any size
- **Stdin support** (`-q -`) - Pipe unlimited query text from any source
- **Auto-detection** - Automatic stdin handling when piping to the command
- **Size feedback** - Helpful messages for large queries with optimization tips

**Example:**
```bash
# Old way: Limited to ~128 KB
yatti-api query kb "short query"

# New way: Unlimited size
yatti-api query kb -Q large_research_query.txt
cat document.txt | yatti-api query kb -q -
```

**Backward Compatible:** All existing commands continue to work exactly as before.

See the [Large Query Input](#large-query-input) section for complete documentation.

---

## Available Knowledgebases

Knowledgebases are updated regularly. To obtain a list of current knowledgebases enter `yatti-api kb`.  Here are a few of these specialized knowledge domains:

### Academic & Research
- **appliedanthropology** - Applied anthropology research and practice
- **prosocial.world** - Prosocial behavior and social evolution

### Regional & Cultural
- **jakartapost** - Indonesian news and current affairs (extensive archive)
- **peraturan.go.id** - Indonesian laws and regulations

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

# Try a simple query
yatti-api query seculardharma "What is mindfulness meditation?"

# Or use a more complex query from stdin
yatti-api query seculardharma -q - <<'EOF'
Explain the relationship between mindfulness practice
and the development of meta-awareness in meditation.
EOF
```

### Quick Examples

**Short queries (command-line):**
```bash
yatti-api query jakartapost "Indonesian economic development"
```

**Long queries (file):**
```bash
# Create a query file
echo "Provide a comprehensive analysis of..." > query.txt

# Execute it
yatti-api query appliedanthropology -Q query.txt
```

**Piped queries (stdin):**
```bash
cat research_question.txt | yatti-api query seculardharma -q -
```

### Windows Users

**Using Windows?** See the [Windows Installation Guide](#windows-installation-wsl) below for WSL setup instructions.

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
- List available knowledgebases
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
- `-m, --model NAME` - LLM model (default: gpt-5.1)
- `-s, --context-scope NUM` - Context segments per result (default: 3)
- `-c, --context-only` - Return only context without AI response
- `-M, --max-tokens NUM` - Maximum response tokens
- `-p, --prompt-template NAME` - Prompt style (`default`, `instructive`, `scholarly`, `concise`, `analytical`, `conversational`, `technical`)
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
yatti-api                       # Main bash script (~850 lines)
yatti-api.bash_completion       # Bash completion
install.sh                      # One-line installer
tests/                          # Test suite (93 tests, 100% passing)
  ├── unit/                     # Unit tests (37 tests)
  │   ├── test_utils.bats       # Utility functions (16 tests)
  │   ├── test_version_compare.bats  # Version comparison (17 tests)
  │   └── test_api_key.bats     # API key loading (4 tests)
  ├── integration/              # Integration tests (56 tests)
  │   ├── test_cmd_configure.bats  # Configure command (17 tests)
  │   ├── test_cmd_help.bats    # Help command (6 tests)
  │   ├── test_cmd_query.bats   # Query command (22 tests)
  │   ├── test_cmd_status.bats  # Status command (6 tests)
  │   └── test_cmd_version.bats # Version command (5 tests)
  ├── helpers/                  # Test utilities
  │   ├── test_helpers.bash     # Common functions
  │   ├── mocks.bash            # Mock functions
  │   └── curl                  # Mock curl executable
  ├── fixtures/                 # Mock data
  │   └── api_responses.json    # API response fixtures
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
- ✓ Test Coverage: 95%+ (93 tests, 100% passing)
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
