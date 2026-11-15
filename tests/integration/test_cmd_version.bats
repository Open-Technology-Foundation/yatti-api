#!/usr/bin/env bats
# Integration tests for cmd_version() in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  # Version command doesn't need API key or curl mocking. The key tests below
  # must see only the keys they create, never the caller's.
  unset XDG_CONFIG_HOME YATTI_API_KEY
}

teardown() {
  teardown_test_env
}

# Version command tests

@test "version command displays version" {
  # Get version from script
  local script_version
  script_version=$(grep "^declare -r VERSION=" ./yatti-api | cut -d"'" -f2)

  run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"$script_version"* ]]
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
  # Get version from script
  local script_version
  script_version=$(grep "^declare -r VERSION=" ./yatti-api | cut -d"'" -f2)

  VERBOSE=0 run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"$script_version"* ]]
}

# Key display: version output gets pasted into terminals and tickets, so it
# names where the key comes from and prints none of its characters (1.3.6
# showed the first 18, 1.4.4 the last 4; either leak forces a key rotation).

@test "version prints no characters of a key from the key file" {
  create_test_api_key "okusi_HEADabcdef0123456789_TAIL"

  run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" != *"TAIL"* ]]
  [[ "$output" != *"HEAD"* ]]
  [[ "$output" != *"okusi_"* ]]
  [[ "$output" != *"****"* ]]
}

@test "version names the key file when the key comes from it" {
  create_test_api_key "okusi_HEADabcdef0123456789_TAIL"

  run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"API Key: Configured (from ${API_KEY_FILE})"* ]]
}

@test "version names YATTI_API_KEY when the key comes from the environment" {
  rm -f "$API_KEY_FILE"

  YATTI_API_KEY="okusi_HEADabcdef0123456789_TAIL" run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"API Key: Configured (from YATTI_API_KEY)"* ]]
  [[ "$output" != *"TAIL"* ]]
}

@test "version reports a missing key" {
  rm -f "$API_KEY_FILE"

  run ./yatti-api version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"API Key: Not configured"* ]]
}

#fin
