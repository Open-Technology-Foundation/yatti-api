#!/bin/bash
# YaTTi API Client - One-line installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/install.sh | bash

set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

# Colors for output
declare -r GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' NC=$'\033[0m'

# GitHub raw URL for additional files
declare -r GITHUB_RAW='https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main'

echo "${GREEN}YaTTi API Client Installer${NC}"
echo

# Check if running with sudo/root
declare -- SUDO=''
if ((EUID)); then
  SUDO=sudo
  echo "${YELLOW}Note: Will use sudo for installation to /usr/local/bin${NC}"
fi

# Install main script
echo 'Downloading yatti-api...'
$SUDO curl -fsSL -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download

# Verify checksum (soft failure - warns if verification unavailable or fails)
echo 'Verifying download...'
EXPECTED_CHECKSUM=$(curl -fsSL https://yatti.id/v1/client/checksum 2>/dev/null || echo "")
if [[ -n "$EXPECTED_CHECKSUM" ]]; then
  ACTUAL_CHECKSUM=$($SUDO sha256sum /usr/local/bin/yatti-api 2>/dev/null | cut -d' ' -f1)
  if [[ "$ACTUAL_CHECKSUM" != "$EXPECTED_CHECKSUM" ]]; then
    echo "${YELLOW}▲ Warning: Checksum verification failed${NC}" >&2
    echo "  Expected: $EXPECTED_CHECKSUM" >&2
    echo "  Actual:   $ACTUAL_CHECKSUM" >&2
  else
    echo 'Checksum verified.'
  fi
else
  echo "${YELLOW}▲ Checksum verification unavailable${NC}"
fi

echo 'Setting permissions...'
$SUDO chmod +x /usr/local/bin/yatti-api

# Install man page (optional, soft failure)
echo 'Installing man page...'
declare -r MAN_DIR=/usr/local/share/man/man1
if $SUDO mkdir -p "$MAN_DIR" 2>/dev/null; then
  if $SUDO curl -fsSL -o "$MAN_DIR/yatti-api.1" "$GITHUB_RAW/yatti-api.1" 2>/dev/null; then
    $SUDO mandb -q 2>/dev/null || true
    echo 'Man page installed.'
  else
    echo "${YELLOW}▲ Man page installation skipped (download failed)${NC}"
  fi
else
  echo "${YELLOW}▲ Man page installation skipped (no write access to $MAN_DIR)${NC}"
fi

# Install bash completion (optional, soft failure)
echo 'Installing bash completion...'
declare -r COMP_SYS_DIR=/etc/bash_completion.d
declare -r COMP_USER_DIR="${HOME}/.local/share/bash-completion/completions"
if [[ -d "$COMP_SYS_DIR" ]] && $SUDO test -w "$COMP_SYS_DIR" 2>/dev/null; then
  if $SUDO curl -fsSL -o "$COMP_SYS_DIR/yatti-api" "$GITHUB_RAW/yatti-api.bash_completion" 2>/dev/null; then
    echo 'Bash completion installed (system-wide).'
  else
    echo "${YELLOW}▲ Bash completion installation skipped (download failed)${NC}"
  fi
elif mkdir -p "$COMP_USER_DIR" 2>/dev/null; then
  if curl -fsSL -o "$COMP_USER_DIR/yatti-api" "$GITHUB_RAW/yatti-api.bash_completion" 2>/dev/null; then
    echo "Bash completion installed to $COMP_USER_DIR"
  else
    echo "${YELLOW}▲ Bash completion installation skipped (download failed)${NC}"
  fi
else
  echo "${YELLOW}▲ Bash completion installation skipped (no writable directory)${NC}"
fi

cat <<EOT
${GREEN}✓ Installation complete!${NC}

Next steps:
  1. Configure your API key:
     ${YELLOW}yatti-api configure${NC}

  2. Try a query:
     ${YELLOW}yatti-api query seculardharma "What is mindfulness?"${NC}

  3. List available knowledgebases:
     ${YELLOW}yatti-api kb list${NC}

Documentation:
  ${YELLOW}man yatti-api${NC}              View man page
  ${YELLOW}yatti-api help${NC}             Show command help

Note: Restart your shell for bash completion to take effect.

Repository: https://github.com/Open-Technology-Foundation/yatti-api
EOT

#fin
