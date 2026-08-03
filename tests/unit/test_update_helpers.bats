#!/usr/bin/env bats
# Behavioral tests for the update-flow helpers: fetch_url() and the GPG
# public-key pinning path. Uses the argv-recording mock curl; GPG tests
# generate a real throwaway key so fingerprint logic is exercised, not grepped.

load '../helpers/test_helpers'

setup() {
  setup_test_env
  source_yatti_functions
}

teardown() {
  teardown_test_env
}

# Generate a throwaway ed25519 key, export armored pubkey to $1.
# Prints the key's fingerprint.
generate_test_pubkey() {
  local -- out=$1 home
  home=$(mktemp -d "${BATS_TEST_TMPDIR}/gnupg.XXXXXX")
  chmod 700 "$home"
  gpg --homedir "$home" --batch --passphrase '' --quick-gen-key \
    'YaTTi Test <test@test.invalid>' ed25519 cert never 2>/dev/null
  gpg --homedir "$home" --armor --export > "$out" 2>/dev/null
  gpg --homedir "$home" --with-colons --fingerprint 2>/dev/null \
    | awk -F: '/^fpr:/{print $10; exit}'
}

# ============================================================
# fetch_url
# ============================================================

@test "fetch_url passes connect and max-time timeouts to curl" {
  export MOCK_CURL_ARGS_FILE="${BATS_TEST_TMPDIR}/args"
  set_mock_curl_response 'body' "200"

  run fetch_url "http://test.yatti.local/v1/client/pubkey" "${BATS_TEST_TMPDIR}/out"

  [[ "$status" -eq 0 ]]
  grep -qx -- '--connect-timeout' "$MOCK_CURL_ARGS_FILE"
  grep -qx -- '--max-time' "$MOCK_CURL_ARGS_FILE"
}

@test "fetch_url writes body to the target file" {
  set_mock_curl_response 'expected-content' "200"

  run fetch_url "http://test.yatti.local/v1/client/pubkey" "${BATS_TEST_TMPDIR}/out"

  [[ "$status" -eq 0 ]]
  [[ "$(cat "${BATS_TEST_TMPDIR}/out")" == 'expected-content' ]]
}

@test "fetch_url propagates curl failure" {
  set_mock_curl_fail

  run fetch_url "http://test.yatti.local/v1/client/pubkey" "${BATS_TEST_TMPDIR}/out"

  [[ "$status" -ne 0 ]]
}

# ============================================================
# GPG pubkey pinning
# ============================================================

@test "pubkey_file_fingerprint extracts the fingerprint of a key file" {
  skip_if_missing gpg
  local -- keyfile="${BATS_TEST_TMPDIR}/test-pubkey.asc" expected_fp
  expected_fp=$(generate_test_pubkey "$keyfile")
  [[ -n "$expected_fp" ]]

  run pubkey_file_fingerprint "$keyfile"

  [[ "$status" -eq 0 ]]
  [[ "$output" == "$expected_fp" ]]
}

@test "import_update_pubkey hard-fails (2) on fingerprint mismatch" {
  skip_if_missing gpg
  # Downloaded key is valid GPG but NOT the pinned YaTTi key
  local -- keyfile="${BATS_TEST_TMPDIR}/wrong-key.asc"
  generate_test_pubkey "$keyfile" >/dev/null
  export MOCK_CURL_RESPONSE
  MOCK_CURL_RESPONSE=$(cat "$keyfile")
  export MOCK_CURL_HTTP_CODE=200
  local -- gpg_home
  gpg_home=$(mktemp -d "${BATS_TEST_TMPDIR}/gnupg-import.XXXXXX")
  chmod 700 "$gpg_home"

  run import_update_pubkey "$gpg_home"

  [[ "$status" -eq 2 ]]
  [[ "$output" == *'fingerprint mismatch'* ]]
  # Poisoned key must not be cached for reuse
  [[ ! -f "$CONFIG_DIR/pubkey.asc" ]]
}

@test "import_update_pubkey soft-fails (1) when download fails" {
  skip_if_missing gpg
  set_mock_curl_fail
  local -- gpg_home
  gpg_home=$(mktemp -d "${BATS_TEST_TMPDIR}/gnupg-import.XXXXXX")
  chmod 700 "$gpg_home"

  run import_update_pubkey "$gpg_home"

  [[ "$status" -eq 1 ]]
}

@test "import_update_pubkey soft-fails (1) on non-key content" {
  skip_if_missing gpg
  set_mock_curl_response '<html>404 not found</html>' "200"
  local -- gpg_home
  gpg_home=$(mktemp -d "${BATS_TEST_TMPDIR}/gnupg-import.XXXXXX")
  chmod 700 "$gpg_home"

  run import_update_pubkey "$gpg_home"

  [[ "$status" -eq 1 ]]
  [[ ! -f "$CONFIG_DIR/pubkey.asc" ]]
}

#fin
