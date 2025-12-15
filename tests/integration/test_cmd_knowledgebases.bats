#!/usr/bin/env bats
# Integration tests for cmd_knowledgebases() in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
}

# List subcommand tests

@test "knowledgebases list works" {
  set_mock_curl_response "$(jq -c '.knowledgebases.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api knowledgebases list
  [[ "$status" -eq 0 ]]
}

@test "knowledgebases list is default subcommand" {
  set_mock_curl_response "$(jq -c '.knowledgebases.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api knowledgebases
  [[ "$status" -eq 0 ]]
}

@test "kb alias works for knowledgebases" {
  set_mock_curl_response "$(jq -c '.knowledgebases.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api kb list
  [[ "$status" -eq 0 ]]
}

@test "knowledgebases list shows available KBs" {
  set_mock_curl_response "$(jq -c '.knowledgebases.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api kb list
  [[ "$output" == *"seculardharma"* ]]
}

# Get subcommand tests

@test "knowledgebases get requires name" {
  run ./yatti-api kb get
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"Knowledgebase name required"* ]]
}

@test "knowledgebases get works with valid name" {
  set_mock_curl_response "$(jq -c '.knowledgebase_get.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api kb get seculardharma
  [[ "$status" -eq 0 ]]
}

@test "knowledgebases get handles not found" {
  set_mock_curl_response "$(jq -c '.knowledgebase_get.not_found' "$FIXTURES_FILE")" "404"
  run ./yatti-api kb get nonexistent
  [[ "$status" -eq 1 ]]
}

# Sync subcommand tests

@test "knowledgebases sync works" {
  set_mock_curl_response "$(jq -c '.knowledgebases_sync.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api kb sync
  [[ "$status" -eq 0 ]]
}

# Error handling

@test "knowledgebases rejects unknown subcommand" {
  run ./yatti-api kb invalid
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"Unknown knowledgebases subcommand"* ]]
}

@test "knowledgebases handles network failure" {
  set_mock_curl_fail
  run ./yatti-api kb list
  [[ "$status" -ne 0 ]]
}

#fin
