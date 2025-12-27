#!/usr/bin/env bats
# Unit tests for API key management functions in yatti-api
# shellcheck disable=SC2030,SC2031  # BATS runs each @test in a subshell by design

load '../helpers/test_helpers'
load '../helpers/mocks'

setup() {
  setup_test_env
  source_yatti_functions
}

teardown() {
  teardown_test_env
  reset_mock_curl
}

# Tests for load_api_key()

@test "load_api_key() reads from file when it exists" {
  create_test_api_key "test_key_from_file"
  result=$(load_api_key)
  [[ "$result" == "test_key_from_file" ]]
}

@test "load_api_key() prefers file over environment variable" {
  create_test_api_key "file_key"
  export YATTI_API_KEY="env_key"
  result=$(load_api_key)
  [[ "$result" == "file_key" ]]
}

@test "load_api_key() uses environment variable when file missing" {
  rm -f "$API_KEY_FILE"
  export YATTI_API_KEY="env_key_12345"
  result=$(load_api_key)
  [[ "$result" == "env_key_12345" ]]
}

@test "load_api_key() handles empty file" {
  mkdir -p "$CONFIG_DIR"
  touch "$API_KEY_FILE"
  result=$(load_api_key)
  [[ "$result" == "" ]]
}

#fin
