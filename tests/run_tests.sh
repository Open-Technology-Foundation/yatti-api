#!/usr/bin/env bash
# Test Runner for YaTTi API Client
# Runs BATS test suite with options for filtering, formatting, and reporting

set -euo pipefail
shopt -s inherit_errexit

# Script metadata
#shellcheck disable=SC2155
declare -r SCRIPT_DIR=$(realpath -- "$(dirname "${BASH_SOURCE[0]}")")
declare -r PROJECT_ROOT=${SCRIPT_DIR%/*}

# Global variables
declare -i VERBOSE=0
declare -i PARALLEL=0
declare -- FORMAT='tap'
declare -- FILTER=''
declare -- TEST_SUITE='all'

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

# Usage information
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [TEST_SUITE]

Run BATS test suite for yatti-api

TEST_SUITE:
  all           Run all tests (default)
  unit          Run unit tests only
  integration   Run integration tests only
  [filename]    Run specific test file (e.g., test_utils)

OPTIONS:
  -v, --verbose       Verbose output
  -p, --parallel      Run tests in parallel
  -f, --format FORMAT Output format: tap, pretty, junit (default: tap)
  -F, --filter PATTERN Run only tests matching pattern
  -h, --help          Show this help message

EXAMPLES:
  $0                              # Run all tests
  $0 unit                         # Run unit tests only
  $0 integration                  # Run integration tests only
  $0 test_utils                   # Run specific test file
  $0 --filter "query command"     # Run tests matching pattern
  $0 --parallel --format=pretty   # Run in parallel with pretty output

EOF
}

# Parse command line arguments
parse_args() {
  while (($#)); do
    case $1 in
      -v|--verbose)
        VERBOSE=1
        shift
        ;;
      -p|--parallel)
        PARALLEL=1
        shift
        ;;
      -f|--format)
        FORMAT="$2"
        shift 2
        ;;
      -F|--filter)
        FILTER="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        error "Unknown option: $1"
        usage >&2
        exit 1
        ;;
      *)
        TEST_SUITE="$1"
        shift
        ;;
    esac
  done
}

# Check dependencies
check_dependencies() {
  if ! command -v bats >/dev/null 2>&1; then
    die 18 'BATS is not installed. Install with: sudo apt-get install bats'
  fi

  if ! command -v jq >/dev/null 2>&1; then
    warn 'jq is not installed - some tests may fail'
  fi
}

# Find test files based on suite
find_test_files() {
  local -- suite="$1"
  local -a files=()

  case $suite in
    all)
      mapfile -t files < <(find "$SCRIPT_DIR" -name "*.bats" | sort)
      ;;
    unit)
      mapfile -t files < <(find "$SCRIPT_DIR/unit" -name "*.bats" 2>/dev/null | sort)
      ;;
    integration)
      mapfile -t files < <(find "$SCRIPT_DIR/integration" -name "*.bats" 2>/dev/null | sort)
      ;;
    *)
      # Specific test file
      if [[ -f "$SCRIPT_DIR/unit/${suite}.bats" ]]; then
        files=("$SCRIPT_DIR/unit/${suite}.bats")
      elif [[ -f "$SCRIPT_DIR/integration/${suite}.bats" ]]; then
        files=("$SCRIPT_DIR/integration/${suite}.bats")
      elif [[ -f "$SCRIPT_DIR/${suite}.bats" ]]; then
        files=("$SCRIPT_DIR/${suite}.bats")
      else
        die 1 "Test file not found: $suite"
      fi
      ;;
  esac

  printf '%s\n' "${files[@]}"
}

# Run tests with BATS
run_tests() {
  local -a test_files=()
  mapfile -t test_files < <(find_test_files "$TEST_SUITE")

  if [[ ${#test_files[@]} -eq 0 ]]; then
    die 1 "No test files found for suite: $TEST_SUITE"
  fi

  >&2 echo "${CYAN}◉${NC} Running ${#test_files[@]} test file(s) from: $TEST_SUITE"
  >&2 echo

  # Build BATS command
  local -a bats_args=()

  # Add format option
  case $FORMAT in
    tap)
      bats_args+=(--formatter tap)
      ;;
    pretty)
      bats_args+=(--formatter pretty)
      ;;
    junit)
      bats_args+=(--formatter junit)
      ;;
    *)
      warn "Unknown format: $FORMAT, using tap"
      bats_args+=(--formatter tap)
      ;;
  esac

  # Add filter if specified
  if [[ -n "$FILTER" ]]; then
    bats_args+=(--filter "$FILTER")
  fi

  # Add parallel execution if requested
  if ((PARALLEL)); then
    bats_args+=(--jobs 4)
  fi

  # Run tests
  local -i exit_code=0
  if bats "${bats_args[@]}" "${test_files[@]}"; then
    >&2 echo
    success 'All tests passed!'
    exit_code=0
  else
    >&2 echo
    error 'Some tests failed'
    exit_code=1
  fi

  return $exit_code
}

# Print test statistics
print_statistics() {
  >&2 echo
  >&2 echo "${CYAN}◉${NC} Test Statistics:"
  >&2 echo "  Test files: $(find "$SCRIPT_DIR" -name "*.bats" | wc -l)"
  >&2 echo "  Unit tests: $(find "$SCRIPT_DIR/unit" -name "*.bats" 2>/dev/null | wc -l)"
  >&2 echo "  Integration tests: $(find "$SCRIPT_DIR/integration" -name "*.bats" 2>/dev/null | wc -l)"
  >&2 echo
}

# Main
main() {
  parse_args "$@"
  check_dependencies

  # Change to project root for tests
  cd "$PROJECT_ROOT"

  # Show statistics if verbose
  if ((VERBOSE)); then
    print_statistics
  fi

  # Run tests
  run_tests
}

main "$@"
#fin
