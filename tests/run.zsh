#!/usr/bin/env zsh
emulate -L zsh
setopt err_return pipe_fail

SCRIPT_DIR="${0:A:h}"
ROOT_DIR="${SCRIPT_DIR:h}"

source "${SCRIPT_DIR}/test_helper.zsh"
source "${SCRIPT_DIR}/halfpipe.test.zsh"

zsh -n "${ROOT_DIR}/halfpipe.zsh"
test::pass "syntax check passes"

test_reset_restores_full_buffer
test_inactive_preview_shows_activation_hint
test_reset_restores_original_bindings
test_toggle_live_output_caches_left_hand_side
test_multi_stage_pipeline_uses_last_pipe
test_quoted_pipe_does_not_split_pipeline
test_live_preview_reacts_to_rhs_edits
test_refresh_source_output_reloads_cache
test_aliases_work_in_source_and_preview_commands
test_functions_work_in_source_and_preview_commands
test_refresh_uses_updated_function_definitions
test_toggle_off_resets_preview_state
test_send_break_cleans_up_preview_state
test_accept_line_resets_preview_state
test_movement_refreshes_highlight
test_repeated_cycles_keep_bindings_stable
test_no_pipe_resets_when_inactive

print -r -- ""
print -r -- "tests run: $TESTS_RUN"
print -r -- "tests failed: $TESTS_FAILED"

if (( TESTS_FAILED > 0 )); then
  exit 1
fi
