#!/usr/bin/env bats
# Integration tests for cmd_help() in yatti-api

load '../helpers/test_helpers'
load '../helpers/mocks'

setup() {
  setup_test_env
  # Help command doesn't need API key or curl mocking
}

teardown() {
  teardown_test_env
}

# Help command tests

@test "help command displays usage" {
  run ./yatti-api help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage:"* ]] || [[ "$output" == *"USAGE:"* ]]
}

@test "help command lists all commands" {
  run ./yatti-api help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"query"* ]]
  [[ "$output" == *"configure"* ]]
  [[ "$output" == *"status"* ]]
  [[ "$output" == *"kb"* ]] || [[ "$output" == *"knowledgebase"* ]]
}

@test "help command shows query options" {
  run ./yatti-api help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"--model"* ]] || [[ "$output" == *"-m"* ]]
  [[ "$output" == *"--top-k"* ]] || [[ "$output" == *"-k"* ]]
}

@test "help command shows examples" {
  run ./yatti-api help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Example"* ]] || [[ "$output" == *"example"* ]]
}

@test "help command doesn't require API key" {
  # Remove API key file if it exists
  rm -f "${CONFIG_DIR}/api_key"

  run ./yatti-api help
  [[ "$status" -eq 0 ]]
}

@test "help command works with no arguments to script" {
  run ./yatti-api
  # Should show help or error with usage
  [[ "$status" -ne 0 ]] || [[ "$output" == *"Usage:"* ]]
}

#fin
