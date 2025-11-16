#!/usr/bin/env bats
# Unit tests for version_compare() function in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  source_yatti_functions
}

teardown() {
  teardown_test_env
}

# Test equal versions

@test "version_compare() returns 0 for equal versions" {
  run version_compare "1.2.3" "1.2.3"
  [[ "$status" -eq 0 ]]
}

@test "version_compare() returns 0 for equal major versions" {
  run version_compare "1.0.0" "1.0.0"
  [[ "$status" -eq 0 ]]
}

# Test greater than

@test "version_compare() returns 1 when first version is greater (major)" {
  run version_compare "2.0.0" "1.9.9"
  [[ "$status" -eq 1 ]]
}

@test "version_compare() returns 1 when first version is greater (minor)" {
  run version_compare "1.3.0" "1.2.9"
  [[ "$status" -eq 1 ]]
}

@test "version_compare() returns 1 when first version is greater (patch)" {
  run version_compare "1.2.4" "1.2.3"
  [[ "$status" -eq 1 ]]
}

# Test less than

@test "version_compare() returns 2 when first version is less (major)" {
  run version_compare "1.9.9" "2.0.0"
  [[ "$status" -eq 2 ]]
}

@test "version_compare() returns 2 when first version is less (minor)" {
  run version_compare "1.2.9" "1.3.0"
  [[ "$status" -eq 2 ]]
}

@test "version_compare() returns 2 when first version is less (patch)" {
  run version_compare "1.2.3" "1.2.4"
  [[ "$status" -eq 2 ]]
}

# Test unequal length versions

@test "version_compare() handles shorter first version" {
  run version_compare "1.2" "1.2.3"
  [[ "$status" -eq 2 ]]  # 1.2.0 < 1.2.3
}

@test "version_compare() handles shorter second version" {
  run version_compare "1.2.3" "1.2"
  [[ "$status" -eq 1 ]]  # 1.2.3 > 1.2.0
}

@test "version_compare() treats 1.2 as equal to 1.2.0" {
  run version_compare "1.2.0" "1.2"
  [[ "$status" -eq 0 ]]
}

# Edge cases

@test "version_compare() handles single digit versions" {
  run version_compare "2" "1"
  [[ "$status" -eq 1 ]]
}

@test "version_compare() handles version with many segments" {
  run version_compare "1.2.3.4.5" "1.2.3.4.6"
  [[ "$status" -eq 2 ]]
}

@test "version_compare() handles zero versions" {
  run version_compare "0.0.0" "0.0.1"
  [[ "$status" -eq 2 ]]
}

@test "version_compare() handles large version numbers" {
  run version_compare "10.20.30" "9.99.99"
  [[ "$status" -eq 1 ]]
}

# Real-world version comparisons

@test "version_compare() correctly compares 1.3.6 vs 1.4.0" {
  run version_compare "1.3.6" "1.4.0"
  [[ "$status" -eq 2 ]]  # 1.3.6 < 1.4.0
}

@test "version_compare() correctly compares 2.0.0 vs 1.9.9" {
  run version_compare "2.0.0" "1.9.9"
  [[ "$status" -eq 1 ]]  # 2.0.0 > 1.9.9
}

#fin
