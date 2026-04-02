emulate -L zsh

test_reset_restores_full_buffer() {
  test::load_plugin

  test::set_binding '^G' 'some-widget'
  test::set_binding '^X^G' 'refresh-widget'
  PREDISPLAY='echo hi | '
  BUFFER='wc -c'
  POSTDISPLAY='preview'
  region_highlight=('P0 1 fg=red')
  _halfpipe_original_ctrl_g_binding='some-widget'
  _halfpipe_original_refresh_binding='refresh-widget'

  halfpipe-reset

  test::assert_eq "reset deactivates preview" "0" "$_halfpipe_activated"
  test::assert_eq "reset restores full pipeline into buffer" "echo hi | wc -c" "$BUFFER"
  test::assert_eq "reset clears predisplay" "" "$PREDISPLAY"
  test::assert_eq "reset clears postdisplay" "" "$POSTDISPLAY"
  test::assert_eq "reset clears cached source output" "" "$_halfpipe_cached_source_output"
  test::assert_eq "reset clears highlights" "" "${(j:,:)region_highlight}"
}

test_inactive_preview_shows_activation_hint() {
  test::load_plugin

  BUFFER='echo hi | wc -c'
  halfpipe-react-to-keypress

  local -a expected_bindkey_calls=('^G:halfpipe-toggle-live-output')

  test::assert_array_eq "inactive preview rebinds ctrl-g" expected_bindkey_calls __bindkey_set_calls
  test::assert_contains "inactive preview shows activation hint" "$POSTDISPLAY" "Press ^g to live-execute the cached result of echo hi"
  test::assert_eq "inactive preview highlights source segment" "P0 0 fg=cyan,bold" "${region_highlight[1]}"
}

test_reset_restores_original_bindings() {
  test::load_plugin

  test::set_binding '^G' 'some-widget'
  test::set_binding '^X^G' 'refresh-widget'
  BUFFER='echo hi | wc -c'
  halfpipe-react-to-keypress
  halfpipe-toggle-live-output
  halfpipe-reset

  local -a expected_bindkey_calls=(
    '^G:halfpipe-toggle-live-output'
    '^X^G:halfpipe-refresh-source-output'
    '^G:some-widget'
    '^X^G:refresh-widget'
  )

  test::assert_array_eq "reset restores prior key bindings" expected_bindkey_calls __bindkey_set_calls
}

test_toggle_live_output_caches_left_hand_side() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  halfpipe-toggle-live-output

  local -a expected_bindkey_calls=('^X^G:halfpipe-refresh-source-output')

  test::assert_eq "toggle enables preview" "1" "$_halfpipe_activated"
  test::assert_eq "toggle moves source command into predisplay" $'printf \'foo\\nbar\\n\' | ' "$PREDISPLAY"
  test::assert_eq "toggle keeps editable rhs in buffer" "grep bar" "$BUFFER"
  test::assert_eq "toggle caches source command output" $'foo\nbar\n' "$_halfpipe_cached_source_output"
  test::assert_eq "toggle renders preview output" $'\nbar' "$POSTDISPLAY"
  test::assert_eq "toggle highlights cached source command" "P0 22 fg=cyan,bold" "${region_highlight[1]}"
  test::assert_array_eq "toggle binds refresh widget" expected_bindkey_calls __bindkey_set_calls
}

test_multi_stage_pipeline_uses_last_pipe() {
  test::load_plugin

  BUFFER=$'printf \'alpha\\nbeta\\n\' | grep a | grep -c .'
  halfpipe-toggle-live-output

  test::assert_eq "multi-stage source command includes earlier pipeline stages" $'printf \'alpha\\nbeta\\n\' | grep a | ' "$PREDISPLAY"
  test::assert_eq "multi-stage preview keeps final command editable" "grep -c ." "$BUFFER"
  test::assert_eq "multi-stage preview uses cached upstream output" $'\n2' "$POSTDISPLAY"
}

test_quoted_pipe_does_not_split_pipeline() {
  test::load_plugin

  BUFFER=$'printf \'x|y\\n\' | grep \'x|y\' | grep -c .'
  halfpipe-toggle-live-output

  test::assert_eq "quoted pipes stay inside command tokens" $'printf \'x|y\\n\' | grep \'x|y\' | ' "$PREDISPLAY"
  test::assert_eq "quoted-pipe preview edits final stage only" "grep -c ." "$BUFFER"
  test::assert_eq "quoted-pipe preview output stays correct" $'\n1' "$POSTDISPLAY"
}

test_live_preview_reacts_to_rhs_edits() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  halfpipe-toggle-live-output
  BUFFER='grep -c .'
  halfpipe-react-to-keypress

  test::assert_eq "editing rhs reuses cached source output" $'\n2' "$POSTDISPLAY"
  test::assert_eq "editing rhs keeps preview active" "1" "$_halfpipe_activated"
}

test_refresh_source_output_reloads_cache() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep -c .'
  halfpipe-toggle-live-output
  _halfpipe_source_command=$'printf \'foo\\n\''
  halfpipe-refresh-source-output

  test::assert_eq "refresh reruns the cached source command" $'foo\n' "$_halfpipe_cached_source_output"
  test::assert_eq "refresh re-renders the preview output" $'\n1' "$POSTDISPLAY"
}

test_aliases_work_in_source_and_preview_commands() {
  test::load_plugin

  alias preview_source_alias="printf 'foo\\nbar\\n'"
  alias preview_filter_alias="grep -c ."
  BUFFER='preview_source_alias | preview_filter_alias'
  halfpipe-toggle-live-output

  test::assert_eq "alias-backed source command is available in preview shell" $'foo\nbar\n' "$_halfpipe_cached_source_output"
  test::assert_eq "alias-backed preview command is available in preview shell" $'\n2' "$POSTDISPLAY"
}

test_functions_work_in_source_and_preview_commands() {
  test::load_plugin

  preview_source_fn() { printf 'foo\nbar\n'; }
  preview_filter_fn() { grep -c .; }
  BUFFER='preview_source_fn | preview_filter_fn'
  halfpipe-toggle-live-output

  test::assert_eq "function-backed source command is available in preview shell" $'foo\nbar\n' "$_halfpipe_cached_source_output"
  test::assert_eq "function-backed preview command is available in preview shell" $'\n2' "$POSTDISPLAY"
}

test_refresh_uses_updated_function_definitions() {
  test::load_plugin

  preview_source_fn() { printf 'foo\n'; }
  BUFFER='preview_source_fn | grep -c .'
  halfpipe-toggle-live-output
  preview_source_fn() { printf 'foo\nbar\n'; }
  halfpipe-refresh-source-output

  test::assert_eq "refresh rebuilds the shell prolog from current functions" $'foo\nbar\n' "$_halfpipe_cached_source_output"
  test::assert_eq "refresh reflects updated function output" $'\n2' "$POSTDISPLAY"
}

test_toggle_off_resets_preview_state() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  halfpipe-toggle-live-output
  halfpipe-toggle-live-output

  test::assert_eq "second toggle disables preview" "0" "$_halfpipe_activated"
  test::assert_eq "second toggle restores original pipeline" $'printf \'foo\\nbar\\n\' | grep bar' "$BUFFER"
  test::assert_eq "second toggle clears postdisplay" "" "$POSTDISPLAY"
  test::assert_eq "second toggle clears predisplay" "" "$PREDISPLAY"
}

test_send_break_cleans_up_preview_state() {
  test::load_plugin

  test::set_binding '^G' 'some-widget'
  test::set_binding '^X^G' 'refresh-widget'
  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  halfpipe-react-to-keypress
  halfpipe-toggle-live-output
  send-break

  local -a expected_bindkey_calls=(
    '^G:halfpipe-toggle-live-output'
    '^X^G:halfpipe-refresh-source-output'
    '^G:some-widget'
    '^X^G:refresh-widget'
  )

  test::assert_eq "send-break deactivates preview" "0" "$_halfpipe_activated"
  test::assert_eq "send-break restores original buffer" $'printf \'foo\\nbar\\n\' | grep bar' "$BUFFER"
  test::assert_eq "send-break clears preview output" "" "$POSTDISPLAY"
  test::assert_eq "send-break clears predisplay" "" "$PREDISPLAY"
  test::assert_array_eq "send-break restores original bindings" expected_bindkey_calls __bindkey_set_calls
  test::assert_contains "send-break delegates to underlying zle widget" "${(j:|:)__zle_calls}" ".send-break"
}

test_accept_line_resets_preview_state() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  halfpipe-toggle-live-output
  accept-line

  test::assert_eq "accept-line deactivates preview" "0" "$_halfpipe_activated"
  test::assert_eq "accept-line restores original buffer" $'printf \'foo\\nbar\\n\' | grep bar' "$BUFFER"
  test::assert_contains "accept-line delegates to underlying zle widget" "${(j:|:)__zle_calls}" ".accept-line"
}

test_movement_refreshes_highlight() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  halfpipe-toggle-live-output
  forward-char

  test::assert_eq "movement keeps source highlight aligned" "P0 22 fg=cyan,bold" "${region_highlight[1]}"
  test::assert_contains "movement delegates to underlying zle widget" "${(j:|:)__zle_calls}" ".forward-char"
}

test_repeated_cycles_keep_bindings_stable() {
  test::load_plugin

  test::set_binding '^G' 'some-widget'
  test::set_binding '^X^G' 'refresh-widget'
  BUFFER='echo hi | wc -c'
  halfpipe-react-to-keypress
  halfpipe-toggle-live-output
  halfpipe-toggle-live-output
  halfpipe-react-to-keypress
  halfpipe-toggle-live-output
  halfpipe-toggle-live-output

  local -a expected_bindkey_calls=(
    '^G:halfpipe-toggle-live-output'
    '^X^G:halfpipe-refresh-source-output'
    '^G:some-widget'
    '^X^G:refresh-widget'
    '^G:halfpipe-toggle-live-output'
    '^X^G:halfpipe-refresh-source-output'
    '^G:some-widget'
    '^X^G:refresh-widget'
  )

  test::assert_array_eq "repeated cycles preserve original bindings" expected_bindkey_calls __bindkey_set_calls
}

test_no_pipe_resets_when_inactive() {
  test::load_plugin

  BUFFER='echo hi'
  PREDISPLAY='stale | '
  POSTDISPLAY='stale'
  _halfpipe_activated=0

  halfpipe-react-to-keypress

  test::assert_eq "no-pipe input clears stale preview" "" "$PREDISPLAY"
  test::assert_eq "no-pipe input keeps plain buffer" "stale | echo hi" "$BUFFER"
  test::assert_eq "no-pipe input clears postdisplay" "" "$POSTDISPLAY"
}
