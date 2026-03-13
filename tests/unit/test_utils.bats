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

# Tests for noarg() function

@test "noarg() succeeds with valid argument" {
  run noarg "-K" "value"
  [[ "$status" -eq 0 ]]
}

#fin
