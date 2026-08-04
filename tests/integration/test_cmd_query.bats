#!/usr/bin/env bats
# Integration tests for cmd_query() in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"

  # Load fixtures
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
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

# Server-assigned default model: the payload must omit the model key entirely
# unless the user explicitly supplies -m/--model.

@test "query payload omits model key when -m not given" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"
  export MOCK_CURL_ARGS_FILE="${BATS_TEST_TMPDIR}/args"

  run ./yatti-api query -K test_kb -q "test"
  [[ "$status" -eq 0 ]]
  ! grep -q '"model"' "$MOCK_CURL_ARGS_FILE"
}

@test "query payload carries exactly the requested model when -m given" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"
  export MOCK_CURL_ARGS_FILE="${BATS_TEST_TMPDIR}/args"

  run ./yatti-api query -K test_kb -q "test" -m gpt-5.6-terra
  [[ "$status" -eq 0 ]]
  grep -q '"model": "gpt-5.6-terra"' "$MOCK_CURL_ARGS_FILE"
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

  run ./yatti-api query -K test_kb -q "test" -k 5 -t 0.7 -m gpt-5.6-terra -s 3
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

@test "query command suggests higher timeout for jawawa" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K jawawa -q "test"
  [[ "$output" == *"large knowledgebase"* ]]
  [[ "$output" == *"timeout 300"* ]]
}

# Numeric and KB-name validation (clear errors instead of cryptic crashes)

@test "query rejects non-numeric --top-k" {
  run ./yatti-api query -K test_kb -q "test" -k abc
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"--top-k"* ]]
  [[ "$output" == *"non-negative integer"* ]]
}

@test "query rejects decimal --top-k" {
  run ./yatti-api query -K test_kb -q "test" -k 2.5
  [[ "$status" -eq 22 ]]
}

@test "query rejects leading-zero --top-k (invalid JSON literal)" {
  run ./yatti-api query -K test_kb -q "test" -k 010
  [[ "$status" -eq 22 ]]
}

@test "query rejects non-numeric --temperature" {
  run ./yatti-api query -K test_kb -q "test" -t abc
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"--temperature"* ]]
}

@test "query rejects --temperature above 2.0" {
  run ./yatti-api query -K test_kb -q "test" -t 5
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"--temperature"* ]]
  [[ "$output" == *"2.0"* ]]
}

@test "query rejects --timeout above documented max 600" {
  run ./yatti-api query -K test_kb -q "test" --timeout 9999
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"600"* ]]
}

@test "query rejects invalid --max-tokens" {
  run ./yatti-api query -K test_kb -q "test" -M 0x10
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"--max-tokens"* ]]
}

@test "query rejects knowledgebase name with disallowed characters" {
  run ./yatti-api query -K "bad/name" -q "test"
  [[ "$status" -eq 22 ]]
  [[ "$output" == *"disallowed characters"* ]]
}

@test "query accepts dotted knowledgebase name (peraturan.go.id)" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K peraturan.go.id -q "test"
  [[ "$status" -eq 0 ]]
}

@test "query accepts valid numeric options at their bounds" {
  set_mock_curl_response "$(jq -c '.query.success' "$FIXTURES_FILE")" "200"

  run ./yatti-api query -K test_kb -q "test" -k 5 -t 2.0 --timeout 600 -s 3
  [[ "$status" -eq 0 ]]
}

#fin
