#!/usr/bin/env zsh
emulate -L zsh
setopt err_return pipe_fail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"

mutants_run=0
mutants_failed=0

run_mutant() {
  local name="$1"
  local perl_expr="$2"
  local expected_failure="$3"
  local mutant_file
  local output=''
  local exit_code=0

  mutant_file=$(mktemp "${TMPDIR:-/tmp}/halfpipe-mutant.XXXXXX")
  cp "${ROOT_DIR}/halfpipe.zsh" "$mutant_file"
  perl -0pi -e "$perl_expr" "$mutant_file"

  output=$(HALFPIPE_PLUGIN="$mutant_file" zsh "${SCRIPT_DIR}/run.zsh" 2>&1) || exit_code=$?
  rm -f "$mutant_file"

  mutants_run=$((mutants_run + 1))

  if [ "$exit_code" -eq 0 ]; then
    mutants_failed=$((mutants_failed + 1))
    print -r -- "not ok - $name"
    print -r -- "  expected the mutant suite to fail"
    return
  fi

  if [[ "$output" != *"$expected_failure"* ]]; then
    mutants_failed=$((mutants_failed + 1))
    print -r -- "not ok - $name"
    print -r -- "  expected output to contain ${(qqq)expected_failure}"
    print -r -- "  actual output: ${(qqq)output}"
    return
  fi

  print -r -- "ok - $name"
}

run_mutant \
  "send-break cleanup mutant is caught" \
  's/halfpipe-reset ; zle \.\$cmd/zle .\$cmd/' \
  'not ok - send-break deactivates preview'

run_mutant \
  "binding restore mutant is caught" \
  's/bindkey "\$key_sequence" "\$original_binding"/:/' \
  'not ok - reset restores prior key bindings'

run_mutant \
  "first-pipe mutant is caught" \
  's/\[ "\$seen_pipes" -eq "\$split_pipe_number" \]/[ "$seen_pipes" -eq 1 ]/' \
  'not ok - multi-stage source command includes earlier pipeline stages'

run_mutant \
  "session-prolog mutant is caught" \
  's/prolog="\$\(halfpipe-shell-prolog\)"/prolog=""/' \
  'not ok - alias-backed source command is available in preview shell'

run_mutant \
  "command allowlist bypass mutant is caught" \
  's/blocked_command="\$\(halfpipe-preview-first-disallowed-command "\$BUFFER"\)"/blocked_command=""/' \
  'not ok - unallowlisted preview does not execute'

run_mutant \
  "default command allowlist mutant is caught" \
  's/HALFPIPE_PREVIEW_COMMAND_ALLOWLIST=\(awk sed grep head tail tr cut sort uniq wc cat nl column jq\)/HALFPIPE_PREVIEW_COMMAND_ALLOWLIST=(awk sed head tail tr cut sort uniq wc cat nl column jq)/' \
  'not ok - default command allowlist still executes grep previews'

run_mutant \
  "later pipeline segment allowlist mutant is caught" \
  's/segment_tokens=\(\)\n        continue/segment_tokens=()\n        break/' \
  'not ok - unallowlisted later rhs pipeline command is skipped'

print -r -- ""
print -r -- "mutants run: $mutants_run"
print -r -- "mutants failed: $mutants_failed"

if (( mutants_failed > 0 )); then
  exit 1
fi
