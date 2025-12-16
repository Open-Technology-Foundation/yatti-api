#!/bin/bash
# YaTTi API Client - One-line installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Open-Technology-Foundation/yatti-api/main/install.sh | bash

set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

# Colors for output
declare -r GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' NC=$'\033[0m'

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
"$SUDO" curl -fsSL -o /usr/local/bin/yatti-api https://yatti.id/v1/client/download

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

cat <<EOT
${GREEN}✓ Installation complete!${NC}

Next steps:
  1. Configure your API key:
     ${YELLOW}yatti-api configure${NC}

  2. Try a query:
     ${YELLOW}yatti-api query seculardharma \"What is mindfulness?\"${NC}

  3. List available knowledgebases:
     ${YELLOW}yatti-api kb list${NC}

For help: ${YELLOW}yatti-api help${NC}

Repository: https://github.com/Open-Technology-Foundation/yatti-api"
EOT

#fin
