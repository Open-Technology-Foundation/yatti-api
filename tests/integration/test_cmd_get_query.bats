#!/usr/bin/env bats
# Integration tests for cmd_get_query() in yatti-api

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

@test "get-query requires query ID" {
  run ./yatti-api get-query
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"Query ID required"* ]]
}

@test "get-query works with valid ID" {
  set_mock_curl_response "$(jq -c '.get_query.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api get-query q_abc123def456
  [[ "$status" -eq 0 ]]
}

@test "get-query returns query details" {
  set_mock_curl_response "$(jq -c '.get_query.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api get-query q_abc123def456
  [[ "$output" == *"seculardharma"* ]]
}

@test "get-query accepts valid query ID formats" {
  set_mock_curl_response "$(jq -c '.get_query.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api get-query q_abc-123_def.456
  [[ "$status" -eq 0 ]]
}

# Error handling

@test "get-query handles not found" {
  set_mock_curl_response "$(jq -c '.get_query.not_found' "$FIXTURES_FILE")" "404"
  run ./yatti-api get-query q_nonexistent
  [[ "$status" -eq 1 ]]
}

@test "get-query handles network failure" {
  set_mock_curl_fail
  run ./yatti-api get-query q_test
  [[ "$status" -ne 0 ]]
}

#fin
