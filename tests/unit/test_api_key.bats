#!/usr/bin/env bats
# Unit tests for API key management functions in yatti-api

load '../helpers/test_helpers'
load '../helpers/mocks'

setup() {
  setup_test_env
  source_yatti_functions
  mock_install
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

@test "load_api_key() returns empty string when file doesn't exist" {
  rm -f "$API_KEY_FILE"
  result=$(load_api_key)
  [[ "$result" == "" ]]
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

# Tests for save_api_key()

@test "save_api_key() creates config directory if missing" {
  rm -rf "$CONFIG_DIR"
  save_api_key "new_key"
  [[ -d "$CONFIG_DIR" ]]
}

@test "save_api_key() creates API key file" {
  rm -f "$API_KEY_FILE"
  save_api_key "new_key_12345"
  assert_file_exists "$API_KEY_FILE"
}

@test "save_api_key() sets correct file permissions (600)" {
  save_api_key "secure_key"
  assert_file_mode "$API_KEY_FILE" "600"
}

@test "save_api_key() writes key to file" {
  save_api_key "test_api_key_content"
  content=$(cat "$API_KEY_FILE")
  [[ "$content" == "test_api_key_content" ]]
}

@test "save_api_key() overwrites existing key" {
  create_test_api_key "old_key"
  save_api_key "new_key"
  content=$(cat "$API_KEY_FILE")
  [[ "$content" == "new_key" ]]
}

@test "save_api_key() handles special characters in key" {
  save_api_key "key_with-special.chars_123"
  content=$(cat "$API_KEY_FILE")
  [[ "$content" == "key_with-special.chars_123" ]]
}

@test "save_api_key() creates file atomically with correct permissions" {
  # This test verifies the security fix - file should never exist with wrong permissions
  save_api_key "atomic_key"

  # File should exist with 600 permissions immediately
  assert_file_exists "$API_KEY_FILE"
  assert_file_mode "$API_KEY_FILE" "600"
}

@test "save_api_key() works when directory already exists" {
  mkdir -p "$CONFIG_DIR"
  save_api_key "key_with_existing_dir"
  assert_file_exists "$API_KEY_FILE"
}

@test "save_api_key() preserves exact key content (no trimming)" {
  save_api_key "key_with_spaces  "
  content=$(cat "$API_KEY_FILE")
  [[ "$content" == "key_with_spaces  " ]]
}

# Integration tests - load and save

@test "load and save API key roundtrip works" {
  test_key="roundtrip_test_key_9876"
  save_api_key "$test_key"
  loaded_key=$(load_api_key)
  [[ "$loaded_key" == "$test_key" ]]
}

@test "saving new key updates loaded value" {
  save_api_key "first_key"
  first=$(load_api_key)
  save_api_key "second_key"
  second=$(load_api_key)

  [[ "$first" == "first_key" ]]
  [[ "$second" == "second_key" ]]
}

#fin
