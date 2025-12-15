#!/usr/bin/env bats
# Integration tests for cmd_history() in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
}

# Basic functionality

@test "history command works without arguments" {
  set_mock_curl_response "$(jq -c '.history.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api history
  [[ "$status" -eq 0 ]]
}

@test "history shows query entries" {
  set_mock_curl_response "$(jq -c '.history.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api history
  [[ "$output" == *"seculardharma"* ]]
}

@test "history accepts limit parameter" {
  set_mock_curl_response "$(jq -c '.history.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api history 50
  [[ "$status" -eq 0 ]]
}

@test "history accepts knowledgebase filter" {
  set_mock_curl_response "$(jq -c '.history.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api history 20 seculardharma
  [[ "$status" -eq 0 ]]
}

@test "history accepts valid kb filter with dots and dashes" {
  set_mock_curl_response "$(jq -c '.history.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api history 20 secular_dharma-v2
  [[ "$status" -eq 0 ]]
}

# Error handling

@test "history handles API errors" {
  set_mock_curl_response "$(jq -c '.errors."500_server_error"' "$FIXTURES_FILE")" "500"
  run ./yatti-api history
  [[ "$status" -eq 1 ]]
}

@test "history handles network failure" {
  set_mock_curl_fail
  run ./yatti-api history
  [[ "$status" -ne 0 ]]
}

#fin
