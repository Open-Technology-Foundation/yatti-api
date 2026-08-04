#!/usr/bin/env bats
# Integration tests for stdin auto-detection edge cases
# Tests the various ways stdin input can be provided to query command

load '../helpers/test_helpers'

setup() {
  setup_test_env
  create_test_api_key "test_api_key_123456"
}

teardown() {
  teardown_test_env
}

# ============================================================
# Explicit stdin with -q - flag
# ============================================================

@test "query with -q - reads from stdin explicitly" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q1","response":"Answer","metadata":{}}}' "200"

  # Act - pipe input with explicit -q -
  run bash -c 'echo "test query" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Answer"* ]]
}

@test "query with -q - and empty stdin fails gracefully" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q2","response":"ok","metadata":{}}}' "200"

  # Act - empty stdin with explicit -q -
  run bash -c 'echo -n "" | ./yatti-api query -K testdb -q -'

  # Assert - should fail due to empty query
  [[ "$status" -ne 0 ]]
  [[ "$output" == *"Query text cannot be empty"* ]] || [[ "$output" == *"query"* ]]
}

@test "query with -q - handles whitespace-only stdin" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q3","response":"ok","metadata":{}}}' "200"

  # Act - whitespace only (note: script does not trim, so whitespace is valid)
  run bash -c 'echo "   " | ./yatti-api query -K testdb -q -'

  # Assert - should succeed (whitespace is not trimmed before validation)
  [[ "$status" -eq 0 ]]
}

@test "query with -q - handles single character input" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q4","response":"ok","metadata":{}}}' "200"

  # Act - single character
  run bash -c 'echo "?" | ./yatti-api query -K testdb -q -'

  # Assert - should succeed
  [[ "$status" -eq 0 ]]
}

@test "query with -q - handles multiline input" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q5","response":"ok","metadata":{}}}' "200"

  # Act - multiline input
  run bash -c 'printf "line 1\nline 2\nline 3" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Auto-detection (no -q flag, stdin piped)
# ============================================================

@test "query auto-detects stdin when piped without -q flag" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q6","response":"auto-detected","metadata":{}}}' "200"

  # Act - no -q flag, just piped input
  run bash -c 'echo "auto detect query" | ./yatti-api query -K testdb'

  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"auto-detected"* ]]
}

@test "query auto-detect ignores stdin when query already provided" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q7","response":"cmdline-query","metadata":{}}}' "200"
  export MOCK_CURL_ARGS_FILE="${BATS_TEST_TMPDIR}/args"

  # Act - query provided on command line AND stdin piped (stdin should be ignored)
  run bash -c 'echo "stdin query" | ./yatti-api query -K testdb -q "cmdline query"'

  # Assert - the payload actually SENT must carry the flag query, not stdin
  [[ "$status" -eq 0 ]]
  grep -q 'cmdline query' "$MOCK_CURL_ARGS_FILE"
  ! grep -q 'stdin query' "$MOCK_CURL_ARGS_FILE"
}

@test "query auto-detect ignores stdin when positional query provided" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q8","response":"positional-query","metadata":{}}}' "200"
  export MOCK_CURL_ARGS_FILE="${BATS_TEST_TMPDIR}/args"

  # Act - positional query AND stdin piped
  run bash -c 'echo "stdin query" | ./yatti-api query testdb "positional query"'

  # Assert - the payload actually SENT must carry the positional query
  [[ "$status" -eq 0 ]]
  grep -q 'positional query' "$MOCK_CURL_ARGS_FILE"
  ! grep -q 'stdin query' "$MOCK_CURL_ARGS_FILE"
}

@test "query auto-detect with empty stdin fails" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q9","response":"ok","metadata":{}}}' "200"

  # Act - empty stdin with auto-detect
  run bash -c 'echo -n "" | ./yatti-api query -K testdb'

  # Assert - should fail
  [[ "$status" -ne 0 ]]
}

# ============================================================
# Special characters and encoding
# ============================================================

@test "query via stdin handles unicode content" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q10","response":"ok","metadata":{}}}' "200"

  # Act - unicode content
  run bash -c 'echo "What is mindfulness? 正念 マインドフルネス" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query via stdin handles special shell characters" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q11","response":"ok","metadata":{}}}' "200"

  # Act - shell special characters (should be safely handled)
  run bash -c 'echo "What about \$HOME and \`commands\` and \"quotes\"?" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query via stdin handles JSON-like content" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q12","response":"ok","metadata":{}}}' "200"

  # Act - JSON-like query content
  run bash -c 'echo "Parse this: {\"key\": \"value\"}" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query via stdin handles newlines and tabs" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q13","response":"ok","metadata":{}}}' "200"

  # Act - content with tabs and newlines
  run bash -c 'printf "Question:\n\tWhat is this?\n\tHow does it work?" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Heredoc input
# ============================================================

@test "query via heredoc with -q - works" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q14","response":"heredoc-ok","metadata":{}}}' "200"

  # Act - heredoc input
  run bash -c './yatti-api query -K testdb -q - <<EOF
This is a heredoc query.
It has multiple lines.
EOF'

  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"heredoc-ok"* ]]
}

@test "query via heredoc with auto-detect works" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q15","response":"heredoc-auto","metadata":{}}}' "200"

  # Act - heredoc without -q flag (auto-detect)
  run bash -c './yatti-api query -K testdb <<EOF
Auto-detected heredoc query.
EOF'

  # Assert
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"heredoc-auto"* ]]
}

# ============================================================
# Combined with other options
# ============================================================

@test "query via stdin works with --top-k option" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q16","response":"ok","metadata":{}}}' "200"

  # Act
  run bash -c 'echo "test query" | ./yatti-api query -K testdb -q - --top-k 10'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query via stdin works with --temperature option" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q17","response":"ok","metadata":{}}}' "200"

  # Act
  run bash -c 'echo "test query" | ./yatti-api query -K testdb -q - --temperature 0.5'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query via stdin works with --context-only option" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q18","contexts":[{"content":"ctx1"}],"metadata":{}}}' "200"

  # Act
  run bash -c 'echo "test query" | ./yatti-api query -K testdb -q - --context-only'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query via stdin works with multiple combined options" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q19","response":"ok","metadata":{}}}' "200"

  # Act
  run bash -c 'echo "test query" | ./yatti-api query -K testdb -q - -k 15 -t 0.3 -m gpt-5.6-terra --max-tokens 500'

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Process substitution and command output
# ============================================================

@test "query accepts input from command substitution via pipe" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q20","response":"ok","metadata":{}}}' "200"

  # Act - use cat to simulate process
  run bash -c 'cat <<< "command output query" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
}

@test "query handles very long single line via stdin" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q21","response":"ok","metadata":{}}}' "200"

  # Act - 1000 character single line
  run bash -c 'printf "%1000s" | tr " " "x" | ./yatti-api query -K testdb -q -'

  # Assert
  [[ "$status" -eq 0 ]]
}

# ============================================================
# Edge cases with file input precedence
# ============================================================

@test "query file input (-Q) takes precedence over stdin" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q22","response":"file-wins","metadata":{}}}' "200"
  export MOCK_CURL_ARGS_FILE="${BATS_TEST_TMPDIR}/args"
  query_file="${BATS_TEST_TMPDIR}/query.txt"
  echo "query from file" > "$query_file"

  # Act - both file and stdin provided
  run bash -c "echo 'query from stdin' | ./yatti-api query -K testdb -Q '$query_file'"

  # Assert - the payload actually SENT must carry the file content
  [[ "$status" -eq 0 ]]
  grep -q 'query from file' "$MOCK_CURL_ARGS_FILE"
  ! grep -q 'query from stdin' "$MOCK_CURL_ARGS_FILE"
}

@test "query -q flag takes precedence over auto-detected stdin" {
  # Arrange
  set_mock_curl_response '{"data":{"query_id":"q23","response":"explicit-wins","metadata":{}}}' "200"
  export MOCK_CURL_ARGS_FILE="${BATS_TEST_TMPDIR}/args"

  # Act - -q with explicit value and stdin
  run bash -c 'echo "stdin content" | ./yatti-api query -K testdb -q "explicit query"'

  # Assert - the payload actually SENT must carry the explicit query
  [[ "$status" -eq 0 ]]
  grep -q 'explicit query' "$MOCK_CURL_ARGS_FILE"
  ! grep -q 'stdin content' "$MOCK_CURL_ARGS_FILE"
}

#fin
