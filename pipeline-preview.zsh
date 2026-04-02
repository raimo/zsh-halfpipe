function () {
  pipeline-preview-bind-temporary() {
    local key_sequence="$1"
    local widget_name="$2"
    local storage_var="$3"
    local current_binding="${$(bindkey "$key_sequence")#* }"

    if [ "$current_binding" != "$widget_name" ]; then
      typeset -g $storage_var="$current_binding"
      bindkey "$key_sequence" "$widget_name"
    fi
  }

  pipeline-preview-restore-binding() {
    local key_sequence="$1"
    local widget_name="$2"
    local storage_var="$3"
    local current_binding="${$(bindkey "$key_sequence")#* }"
    local original_binding="${(P)storage_var}"

    if [ "$current_binding" = "$widget_name" ] && [ -n "$original_binding" ]; then
      bindkey "$key_sequence" "$original_binding"
    fi

    typeset -g $storage_var=''
  }

  pipeline-preview-capture-command-output() {
    local command_text="$1"
    local target_var="$2"

    IFS= read -r -d $'\0' "$target_var" < <(
      {
        pipeline-preview-run-in-subshell "$command_text"
        printf '\0'
      }
    )
  }

  pipeline-preview-shell-prolog() {
    printf '%s\n' "$(alias -L)"
    functions
  }

  pipeline-preview-run-in-subshell() {
    local command_text="$1"
    local prolog=''

    prolog="$(pipeline-preview-shell-prolog)"
    command zsh -fc "$prolog
eval \"\$1\"" _ "$command_text" 2>&1
  }

  pipeline-preview-parse-buffer() {
    local buffer_text="$1"
    local -a tokens
    local -a source_tokens
    local -a preview_tokens
    local last_pipe_index=0
    local idx=0

    tokens=(${(z)buffer_text})

    for idx in {1..${#tokens}}; do
      [ "${tokens[$idx]}" = "|" ] && last_pipe_index=$idx
    done

    if [ "$last_pipe_index" -eq 0 ] || [ "$last_pipe_index" -eq 1 ] || [ "$last_pipe_index" -eq "${#tokens}" ]; then
      return 1
    fi

    source_tokens=("${tokens[@][1,$((last_pipe_index - 1))]}")
    preview_tokens=("${tokens[@][$((last_pipe_index + 1)),-1]}")

    typeset -g _pipeline_preview_source_command="${(j: :)source_tokens}"
    typeset -g _pipeline_preview_preview_command="${(j: :)preview_tokens}"
  }

  pipeline-preview-reset() {
    typeset -gi _pipeline_preview_activated=0
    typeset -g _pipeline_preview_cached_source_output=''
    typeset -g _pipeline_preview_source_command=''
    typeset -g _pipeline_preview_preview_command=''
    pipeline-preview-restore-binding "^G" pipeline-preview-toggle-live-output _pipeline_preview_original_ctrl_g_binding
    pipeline-preview-restore-binding "^X^G" pipeline-preview-refresh-source-output _pipeline_preview_original_refresh_binding
    [ -n "$PREDISPLAY" ] && BUFFER="$PREDISPLAY$BUFFER"
    POSTDISPLAY=''
    PREDISPLAY=''
    region_highlight=("")
  }
  pipeline-preview-reset

  pipeline-preview-refresh-source-output() {
    [ "$_pipeline_preview_activated" = "1" ] || return

    pipeline-preview-capture-command-output "$_pipeline_preview_source_command" _pipeline_preview_cached_source_output
    pipeline-preview-react-to-keypress
  }

  pipeline-preview-toggle-live-output() {
    if [ "$_pipeline_preview_activated" = "1" ]; then
      pipeline-preview-reset
      return
    fi

    if ! pipeline-preview-parse-buffer "$BUFFER"; then
      pipeline-preview-reset
      return
    fi

    _pipeline_preview_activated=1
    pipeline-preview-capture-command-output "$_pipeline_preview_source_command" _pipeline_preview_cached_source_output
    PREDISPLAY=$(printf "%s | " "$_pipeline_preview_source_command")
    BUFFER="$_pipeline_preview_preview_command"
    pipeline-preview-bind-temporary "^X^G" pipeline-preview-refresh-source-output _pipeline_preview_original_refresh_binding
    pipeline-preview-react-to-keypress
  }

  pipeline-preview-react-to-keypress() {
    if [ "$_pipeline_preview_activated" = "0" ]; then
      if ! pipeline-preview-parse-buffer "$BUFFER"; then
        pipeline-preview-reset
        return
      fi

      pipeline-preview-bind-temporary "^G" pipeline-preview-toggle-live-output _pipeline_preview_original_ctrl_g_binding
      POSTDISPLAY=$(printf "\nPress ^g to live-execute the cached result of %s" "$_pipeline_preview_source_command")
    elif [ "$_pipeline_preview_activated" = "1" ]; then
      local preview_output=''

      IFS= read -r -d $'\0' preview_output < <(
        {
          printf '%s' "$_pipeline_preview_cached_source_output" | pipeline-preview-run-in-subshell "$BUFFER"
          printf '\0'
        }
      )
      POSTDISPLAY=$(printf "\n%s" "$preview_output")
    fi

    pipeline-preview-react-to-movement
  }

  pipeline-preview-react-to-movement() {
    region_highlight=("P0 ${#PREDISPLAY} fg=cyan,bold")
  }

  for cmd in backward-delete-char self-insert; do
    eval "$cmd() { zle .$cmd ; pipeline-preview-react-to-keypress } ; zle -N $cmd"
  done

  for cmd in vi-backward-blank-word backward-char vi-backward-char backward-word emacs-backward-word vi-backward-word \
    beginning-of-line vi-beginning-of-line end-of-line vi-end-of-line vi-forward-blank-word vi-forward-blank-word-end \
    forward-char vi-forward-char vi-find-next-char vi-find-next-char-skip vi-find-prev-char vi-find-prev-char-skip \
    vi-first-non-blank vi-forward-word forward-word emacs-forward-word vi-forward-word-end vi-goto-column \
    vi-goto-mark vi-goto-mark-line vi-repeat-find vi-rev-repeat-find read-command; do
    eval "$cmd() { zle .$cmd ; pipeline-preview-react-to-movement } ; zle -N $cmd"
  done

  for cmd in accept-line; do
    eval "$cmd() { zle .$cmd ; pipeline-preview-reset } ; zle -N $cmd"
  done

  for cmd in send-break; do
    eval "$cmd() { pipeline-preview-reset ; zle .$cmd } ; zle -N $cmd"
  done

  zle -N read-command
  zle -N pipeline-preview-toggle-live-output
  zle -N pipeline-preview-refresh-source-output
  zle -N self-insert
  zle -N backward-delete-char
  zle -N accept-line
}
