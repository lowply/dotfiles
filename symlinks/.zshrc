# bindkey
bindkey "^A" vi-beginning-of-line
bindkey "^E" vi-end-of-line
bindkey "^B" vi-backward-word
bindkey "^F" vi-forward-word
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey "^P" up-history
bindkey "^N" down-history

# history
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt share_history
setopt hist_ignore_all_dups

# prompt
source $(brew --prefix)/opt/git/etc/bash_completion.d/git-prompt.sh
precmd () { __git_ps1 "%* %n@%m:%~:" "$ " "(%s)" }
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWUPSTREAM="auto"
GIT_PS1_SHOWCOLORHINTS=true

eval "$(jump shell zsh)"
