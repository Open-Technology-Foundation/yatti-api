#!/usr/bin/env bash
# Test Runner for YaTTi API Client
# Runs BATS test suite with options for filtering, formatting, and reporting

set -euo pipefail

# Colors
declare -r RED=$'\033[0;31m'
declare -r GREEN=$'\033[0;32m'
declare -r YELLOW=$'\033[0;33m'
declare -r CYAN=$'\033[0;36m'
declare -r NC=$'\033[0m'

# Script directory
declare -r SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Test configuration
declare -i VERBOSE=0
declare -i PARALLEL=0
declare -- FORMAT="tap"
declare -- FILTER=""
declare -- TEST_SUITE="all"

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
  while [[ $# -gt 0 ]]; do
    case "$1" in
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
        echo "Unknown option: $1" >&2
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
    echo "${RED}✗${NC} Error: BATS is not installed" >&2
    echo "Install with: sudo apt-get install bats" >&2
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "${YELLOW}⚡${NC} Warning: jq is not installed - some tests may fail" >&2
  fi
}

# Find test files based on suite
find_test_files() {
  local -- suite="$1"
  local -a files=()

  case "$suite" in
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
        echo "${RED}✗${NC} Test file not found: $suite" >&2
        exit 1
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
    echo "${YELLOW}⚡${NC} No test files found for suite: $TEST_SUITE" >&2
    exit 1
  fi

  echo "${CYAN}◉${NC} Running ${#test_files[@]} test file(s) from: $TEST_SUITE"
  echo

  # Build BATS command
  local -a bats_args=()

  # Add format option
  case "$FORMAT" in
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
      echo "${YELLOW}⚡${NC} Unknown format: $FORMAT, using tap" >&2
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
    echo
    echo "${GREEN}✓${NC} All tests passed!"
    exit_code=0
  else
    echo
    echo "${RED}✗${NC} Some tests failed"
    exit_code=1
  fi

  return $exit_code
}

# Print test statistics
print_statistics() {
  echo
  echo "${CYAN}◉${NC} Test Statistics:"
  echo "  Test files: $(find "$SCRIPT_DIR" -name "*.bats" | wc -l)"
  echo "  Unit tests: $(find "$SCRIPT_DIR/unit" -name "*.bats" 2>/dev/null | wc -l)"
  echo "  Integration tests: $(find "$SCRIPT_DIR/integration" -name "*.bats" 2>/dev/null | wc -l)"
  echo
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
