#!/usr/bin/env bats
# Unit tests for URL path validation functions in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  source_yatti_functions
  create_test_api_key "test_api_key"
}

teardown() {
  teardown_test_env
}

# Tests for validate_path_segment() - success cases (no die/exit involved)

@test "validate_path_segment() accepts alphanumeric" {
  # Should return success (exit 0)
  validate_path_segment "user123" "test"
}

@test "validate_path_segment() accepts dots dashes underscores" {
  validate_path_segment "my_kb-name.v2" "test"
}

@test "validate_path_segment() accepts typical KB names" {
  validate_path_segment "seculardharma" "test"
}

@test "validate_path_segment() accepts query IDs with mixed chars" {
  validate_path_segment "q_abc-123_def.456" "test"
}

# Tests for validate_query_param() - success cases

@test "validate_query_param() accepts valid integer" {
  validate_query_param "100" "limit" "integer"
}

@test "validate_query_param() accepts zero" {
  validate_query_param "0" "limit" "integer"
}

@test "validate_query_param() accepts safe string" {
  validate_query_param "seculardharma" "kb" "string"
}

# Error case tests - test via CLI commands instead of raw functions
# These exercise the validation through the actual command interface

@test "users get rejects path traversal" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api users get "../admin"
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"disallowed characters"* ]]
}

@test "users get rejects forward slashes" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api users get "users/admin"
  [[ "$status" -eq 22 ]]
}

@test "users get rejects query strings" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api users get "user?admin=true"
  [[ "$status" -eq 22 ]]
}

@test "users delete rejects path traversal" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api users delete "../admin"
  [[ "$status" -eq 22 ]]
}

@test "kb get rejects path traversal" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api kb get "../secret"
  [[ "$status" -eq 22 ]]
}

@test "kb get rejects query injection" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api kb get "kb?admin=true"
  [[ "$status" -eq 22 ]]
}

@test "history rejects non-integer limit" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api history abc
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"integer"* ]]
}

@test "history rejects negative limit" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api history -5
  [[ "$status" -eq 22 ]]
}

@test "history rejects injection in kb filter" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api history 20 "kb&admin=true"
  [[ "$status" -eq 22 ]]
}

@test "get-query rejects path traversal" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api get-query "../admin"
  [[ "$status" -eq 22 ]]
}

@test "get-query rejects query string injection" {
  set_mock_curl_response '{"data":{}}' "200"
  run ./yatti-api get-query "q_123?debug=1"
  [[ "$status" -eq 22 ]]
}

#fin
