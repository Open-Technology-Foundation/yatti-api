#!/usr/bin/env bash
# Test Helpers for YaTTi API Client Tests
# Provides common setup, teardown, and utility functions for BATS tests

# Source the main script functions (without executing main)
# We'll override main() to prevent execution
source_yatti_functions() {
  # Store original main if it exists
  if declare -f main >/dev/null 2>&1; then
    eval "$(declare -f main | sed '1s/main/__original_main/')"
  fi

  # Source the script (loads all functions)
  # Override main to do nothing
  main() { :; }

  source "${BATS_TEST_DIRNAME}/../../yatti-api"

  # Restore environment
  unset -f main
  if declare -f __original_main >/dev/null 2>&1; then
    eval "$(declare -f __original_main | sed '1s/__original_main/main/')"
  fi
}

# Setup mock curl in PATH
setup_mock_curl_path() {
  # Save original PATH
  export ORIGINAL_PATH="$PATH"

  # Prepend helpers directory to PATH so our mock curl is found first
  export PATH="${BATS_TEST_DIRNAME}/../helpers:$PATH"
}

# Set mock curl response via environment variables
set_mock_curl_response() {
  local -- response="$1"
  local -- http_code="${2:-200}"

  export MOCK_CURL_RESPONSE="$response"
  export MOCK_CURL_HTTP_CODE="$http_code"
  export MOCK_CURL_FAIL=0
}

# Make curl fail (simulate network failure)
set_mock_curl_fail() {
  export MOCK_CURL_FAIL=1
}

# Setup mock curl for retry testing with sequence of responses
# Usage: setup_mock_curl_retries "500:{\"error\":\"server error\"}" "200:{\"status\":\"ok\"}"
setup_mock_curl_retries() {
  # Create temp files for tracking
  export MOCK_CURL_CALL_COUNT="${BATS_TEST_TMPDIR}/curl_call_count"
  export MOCK_CURL_RESPONSES="${BATS_TEST_TMPDIR}/curl_responses"

  # Initialize call count
  echo "0" > "$MOCK_CURL_CALL_COUNT"

  # Write responses (one per line)
  printf '%s\n' "$@" > "$MOCK_CURL_RESPONSES"

  # Clear single-response vars
  unset MOCK_CURL_RESPONSE MOCK_CURL_HTTP_CODE MOCK_CURL_FAIL
}

# Get the number of times mock curl was called
get_mock_curl_call_count() {
  cat "${MOCK_CURL_CALL_COUNT:-/dev/null}" 2>/dev/null || echo 0
}

# Reset retry tracking
reset_mock_curl_retries() {
  rm -f "${MOCK_CURL_CALL_COUNT:-}" "${MOCK_CURL_RESPONSES:-}"
  unset MOCK_CURL_CALL_COUNT MOCK_CURL_RESPONSES
}

# Setup test environment
setup_test_env() {
  # Create isolated test environment
  export TEST_HOME="${BATS_TEST_TMPDIR}/home"
  export HOME="$TEST_HOME"
  mkdir -p "$TEST_HOME"

  # Override config directory for tests
  export YATTI_TEST_MODE=1
  export CONFIG_DIR="${TEST_HOME}/.config/yatti-api"
  export API_KEY_FILE="${CONFIG_DIR}/api_key"

  # Set test API base
  export YATTI_API_BASE="${YATTI_API_BASE:-http://test.yatti.local/v1}"

  # Disable prompts and enable verbose for testing
  export PROMPT=0
  export VERBOSE=1

  # Ensure config dir exists
  mkdir -p "$CONFIG_DIR"

  # Setup mock curl in PATH
  setup_mock_curl_path
}

# Cleanup test environment
teardown_test_env() {
  # Restore original PATH
  if [[ -n "${ORIGINAL_PATH:-}" ]]; then
    export PATH="$ORIGINAL_PATH"
    unset ORIGINAL_PATH
  fi

  # Clean up temp files
  [[ -d "$TEST_HOME" ]] && rm -rf "$TEST_HOME"

  # Unset test variables
  unset TEST_HOME CONFIG_DIR API_KEY_FILE
  unset YATTI_TEST_MODE YATTI_API_BASE
  unset YATTI_API_KEY PROMPT VERBOSE

  # Unset mock curl variables
  unset MOCK_CURL_RESPONSE MOCK_CURL_HTTP_CODE MOCK_CURL_FAIL
}

# Create a test API key file
create_test_api_key() {
  local -- key="${1:-test_api_key_12345}"
  mkdir -p "$CONFIG_DIR"
  echo "$key" > "$API_KEY_FILE"
  chmod 600 "$API_KEY_FILE"
}

# Create a mock API response file
create_mock_response() {
  local -- response_file="${1}"
  local -- content="${2}"
  echo "$content" > "$response_file"
}

# Assert file exists
assert_file_exists() {
  local -- file="$1"
  [[ -f "$file" ]] || {
    echo "Expected file to exist: $file" >&2
    return 1
  }
}

# Assert file has specific permissions
assert_file_mode() {
  local -- file="$1"
  local -- expected_mode="$2"
  local -- actual_mode
  actual_mode=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%Lp" "$file" 2>/dev/null)

  [[ "$actual_mode" == "$expected_mode" ]] || {
    echo "Expected file mode $expected_mode, got $actual_mode for: $file" >&2
    return 1
  }
}

# Assert string contains substring
assert_contains() {
  local -- haystack="$1"
  local -- needle="$2"

  [[ "$haystack" == *"$needle"* ]] || {
    echo "Expected string to contain: $needle" >&2
    echo "Actual string: $haystack" >&2
    return 1
  }
}

# Assert string does not contain substring
assert_not_contains() {
  local -- haystack="$1"
  local -- needle="$2"

  [[ "$haystack" != *"$needle"* ]] || {
    echo "Expected string NOT to contain: $needle" >&2
    echo "Actual string: $haystack" >&2
    return 1
  }
}

# Assert exit code
assert_exit_code() {
  local -- expected="$1"
  local -- actual="$2"

  [[ "$actual" -eq "$expected" ]] || {
    echo "Expected exit code $expected, got $actual" >&2
    return 1
  }
}

# Assert JSON is valid
assert_json_valid() {
  local -- json="$1"
  echo "$json" | jq empty 2>/dev/null || {
    echo "Invalid JSON:" >&2
    echo "$json" >&2
    return 1
  }
}

# Get JSON field value
json_get() {
  local -- json="$1"
  local -- field="$2"
  echo "$json" | jq -r "$field" 2>/dev/null
}

# Mock curl command
mock_curl_response() {
  local -- http_code="${1:-200}"
  local -- body="${2:-{}}"

  # Format matches yatti-api's curl output pattern
  printf '%s\n__HTTP_CODE__%s' "$body" "$http_code"
}

# Skip test if command not available
skip_if_missing() {
  local -- cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || skip "$cmd not available"
}

# Run command and capture output/exit code
run_command() {
  set +e
  output=$("$@" 2>&1)
  status=$?
  set -e
  export output status
}

#fin
