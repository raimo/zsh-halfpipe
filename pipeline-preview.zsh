function () {
  pipeline-preview-reset() {
    typeset -g _pipeline_preview_source_command_suffix="|"
    typeset -gi _pipeline_preview_activated=0
    typeset -g _pipeline_preview_cached_source_output=''
    if [ "${$(bindkey '^G')#* }" = "pipeline-preview-toggle-live-output" ] && [ -n "$_pipeline_preview_original_ctrl_g_binding" ]; then
      bindkey "^G" "$_pipeline_preview_original_ctrl_g_binding"
    fi
    [ -n "$PREDISPLAY" ] && BUFFER="$PREDISPLAY$BUFFER"
    POSTDISPLAY=''
    PREDISPLAY=''
    region_highlight=("")
  }
  pipeline-preview-reset

  pipeline-preview-toggle-live-output() {
    _pipeline_preview_activated=$((($_pipeline_preview_activated + 1) % 2))

    if [ "$_pipeline_preview_activated" = "1" ]; then
      eval "${BUFFER%%|*}" | IFS= read -r -d $'\0' _pipeline_preview_cached_source_output
      PREDISPLAY=$(printf "%s|" "${BUFFER%%|*}")
      BUFFER="${BUFFER#*|}"
    fi

    pipeline-preview-react-to-keypress
  }

  pipeline-preview-react-to-keypress() {
    [[ "$_pipeline_preview_activated" = "0" && "${BUFFER#*|}" = "$BUFFER" ]] && pipeline-preview-reset && return

    if [ "$_pipeline_preview_activated" = "0" ]; then
      if [ "${$(bindkey '^G')#* }" != "pipeline-preview-toggle-live-output" ]; then
        typeset -g _pipeline_preview_original_ctrl_g_binding="${$(bindkey '^G')#* }"
        bindkey "^G" pipeline-preview-toggle-live-output
      fi
      POSTDISPLAY=$(printf "\nPress ^g to live-execute pipeline for cached result of %s" "${BUFFER%%|*}")
    elif [ "$_pipeline_preview_activated" = "1" ]; then
      POSTDISPLAY=$(
        printf "\n%s" "$(printf '%s' "$_pipeline_preview_cached_source_output" | eval "$BUFFER" 2>&1)"
      )
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
  zle -N self-insert
  zle -N backward-delete-char
  zle -N accept-line
}
