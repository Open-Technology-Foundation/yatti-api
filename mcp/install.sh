#!/usr/bin/env bash
# YaTTi API MCP Server - Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/mcp/install.sh | sudo bash

set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob
readonly -- PATH='/usr/local/bin:/usr/bin:/bin'
export PATH

# Script metadata
declare -r SCRIPT_NAME='install.sh'
declare -r VERSION=1.0.0
declare -r INSTALL_DIR=/usr/local/share/yatti/yatti-api-mcp
declare -r GITHUB_RAW='https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/mcp'

# Global variables
declare -i VERBOSE=1
declare -i USE_UV=0
declare -i PARTIAL_INSTALL=0

# Colors (TTY-conditional)
if [[ -t 1 && -t 2 ]]; then
  declare -r RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' CYAN=$'\033[0;36m' NC=$'\033[0m'
else
  declare -r RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

# Messaging functions
_msg() {
  local -- prefix
  case ${FUNCNAME[1]} in
    info)  prefix="${CYAN}◉${NC}" ;;
    warn)  prefix="${YELLOW}▲${NC}" ;;
    error) prefix="${RED}✗${NC}" ;;
    *)     prefix='◉' ;;
  esac
  >&2 printf '%s %s\n' "$prefix" "$*"
}
info()    { ((VERBOSE)) || return 0; _msg "$@"; }
warn()    { _msg "$@"; }
error()   { _msg "$@"; }
die()     { (($# < 2)) || error "${@:2}"; exit "${1:-1}"; }

# Cleanup trap for partial installations
cleanup() {
  local -i exitcode=${1:-$?}
  trap - SIGINT SIGTERM EXIT
  if ((PARTIAL_INSTALL)) && ((exitcode)); then
    >&2 echo
    warn "Partial installation detected — cleaning up ${INSTALL_DIR@Q}"
    rm -rf "$INSTALL_DIR"
  fi
  exit "$exitcode"
}

show_help() {
  cat <<'HELP'
YaTTi API MCP Server Installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/mcp/install.sh | sudo bash
  sudo ./install.sh [-h|--help]

Options:
  -h, --help       Show this help message
  -V, --version    Show version

Description:
  Installs the YaTTi API MCP server to /usr/local/share/yatti/yatti-api-mcp/
  and sets up the Python virtual environment using uv (preferred) or pip.

Requirements:
  - Python 3.12+
  - uv (preferred) or pip
  - yatti-api CLI installed

Post-installation:
  Add to ~/.claude/settings.local.json or /etc/claude-code/managed-mcp.json.
  Configuration differs based on package manager used (shown after install).
HELP
  exit 0
}

main() {
  # Parse arguments
  while (($#)); do case $1 in
    -h|--help)    show_help ;;
    -V|--version) echo "$SCRIPT_NAME $VERSION"; exit 0 ;;
    -*)           die 22 "Invalid option ${1@Q}" ;;
  esac; shift; done

  trap 'cleanup $?' SIGINT SIGTERM EXIT

  # Check root
  ((EUID == 0)) || die 13 'This script must be run as root (use sudo)'

  # Check Python
  command -v python3 &>/dev/null || die 18 'Python 3 is required but not installed'

  # Check package manager availability
  if command -v uv &>/dev/null; then
    USE_UV=1
  elif command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
    USE_UV=0
    warn 'uv not found, using pip instead (slower)'
  else
    die 18 'Neither uv nor pip found. Install uv (https://docs.astral.sh/uv/) or pip.'
  fi

  # Check yatti-api
  command -v yatti-api &>/dev/null || warn 'yatti-api CLI not found. Install it first.'

  info "${GREEN}YaTTi API MCP Server Installer ${VERSION}${NC}"
  >&2 echo

  # Create directory
  PARTIAL_INSTALL=1
  info "Creating ${INSTALL_DIR@Q}..."
  mkdir -p "$INSTALL_DIR"/mcp_server

  # Download files
  info 'Downloading MCP server files...'
  curl -fsSL -o "$INSTALL_DIR"/mcp_server/__init__.py "$GITHUB_RAW"/mcp_server/__init__.py
  curl -fsSL -o "$INSTALL_DIR"/mcp_server/server.py "$GITHUB_RAW"/mcp_server/server.py
  curl -fsSL -o "$INSTALL_DIR"/pyproject.toml "$GITHUB_RAW"/pyproject.toml
  curl -fsSL -o "$INSTALL_DIR"/uv.lock "$GITHUB_RAW"/uv.lock

  # Set permissions
  chmod 755 "$INSTALL_DIR"
  chmod 755 "$INSTALL_DIR"/mcp_server
  chmod 644 "$INSTALL_DIR"/mcp_server/*.py
  chmod 644 "$INSTALL_DIR"/pyproject.toml
  chmod 644 "$INSTALL_DIR"/uv.lock

  # Install Python dependencies
  info 'Installing Python dependencies...'
  cd "$INSTALL_DIR" || die 1 "Cannot enter ${INSTALL_DIR@Q}"

  if ((USE_UV)); then
    uv sync
  else
    # Create venv and install with pip
    python3 -m venv .venv
    .venv/bin/pip install --upgrade pip
    .venv/bin/pip install .
  fi

  PARTIAL_INSTALL=0
  >&2 echo
  info "${GREEN}Installation complete!${NC}"
  >&2 echo

  # Show appropriate configuration based on package manager
  if ((USE_UV)); then
    cat <<CONFIG_UV
Add MCP server to Claude Code configuration.
Edit ~/.claude/settings.local.json or /etc/claude-code/managed-mcp.json:

${YELLOW}{
  "mcpServers": {
    "yatti": {
      "command": "uv",
      "args": ["run", "--directory", "$INSTALL_DIR", "python", "-m", "mcp_server.server"],
      "env": {}
    }
  }
}${NC}
CONFIG_UV
  else
    cat <<CONFIG_PIP
Add MCP server to Claude Code configuration.
Edit ~/.claude/settings.local.json or /etc/claude-code/managed-mcp.json:

${YELLOW}{
  "mcpServers": {
    "yatti": {
      "command": "$INSTALL_DIR/.venv/bin/python",
      "args": ["-m", "mcp_server.server"],
      "env": {}
    }
  }
}${NC}
CONFIG_PIP
  fi

  cat <<NEXT_STEPS

Restart Claude Code to load the MCP server.

Test with: ${YELLOW}yatti-api status health${NC}

NEXT_STEPS
}

main "$@"

#fin
