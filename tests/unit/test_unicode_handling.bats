#!/usr/bin/env bats
# Unit tests for Unicode and special character handling
# Tests international text, emoji, and escape sequences

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key_123456"
}

teardown() {
  teardown_test_env
}

# ============================================================
# Unicode Query Input Tests
# ============================================================

@test "query with Chinese characters" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"cn","response":"心灵感悟是对人生的理解","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "什么是心灵感悟"

  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"心灵感悟"* ]]
}

@test "query with Japanese characters" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"jp","response":"瞑想は古代の修行です","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "瞑想とは何ですか"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query with Korean characters" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"kr","response":"명상은 고대의 수행입니다","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "명상이 무엇입니까"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query with emoji characters" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"emoji","response":"Meditation 🧘 is a practice","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "What is meditation? 🤔"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query with RTL Arabic text" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"ar","response":"التأمل هو ممارسة قديمة","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "ما هو التأمل"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query with Hebrew text" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"he","response":"מדיטציה היא תרגול עתיק","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "מה זה מדיטציה"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query with combining diacritical marks" {
  # Arrange - Vietnamese with diacritics
  set_mock_curl_response '{"data":{"query_id":"vi","response":"Thiền là một thực hành cổ xưa","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "Thiền định là gì"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query with Cyrillic characters" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"ru","response":"Медитация - это практика","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "Что такое медитация"

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# JSON Escape Sequence Tests
# ============================================================

@test "JSON escape sequences in query - newline" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"esc","response":"ok","metadata":{}}}' "200"

  # Act - query with embedded newline
  run ./yatti-api query -K testdb -q "Line 1
Line 2"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "JSON escape sequences in query - tabs" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"tab","response":"ok","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "Column1	Column2	Column3"

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "JSON escape sequences in query - quotes" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"quot","response":"ok","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q 'What is "mindfulness"?'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "JSON escape sequences in query - backslash" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"bs","response":"ok","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q 'Path: C:\Users\test'

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Response Unicode Display Tests
# ============================================================

@test "response containing Unicode displayed correctly" {
  # Arrange - response with mixed Unicode
  set_mock_curl_response '{"data":{"query_id":"mix","response":"English 中文 日本語 한국어 العربية 🌍","metadata":{}}}' "200"

  # Act
  run ./yatti-api query -K testdb -q "test"

  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"中文"* ]]
}

# ============================================================
# Special Parameter Values Tests
# ============================================================

@test "knowledgebase name with dots and dashes" {
  # Arrange
  set_mock_curl_response '{"data":{"name":"test-kb.v2","documents":5}}' "200"

  # Act
  run ./yatti-api kb get test-kb.v2

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "knowledgebase name with underscores" {
  # Arrange
  set_mock_curl_response '{"data":{"name":"test_knowledge_base","documents":3}}' "200"

  # Act
  run ./yatti-api kb get test_knowledge_base

  # Assert
  [[ "$status" -eq 0 ]]
}

#fin
