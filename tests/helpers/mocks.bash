#!/usr/bin/env bash
# Mock Functions for YaTTi API Client Tests
# Provides mock implementations of external commands (curl, jq, etc.)

# Global mock state
declare -g MOCK_CURL_RESPONSE=""
declare -g MOCK_CURL_HTTP_CODE="200"
declare -g MOCK_CURL_FAIL=0
declare -A MOCK_CURL_RESPONSES  # URL -> response mapping

# Mock curl - intercepts HTTP requests
mock_curl() {
  # Enable mock mode
  eval 'curl() {
    local -a args=("$@")
    local -- url="" method="GET" data="" write_out=""
    local -i i=0

    # Parse curl arguments
    while ((i < ${#args[@]})); do
      case "${args[i]}" in
        -X)
          ((i++))
          method="${args[i]}"
          ;;
        -d|--data)
          ((i++))
          data="${args[i]}"
          ;;
        -w)
          ((i++))
          write_out="${args[i]}"
          ;;
        -s|-f|-L)
          # Silent, fail, location - ignore for mocking
          ;;
        -H)
          # Headers - skip for now
          ((i++))
          ;;
        http*)
          url="${args[i]}"
          ;;
      esac
      ((i++))
    done

    # Check if we should fail
    if ((MOCK_CURL_FAIL)); then
      return 1
    fi

    # Get response for this URL
    local -- response_body="$MOCK_CURL_RESPONSE"
    local -- response_code="$MOCK_CURL_HTTP_CODE"

    # Check for URL-specific responses
    for mock_url in "${!MOCK_CURL_RESPONSES[@]}"; do
      if [[ "$url" == *"$mock_url"* ]]; then
        response_body="${MOCK_CURL_RESPONSES[$mock_url]}"
        break
      fi
    done

    # Output response
    if [[ -n "$write_out" ]]; then
      # Include HTTP code in output (matches yatti-api pattern)
      printf "%s\n%s%s\n" "$response_body" "__HTTP_CODE__" "$response_code"
    else
      echo "$response_body"
    fi

    # Return success/failure based on HTTP code
    if [[ "$response_code" -ge 200 ]] && [[ "$response_code" -lt 300 ]]; then
      return 0
    else
      return 1
    fi
  }'
}

# Set mock curl response
set_mock_curl_response() {
  local -- body="${1:-{}}"
  local -- code="${2:-200}"
  MOCK_CURL_RESPONSE="$body"
  MOCK_CURL_HTTP_CODE="$code"
}

# Set URL-specific mock response
set_mock_curl_url_response() {
  local -- url="$1"
  local -- body="$2"
  MOCK_CURL_RESPONSES["$url"]="$body"
}

# Make curl fail
set_mock_curl_fail() {
  MOCK_CURL_FAIL=1
}

# Reset curl mock
reset_mock_curl() {
  MOCK_CURL_RESPONSE=""
  MOCK_CURL_HTTP_CODE="200"
  MOCK_CURL_FAIL=0
  unset MOCK_CURL_RESPONSES
  declare -gA MOCK_CURL_RESPONSES
  unset -f curl 2>/dev/null || true
}

# Mock jq - passes through for basic testing
# In real tests, we use actual jq since it's a core dependency
mock_jq() {
  eval 'jq() {
    # For testing, we can use actual jq or provide simple mocks
    command jq "$@"
  }'
}

# Mock install command for testing file creation
mock_install() {
  eval 'install() {
    local -- mode="" source="" dest=""
    local -i i=0
    local -a args=("$@")

    while ((i < ${#args[@]})); do
      case "${args[i]}" in
        -m)
          ((i++))
          mode="${args[i]}"
          ;;
        *)
          if [[ -z "$source" ]]; then
            source="${args[i]}"
          elif [[ -z "$dest" ]]; then
            dest="${args[i]}"
          fi
          ;;
      esac
      ((i++))
    done

    # Create destination file
    if [[ -n "$dest" ]]; then
      if [[ "$source" == "/dev/null" ]]; then
        touch "$dest"
      else
        cp "$source" "$dest"
      fi

      # Set permissions if specified
      if [[ -n "$mode" ]]; then
        chmod "$mode" "$dest"
      fi
    fi
  }'
}

# Mock mktemp
declare -g MOCK_TEMP_FILE=""
mock_mktemp() {
  eval 'mktemp() {
    local -- template="${1:-/tmp/tmp.XXXXXX}"
    # Create actual temp file in BATS tmpdir
    local -- tempfile="${BATS_TEST_TMPDIR}/mocktemp_$$_${RANDOM}"
    touch "$tempfile"
    MOCK_TEMP_FILE="$tempfile"
    echo "$tempfile"
  }'
}

# Get the last temp file created by mock
get_mock_temp_file() {
  echo "$MOCK_TEMP_FILE"
}

# Mock realpath (for systems without it)
mock_realpath() {
  eval 'realpath() {
    local -- path="$2"
    # Simple mock - just echo the path
    if [[ "$path" == /* ]]; then
      echo "$path"
    else
      echo "$PWD/$path"
    fi
  }'
}

# Generate mock API response for status endpoint
mock_api_status_response() {
  cat <<'EOF'
{
  "status": "ok",
  "version": "1.0.0",
  "timestamp": "2025-01-08T12:00:00Z"
}
EOF
}

# Generate mock API response for knowledgebases list
mock_api_knowledgebases_response() {
  cat <<'EOF'
{
  "data": {
    "knowledgebases": [
      {
        "name": "seculardharma",
        "description": "Secular Dharma teachings"
      },
      {
        "name": "jakartapost",
        "description": "Jakarta Post archives"
      }
    ]
  }
}
EOF
}

# Generate mock API response for query
mock_api_query_response() {
  local -- query_id="${1:-q_12345}"
  cat <<EOF
{
  "data": {
    "query_id": "$query_id",
    "response": "This is a test response to your query.",
    "metadata": {
      "cached": false,
      "model": "gpt-4o",
      "tokens": 150
    },
    "contexts": [
      {
        "source": "test_doc.md",
        "content": "This is context from the document."
      }
    ]
  }
}
EOF
}

# Generate mock API response for version check
mock_api_version_check_response() {
  local -- current_version="${1:-1.3.6}"
  local -- latest_version="${2:-1.3.7}"
  local -i update_available=0

  if [[ "$latest_version" != "$current_version" ]]; then
    update_available=1
  fi

  cat <<EOF
{
  "data": {
    "current_version": "$current_version",
    "latest_version": "$latest_version",
    "update_available": $([ $update_available -eq 1 ] && echo "true" || echo "false"),
    "changelog": {
      "$latest_version": {
        "changes": [
          "Bug fixes and improvements"
        ]
      }
    }
  }
}
EOF
}

# Generate mock error response
mock_api_error_response() {
  local -- code="${1:-400}"
  local -- message="${2:-Bad Request}"
  cat <<EOF
{
  "error": {
    "code": $code,
    "message": "$message"
  }
}
EOF
}

#fin
