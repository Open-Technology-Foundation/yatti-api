#!/bin/bash
# YaTTi API MCP Server - Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/mcp/install.sh | sudo bash

set -euo pipefail
shopt -s inherit_errexit

declare -r VERSION='1.0.0'
declare -r INSTALL_DIR='/usr/local/share/yatti/yatti-api-mcp'
declare -r GITHUB_RAW='https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/mcp'

# Colors
declare -r GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' RED=$'\033[0;31m' NC=$'\033[0m'

show_help() {
  cat <<'EOF'
YaTTi API MCP Server Installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/mcp/install.sh | sudo bash
  sudo ./install.sh [-h|--help]

Options:
  -h, --help    Show this help message

Description:
  Installs the YaTTi API MCP server to /usr/local/share/yatti/yatti-api-mcp/
  and sets up the Python virtual environment using uv.

Requirements:
  - Python 3.12+
  - uv (https://docs.astral.sh/uv/)
  - yatti-api CLI installed

Post-installation:
  Add to ~/.claude/settings.local.json or /etc/claude-code/managed-mcp.json:

  {
    "mcpServers": {
      "yatti": {
        "command": "uv",
        "args": ["run", "--directory", "/usr/local/share/yatti/yatti-api-mcp", "python", "-m", "mcp_server.server"],
        "env": {}
      }
    }
  }
EOF
  exit 0
}

die() { echo "${RED}Error: $*${NC}" >&2; exit 1; }

# Parse arguments
case "${1:-}" in
  -h|--help) show_help ;;
esac

# Check root
((EUID == 0)) || die 'This script must be run as root (use sudo)'

# Check dependencies
command -v uv &>/dev/null || die 'uv is required but not installed. See https://docs.astral.sh/uv/'
command -v python3 &>/dev/null || die 'Python 3 is required but not installed'
command -v yatti-api &>/dev/null || echo "${YELLOW}Warning: yatti-api CLI not found. Install it first.${NC}"

echo "${GREEN}YaTTi API MCP Server Installer v${VERSION}${NC}"
echo

# Create directory
echo "Creating ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}/mcp_server"

# Download files
echo 'Downloading MCP server files...'
curl -fsSL -o "${INSTALL_DIR}/mcp_server/__init__.py" "${GITHUB_RAW}/mcp_server/__init__.py"
curl -fsSL -o "${INSTALL_DIR}/mcp_server/server.py" "${GITHUB_RAW}/mcp_server/server.py"
curl -fsSL -o "${INSTALL_DIR}/pyproject.toml" "${GITHUB_RAW}/pyproject.toml"
curl -fsSL -o "${INSTALL_DIR}/uv.lock" "${GITHUB_RAW}/uv.lock"

# Set permissions
chmod 755 "${INSTALL_DIR}"
chmod 755 "${INSTALL_DIR}/mcp_server"
chmod 644 "${INSTALL_DIR}/mcp_server"/*.py
chmod 644 "${INSTALL_DIR}/pyproject.toml"
chmod 644 "${INSTALL_DIR}/uv.lock"

# Install Python dependencies
echo 'Installing Python dependencies...'
cd "${INSTALL_DIR}"
uv sync

echo
echo "${GREEN}Installation complete!${NC}"
echo
cat <<EOF
Next steps:

1. Add MCP server to Claude Code configuration.
   Edit ~/.claude/settings.local.json or /etc/claude-code/managed-mcp.json:

   ${YELLOW}{
     "mcpServers": {
       "yatti": {
         "command": "uv",
         "args": ["run", "--directory", "${INSTALL_DIR}", "python", "-m", "mcp_server.server"],
         "env": {}
       }
     }
   }${NC}

2. Restart Claude Code to load the MCP server.

3. Test with: ${YELLOW}yatti-api status health${NC}

EOF

#fin
