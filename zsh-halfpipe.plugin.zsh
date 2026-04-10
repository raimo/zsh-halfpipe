# Oh My Zsh and similar plugin managers look for a root-level
# <plugin-name>.plugin.zsh entrypoint. Keep the implementation in
# halfpipe.zsh and source it from here for compatibility.
source "${0:A:h}/halfpipe.zsh"
