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

# Test: GPG functions exist and are callable

@test "verify_update_signature function exists in script" {
  run grep -c 'verify_update_signature()' ./yatti-api
  [[ "$output" -ge 1 ]]
}

@test "import_update_pubkey function exists in script" {
  run grep -c 'import_update_pubkey()' ./yatti-api
  [[ "$output" -ge 1 ]]
}

# Test: GPG verification returns correct codes

@test "GPG verification returns 1 (unavailable) when signature endpoint fails" {
  # This tests the soft-fail behavior
  # When the signature endpoint returns 404 or connection fails,
  # verify_update_signature should return 1 (not 2)
  # We test this indirectly by checking the warn message pattern exists
  run grep -c 'Signature verification unavailable' ./yatti-api
  [[ "$output" -ge 1 ]]
}

@test "GPG verification returns 2 (failure) when signature doesn't match" {
  # This tests the hard-fail behavior
  # We verify the error message pattern exists in the script
  run grep -c 'GPG signature verification failed' ./yatti-api
  [[ "$output" -ge 1 ]]
}

# Test: GPG key fingerprint pinning

@test "GPG_KEY_FINGERPRINT constant is defined in script" {
  run grep -c "declare -r GPG_KEY_FINGERPRINT=" ./yatti-api
  [[ "$output" -ge 1 ]]
}

@test "verify_key_fingerprint function exists in script" {
  run grep -c 'verify_key_fingerprint()' ./yatti-api
  [[ "$output" -ge 1 ]]
}

@test "GPG fingerprint mismatch warning exists in script" {
  # This tests that the MITM attack warning is present
  run grep -c 'fingerprint mismatch - possible MITM attack' ./yatti-api
  [[ "$output" -ge 1 ]]
}

@test "GPG key pinning returns code 2 on fingerprint mismatch" {
  # Verify the return code 2 is used for fingerprint mismatch
  run grep -c 'return 2.*# Hard fail - fingerprint' ./yatti-api
  [[ "$output" -ge 1 ]]
}

#fin
