#!/usr/bin/env bats
# Integration tests for retry logic with exponential backoff
# Tests automatic retry on transient failures

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key_123456"
  # Use minimal retries for faster tests
  export YATTI_MAX_RETRIES=3
}

teardown() {
  reset_mock_curl_retries
  teardown_test_env
}

# ============================================================
# Retry on Server Errors
# ============================================================

@test "retry on 429 rate limit succeeds after retry" {
  # Arrange - first call returns 429, second returns 200
  setup_mock_curl_retries \
    '429:{"error":{"message":"Rate limit exceeded"}}' \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert - should succeed after retry
  [[ "$status" -eq 0 ]]
  [[ $(get_mock_curl_call_count) -eq 2 ]]
}

@test "retry on 503 service unavailable succeeds after retry" {
  # Arrange - first call returns 503, second returns 200
  setup_mock_curl_retries \
    '503:{"error":{"message":"Service unavailable"}}' \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
  [[ $(get_mock_curl_call_count) -eq 2 ]]
}

@test "retry on 500 server error succeeds after retry" {
  # Arrange
  setup_mock_curl_retries \
    '500:{"error":{"message":"Internal server error"}}' \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
  [[ $(get_mock_curl_call_count) -eq 2 ]]
}

@test "retry on 502 bad gateway succeeds after retry" {
  # Arrange
  setup_mock_curl_retries \
    '502:{"error":{"message":"Bad gateway"}}' \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
  [[ $(get_mock_curl_call_count) -eq 2 ]]
}

@test "retry on 504 gateway timeout succeeds after retry" {
  # Arrange
  setup_mock_curl_retries \
    '504:{"error":{"message":"Gateway timeout"}}' \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# No Retry on Client Errors
# ============================================================

@test "no retry on 400 bad request" {
  # Arrange
  setup_mock_curl_retries \
    '400:{"error":{"message":"Bad request"}}'

  # Act
  run ./yatti-api status

  # Assert - should fail immediately without retry
  [[ "$status" -ne 0 ]]
  [[ $(get_mock_curl_call_count) -eq 1 ]]
}

@test "no retry on 401 unauthorized" {
  # Arrange
  setup_mock_curl_retries \
    '401:{"error":{"message":"Invalid API key"}}'

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
  [[ $(get_mock_curl_call_count) -eq 1 ]]
}

@test "no retry on 403 forbidden" {
  # Arrange
  setup_mock_curl_retries \
    '403:{"error":{"message":"Access denied"}}'

  # Act - use status command (simpler than kb list which has fallback pattern)
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
  [[ $(get_mock_curl_call_count) -eq 1 ]]
}

@test "no retry on 404 not found" {
  # Arrange
  setup_mock_curl_retries \
    '404:{"error":{"message":"Resource not found"}}'

  # Act
  run ./yatti-api get-query nonexistent-id

  # Assert
  [[ "$status" -ne 0 ]]
  [[ $(get_mock_curl_call_count) -eq 1 ]]
}

@test "no retry on 422 unprocessable entity" {
  # Arrange
  setup_mock_curl_retries \
    '422:{"error":{"message":"Validation failed"}}'

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -ne 0 ]]
  [[ $(get_mock_curl_call_count) -eq 1 ]]
}

# ============================================================
# Max Retries Tests
# ============================================================

@test "max retries respected - gives up after limit" {
  # Arrange - all 500 errors, should give up after MAX_RETRIES
  # shellcheck disable=SC2030,SC2031  # BATS subshell export is intentional
  export YATTI_MAX_RETRIES=3
  setup_mock_curl_retries \
    '500:{"error":{"message":"Error 1"}}' \
    '500:{"error":{"message":"Error 2"}}' \
    '500:{"error":{"message":"Error 3"}}' \
    '200:{"status":"ok"}'  # This won't be reached

  # Act
  run ./yatti-api status

  # Assert - should fail after 3 attempts
  [[ "$status" -ne 0 ]]
  [[ $(get_mock_curl_call_count) -eq 3 ]]
}

@test "YATTI_MAX_RETRIES=1 disables retries" {
  # Arrange
  # shellcheck disable=SC2030,SC2031  # BATS subshell export is intentional
  export YATTI_MAX_RETRIES=1
  setup_mock_curl_retries \
    '500:{"error":{"message":"Server error"}}' \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert - should fail immediately (only 1 attempt, no retries)
  [[ "$status" -ne 0 ]]
  [[ $(get_mock_curl_call_count) -eq 1 ]]
}

@test "multiple retries needed before success" {
  # Arrange - need 3 attempts to succeed
  # shellcheck disable=SC2030,SC2031  # BATS subshell export is intentional
  export YATTI_MAX_RETRIES=3
  setup_mock_curl_retries \
    '500:{"error":"error1"}' \
    '503:{"error":"error2"}' \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert - should succeed on third attempt
  [[ "$status" -eq 0 ]]
  [[ $(get_mock_curl_call_count) -eq 3 ]]
}

# ============================================================
# Connection Failure Retry Tests
# ============================================================

@test "connection timeout triggers retry" {
  # Note: Testing actual timeout behavior is tricky with mock
  # This test verifies the network failure path works
  set_mock_curl_fail

  # Act
  run ./yatti-api status

  # Assert - should fail after retries
  [[ "$status" -ne 0 ]]
}

# ============================================================
# First Success Tests (No Retry Needed)
# ============================================================

@test "no retry when first request succeeds" {
  # Arrange - immediate success
  setup_mock_curl_retries \
    '200:{"status":"ok"}'

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
  [[ $(get_mock_curl_call_count) -eq 1 ]]
}

#fin
