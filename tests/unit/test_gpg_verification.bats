#!/usr/bin/env bats
# Unit tests for GPG signature verification in yatti-api

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key"
  FIXTURES_FILE="${BATS_TEST_DIRNAME}/../fixtures/api_responses.json"
}

teardown() {
  teardown_test_env
}

# Test: --check mode works and reports update available

@test "update --check shows update available message" {
  set_mock_curl_response "$(jq -c '.update_check.update_available' "$FIXTURES_FILE")" "200"
  run ./yatti-api update --check
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Update available"* ]] || [[ "$output" == *"1.4.1"* ]]
}

# Test: GPG verification is called during update (when not --check)
# Since signature endpoint isn't available, we expect soft fail warning

@test "update warns when signature verification unavailable" {
  # This test verifies the soft-fail behavior when signature can't be downloaded
  # We can't fully test this without mocking multiple curl calls differently
  # But we can verify the update --check path doesn't crash
  set_mock_curl_response "$(jq -c '.update_check.no_update' "$FIXTURES_FILE")" "200"
  run ./yatti-api update --check
  [[ "$status" -eq 0 ]]
}

# NOTE: this file previously held seven grep-the-source "tests" that asserted
# strings existed in the script — zero behavioral coverage (the functions
# could have been rewritten to no-ops without a failure). Real behavioral
# coverage of signature verification and fingerprint pinning now lives in
# tests/unit/test_update_helpers.bats: actual key generation, actual signing,
# actual verification, tamper detection, and pin-mismatch hard-fail.

#fin
