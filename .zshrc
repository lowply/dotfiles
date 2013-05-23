# .zshrc

#
# oh-my-zsh
#

ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git brew autojump)
source $ZSH/oh-my-zsh.sh

#
# zsh
#
export LANG=en_US.UTF-8

setopt no_beep
setopt nolistbeep
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt correct
setopt list_packed
setopt print_eight_bit
setopt notify
setopt transient_rprompt
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

#
# prompt
#

#--- setopt prompt_subst
#--- 
#--- # colors
#--- local DEFAULT=$'%{\e[m%}'
#--- local GREEN=$'%{\e[32m%}'
#--- local YELLOW=$'%{\e[33m%}'
#--- 
#--- # user
#--- PROMPT="${GREEN}[%n@%m %1~]%#${DEFAULT} "
#--- RPROMPT="${GREEN}[%/]${DEFAULT}"
#--- 
#--- # root
#--- if [ ${UID} = 0 ]; then
#---   PROMPT="${YELLOW}[%n@%m %1~]%#${DEFAULT} "
#---   RPROMPT="${YELLOW}[%/]${DEFAULT}"
#--- fi
#--- 
#--- # ターミナルタイトル表示 user@host:~/dir
#--- if [[ ${TERM} == [xk]term || ${TERM} == screen ]]; then
#---   precmd() {
#---     echo -ne "\033]0;${USER}@${HOST%%.*}:${PWD/~HOME/~}\007"
#---   }
#--- fi

#
# bindkey
#
bindkey -v
bindkey "^H" backward-delete-word
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^W" forward-word
#bindkey "^B" backward-word
bindkey "^P" history-beginning-search-backward
bindkey "^N" history-beginning-search-forward
bindkey '^R' history-incremental-pattern-search-backward
#bindkey '^F' history-incremental-pattern-search-forward
bindkey '^F' forward-char
bindkey '^B' backward-char

#
# aliases
#
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias man='LANG=ja_JP.utf8 man'

#
# completion
#
LISTMAX=0
setopt complete_aliases
setopt noautoremoveslash
setopt magic_equal_subst
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' '+m:{A-Z}={a-z}'
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

#
# History
#
setopt extended_history
setopt append_history
setopt inc_append_history
setopt share_history
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify

HISTFILE=~/.zsh_history
HISTIGNORE=ls:history
HISTSIZE=100000
SAVEHIST=100000
HISTTIMEFORMAT="%y/%m/%d %H:%M:%S : "

#
# Keychain
#
if [ -x /usr/bin/keychain ]; then
  keychain $HOME/.ssh/id_rsa
  source $HOME/.keychain/$HOSTNAME-sh
fi

#
# less prompt customize. see details for http://kazmax.zpp.jp/cmd/l/less.1.html
#
export PAGER=/usr/bin/less
export LESS='-X -i -P ?f%f:(stdin).  ?lb%lb?L/%L..  [?eEOF:?pb%pb\%..]'

#
# OS Specific Settings
#
function do_mac {
  echo "This is mac"

  if [ -d /usr/local/Cellar/coreutils ]; then
    alias ls='/usr/local/bin/gls --color=auto'
    alias echo='/usr/local/bin/gecho'
  fi
  export EDITOR=/usr/local/bin/vim
}

function do_linux {
  echo "This is linux"

  alias ls='ls --color=auto'
  alias ll='ls -l --color=auto'

  export EDITOR=/usr/bin/vim
}

function do_fbsd {
  echo "This is FreeBSD"

  alias ls='ls -G'
  alias ll='ls -l -G'
  alias gls='gls --color=auto'
}

case "$OSTYPE" in
darwin*)
    do_mac
    ;;
linux)
    do_linux
    ;;
freebsd)
    do_fbsd
    ;;
esac

#
# load additional settings
#
[ -f ${HOME}/.zshrc.me ] && source ${HOME}/.zshrc.me
