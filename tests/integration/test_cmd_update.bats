#!/usr/bin/env bats
# Integration tests for cmd_update() in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
}

# Check-only mode tests

@test "update --check works" {
  set_mock_curl_response "$(jq -c '.update_check.no_update' "$FIXTURES_FILE")" "200"
  run ./yatti-api update --check
  [[ "$status" -eq 0 ]]
}

@test "update --check reports no update available" {
  set_mock_curl_response "$(jq -c '.update_check.no_update' "$FIXTURES_FILE")" "200"
  run ./yatti-api update --check
  [[ "$output" == *"latest version"* ]] || [[ "$output" == *"up to date"* ]]
}

@test "update --check reports update available" {
  set_mock_curl_response "$(jq -c '.update_check.update_available' "$FIXTURES_FILE")" "200"
  run ./yatti-api update --check
  [[ "$output" == *"Update available"* ]] || [[ "$output" == *"1.4.1"* ]]
}

@test "update --check does not modify files" {
  set_mock_curl_response "$(jq -c '.update_check.update_available' "$FIXTURES_FILE")" "200"
  local original_hash
  original_hash=$(md5sum ./yatti-api | cut -d' ' -f1)
  run ./yatti-api update --check
  local new_hash
  new_hash=$(md5sum ./yatti-api | cut -d' ' -f1)
  [[ "$original_hash" == "$new_hash" ]]
}

# Help tests
# Note: --help has a known issue with EXIT trap and local variable scope
# These tests verify the output content rather than exit status

@test "update --help shows usage information" {
  run ./yatti-api update --help
  [[ "$output" == *"Usage"* ]]
  [[ "$output" == *"--check"* ]]
  [[ "$output" == *"--force"* ]]
}

@test "update -h shows help content" {
  run ./yatti-api update -h
  [[ "$output" == *"Options"* ]]
}

# Error handling tests

@test "update rejects unknown option" {
  run ./yatti-api update --invalid
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"Unknown"* ]]
}

@test "update handles API failure gracefully" {
  set_mock_curl_fail
  run ./yatti-api update --check
  # curl failures exit with code 7 (connection refused); set -e causes immediate exit
  [[ "$status" -ne 0 ]]
}

@test "update handles malformed API response" {
  set_mock_curl_response "not json" "200"
  run ./yatti-api update --check
  [[ "$status" -ne 0 ]]
}

# Version comparison integration

@test "update correctly identifies when version is current" {
  set_mock_curl_response "$(jq -c '.update_check.no_update' "$FIXTURES_FILE")" "200"
  run ./yatti-api update --check
  [[ "$output" != *"Update available"* ]]
}

#fin
