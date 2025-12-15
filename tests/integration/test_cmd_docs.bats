#!/usr/bin/env bats
# Integration tests for cmd_docs() in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
}

# User docs tests

@test "docs command defaults to user docs" {
  set_mock_curl_response "$(jq -c '.docs.user' "$FIXTURES_FILE")" "200"
  run ./yatti-api docs
  [[ "$status" -eq 0 ]]
}

@test "docs user works explicitly" {
  set_mock_curl_response "$(jq -c '.docs.user' "$FIXTURES_FILE")" "200"
  run ./yatti-api docs user
  [[ "$status" -eq 0 ]]
}

@test "docs user raw format works" {
  set_mock_curl_response "# YaTTi User Guide" "200"
  run ./yatti-api docs user raw
  [[ "$status" -eq 0 ]]
}

@test "docs aliases work (doc)" {
  set_mock_curl_response "$(jq -c '.docs.user' "$FIXTURES_FILE")" "200"
  run ./yatti-api doc
  [[ "$status" -eq 0 ]]
}

# API docs tests

@test "docs api works" {
  set_mock_curl_response "$(jq -c '.docs.api' "$FIXTURES_FILE")" "200"
  run ./yatti-api docs api
  [[ "$status" -eq 0 ]]
}

@test "docs api raw format extracts content" {
  set_mock_curl_response "$(jq -c '.docs.api' "$FIXTURES_FILE")" "200"
  run ./yatti-api docs api raw
  # Raw format pipes through jq to extract .data.content
  [[ "$status" -eq 0 ]]
}

# Technical docs tests

@test "docs technical works" {
  set_mock_curl_response "$(jq -c '.docs.technical' "$FIXTURES_FILE")" "200"
  run ./yatti-api docs technical
  [[ "$status" -eq 0 ]]
}

@test "docs technical aliases work (dev)" {
  set_mock_curl_response "$(jq -c '.docs.technical' "$FIXTURES_FILE")" "200"
  run ./yatti-api docs dev
  [[ "$status" -eq 0 ]]
}

@test "docs technical raw format extracts content" {
  set_mock_curl_response "$(jq -c '.docs.technical' "$FIXTURES_FILE")" "200"
  run ./yatti-api docs technical raw
  # Raw format pipes through jq to extract .data.content
  [[ "$status" -eq 0 ]]
}

# List and help tests

@test "docs list shows available docs" {
  run ./yatti-api docs list
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"user"* ]]
  [[ "$output" == *"api"* ]]
  [[ "$output" == *"technical"* ]]
}

# Error handling

@test "docs handles API errors" {
  set_mock_curl_response "$(jq -c '.errors."500_server_error"' "$FIXTURES_FILE")" "500"
  run ./yatti-api docs api
  [[ "$status" -eq 1 ]]
}

@test "docs handles network failure" {
  set_mock_curl_fail
  run ./yatti-api docs api
  [[ "$status" -ne 0 ]]
}

#fin
