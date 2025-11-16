#!/usr/bin/env bats
# Integration tests for cmd_status() in yatti-api

load '../helpers/test_helpers'
load '../helpers/mocks'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"

  # Load fixtures
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"

  # Mock curl for API requests
  mock_curl
}

teardown() {
  teardown_test_env
  reset_mock_curl
}

# Basic status tests

@test "status command works without arguments" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api status
  [[ "$status" -eq 0 ]]
}

@test "status command returns JSON" {
  set_mock_curl_response "$(jq -c '.status.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api status
  # Output should contain JSON elements
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"ok"* ]]
}

# Subcommand tests

@test "status health subcommand works" {
  set_mock_curl_response "$(jq -c '.status_health.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api status health
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"healthy"* ]]
}

@test "status info subcommand works" {
  set_mock_curl_response "$(jq -c '.status_info.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api status info
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"version"* ]]
}

# Error handling

@test "status command handles API errors" {
  set_mock_curl_response "$(jq -c '.errors."500_server_error"' "$FIXTURES_FILE")" "500"

  run ./yatti-api status
  [[ "$status" -eq 1 ]]
}

@test "status command handles network failures" {
  set_mock_curl_fail

  run ./yatti-api status
  [[ "$status" -eq 1 ]]
}

#fin
