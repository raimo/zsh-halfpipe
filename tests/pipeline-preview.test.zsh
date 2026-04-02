emulate -L zsh

test_reset_restores_full_buffer() {
  test::load_plugin

  PREDISPLAY='echo hi |'
  BUFFER=' wc -c'
  POSTDISPLAY='preview'
  region_highlight=('P0 1 fg=red')

  pipeline-preview-reset

  test::assert_eq "reset deactivates preview" "0" "$_pipeline_preview_activated"
  test::assert_eq "reset restores full pipeline into buffer" "echo hi | wc -c" "$BUFFER"
  test::assert_eq "reset clears predisplay" "" "$PREDISPLAY"
  test::assert_eq "reset clears postdisplay" "" "$POSTDISPLAY"
  test::assert_eq "reset clears cached source output" "" "$_pipeline_preview_cached_source_output"
  test::assert_eq "reset clears highlights" "" "${(j:,:)region_highlight}"
}

test_inactive_preview_shows_activation_hint() {
  test::load_plugin

  BUFFER='echo hi | wc -c'
  pipeline-preview-react-to-keypress

  local -a expected_bindkey_calls=('^G:pipeline-preview-toggle-live-output')

  test::assert_array_eq "inactive preview rebinds ctrl-g" expected_bindkey_calls __bindkey_set_calls
  test::assert_contains "inactive preview shows activation hint" "$POSTDISPLAY" "Press ^g to live-execute pipeline for cached result of echo hi "
  test::assert_eq "inactive preview highlights source segment" "P0 0 fg=cyan,bold" "${region_highlight[1]}"
}

test_reset_restores_original_ctrl_g_binding() {
  test::load_plugin

  __bindkey_query_result='^G some-widget'
  BUFFER='echo hi | wc -c'
  pipeline-preview-react-to-keypress
  pipeline-preview-reset

  local -a expected_bindkey_calls=('^G:pipeline-preview-toggle-live-output' '^G:some-widget')

  test::assert_array_eq "reset restores prior ctrl-g binding" expected_bindkey_calls __bindkey_set_calls
}

test_toggle_live_output_caches_left_hand_side() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  pipeline-preview-toggle-live-output

  test::assert_eq "toggle enables preview" "1" "$_pipeline_preview_activated"
  test::assert_eq "toggle moves source command into predisplay" $'printf \'foo\\nbar\\n\' |' "$PREDISPLAY"
  test::assert_eq "toggle keeps editable rhs in buffer" " grep bar" "$BUFFER"
  test::assert_eq "toggle caches source command output" $'foo\nbar\n' "$_pipeline_preview_cached_source_output"
  test::assert_eq "toggle renders preview output" $'\nbar' "$POSTDISPLAY"
  test::assert_eq "toggle highlights cached source command" "P0 21 fg=cyan,bold" "${region_highlight[1]}"
}

test_live_preview_reacts_to_rhs_edits() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  pipeline-preview-toggle-live-output
  BUFFER=' grep -c .'
  pipeline-preview-react-to-keypress

  test::assert_eq "editing rhs reuses cached source output" $'\n2' "$POSTDISPLAY"
  test::assert_eq "editing rhs keeps preview active" "1" "$_pipeline_preview_activated"
}

test_toggle_off_resets_preview_state() {
  test::load_plugin

  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  pipeline-preview-toggle-live-output
  pipeline-preview-toggle-live-output

  test::assert_eq "second toggle disables preview" "0" "$_pipeline_preview_activated"
  test::assert_eq "second toggle restores original pipeline" $'printf \'foo\\nbar\\n\' | grep bar' "$BUFFER"
  test::assert_eq "second toggle clears postdisplay" "" "$POSTDISPLAY"
  test::assert_eq "second toggle clears predisplay" "" "$PREDISPLAY"
}

test_send_break_cleans_up_preview_state() {
  test::load_plugin

  __bindkey_query_result='^G some-widget'
  BUFFER=$'printf \'foo\\nbar\\n\' | grep bar'
  pipeline-preview-react-to-keypress
  pipeline-preview-toggle-live-output
  send-break

  local -a expected_bindkey_calls=('^G:pipeline-preview-toggle-live-output' '^G:some-widget')

  test::assert_eq "send-break deactivates preview" "0" "$_pipeline_preview_activated"
  test::assert_eq "send-break restores original buffer" $'printf \'foo\\nbar\\n\' | grep bar' "$BUFFER"
  test::assert_eq "send-break clears preview output" "" "$POSTDISPLAY"
  test::assert_eq "send-break clears predisplay" "" "$PREDISPLAY"
  test::assert_array_eq "send-break restores original ctrl-g binding" expected_bindkey_calls __bindkey_set_calls
  test::assert_contains "send-break delegates to underlying zle widget" "${(j:|:)__zle_calls}" ".send-break"
}

test_no_pipe_resets_when_inactive() {
  test::load_plugin

  BUFFER='echo hi'
  PREDISPLAY='stale |'
  POSTDISPLAY='stale'
  _pipeline_preview_activated=0

  pipeline-preview-react-to-keypress

  test::assert_eq "no-pipe input clears stale preview" "" "$PREDISPLAY"
  test::assert_eq "no-pipe input keeps plain buffer" "stale |echo hi" "$BUFFER"
  test::assert_eq "no-pipe input clears postdisplay" "" "$POSTDISPLAY"
}
