#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function tapsum_help () {
  local INVO="$(basename "$0")"
  local HELP="
    tapsum: run selected tests, log the result, and summarize it.

    Invocation:
      * $INVO --help
        Show this summary.
      * $INVO
        Run all tests and show an overall summary.
      * $INVO 304
        Run test/304.js and show its error summary.
      * $INVO --sumerr 304.tap.err
        Summarize the errors of test's last recording.
      * $INVO --sumerr
        Summarize errors of all recorded test results.
      * $INVO --sumerr 304.tap.err
        Summarize errors of this test's last recording.
      * $INVO --versions
        Show versions of node, npm, linux distro and the git HEAD hash.
    "
  local NL=$'\n'
  HELP="${HELP//$NL    /$NL}"
  HELP="${HELP%$NL}"
  HELP="${HELP#$NL}"
  echo "$HELP"
}


function tapsum_main () {
  case "$PWD" in
    */test ) cd ..;;
  esac
  case "$1" in
    --sumerr ) summarize_error_logs "${@:2}"; return $?;;
    --versions ) summarize_versions; return $?;;
    --help | -h ) tapsum_help; return $?;;
  esac

  local TEST_FN=
  local TESTS=()
  tapsum_parse_args "$@" || return $?

  local TAP_BIN='require.resolve("tap/" + require("tap/package.json").bin.tap)'
  TAP_BIN="$(nodejs -p "$TAP_BIN")"
  [ -f "$TAP_BIN" ] || return 4$(
    echo 'E: cannot find tap script. "npm i -d" might solve this.' >&2)
  local BASEDIR_RGX="$(dirname "$PWD" | sed -re 's~[^A-Za-z0-9_]~\\&~g')"
  local LOG_FN=
  local FAIL_LOGS=()
  for TEST_FN in "${TESTS[@]}"; do
    LOG_FN="${TEST_FN%.js}.tap.err"
    if [ ! -f "$TEST_FN" ]; then
      <<<"E: test file doesn't exist: $TEST_FN" tee -- "$LOG_FN" >&2
      FAIL_LOGS+=( "$LOG_FN" )
      continue
    fi
    </dev/null nodejs "$TAP_BIN" "$TEST_FN" 2>&1 | sed -re "
      s:$BASEDIR_RGX/:/…/:g" | tee -- "$LOG_FN"
    if tapsum_summarize_log "$LOG_FN"; then
      mv --no-target-directory -- "$LOG_FN" "${LOG_FN%.err}.log"
    else
      FAIL_LOGS+=( "$LOG_FN" )
    fi
  done

  local FAIL_CNT="${#FAIL_LOGS[@]}"
  if [ "$FAIL_CNT" == 0 ]; then
    echo "+OK ${#TESTS[@]}"
    return 0
  fi

  if [ "$FAIL_CNT" -gt 1 ]; then
    tapsum_chapter_sep
    summarize_error_logs "${FAIL_LOGS[@]}"
  fi
  summarize_versions
  echo "-ERR $FAIL_CNT"
  return "$FAIL_CNT"
}


function summarize_error_logs () {
  local FAIL_LOGS=( "$@" )
  [ "$#" == 0 ] && FAIL_LOGS=( *.tap.err )
  for LOG_FN in "${FAIL_LOGS[@]}"; do
    grep -Pe '^\s*(·|!) ' "$LOG_FN"
  done
}


function tapsum_parse_args () {
  [ "$#" == 0 ] && TESTS=( test/*.js )
  for TEST_FN in "$@"; do
    # normalize test file names
    case "$TEST_FN" in
      -* ) return 2$(echo "E: unsupported option: $TEST_FN" >&2);;
    esac
    case "${TEST_FN#test/}" in
      *'/'* ) ;;
      * )
        # no slash in name or starts with "test/"
        # => no external path => normalize
        TEST_FN="${TEST_FN%.}"
        case "$TEST_FN" in
          # shorthand: dot at end = *.js, to save on shell quotes.
          *':' ) TEST_FN="${TEST_FN%:}*.js";;
        esac
        TEST_FN="test/${TEST_FN#test/}"
        TEST_FN="${TEST_FN%.js}.js"
        ;;
    esac
    case "$TEST_FN" in
      *'*'* )
        readarray -tO "${#TESTS[@]}" TESTS < <(find test/ -path "$TEST_FN");;
      * ) TESTS+=( "$TEST_FN" )
    esac
  done
}


function tapsum_summarize_log () {
  local LOG_FN="$1"
  TAP_RESULT="$(tail -n 5 -- "$LOG_FN" \
    | grep -Pe '^(not |)ok \d+ - ' | tail -n 1)"
  case "$TAP_RESULT" in
    "ok 1 - "* )
      TAP_RESULT="${TAP_RESULT%% - *}"
      echo "· $TAP_RESULT"
      return 0;;
  esac

  tapsum_chapter_sep
  grep -Pe '^\s+#' -- "$LOG_FN" | tr '\n' '\r' | sed -re 's~\r~\n~g
    s~([ \t]+)# Subtest: ([^\n]+)\n\1#? ?failed ([0-9]+) of ([0-9]+) tests|$\
      ~\1\r! \3/\4 failed in \2~g
    s~\n\s+# time=\S+$~~g
    s~\n\s+(# time=\S+\n)~ \1~g
    ' | sed -re '
    /^\s*# failed ([0-9]+ |of )+tests(\s+|#|time=\S+)*$/d
    s~^[ \t]{4}([ \t]*)# ?~\1· ~g
    s~^[ \t]{4}([ \t]*)\r~\1~g
    s~\r~«~g;s~\t~»~g
    ' | tee --append -- "$LOG_FN"
  return 1
}


function tapsum_chapter_sep () {
    echo; echo '________________________________________'
}


function summarize_versions () {
  echo -n '· versions: nodejs '
  nodejs --version | tr -d '\n'
  echo -n ', npm '
  npm --version | tr -d '\n'
  echo -n ", $(lsb_release -sd) ($(lsb_release -sc))"
  echo -n ', git HEAD='
  local GIT_REV="$(git rev-parse HEAD 2>/dev/null)"
  GIT_REV="${GIT_REV:0:7}"
  echo "${GIT_REV:-none?}"
  return 0
}












[ "$1" == --lib ] && return 0; tapsum_main "$@"; exit $?
