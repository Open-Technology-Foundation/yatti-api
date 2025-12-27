#!/usr/bin/env bats
# Integration tests for api_request() behavior
# Tests HTTP handling through actual command execution

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key_123456"

  # Load fixtures (reserved for future use with complex test data)
  # shellcheck disable=SC2034
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
}

# ============================================================
# Success Cases (via status command which uses api_request)
# ============================================================

@test "api_request returns JSON body on 200 response" {
  # Arrange
  set_mock_curl_response '{"status":"ok","data":"test"}' "200"

  # Act - status command exercises api_request GET
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"ok"* ]]
}

@test "api_request handles 201 Created response" {
  # Arrange
  set_mock_curl_response '{"id":"new_user_123","email":"test@example.com"}' "201"

  # Act - users create exercises api_request POST (requires valid JSON)
  run ./yatti-api users create '{"email":"test@example.com","name":"Test"}'

  # Assert - 201 is treated as success (2xx range)
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Error Cases
# ============================================================

@test "api_request returns error on 400 Bad Request" {
  # Arrange
  set_mock_curl_response '{"error":{"message":"Invalid parameters"}}' "400"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"400"* ]] || [[ "$output" == *"Invalid"* ]]
}

@test "api_request returns error on 401 Unauthorized" {
  # Arrange
  set_mock_curl_response '{"error":{"message":"Invalid API key"}}' "401"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"401"* ]]
}

@test "api_request returns error on 403 Forbidden" {
  # Arrange
  set_mock_curl_response '{"error":{"message":"Access denied"}}' "403"

  # Act
  run ./yatti-api kb list

  # Assert
  [[ "$status" -ne 0 ]]
}

@test "api_request returns error on 404 Not Found" {
  # Arrange
  set_mock_curl_response '{"error":{"message":"Resource not found"}}' "404"

  # Act
  run ./yatti-api get-query nonexistent-id

  # Assert
  [[ "$status" -ne 0 ]]
}

@test "api_request returns error on 500 Server Error" {
  # Arrange
  set_mock_curl_response '{"error":{"message":"Internal server error"}}' "500"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"500"* ]]
}

# ============================================================
# Network Failure Cases
# ============================================================

@test "api_request handles network failure" {
  # Arrange
  set_mock_curl_fail

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
}

# ============================================================
# API Key Handling
# ============================================================

@test "api_request works without API key for public endpoints" {
  # Arrange - remove API key
  rm -f "$API_KEY_FILE"
  unset YATTI_API_KEY
  set_mock_curl_response '{"status":"ok"}' "200"

  # Act - help doesn't need API key
  run ./yatti-api help

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "api_request uses API key from environment variable" {
  # Arrange
  rm -f "$API_KEY_FILE"
  export YATTI_API_KEY="env_key_456789"
  set_mock_curl_response '{"status":"ok"}' "200"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
}

#fin
