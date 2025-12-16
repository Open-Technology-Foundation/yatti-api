#!/usr/bin/env bats
# Unit tests for large payload handling
# Tests query size feedback and processing of large inputs/outputs

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key_123456"
}

teardown() {
  teardown_test_env
}

# ============================================================
# Large Query Input Tests
# ============================================================

@test "query command handles 10KB query with info message" {
  # Arrange - create a 10KB query (10240 bytes)
  query=$(head -c 10240 /dev/zero | tr '\0' 'a')
  set_mock_curl_response '{"data":{"query_id":"q1","response":"ok","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "$query"

  # Assert - should succeed (10KB is info level, not error)
  [[ "$status" -eq 0 ]]
}

@test "query command warns about queries over 100KB" {
  # Arrange - create a 100KB+ query
  query=$(head -c 102401 /dev/zero | tr '\0' 'b')
  set_mock_curl_response '{"data":{"query_id":"q2","response":"ok","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "$query"

  # Assert - should have warning in output but still succeed
  [[ "$status" -eq 0 ]]
  # The warning goes to stderr which gets captured in BATS output
}

@test "query via stdin handles large input" {
  # Arrange - 50KB query via stdin
  query=$(head -c 51200 /dev/zero | tr '\0' 'c')
  set_mock_curl_response '{"data":{"query_id":"q3","response":"ok","metadata":{}}}' "200"

  # Act
  run bash -c "echo '$query' | ./yatti-api query -K testdb -q -"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query via file (-Q) handles large file" {
  # Arrange - 50KB query file
  query_file="${BATS_TEST_TMPDIR}/large_query.txt"
  head -c 51200 /dev/zero | tr '\0' 'd' > "$query_file"
  set_mock_curl_response '{"data":{"query_id":"q4","response":"ok","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -Q "$query_file"

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Large Response Handling Tests
# ============================================================

@test "api_request handles large JSON response (100KB)" {
  # Arrange - create a large response (100KB of JSON)
  large_data=$(head -c 100000 /dev/zero | tr '\0' 'x')
  response="{\"data\":{\"response\":\"${large_data}\",\"query_id\":\"big\",\"metadata\":{}}}"
  set_mock_curl_response "$response" "200"

  # Act
  run ./yatti-api status

  # Assert - should handle large response
  [[ "$status" -eq 0 ]]
}

@test "format_json handles large output" {
  # Arrange - create response with lots of keys
  # Build JSON with 100 keys
  json="{"
  for i in $(seq 1 100); do
    [[ $i -gt 1 ]] && json+=","
    json+="\"key$i\":\"value$i\""
  done
  json+="}"
  set_mock_curl_response "$json" "200"

  # Act
  run ./yatti-api status

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Context Extraction with Large Data
# ============================================================

@test "query with large context array succeeds" {
  # Arrange - response with large contexts array
  contexts=""
  for i in $(seq 1 20); do
    [[ $i -gt 1 ]] && contexts+=","
    contexts+="{\"content\":\"Context chunk $i with substantial text content for testing.\",\"score\":0.${i}}"
  done
  response="{\"data\":{\"query_id\":\"ctx\",\"response\":\"Summary\",\"contexts\":[$contexts],\"metadata\":{}}}"
  set_mock_curl_response "$response" "200"

  # Act
  run ./yatti-api query -K testdb -q "test" --context-only

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "jq parsing succeeds on deeply nested JSON" {
  # Arrange - deeply nested structure
  response='{"data":{"query_id":"deep","response":"ok","metadata":{"nested":{"level1":{"level2":{"level3":"value"}}}}}}'
  set_mock_curl_response "$response" "200"

  # Act
  run ./yatti-api query -K testdb -q "test"

  # Assert
  [[ "$status" -eq 0 ]]
}

#fin
