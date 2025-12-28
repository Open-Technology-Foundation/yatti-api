#!/bin/bash
# Install git hooks for yatti-api development
#
# Usage: ./scripts/install-hooks.sh
#
set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m'

info()    { printf "${GREEN}✓${NC} %s\n" "$*"; }
warn()    { printf "${YELLOW}▲${NC} %s\n" "$*"; }
error()   { printf "${RED}✗${NC} %s\n" "$*" >&2; }

# Find repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_SRC="$SCRIPT_DIR/hooks"
HOOKS_DST="$REPO_ROOT/.git/hooks"

# Verify we're in a git repo
if [[ ! -d "$REPO_ROOT/.git" ]]; then
  error "Not a git repository: $REPO_ROOT"
  exit 1
fi

# Verify hooks source directory exists
if [[ ! -d "$HOOKS_SRC" ]]; then
  error "Hooks source directory not found: $HOOKS_SRC"
  exit 1
fi

echo "Installing git hooks for yatti-api..."
echo ""

# Install each hook
declare -i installed=0
for hook in "$HOOKS_SRC"/*; do
  [[ -f "$hook" ]] || continue

  hook_name=$(basename "$hook")
  dst="$HOOKS_DST/$hook_name"

  # Check if hook already exists
  if [[ -f "$dst" ]]; then
    if cmp -s "$hook" "$dst"; then
      info "$hook_name (already installed, up to date)"
    else
      warn "$hook_name exists with different content"
      read -rp "  Overwrite? [y/N] " answer
      if [[ "$answer" =~ ^[Yy] ]]; then
        cp "$hook" "$dst"
        chmod 755 "$dst"
        info "$hook_name (updated)"
        ((++installed))
      else
        warn "$hook_name (skipped)"
      fi
    fi
  else
    cp "$hook" "$dst"
    chmod 755 "$dst"
    info "$hook_name (installed)"
    ((++installed))
  fi
done

echo ""
if ((installed > 0)); then
  info "Installed $installed hook(s)"
else
  info "All hooks already installed"
fi

# Check for shellcheck
if ! command -v shellcheck &>/dev/null; then
  echo ""
  warn "shellcheck not found - pre-commit hook will skip linting"
  echo "  Install: sudo apt-get install shellcheck"
fi

#fin
