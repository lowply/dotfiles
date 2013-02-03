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
keychain $HOME/.ssh/id_rsa
source $HOME/.keychain/$HOSTNAME-sh

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
# EDITOR
#
export EDITOR=/usr/bin/vim

#
# PS1 (from https://gist.github.com/293517)
#
function smart_pwd {
    local pwdmaxlen=25
    local trunc_symbol=".."
    local dir=${PWD##*/}
    local tmp=""
    pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
    NEW_PWD=${PWD/#$HOME/\~}
    local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
    if [ ${pwdoffset} -gt "0" ]
    then
        tmp=${NEW_PWD:$pwdoffset:$pwdmaxlen}
        tmp=${trunc_symbol}/${tmp#*/}
        if [ "${#tmp}" -lt "${#NEW_PWD}" ]; then
            NEW_PWD=$tmp
        fi
    fi
}
 
function boldtext {
    echo "\\[\\033[1m\\]"$1"\\[\\033[0m\\]"
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
    PROMPT_COMMAND="smart_pwd"
    PS1="$(bgcolor 0)$(fgcolor 198)\u$(fgcolor 147)@$(fgcolor 172)\h$(fgcolor 147)$(boldtext :)$(bgcolor 232)$(fgcolor 120)\$NEW_PWD$(resetcolor)$(bgcolor 0)$(fgcolor 220)$(resetcolor)$(fgcolor 129)"'\$ '"$(resetcolor)"
}

# use this command to check 256 color:
# for i in {0..255}; do echo -e "\e[38;05;${i}m${i}"; done | column -c 80 -s '  '; echo -e "\e[m"
 
function dullprompt {
    PROMPT_COMMAND=""
    PS1="\u@\h:\w\$ "
}

case "$TERM" in
xterm-color|xterm-256color|rxvt*|screen-256color)
        fancyprompt
    ;;
*)
        dullprompt
    ;;
esac
