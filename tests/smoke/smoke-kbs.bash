#!/usr/bin/env bash
# smoke-kbs.bash - Live knowledgebase smoke test for yatti-api
#
# Runs a context-only RAG query against each live knowledgebase and reports
# per-KB pass/fail. KBs are discovered at runtime from `yatti-api kb list`,
# so the test adapts as the production KB roster changes.
#
# This script is intentionally outside the BATS suite (which is 100% mocked).
# It exercises the real https://yatti.id/v1 endpoint with the configured
# API key, so it requires network + auth and is not suitable for CI.
#
# Usage: ./tests/smoke/smoke-kbs.bash [-q QUERY] [-k KB,...] [-p] [-j N] [-v]

set -euo pipefail
shopt -s inherit_errexit shift_verbose extglob nullglob

#shellcheck disable=SC2155
declare -r SCRIPT_PATH=$(realpath -- "${BASH_SOURCE[0]}")
declare -r SCRIPT_NAME=${SCRIPT_PATH##*/}
declare -r SCRIPT_DIR=${SCRIPT_PATH%/*}
declare -r PROJECT_ROOT=${SCRIPT_DIR%/*/*}
declare -r YATTI_BIN=$PROJECT_ROOT/yatti-api

# Per-KB curated queries. Each query is picked to retrieve >=1 context
# reliably from that specific KB. Unknown KBs fall through to FALLBACK_QUERY.
declare -rA KB_QUERIES=(
  [appliedanthropology]='ethnography fieldwork methods'
  [biksuokusi]='who is biksu okusi'
  [jawawa]='javanese culture'
  [okusiassociates]='PMA company setup Indonesia'
  [okusimail]='email server configuration'
  [okusiresearch]='research projects'
  [ollama]='ollama model serving'
  [peraturan.go.id]='undang-undang pajak'
  [prosocial.world]='core design principles'
  [seculardharma]='secular dharma mindfulness'
  [smi]='overview'
  [uv]='uv package manager'
  [wayang.net]='wayang kulit puppet theatre'
)
declare -r FALLBACK_QUERY='overview'

if [[ -t 1 && -t 2 ]]; then
  declare -r RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[0;33m' CYAN=$'\033[0;36m' NC=$'\033[0m'
else
  declare -r RED='' GREEN='' YELLOW='' CYAN='' NC=''
fi

declare -i VERBOSE=0
declare -i JOBS=1
declare -- QUERY_OVERRIDE=''
declare -a USER_KBS=()

_msg() {
  local -- prefix
  case ${FUNCNAME[1]} in
    info)    prefix="${CYAN}◉${NC}" ;;
    success) prefix="${GREEN}✓${NC}" ;;
    warn)    prefix="${YELLOW}▲${NC}" ;;
    error)   prefix="${RED}✗${NC}" ;;
    *)       prefix='◉' ;;
  esac
  >&2 printf '%s %s\n' "$prefix" "$*"
}
info()    { ((VERBOSE)) || return 0; _msg "$@"; }
success() { _msg "$@"; }
# shellcheck disable=SC2329  # kept for symmetry; available for future use
warn()    { _msg "$@"; }
error()   { _msg "$@"; }
die()     { (($# < 2)) || error "${@:2}"; exit "${1:-1}"; }

usage() {
  cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Live smoke test against every yatti-api knowledgebase. Performs a
context-only query per KB and reports pass/fail. Discovers KBs at
runtime; per-KB queries are curated in KB_QUERIES at top of script.

Options:
  -q QUERY    Override query for ALL KBs (ignores per-KB curated map)
  -k LIST     Comma-separated KB list (default: live discovery)
  -p          Parallel mode (implies -j 4)
  -j N        Parallel job count (1 = sequential, default: 1)
  -v          Verbose: print first context snippet per KB
  -h          Show this help

Exit codes:
  0   all KBs returned >=1 context
  1   one or more KBs failed
  2   KB discovery failed
  3   bad arguments / prerequisites missing
EOF
}

parse_args() {
  local opt
  while getopts ':q:k:pj:vh' opt; do
    case $opt in
      q) QUERY_OVERRIDE=$OPTARG ;;
      k) IFS=',' read -ra USER_KBS <<< "$OPTARG" ;;
      p) ((JOBS > 1)) || JOBS=4 ;;
      j) [[ $OPTARG =~ ^[1-9][0-9]*$ ]] \
            || die 3 "Invalid -j ${OPTARG@Q}: positive integer required"
         JOBS=$OPTARG ;;
      v) VERBOSE=1 ;;
      h) usage; exit 0 ;;
      :) die 3 "Option -${OPTARG} requires an argument" ;;
      \?) die 3 "Unknown option -${OPTARG@Q}" ;;
    esac
  done
}

check_prereqs() {
  [[ -x $YATTI_BIN ]] || die 3 "yatti-api not executable at ${YATTI_BIN@Q}"
  command -v jq >/dev/null || die 3 'jq required (apt install jq)'
  [[ -n ${YATTI_API_KEY:-} || -r $HOME/.config/yatti-api/api_key ]] \
    || die 3 'No API key (set YATTI_API_KEY or run yatti-api configure)'
}

# Discover live KBs by parsing `yatti-api kb list` pretty output.
# Output is "name - description" per line; we take the first token.
discover_kbs() {
  local -a kbs=()
  local line
  while IFS= read -r line; do
    line=${line#"${line%%[![:space:]]*}"}
    [[ -n $line ]] || continue
    kbs+=("${line%% - *}")
  done < <("$YATTI_BIN" kb list 2>/dev/null)
  # Caller checks emptiness: die from a process substitution only kills
  # the subshell, so we cannot exit the parent from inside here.
  ((${#kbs[@]})) || return 0
  printf '%s\n' "${kbs[@]}"
}

# Test a single KB. Writes one PASS/FAIL line to stdout; returns 0 on PASS.
test_kb() {
  local -- kb=$1
  local -- query response reason='' src content snippet pass_line verbose_extra=''
  local -i n=0 t0=$SECONDS elapsed exit_code=0
  local -- stderr_file
  stderr_file=$(mktemp)
  # shellcheck disable=SC2064
  trap "rm -f '$stderr_file'" RETURN

  query=${QUERY_OVERRIDE:-${KB_QUERIES[$kb]:-$FALLBACK_QUERY}}
  if [[ -z ${KB_QUERIES[$kb]:-} && -z $QUERY_OVERRIDE ]]; then
    info "No curated query for ${kb@Q}; using fallback ${FALLBACK_QUERY@Q}"
  fi

  # yatti-api's format_json forces `jq --color-output`, so the captured
  # stdout contains ANSI escapes. Strip them before re-parsing with jq.
  if response=$(OUTPUT_FORMAT=json "$YATTI_BIN" query \
                  -K "$kb" -q "$query" -c 2>"$stderr_file" \
                  | sed $'s/\x1b\\[[0-9;]*[a-zA-Z]//g'); then
    n=$(jq -r '.data.contexts | length' <<< "$response" 2>/dev/null || echo 0)
    elapsed=$((SECONDS - t0))
    if ((n > 0)); then
      pass_line=$(printf '%-25s %sPASS%s  contexts=%-3d time=%ds' \
                    "$kb" "$GREEN" "$NC" "$n" "$elapsed")
      if ((VERBOSE)); then
        src=$(jq -r '.data.contexts[0].source // ""' <<< "$response")
        content=$(jq -r '.data.contexts[0].content // ""' <<< "$response")
        snippet=${content:0:80}
        snippet=${snippet//$'\n'/ }
        verbose_extra=$'\n  └─ source='${src##*/}$'\n     "'$snippet'..."'
      fi
      printf '%s%s\n' "$pass_line" "$verbose_extra"
      return 0
    fi
    elapsed=$((SECONDS - t0))
    printf '%-25s %sFAIL%s  reason=empty_contexts time=%ds\n' \
      "$kb" "$RED" "$NC" "$elapsed"
    return 1
  fi

  exit_code=$?
  elapsed=$((SECONDS - t0))
  if grep -qE 'Connection failed' "$stderr_file"; then
    reason=connection_failed
  elif reason=$(grep -oE 'HTTP [0-9]+' "$stderr_file" | head -1) && [[ -n $reason ]]; then
    reason=http_${reason##HTTP }
  elif grep -qi 'timeout' "$stderr_file"; then
    reason='timeout'
  else
    reason="exit_$exit_code"
  fi
  printf '%-25s %sFAIL%s  reason=%s time=%ds\n' \
    "$kb" "$RED" "$NC" "$reason" "$elapsed"
  return 1
}

main() {
  parse_args "$@"
  check_prereqs

  local -a kbs=()
  if ((${#USER_KBS[@]})); then
    kbs=("${USER_KBS[@]}")
  else
    mapfile -t kbs < <(discover_kbs)
    ((${#kbs[@]})) || die 2 'KB discovery failed (try: yatti-api kb list)'
  fi
  info "Smoke testing ${#kbs[@]} knowledgebase(s) with up to $JOBS parallel job(s)"

  local -i passed=0 failed=0 t_start=$SECONDS total_time
  local -- kb results_dir
  local -i i=0 running=0

  if ((JOBS > 1)); then
    results_dir=$(mktemp -d)
    # shellcheck disable=SC2064
    trap "rm -rf '$results_dir'" EXIT
    trap 'kill $(jobs -p) 2>/dev/null || :; exit 130' INT TERM
    for kb in "${kbs[@]}"; do
      if ((running >= JOBS)); then
        wait -n
        running=$((running - 1))
      fi
      (
        if test_kb "$kb"; then
          : >"$results_dir/$i.pass"
        else
          : >"$results_dir/$i.fail"
        fi
      ) &
      running+=1
      i+=1
    done
    wait
    passed=$(find "$results_dir" -name '*.pass' -printf . | wc -c)
    failed=$(find "$results_dir" -name '*.fail' -printf . | wc -c)
  else
    for kb in "${kbs[@]}"; do
      if test_kb "$kb"; then
        passed+=1
      else
        failed+=1
      fi
    done
  fi

  total_time=$((SECONDS - t_start))
  echo '---'
  if ((failed)); then
    error "passed: $passed/${#kbs[@]}   failed: $failed   total: ${total_time}s"
    exit 1
  fi
  success "passed: $passed/${#kbs[@]}   total: ${total_time}s"
  exit 0
}

main "$@"
#fin
