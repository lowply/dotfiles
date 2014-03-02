# .bashrc

# User specific aliases and functions

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# ---------------------------------------------------------------
# Original Setting
# ---------------------------------------------------------------

alias tm='tmux -2u a || tmux -2u'
alias man='LANG=ja_JP.utf8 man'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

#
# Keychain
#
#if [ -x /usr/bin/keychain ]; then
#  keychain $HOME/.ssh/id_rsa
#  source $HOME/.keychain/$HOSTNAME-sh
#fi

#
# append to the history file, don't overwrite it
#
shopt -s histappend

#
# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
#
shopt -s checkwinsize

#
# History size & format
#
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=10000
HISTTIMEFORMAT="%y/%m/%d %H:%M:%S : "

#
# less prompt customize. see details for http://kazmax.zpp.jp/cmd/l/less.1.html
#
export LESS='-X -i -P ?f%f:(stdin).  ?lb%lb?L/%L..  [?eEOF:?pb%pb\%..]'

#
# set EDITOR to vim
#
if [ -f /usr/local/bin/vim ]; then
    export EDITOR=/usr/local/bin/vim
else
    export EDITOR=/usr/bin/vim
fi

#
# PS1
#
 
# use this command to check 256 color:
# for i in {0..255}; do echo -e "\e[38;05;${i}m${i}"; done | column -c 80 -s '  '; echo -e "\e[m"
 
function color_local {
  BACKGROUND=0
  UNAME=112
  SYMBOL=127
  HOST=222
  DIRNAME=39
  PROMPT=109
}

function color_remote {
  BACKGROUND=0
  UNAME=198
  SYMBOL=147
  HOST=173
  DIRNAME=120
  PROMPT=129
}

function bgcolor {
    echo "\\[\\033[48;5;"$1"m\\]"
}
 
function fgcolor {
    echo "\\[\\033[38;5;"$1"m\\]"
}
 
function resetcolor {
    echo "\\[\\e[0m\\]"
}
 
function fancyprompt {
    PS1="$(bgcolor $BACKGROUND)$(fgcolor $UNAME)\u$(fgcolor $SYMBOL)@$(fgcolor $HOST)\h$(fgcolor $SYMBOL):$(fgcolor $DIRNAME)\$PWD$(resetcolor)$(fgcolor $PROMPT)"'\$ '"$(resetcolor)"
}

function dullprompt {
    PS1="\u@\h:\w\$ "
}

case "$TERM_PROGRAM" in
Apple_Terminal)
    color_local
    ;;
*)
    color_remote
    ;;
esac

case "$TERM" in
xterm-color|xterm-256color|rxvt*|screen-256color)
    fancyprompt
    ;;
*)
    dullprompt
    ;;
esac

#
# path
#
case "${OSTYPE}" in
darwin*)
	. ~/.bashrc_osx
	;;
linux*)
	. ~/.bashrc_linux
	;;
esac
