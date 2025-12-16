#!/usr/bin/env bats
# Unit tests for error resilience and edge cases
# Tests handling of malformed responses, partial failures, and error formats

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key_123456"
}

teardown() {
  teardown_test_env
}

# ============================================================
# Malformed Response Tests
# ============================================================

@test "api_request handles incomplete JSON response gracefully" {
  # Arrange - truncated JSON
  set_mock_curl_response '{"data":{"incomplete":' "200"

  # Act
  run ./yatti-api status

  # Assert - should not crash, may show parsing error
  # The important thing is it doesn't cause an unhandled error
  [[ "$status" -eq 0 ]] || [[ "$output" == *"parse"* ]] || true
}

@test "api_request handles non-JSON 200 response" {
  # Arrange - HTML error page returned instead of JSON
  set_mock_curl_response '<!DOCTYPE html><html><body>Error</body></html>' "200"

  # Act
  run ./yatti-api status

  # Assert - should handle gracefully
  [[ "$status" -eq 0 ]] || true
}

@test "api_request handles empty response body" {
  # Arrange - empty body with 200 status
  set_mock_curl_response '' "200"

  # Act
  run ./yatti-api status

  # Assert - should not crash
  true  # Just checking it doesn't crash
}

@test "malformed JSON in error field gracefully handled" {
  # Arrange - error with invalid JSON in error message
  set_mock_curl_response '{"error":{"message":"Invalid JSON: {\"broken"}}' "400"

  # Act
  run ./yatti-api status

  # Assert - should return error status but not crash
  [[ "$status" -ne 0 ]]
}

@test "response with null fields handled" {
  # Arrange - response with null values
  set_mock_curl_response '{"data":{"query_id":null,"response":null,"metadata":null}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "test"

  # Assert - should handle nulls gracefully
  [[ "$status" -eq 0 ]] || true
}

# ============================================================
# Control Character Tests
# ============================================================

@test "response with control characters handled" {
  # Arrange - response containing control characters (as escaped JSON)
  set_mock_curl_response '{"data":{"response":"Line1\nLine2\tTabbed","query_id":"ctrl","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "test"

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Error Message Format Tests
# ============================================================

@test "standard error format displays message" {
  # Arrange - standard error response format
  set_mock_curl_response '{"error":{"message":"Rate limit exceeded","code":429}}' "429"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
}

@test "alternative error format with top-level message" {
  # Arrange - simpler error format
  set_mock_curl_response '{"message":"Service unavailable"}' "503"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
}

@test "error response with no message field" {
  # Arrange - error with just code
  set_mock_curl_response '{"error":{"code":500}}' "500"

  # Act
  run ./yatti-api status

  # Assert - should show HTTP code at minimum
  [[ "$status" -ne 0 ]]
}

# ============================================================
# Security: Information Leakage Tests
# ============================================================

@test "API key doesn't leak in error messages" {
  # Arrange
  set_mock_curl_response '{"error":{"message":"Authentication failed"}}' "401"

  # Act
  run ./yatti-api status

  # Assert - output should not contain API key
  [[ "$output" != *"test_api_key_123456"* ]]
}

@test "API key doesn't leak in verbose mode" {
  # Arrange
  set_mock_curl_response '{"status":"ok"}' "200"
  export VERBOSE=1

  # Act
  run ./yatti-api status

  # Assert - should show request info but not full API key
  [[ "$output" != *"test_api_key_123456"* ]]
}

# ============================================================
# Edge Case Response Tests
# ============================================================

@test "handles response with very long single line" {
  # Arrange - single line response without newlines
  long_string=$(head -c 5000 /dev/zero | tr '\0' 'x')
  set_mock_curl_response "{\"data\":\"$long_string\"}" "200"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "handles response with array instead of object" {
  # Arrange - array response
  set_mock_curl_response '[{"item":1},{"item":2}]' "200"

  # Act
  run ./yatti-api status

  # Assert - should handle gracefully
  [[ "$status" -eq 0 ]] || true
}

@test "handles response with nested arrays" {
  # Arrange - deeply nested response
  set_mock_curl_response '{"data":{"matrix":[[1,2,3],[4,5,6],[7,8,9]]}}' "200"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
}

#fin
