#!/usr/bin/env bats
# Integration tests for cmd_query() in yatti-api

load '../helpers/test_helpers'
load '../helpers/mocks'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"

  # Load fixtures
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"

  # Mock curl for API requests
  mock_curl
}

teardown() {
  teardown_test_env
  reset_mock_curl
}

# Basic query tests

@test "query command requires knowledgebase" {
  run ./yatti-api query -q "test query"
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"Knowledgebase name required"* ]]
}

@test "query command requires query text" {
  run ./yatti-api query -K seculardharma
  [[ "$status" -eq 2 ]]
  [[ "$output" == *"Query text required"* ]]
}

@test "query command accepts positional arguments" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query seculardharma "What is mindfulness?"
  [[ "$status" -eq 0 ]]
}

@test "query command accepts flag arguments" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K seculardharma -q "What is mindfulness?"
  [[ "$status" -eq 0 ]]
}

# Option parsing tests

@test "query command handles --top-k option" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -k 10
  [[ "$status" -eq 0 ]]
}

@test "query command handles --temperature option" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -t 0.5
  [[ "$status" -eq 0 ]]
}

@test "query command handles --model option" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -m claude-haiku-4-5
  [[ "$status" -eq 0 ]]
}

@test "query command handles --context-scope option" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -s 5
  [[ "$status" -eq 0 ]]
}

@test "query command handles --force-refresh flag" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -f
  [[ "$status" -eq 0 ]]
}

@test "query command handles --context-only flag" {
  set_mock_curl_response "$(jq -c '.query.context_only' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -c
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Contexts:"* ]]
}

@test "query command handles --max-tokens option" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -M 2000
  [[ "$status" -eq 0 ]]
}

@test "query command handles --prompt-template option" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -p scholarly
  [[ "$status" -eq 0 ]]
}

# Combined options test

@test "query command handles multiple options together" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -k 5 -t 0.7 -m gpt-5.1 -s 3
  [[ "$status" -eq 0 ]]
}

# Output format tests

@test "query command shows query ID in output" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test"
  [[ "$output" == *"Query ID:"* ]]
  [[ "$output" == *"q_abc123def456"* ]]
}

@test "query command shows answer in output" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test"
  [[ "$output" == *"Answer:"* ]]
  [[ "$output" == *"Mindfulness"* ]]
}

@test "query command indicates cached responses" {
  set_mock_curl_response "$(jq -c '.query.cached' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test"
  [[ "$output" == *"Cached response"* ]]
}

# Context-only mode tests

@test "query command shows contexts in context-only mode" {
  set_mock_curl_response "$(jq -c '.query.context_only' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" --context-only
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Contexts:"* ]]
  [[ "$output" == *"test_doc.md"* ]]
}

# Error handling tests

@test "query command handles missing knowledgebase error" {
  set_mock_curl_response "$(jq -c '.query.error_missing_kb' "$FIXTURES_FILE")" "404"

  run ./yatti-api query -K nonexistent_kb -q "test"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"404"* ]]
}

@test "query command handles unauthorized error" {
  set_mock_curl_response "$(jq -c '.query.error_unauthorized' "$FIXTURES_FILE")" "401"

  run ./yatti-api query -K test_kb -q "test"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"401"* ]]
}

@test "query command handles timeout error" {
  set_mock_curl_response "$(jq -c '.query.error_timeout' "$FIXTURES_FILE")" "504"

  run ./yatti-api query -K test_kb -q "test"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"504"* ]]
}

# Help text test

@test "query command shows help with -h flag" {
  run ./yatti-api query -h
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"--knowledgebase"* ]]
  [[ "$output" == *"--query"* ]]
}

# Large knowledgebase warning test

@test "query command suggests higher timeout for jakartapost" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K jakartapost -q "test"
  [[ "$output" == *"large knowledgebase"* ]]
  [[ "$output" == *"timeout 300"* ]]
}

#fin
