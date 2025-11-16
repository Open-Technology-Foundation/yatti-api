#!/usr/bin/env bats
# Integration tests for cmd_version() in yatti-api

load '../helpers/test_helpers'
load '../helpers/mocks'

setup() {
  setup_test_env
  # Version command doesn't need API key or curl mocking
}

teardown() {
  teardown_test_env
}

# Version command tests

@test "version command displays version" {
  run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"1.4.0"* ]]
}

@test "version command format is correct" {
  run ./yatti-api version
  [[ "$status" -eq 0 ]]
  # Should contain "YaTTi API Client" or "yatti-api"
  [[ "$output" == *"yatti-api"* ]] || [[ "$output" == *"YaTTi"* ]]
}

@test "version command matches VERSION constant" {
  run ./yatti-api version
  [[ "$status" -eq 0 ]]

  # Extract version from script
  local script_version
  script_version=$(grep "^declare -r VERSION=" ./yatti-api | cut -d"'" -f2)

  [[ "$output" == *"$script_version"* ]]
}

@test "version command doesn't require API key" {
  # Remove API key file if it exists
  rm -f "${CONFIG_DIR}/api_key"

  run ./yatti-api version
  [[ "$status" -eq 0 ]]
}

@test "version command works in non-verbose mode" {
  VERBOSE=0 run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"1.4.0"* ]]
}

#fin
