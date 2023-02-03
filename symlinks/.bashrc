# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

#
# Reset default path and add /usr/local/bin and /usr/local/sbin at proper position
# except on GitHub Codespaces
#
[ -z "${CODESPACES}" ] && export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

#
# functions
#
addpath(){
    [ -d ${1} ] || return
    export PATH=${1}:${PATH//$1:/}
}

has(){
    type ${1} > /dev/null 2>&1
    return $?
}

error(){
    echo "${1}"
    return 1
}

peco-run-cmd(){
    if [ -n "$1" ] ; then
        # Replace the last entry, with $1
        history -s $1
        # Execute it
        echo $1 >&2
        eval $1
    else
        # Remove the last entry
        history -d $((HISTCMD-1))
    fi
}

# See ~/.inputrc
peco-ghq () {
    has "peco" || error "peco is not installed"
    has "ghq" || error "ghq is not installed"
    local GHQDIR="${HOME}/ghq"
    local DIR="$(ghq list | peco)"
    if [ ! -z "${DIR}" ]; then
        cd "${GHQDIR}/${DIR}"
    fi
}

# See ~/.inputrc
peco-snippets() {
    has "peco" || return
    [ -f ${HOME}/.snippets ] || { echo "Couldn't find ~/.snippets"; return; }
    local CMD=$(grep -v "^#" ~/.snippets | sed '/^$/d' | peco)
    peco-run-cmd "$CMD"
}

backup() {
    cp -a $1{,.$(date +%y%m%d_%H%M%S)}
}

# Docker

docker_cleanup(){
    for x in $(docker ps -a | grep Exited | awk '{print $1}'); do docker rm $x; done
    for x in $(docker images | grep "<none>" | awk '{print $3}'); do docker rmi $x; done
}

#
# aliases
#

alias jman='LANG=ja_JP.utf8 man'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias zcat='gzcat'
alias nstlnp='lsof -nP -iTCP -sTCP:LISTEN'
alias nstanp='lsof -nP -iTCP'
alias lsdsstr='find . -name .DS_Store -print'
alias rmdsstr='find . -name .DS_Store -delete -exec echo removed: {} \;'

# https://sw.kovidgoyal.net/kitty/faq.html#i-get-errors-about-the-terminal-being-unknown-or-opening-the-terminal-failing-when-sshing-into-a-different-computer
alias kssh='/Applications/kitty.app/Contents/MacOS/kitty +kitten ssh'

has gsed && alias sed='gsed'
has ggrep && alias grep='ggrep'
has gmake && alias make='gmake'
has colordiff && alias diff='colordiff'
has gls && alias ls='ls -v --color=auto'
has gh && alias openw='gh repo view --web'

# The 'code' command needs to be installed.
# See https://code.visualstudio.com/docs/editor/command-line#_launching-from-command-line
has code && alias cr='code . -r'

#
# History size & format
#
export HISTCONTROL=ignoredups:ignorespace
export HISTSIZE=10000
export HISTTIMEFORMAT="%F %T : "

# less prompt customize. See details for
# http://kazmax.zpp.jp/cmd/l/less.1.html
# http://qiita.com/hatchinee/items/586fb1c4915e2bb5c03b
#
export LESS='-X -R -i -P ?f%f:(stdin). ?lb%lb?L/%L.. [?eEOF:?pb%pb\%..]'

#
# for Mac, brew install source-highlight
# for Linux, yum install source-highlight
#
if has source-highlight; then
    if has src-hilite-lesspipe.sh; then
        # macOS
        LESSPIPE=$(which src-hilite-lesspipe.sh)
    elif [ -x "/usr/share/source-highlight/src-hilite-lesspipe.sh" ]; then
        # Ubuntu
        LESSPIPE="/usr/share/source-highlight/src-hilite-lesspipe.sh"
    fi
    export LESSOPEN="| $LESSPIPE %s"
fi

#
# set EDITOR, PAGER
#

[ -x "/usr/bin/vim" ] && export EDITOR=/usr/bin/vim
[ -x "/usr/local/bin/vim" ] && export EDITOR=/usr/local/bin/vim
[ -x "/opt/homebrew/bin/vim" ] && export EDITOR=/opt/homebrew/bin/vim

[ -x "/usr/bin/less" ] && export PAGER=/usr/bin/less
[ -x "/opt/homebrew/bin/less" ] && export PAGER=/opt/homebrew/bin/less

#
# avoid screen lock by hitting Ctrl+S
#
[ -t 0 ] && stty stop undef

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
# PS1
#
psone(){
    bgcolor(){
        echo "\\[\\033[48;5;"$1"m\\]"
    }

    fgcolor(){
        echo "\\[\\033[38;5;"$1"m\\]"
    }

    resetcolor(){
        echo "\\[\\e[0m\\]"
    }

    # color config
    if [ $(id -u) == 0 ]; then
        local BACKGROUND=0
        local UNAME=196
        local SYMBOL=226
        local HOST=196
        local DIRNAME=196
        local PROMPT=196
        local BRANCH=226
    else
        if [ -f ${HOME}/.bash_color ]; then
            . ${HOME}/.bash_color
        else
            local BACKGROUND=0
            local UNAME=252
            local SYMBOL=3
            local HOST=252
            local DIRNAME=252
            local PROMPT=3
            local BRANCH=33
        fi
    fi

    GIT_PS1_SHOWDIRTYSTATE=true
    GIT_PS1_SHOWUNTRACKEDFILES=true
    GIT_PS1_SHOWUPSTREAM="auto"
    GIT_PS1_SHOWCOLORHINTS=true

    # set PS1
    export PS1="\t:$(fgcolor $UNAME)\u$(fgcolor $SYMBOL)@$(fgcolor $HOST)\h$(fgcolor $BRANCH)"'$(__git_ps1 ":(%s)")'"$(fgcolor $PROMPT)\n\$ $(resetcolor)"
}

#
# $PATH
#
if [[ ${OSTYPE} =~ ^darwin ]]; then
    # Silence zsh warning when using bash: https://support.apple.com/en-us/HT208050
    export BASH_SILENCE_DEPRECATION_WARNING=1

    [ -f "/opt/homebrew/bin/brew" ] || { echo "brew is not installed"; return; }

    export BREW_PREFIX="$(/opt/homebrew/bin/brew --prefix)"

    addpath ${BREW_PREFIX}/bin

    # aliasing every command with the 'g' prefix in ${BREW_PREFIX}/bin is not a great idea.
    # instead, let's just add the gnubin dir to the PATH
    addpath ${BREW_PREFIX}/opt/coreutils/libexec/gnubin

    # Prefer OpenSSL over LibreSSL
    addpath ${BREW_PREFIX}/opt/openssl/bin

    # Ruby and Gems
    addpath ${BREW_PREFIX}/opt/ruby/bin
    has gem && addpath $(gem environment | grep "EXECUTABLE DIRECTORY: " | cut -d ':' -f 2 | xargs)

    # curl
    addpath ${BREW_PREFIX}/opt/curl/bin

    # Dropbox
    addpath ${HOME}/Dropbox/bin

    # for dnsmasq, dsvpn etc
    addpath ${BREW_PREFIX}/sbin
elif [[ ${OSTYPE} =~ ^linux ]]; then
    # noop
    :
fi

# rbenv
if [ -z "${CODESPACES}" ] && [ -d ${HOME}/.rbenv ]; then
    # Only Linux except Codespaces
    # On macOS, rbenv is supposed to be installed via Homebrew
    #
    # Using apt on Debian/Ubuntu is not recommended. See:
    # https://github.com/rbenv/rbenv#debian-ubuntu-and-their-derivatives
    [[ ${OSTYPE} =~ ^linux ]] && addpath ${HOME}/.rbenv/bin
    eval "$(rbenv init -)"
fi

# dotfiles/bin
DOTFILES_DIR="$(dirname $(dirname $(realpath ${BASH_SOURCE})))"
addpath ${DOTFILES_DIR}/bin

# go
addpath ${HOME}/go/bin

#
# git prompt, bash completion and diff-highlight
#
if [[ ${OSTYPE} =~ ^darwin ]]; then
    # bash completion (need brew install bash-completion)
    # This will automatically include
    # ${BREW_PREFIX}/etc/bash_completion.d/git-completion.bash
    # ${BREW_PREFIX}/etc/bash_completion.d/git-prompt.sh
    if [ -h ${BREW_PREFIX}/etc/bash_completion ]; then
        . ${BREW_PREFIX}/etc/bash_completion
    fi

    # diff-highlight
    addpath ${BREW_PREFIX}/share/git-core/contrib/diff-highlight
elif [[ ${OSTYPE} =~ ^linux ]]; then
    # On Linux. Git is either installed from source or via the package manager
    #
    # /usr/share/git-core/contrib and /usr/share/doc/git/contrib/diff-highlight
    # are almost empty on Ubuntu 20.04 / 22.04
    #
    # This only matches if Git is either
    # A) Installed via source
    # B) Installed via apt-get and the install.sh script cloned
    #    https://github.com/lowply/git-contrib to /usr/local/git
    #
    # In the case of B, the install.sh script also checks out
    # the tag that's the exact same version of installed Git

    if [ -d /usr/local/git ]; then
        CONTRIB_PATH="/usr/local/git/contrib"
        addpath ${CONTRIB_PATH}/diff-highlight
        . ${CONTRIB_PATH}/completion/git-prompt.sh
        . ${CONTRIB_PATH}/completion/git-completion.bash
    fi
fi

#
# aws cli completion
#
has aws_completer && complete -C aws_completer aws

#
# GCP
#
if [[ ${OSTYPE} =~ ^darwin ]]; then
    if [ -d ${HOME}/google-cloud-sdk ]; then
        source "${HOME}/google-cloud-sdk/path.bash.inc"
        source "${HOME}/google-cloud-sdk/completion.bash.inc"
    fi
fi

#
# acme.sh
#
if [ -d ${HOME}/.acme.sh ]; then
    . "${HOME}/.acme.sh/acme.sh.env"
fi

#
# psone
#
psone

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# For SSH commit signing
if [ "${CODESPACES}" == "true" ] && [ "${TERM_PROGRAM}" == "vscode" ]; then
    for x in $(find /tmp/ssh-* -type s 2>/dev/null); do
        if SSH_AUTH_SOCK=${x} ssh-add -l > /dev/null; then
            echo "Setting SSH_AUTH_SOCK to ${x}"
            export SSH_AUTH_SOCK=${x}
            break
        fi
    done
fi

#
# env specific additions
#
if [ -f ${HOME}/.bashrc.local ]; then
    . ${HOME}/.bashrc.local
fi
