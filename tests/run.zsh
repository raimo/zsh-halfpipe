#!/usr/bin/env zsh
emulate -L zsh
setopt err_return pipe_fail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"

source "${SCRIPT_DIR}/test_helper.zsh"
source "${SCRIPT_DIR}/pipeline-preview.test.zsh"

zsh -n "${ROOT_DIR}/pipeline-preview.zsh"
test::pass "syntax check passes"

test_reset_restores_full_buffer
test_inactive_preview_shows_activation_hint
test_toggle_live_output_caches_left_hand_side
test_live_preview_reacts_to_rhs_edits
test_toggle_off_resets_preview_state
test_no_pipe_resets_when_inactive

print -r -- ""
print -r -- "tests run: $TESTS_RUN"
print -r -- "tests failed: $TESTS_FAILED"

if (( TESTS_FAILED > 0 )); then
  exit 1
fi
