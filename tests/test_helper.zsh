emulate -L zsh

typeset -gi TESTS_RUN=0
typeset -gi TESTS_FAILED=0
typeset -ga __bindkey_set_calls=()
typeset -ga __zle_calls=()
typeset -gA __bindkey_bindings=()

test::reset_stubs() {
  __bindkey_set_calls=()
  __zle_calls=()
  __bindkey_bindings=(
    '^G' 'send-break'
    '^X^G' 'undefined-key'
  )
}

function zle() {
  __zle_calls+=("$*")
  return 0
}

function bindkey() {
  if [[ "$#" -eq 1 ]]; then
    print -r -- "$1 ${__bindkey_bindings[$1]:-undefined-key}"
    return 0
  fi

  if [[ "$#" -eq 2 ]]; then
    __bindkey_set_calls+=("$1:$2")
    __bindkey_bindings[$1]="$2"
    return 0
  fi

  return 0
}

test::load_plugin() {
  test::reset_stubs
  source "${HALFPIPE_PLUGIN:-${ROOT_DIR}/halfpipe.zsh}"
}

test::set_binding() {
  __bindkey_bindings[$1]="$2"
}

test::pass() {
  TESTS_RUN+=1
  print -r -- "ok - $1"
}

test::fail() {
  TESTS_RUN+=1
  TESTS_FAILED+=1
  print -r -- "not ok - $1"
  shift
  for line in "$@"; do
    print -r -- "  $line"
  done
}

test::assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  if [[ "$actual" == "$expected" ]]; then
    test::pass "$label"
  else
    test::fail "$label" "expected: ${(qqq)expected}" "actual:   ${(qqq)actual}"
  fi
}

test::assert_array_eq() {
  local label="$1"
  shift
  local -a expected=("${(@P)1}")
  local -a actual=("${(@P)2}")

  if [[ "${(j:\n:)actual}" == "${(j:\n:)expected}" ]]; then
    test::pass "$label"
  else
    test::fail "$label" \
      "expected: ${(qqq)${(j:,:)expected}}" \
      "actual:   ${(qqq)${(j:,:)actual}}"
  fi
}

test::assert_contains() {
  local label="$1"
  local haystack="$2"
  local needle="$3"

  if [[ "$haystack" == *"$needle"* ]]; then
    test::pass "$label"
  else
    test::fail "$label" "expected ${(qqq)haystack} to contain ${(qqq)needle}"
  fi
}

test::assert_not_eq() {
  local label="$1"
  local unexpected="$2"
  local actual="$3"

  if [[ "$actual" != "$unexpected" ]]; then
    test::pass "$label"
  else
    test::fail "$label" "did not expect: ${(qqq)unexpected}" "actual:         ${(qqq)actual}"
  fi
}
