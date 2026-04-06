function () {
  halfpipe-bind-temporary() {
    local key_sequence="$1"
    local widget_name="$2"
    local storage_var="$3"
    local current_binding="${$(bindkey "$key_sequence")#* }"

    if [ "$current_binding" != "$widget_name" ]; then
      typeset -g $storage_var="$current_binding"
      bindkey "$key_sequence" "$widget_name"
    fi
  }

  halfpipe-restore-binding() {
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

  halfpipe-capture-command-output() {
    local command_text="$1"
    local target_var="$2"

    IFS= read -r -d $'\0' "$target_var" < <(
      {
        halfpipe-run-in-subshell "$command_text"
        printf '\0'
      }
    )
  }

  halfpipe-shell-prolog() {
    printf '%s\n' "$(alias -L)"
    functions
  }

  halfpipe-run-in-subshell() {
    local command_text="$1"
    local prolog=''

    prolog="$(halfpipe-shell-prolog)"
    command zsh -fc "$prolog
eval \"\$1\"" _ "$command_text" 2>&1
  }

  halfpipe-parse-buffer() {
    local buffer_text="$1"
    local cursor_pos="${2:--1}"
    local -a tokens
    local -a source_tokens
    local -a preview_tokens
    local -a left_tokens
    local split_pipe_number=0
    local split_pipe_index=0
    local seen_pipes=0
    local idx=0
    local left_text=''
    local buffer_len=${#buffer_text}

    tokens=(${(z)buffer_text})

    if [ "${#tokens}" -eq 0 ]; then
      return 1
    fi

    if [ "$cursor_pos" -lt 0 ] || [ "$cursor_pos" -gt "$buffer_len" ]; then
      cursor_pos=$buffer_len
    fi

    if [ "$cursor_pos" -gt 0 ]; then
      left_text="${buffer_text[1,$cursor_pos]}"
    fi

    left_tokens=(${(z)left_text})

    for idx in {1..${#left_tokens}}; do
      [ "${left_tokens[$idx]}" = "|" ] && split_pipe_number=$((split_pipe_number + 1))
    done

    if [ "$split_pipe_number" -eq 0 ]; then
      return 1
    fi

    for idx in {1..${#tokens}}; do
      if [ "${tokens[$idx]}" = "|" ]; then
        seen_pipes=$((seen_pipes + 1))
        if [ "$seen_pipes" -eq "$split_pipe_number" ]; then
          split_pipe_index=$idx
          break
        fi
      fi
    done

    if [ "$split_pipe_index" -eq 0 ] || [ "$split_pipe_index" -eq 1 ] || [ "$split_pipe_index" -eq "${#tokens}" ]; then
      return 1
    fi

    source_tokens=("${tokens[@][1,$((split_pipe_index - 1))]}")
    preview_tokens=("${tokens[@][$((split_pipe_index + 1)),-1]}")

    typeset -g _halfpipe_source_command="${(j: :)source_tokens}"
    typeset -g _halfpipe_preview_command="${(j: :)preview_tokens}"
  }

  halfpipe-reset() {
    typeset -gi _halfpipe_activated=0
    typeset -g _halfpipe_cached_source_output=''
    typeset -g _halfpipe_source_command=''
    typeset -g _halfpipe_preview_command=''
    halfpipe-restore-binding "^G" halfpipe-toggle-live-output _halfpipe_original_ctrl_g_binding
    halfpipe-restore-binding "^X^G" halfpipe-refresh-source-output _halfpipe_original_refresh_binding
    [ -n "$PREDISPLAY" ] && BUFFER="$PREDISPLAY$BUFFER"
    POSTDISPLAY=''
    PREDISPLAY=''
    region_highlight=("")
  }
  halfpipe-reset

  halfpipe-deactivate-preview() {
    local restored_buffer="$PREDISPLAY$BUFFER"
    local restored_cursor=$((CURSOR + ${#PREDISPLAY}))

    typeset -gi _halfpipe_activated=0
    typeset -g _halfpipe_cached_source_output=''
    typeset -g _halfpipe_source_command=''
    typeset -g _halfpipe_preview_command=''
    halfpipe-restore-binding "^X^G" halfpipe-refresh-source-output _halfpipe_original_refresh_binding
    BUFFER="$restored_buffer"
    CURSOR="$restored_cursor"
    POSTDISPLAY=''
    PREDISPLAY=''
    region_highlight=("")
    halfpipe-react-to-keypress
  }

  halfpipe-refresh-source-output() {
    [ "$_halfpipe_activated" = "1" ] || return

    halfpipe-capture-command-output "$_halfpipe_source_command" _halfpipe_cached_source_output
    halfpipe-react-to-keypress
  }

  halfpipe-toggle-live-output() {
    if [ "$_halfpipe_activated" = "1" ]; then
      halfpipe-deactivate-preview
      return
    fi

    if ! halfpipe-parse-buffer "$BUFFER" "$CURSOR"; then
      halfpipe-reset
      return
    fi

    _halfpipe_activated=1
    halfpipe-capture-command-output "$_halfpipe_source_command" _halfpipe_cached_source_output
    PREDISPLAY=$(printf "%s | " "$_halfpipe_source_command")
    BUFFER="$_halfpipe_preview_command"
    halfpipe-bind-temporary "^X^G" halfpipe-refresh-source-output _halfpipe_original_refresh_binding
    halfpipe-react-to-keypress
  }

  halfpipe-react-to-keypress() {
    if [ "$_halfpipe_activated" = "0" ]; then
      if ! halfpipe-parse-buffer "$BUFFER" "$CURSOR"; then
        halfpipe-reset
        return
      fi

      halfpipe-bind-temporary "^G" halfpipe-toggle-live-output _halfpipe_original_ctrl_g_binding
      POSTDISPLAY=$(printf "\nPress ^g to freeze up to the pipe left of cursor and live-execute the cached result of %s" "$_halfpipe_source_command")
    elif [ "$_halfpipe_activated" = "1" ]; then
      local preview_output=''

      IFS= read -r -d $'\0' preview_output < <(
        {
          printf '%s' "$_halfpipe_cached_source_output" | halfpipe-run-in-subshell "$BUFFER"
          printf '\0'
        }
      )
      POSTDISPLAY=$(printf "\n%s" "$preview_output")
    fi

    halfpipe-react-to-movement
  }

  halfpipe-react-to-movement() {
    region_highlight=("P0 ${#PREDISPLAY} fg=cyan,bold")
  }

  for cmd in backward-delete-char self-insert; do
    eval "$cmd() { zle .$cmd ; halfpipe-react-to-keypress } ; zle -N $cmd"
  done

  for cmd in vi-backward-blank-word backward-char vi-backward-char backward-word emacs-backward-word vi-backward-word \
    beginning-of-line vi-beginning-of-line end-of-line vi-end-of-line vi-forward-blank-word vi-forward-blank-word-end \
    forward-char vi-forward-char vi-find-next-char vi-find-next-char-skip vi-find-prev-char vi-find-prev-char-skip \
    vi-first-non-blank vi-forward-word forward-word emacs-forward-word vi-forward-word-end vi-goto-column \
    vi-goto-mark vi-goto-mark-line vi-repeat-find vi-rev-repeat-find read-command; do
    eval "$cmd() { zle .$cmd ; if [ \"\$_halfpipe_activated\" = \"1\" ]; then halfpipe-react-to-movement; else halfpipe-react-to-keypress; fi } ; zle -N $cmd"
  done

  for cmd in accept-line; do
    eval "$cmd() { zle .$cmd ; halfpipe-reset } ; zle -N $cmd"
  done

  for cmd in send-break; do
    eval "$cmd() { halfpipe-reset ; zle .$cmd } ; zle -N $cmd"
  done

  zle -N read-command
  zle -N halfpipe-toggle-live-output
  zle -N halfpipe-refresh-source-output
  zle -N self-insert
  zle -N backward-delete-char
  zle -N accept-line
}
