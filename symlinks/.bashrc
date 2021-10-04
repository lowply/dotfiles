# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

#
# Reset default path and adding /usr/local/bin and /usr/local/sbin at proper position
# except on GitHub Codespaces
#
uname -a | grep -q "^Linux codespaces" || export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

# Add brew path for Apple Sillicon macs
[[ ${OSTYPE} =~ ^darwin && ${HOSTTYPE} = "arm64" ]] && export PATH="/opt/homebrew/bin:${PATH}"

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

epoch () {
    if [ "$1" == "now" ]; then
        /bin/date -ju '+%F %T %Z';
    else
        /bin/date -jur $1 '+%F %T %Z';
    fi
}

#
# aliases
#
#alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias jman='LANG=ja_JP.utf8 man'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ls='ls -v --color=auto'
alias tm='tmux -2u a || tmux -2u'
alias zcat='gzcat'
alias pullall='git pull origin master && git submodule foreach git pull origin master'
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
        # CentOS / Mac
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
# path
#
if [[ ${OSTYPE} =~ ^darwin ]]; then
    # Silence zsh warning when using bash: https://support.apple.com/en-us/HT208050
    export BASH_SILENCE_DEPRECATION_WARNING=1

    has "brew" && export BREW_PREFIX="$(brew --prefix)" || { echo "brew is not installed"; return; }

    # aliasing every command with the 'g' prefix in ${BREW_PREFIX}/bin is not a great idea.
    # instead, let's just add the gnubin dir to the PATH
    addpath ${BREW_PREFIX}/opt/coreutils/libexec/gnubin

    # Use OpenSSL
    addpath ${BREW_PREFIX}/opt/openssl/bin

    # Ruby
    addpath ${BREW_PREFIX}/opt/ruby/bin
    addpath ${BREW_PREFIX}/lib/ruby/gems/2.7.0/bin

    # curl
    addpath ${BREW_PREFIX}/opt/curl/bin

elif [[ ${OSTYPE} =~ ^linux ]]; then
    # noop
    :
fi

# rbenv
[ -d ${HOME}/.rbenv ] && eval "$(rbenv init -)"

# dotfiles/bin
addpath ${HOME}/ghq/github.com/lowply/dotfiles/bin

# ~/bin
addpath ${HOME}/bin

# golang
addpath ${HOME}/go/bin

#
# git prompt, bash completion and diff-highlight
#
if [[ ${OSTYPE} =~ ^darwin ]]; then
    # bash completion (need brew install bash-completion)
    if [ -h ${BREW_PREFIX}/etc/bash_completion ]; then
        . ${BREW_PREFIX}/etc/bash_completion
    fi

    # git-prompt (need bash-completion)
    # I didn't like bash-git-prompt, just git-prompt.sh is fine
    if [ -h ${BREW_PREFIX}/etc/bash_completion.d/git-prompt.sh ]; then
        . ${BREW_PREFIX}/etc/bash_completion.d/git-prompt.sh
    fi

    # diff-highlight
    if [ ! -h ${BREW_PREFIX}/bin/diff-highlight ]; then
        CONTRIB_PATH="${BREW_PREFIX}/opt/git/share/git-core/contrib"
        ln -s ${CONTRIB_PATH}/diff-highlight/diff-highlight ${BREW_PREFIX}/bin
    fi
elif [[ ${OSTYPE} =~ ^linux ]]; then
    GIT_VERSION=$(git --version | sed -e "s/git version //")
    # On Linux. Git is either installed from source or via the package manager 
    # 
    # The contrib directory is empty on Ubuntu at least on 20.04
    # and it's incomplete on Amazon Linux 2 / CentOS 8.
    # The install.sh script will download the git tarball
    # and extract it into /usr/local/git

    if [ -d /usr/local/git ]; then
        CONTRIB_PATH="/usr/local/git/contrib"
        GIT_COMPLETION_PATH="${CONTRIB_PATH}/completion"

        if [ ! -h "/usr/local/bin/diff-highlight" ]; then
            echo "Look for diff-highlight in ${CONTRIB_PATH} and symlink into /usr/local/bin/"
        fi

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

#
# env specific additions
#
if [ -f ${HOME}/.bashrc.local ]; then
    . ${HOME}/.bashrc.local
fi
