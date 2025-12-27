#!/usr/bin/env bats
# Integration tests for cmd_users() in yatti-api

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

@test "users list works without arguments" {
  set_mock_curl_response "$(jq -c '.users.list' "$FIXTURES_FILE")" "200"
  run ./yatti-api users list
  [[ "$status" -eq 0 ]]
}

@test "users list is the default subcommand" {
  set_mock_curl_response "$(jq -c '.users.list' "$FIXTURES_FILE")" "200"
  run ./yatti-api users
  [[ "$status" -eq 0 ]]
}

@test "users list returns user data" {
  set_mock_curl_response "$(jq -c '.users.list' "$FIXTURES_FILE")" "200"
  run ./yatti-api users list
  [[ "$output" == *"user_001"* ]]
}

# Get subcommand tests

@test "users get requires user ID" {
  run ./yatti-api users get
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"User ID required"* ]]
}

@test "users get works with valid ID" {
  set_mock_curl_response "$(jq -c '.users.get.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api users get user_001
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"admin@example.com"* ]]
}

@test "users get handles not found" {
  set_mock_curl_response "$(jq -c '.users.get.not_found' "$FIXTURES_FILE")" "404"
  run ./yatti-api users get nonexistent
  [[ "$status" -eq 1 ]]
}

# Create subcommand tests

@test "users create requires JSON data" {
  run ./yatti-api users create
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"User data required"* ]]
}

@test "users create works with valid JSON" {
  set_mock_curl_response "$(jq -c '.users.create.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api users create '{"email":"new@example.com"}'
  [[ "$status" -eq 0 ]]
}

@test "users create rejects invalid JSON" {
  run ./yatti-api users create 'not valid json'
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"Invalid JSON format"* ]]
}

@test "users create rejects truncated JSON" {
  run ./yatti-api users create '{"email":"test@example.com"'
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"Invalid JSON format"* ]]
}

@test "users create handles validation errors" {
  set_mock_curl_response "$(jq -c '.users.create.invalid' "$FIXTURES_FILE")" "400"
  run ./yatti-api users create '{"invalid":"data"}'
  [[ "$status" -eq 1 ]]
}

# Update subcommand tests

@test "users update requires user ID" {
  run ./yatti-api users update
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"User ID required"* ]]
}

@test "users update requires JSON data" {
  run ./yatti-api users update user_001
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"User data required"* ]]
}

@test "users update rejects invalid JSON" {
  run ./yatti-api users update user_001 'not valid json'
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"Invalid JSON format"* ]]
}

@test "users update rejects truncated JSON" {
  run ./yatti-api users update user_001 '{"email":"updated@example.com"'
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"Invalid JSON format"* ]]
}

@test "users update works with valid inputs" {
  set_mock_curl_response "$(jq -c '.users.update.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api users update user_001 '{"email":"updated@example.com"}'
  [[ "$status" -eq 0 ]]
}

# Delete subcommand tests

@test "users delete requires user ID" {
  run ./yatti-api users delete
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"User ID required"* ]]
}

@test "users delete works with valid ID" {
  set_mock_curl_response "$(jq -c '.users.delete.success' "$FIXTURES_FILE")" "200"
  run ./yatti-api users delete user_001
  [[ "$status" -eq 0 ]]
}

# Error handling

@test "users rejects unknown subcommand" {
  run ./yatti-api users invalid_subcommand
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"Unknown users subcommand"* ]]
}

@test "users handles network failure" {
  set_mock_curl_fail
  run ./yatti-api users list
  [[ "$status" -ne 0 ]]
}

#fin
