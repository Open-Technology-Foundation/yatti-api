#!/usr/bin/env bats
# Unit tests for utility functions in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  source_yatti_functions
}

teardown() {
  teardown_test_env
}

# Tests for trim() function

@test "trim() removes leading whitespace" {
  result=$(trim "  hello")
  [[ "$result" == "hello" ]]
}

@test "trim() removes trailing whitespace" {
  result=$(trim "hello  ")
  [[ "$result" == "hello" ]]
}

@test "trim() removes both leading and trailing whitespace" {
  result=$(trim "  hello  ")
  [[ "$result" == "hello" ]]
}

@test "trim() removes tabs and spaces" {
  result=$(trim $'	  hello world	  ')
  [[ "$result" == "hello world" ]]
}

@test "trim() handles empty string" {
  result=$(trim "")
  [[ "$result" == "" ]]
}

@test "trim() handles string with only whitespace" {
  result=$(trim "   ")
  [[ "$result" == "" ]]
}

@test "trim() preserves internal whitespace" {
  result=$(trim "  hello   world  ")
  [[ "$result" == "hello   world" ]]
}

# Tests for s() pluralization function

@test "s() returns empty string for 1" {
  result=$(s 1)
  [[ "$result" == "" ]]
}

@test "s() returns 's' for 0" {
  result=$(s 0)
  [[ "$result" == "s" ]]
}

@test "s() returns 's' for 2" {
  result=$(s 2)
  [[ "$result" == "s" ]]
}

@test "s() returns 's' for large numbers" {
  result=$(s 999)
  [[ "$result" == "s" ]]
}

@test "s() handles negative numbers" {
  result=$(s -1)
  [[ "$result" == "s" ]]
}

# Tests for noarg() function

@test "noarg() succeeds with valid argument" {
  run noarg "-K" "value"
  [[ "$status" -eq 0 ]]
}

@test "noarg() fails when argument is missing" {
  run noarg "-K"
  [[ "$status" -eq 2 ]]
}

@test "noarg() fails when next arg starts with dash" {
  run noarg "-K" "-q"
  [[ "$status" -eq 2 ]]
}

@test "noarg() error message includes option name" {
  run noarg "-K" "-q"
  [[ "$output" == *"-K"* ]]
}

# Tests for decp() function

@test "decp() prints VERBOSE variable by default" {
  VERBOSE=1
  result=$(decp)
  [[ "$result" == *"VERBOSE"* ]]
}

@test "decp() prints specified variable" {
  TEST_VAR="test_value"
  result=$(decp TEST_VAR)
  [[ "$result" == *"TEST_VAR"* ]]
}

@test "decp() handles undefined variable" {
  result=$(decp UNDEFINED_VAR_12345)
  [[ "$result" == "undefined" ]]
}

#fin
