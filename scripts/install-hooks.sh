#!/usr/bin/env bash
# Install git hooks for yatti-api development
#
# Usage: ./scripts/install-hooks.sh
#
set -euo pipefail
shopt -s inherit_errexit
export PATH=/usr/local/bin:/usr/bin:/bin

# Script metadata
#shellcheck disable=SC2155
declare -r SCRIPT_DIR=$(realpath -- "$(dirname "${BASH_SOURCE[0]}")")
declare -r REPO_ROOT=${SCRIPT_DIR%/*}
declare -r HOOKS_SRC=$SCRIPT_DIR/hooks
declare -r HOOKS_DST=$REPO_ROOT/.git/hooks

# Global variables
declare -i VERBOSE=1
declare -i INSTALLED=0
declare -- HOOK_NAME='' DST='' ANSWER=''

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
    info)    prefix="${CYAN}◉${NC}" ;;
    success) prefix="${GREEN}✓${NC}" ;;
    warn)    prefix="${YELLOW}▲${NC}" ;;
    error)   prefix="${RED}✗${NC}" ;;
    *)       prefix='◉' ;;
  esac
  >&2 printf '%s %s\n' "$prefix" "$*"
}
info()    { ((VERBOSE)) || return 0; _msg "$@"; }
success() { ((VERBOSE)) || return 0; _msg "$@"; }
warn()    { _msg "$@"; }
error()   { _msg "$@"; }
die()     { (($# < 2)) || error "${@:2}"; exit "${1:-1}"; }

# Verify we're in a git repo
if [[ ! -d "$REPO_ROOT/.git" ]]; then
  die 1 "Not a git repository: ${REPO_ROOT@Q}"
fi

# Verify hooks source directory exists
if [[ ! -d "$HOOKS_SRC" ]]; then
  die 3 "Hooks source directory not found: ${HOOKS_SRC@Q}"
fi

info 'Installing git hooks for yatti-api...'
>&2 echo

# Install each hook
for hook in "$HOOKS_SRC"/*; do
  [[ -f "$hook" ]] || continue

  HOOK_NAME=${hook##*/}
  DST="$HOOKS_DST/$HOOK_NAME"

  # Check if hook already exists
  if [[ -f "$DST" ]]; then
    if cmp -s "$hook" "$DST"; then
      success "$HOOK_NAME (already installed, up to date)"
    else
      warn "$HOOK_NAME exists with different content"
      read -rp '  Overwrite? [y/N] ' ANSWER
      if [[ "$ANSWER" =~ ^[Yy] ]]; then
        cp "$hook" "$DST" || die 1 "Failed to copy ${hook@Q}"
        chmod 755 "$DST" || die 1 "Failed to chmod ${DST@Q}"
        success "$HOOK_NAME (updated)"
        INSTALLED+=1
      else
        warn "$HOOK_NAME (skipped)"
      fi
    fi
  else
    cp "$hook" "$DST" || die 1 "Failed to copy ${hook@Q}"
    chmod 755 "$DST" || die 1 "Failed to chmod ${DST@Q}"
    success "$HOOK_NAME (installed)"
    INSTALLED+=1
  fi
done

>&2 echo
if ((INSTALLED)); then
  success "Installed $INSTALLED hook(s)"
else
  success 'All hooks already installed'
fi

# Check for shellcheck
if ! command -v shellcheck &>/dev/null; then
  >&2 echo
  warn 'shellcheck not found - pre-commit hook will skip linting'
  warn 'Install: sudo apt-get install shellcheck'
fi

#fin
