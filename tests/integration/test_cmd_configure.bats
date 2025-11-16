#!/usr/bin/env bats
# Integration tests for cmd_configure() in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env

  # Load fixtures
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
}

# Basic configuration tests

@test "configure command displays header" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  # Mock empty input
  run bash -c 'echo "" | ./yatti-api configure'
  [[ "$output" == *"YaTTi API Configuration"* ]]
}

@test "configure command shows existing API key (masked)" {
  create_test_api_key "test_key_1234567890abcdef"
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "" | ./yatti-api configure'
  [[ "$output" == *"Current API key: test_key"* ]]
  [[ "$output" == *"...90abcdef"* ]]
}

@test "configure command accepts new API key from input" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "new_api_key_12345" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]

  # Verify key was saved
  [[ -f "$API_KEY_FILE" ]]
  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "new_api_key_12345" ]]
}

@test "configure command creates config directory if missing" {
  rm -rf "$CONFIG_DIR"
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "test_key" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]
  [[ -d "$CONFIG_DIR" ]]
}

@test "configure command sets correct file permissions (600)" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "secure_key" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]

  perms=$(stat -c "%a" "$API_KEY_FILE" 2>/dev/null || stat -f "%OLp" "$API_KEY_FILE" 2>/dev/null)
  [[ "$perms" == "600" ]]
}

@test "configure command handles special characters in key" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  special_key="key-with_special.chars/123+ABC="
  run bash -c "echo '$special_key' | ./yatti-api configure"
  [[ "$status" -eq 0 ]]

  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "$special_key" ]]
}

@test "configure command overwrites existing key" {
  create_test_api_key "old_key"
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "new_key" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]

  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "new_key" ]]
}

@test "configure command skips on empty input" {
  create_test_api_key "existing_key"
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]

  # Key should remain unchanged
  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "existing_key" ]]
}

@test "configure command preserves whitespace in key" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  # Note: read -r will trim leading/trailing whitespace, so internal spaces only
  run bash -c 'echo "key with spaces" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]

  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "key with spaces" ]]
}

# API validation tests

@test "configure command tests API connection" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "test_key" | ./yatti-api configure'
  [[ "$output" == *"Testing configuration"* ]]
}

@test "configure command shows success on valid API key" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "valid_key" | ./yatti-api configure'
  [[ "$output" == *"Configuration successful"* ]]
}

@test "configure command shows warning on API connection failure" {
  set_mock_curl_fail

  run bash -c 'echo "test_key" | ./yatti-api configure'
  [[ "$output" == *"Could not connect to API"* ]]
}

@test "configure command shows warning on invalid API key" {
  set_mock_curl_response "$(jq -c '.errors."401_unauthorized"' "$FIXTURES_FILE")" "401"

  run bash -c 'echo "invalid_key" | ./yatti-api configure'
  [[ "$output" == *"Could not connect to API"* ]]
}

# Load and save roundtrip test

@test "configure saves and loads API key correctly" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  test_key="roundtrip_key_abc123xyz789"

  # Save via configure
  run bash -c "echo '$test_key' | ./yatti-api configure"
  [[ "$status" -eq 0 ]]

  # Verify it's displayed (masked) on next configure
  run bash -c 'echo "" | ./yatti-api configure'
  [[ "$output" == *"Current API key: roundtri"* ]]
  [[ "$output" == *"23xyz789"* ]]
}

# Edge cases

@test "configure command handles very long API key" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  long_key=$(printf 'a%.0s' {1..256})
  run bash -c "echo '$long_key' | ./yatti-api configure"
  [[ "$status" -eq 0 ]]

  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "$long_key" ]]
}

@test "configure command handles short API key" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "short" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]

  # If key is shorter than 16 chars, masking might not show properly
  # Just verify it was saved
  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "short" ]]
}

@test "configure command works when config file already exists" {
  create_test_api_key "existing_key"
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run bash -c 'echo "updated_key" | ./yatti-api configure'
  [[ "$status" -eq 0 ]]

  saved_key=$(cat "$API_KEY_FILE")
  [[ "$saved_key" == "updated_key" ]]
}

#fin
