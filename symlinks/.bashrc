# .bashrc

# Source global definitions
[ -f /etc/bashrc ] && . /etc/bashrc

# Set dotfiles dir
if [ -n "${CODESPACES}" ]; then
    DOTFILES_DIR="/workspaces/.codespaces/.persistedshare/dotfiles"
else
    DOTFILES_DIR="$(dirname $(dirname $(realpath ${BASH_SOURCE})))"
fi

# Source dotfiles/bin/lib.sh
. "${DOTFILES_DIR}/bin/lib.sh"

#
# Reset default path and add /usr/local/bin and /usr/local/sbin at proper position
# except on GitHub Codespaces
#
[ -z "${CODESPACES}" ] && export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

#
# functions
#
addpath(){
    [ -d "${1}" ] && export PATH="${1}:${PATH//$1:/}"
}

peco-run-cmd(){
    [ "$#" -ne 1 ] && return
    # Replace the last entry, with $1
    history -s "${1}"
    # Execute it
    echo "${1}" >&2
    eval "${1}"
}

# See ~/.inputrc
peco-cd-repo () {
    has "peco" || { error "peco is not installed"; return; }
    if is_codespaces; then
        local DIR="$(find /workspaces -maxdepth 1 -mindepth 1 -type d -not -path '*/.*' | peco)"
        [ -n "${DIR}" ] && cd "${DIR}" || return
    else
        has "ghq" || { error "ghq is not installed"; return; }
        local GHQDIR="${HOME}/ghq"
        local DIR="$(ghq list | peco)"
        [ -n "${DIR}" ] && cd "${GHQDIR}/${DIR}" || return
    fi
}

# See ~/.inputrc
peco-snippets() {
    has "peco" || { error "peco is not installed"; return; }
    if [ -f "${HOME}/.snippets" ]; then
        local CMD=$(cat ~/.snippets | sed '/^#.*$/d' | sed '/^$/d' | peco)
        peco-run-cmd "$CMD"
    else
         error "Couldn't find ~/.snippets"
    fi
}

backup() {
    cp -a "${1}"{,.$(date +%y%m%d_%H%M%S)}
}

colortext(){
    printf "\[$(tput setaf ${2})\]${1}\[$(tput sgr0)\]"
}

#
# aliases
#

alias jman='LANG=ja_JP.utf8 man'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias nstlnp='lsof -nP -iTCP -sTCP:LISTEN'
alias nstanp='lsof -nP -iTCP'
alias lsdsstr='find . -name .DS_Store -print'
alias rmdsstr='find . -name .DS_Store -delete -exec echo removed: {} \;'

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
# set EDITOR, PAGER
#

for P in /usr/bin/vim /usr/local/bin/vim /opt/homebrew/bin/vim; do
    [ -x ${P} ] && export EDITOR=${P}
done

for P in /usr/bin/less /opt/homebrew/bin/less; do
    [ -x ${P} ] && export PAGER=${P}
done

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
# $PATH
#

# ~/bin
addpath "${HOME}/bin"

# dotfiles/bin
addpath "${DOTFILES_DIR}"/bin

# go
addpath "${HOME}"/go/bin

if is_darwin; then
    # Silence zsh warning when using bash: https://support.apple.com/en-us/HT208050
    export BASH_SILENCE_DEPRECATION_WARNING=1

    [ -f "/opt/homebrew/bin/brew" ] || error "brew is not installed"

    export BREW_PREFIX="$(/opt/homebrew/bin/brew --prefix)"

    addpath "${BREW_PREFIX}/bin"

    # aliasing every command with the 'g' prefix in ${BREW_PREFIX}/bin is not a great idea.
    # instead, let's just add the gnubin dir to the PATH
    addpath "${BREW_PREFIX}/opt/coreutils/libexec/gnubin"

    # Prefer OpenSSL over LibreSSL
    addpath "${BREW_PREFIX}/opt/openssl/bin"

    # Ruby and Gems
    addpath "${BREW_PREFIX}/opt/ruby/bin"
    has gem && addpath "$(gem environment | grep "EXECUTABLE DIRECTORY: " | cut -d ':' -f 2 | xargs)"

    # curl
    addpath "${BREW_PREFIX}/opt/curl/bin"

    # for dnsmasq, dsvpn etc
    addpath "${BREW_PREFIX}/sbin"

    # wezterm
    addpath /Applications/WezTerm.app/Contents/MacOS

    has gsed && alias sed='gsed'
    has gawk && alias awk='gawk'
    has ggrep && alias grep='ggrep'
    has gmake && alias make='gmake'
    has gzcat && alias zcat='gzcat'

    # https://sw.kovidgoyal.net/kitty/kittens/ssh/
    has kitten && alias kssh='kitten ssh'
elif is_linux; then
    # noop
    :
fi

#
# brew install source-highlight for macOS
#  apt install source-highlight for Ubuntu
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

# rbenv
#
# On macOS, rbenv should be installed via Homebrew
# On Codespaces, rbenv is pre-installed in the base image
# On Debian/Ubuntu, installing rbenv via apt is not recommended. See:
# https://github.com/rbenv/rbenv#debian-ubuntu-and-their-derivatives
#
# ~/.rbenv/bin only exists when rbenv is installed via Git
#
if [ -d "${HOME}/.rbenv" ]; then
    addpath "${HOME}/.rbenv/bin"
    eval "$(rbenv init -)"
fi

# n
if has n; then
    export N_PREFIX="${HOME}/.n"
    addpath "${HOME}/.n/bin"
fi

#
# git prompt, bash completion and diff-highlight
#
if is_darwin; then
    # bash completion (need brew install bash-completion)
    # This will automatically include
    # ${BREW_PREFIX}/etc/bash_completion.d/git-completion.bash
    # ${BREW_PREFIX}/etc/bash_completion.d/git-prompt.sh
    if [ -h ${BREW_PREFIX}/etc/bash_completion ]; then
        . "${BREW_PREFIX}/etc/bash_completion"
    fi

    # diff-highlight
    addpath ${BREW_PREFIX}/share/git-core/contrib/diff-highlight
elif is_linux; then
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
        addpath "${CONTRIB_PATH}/diff-highlight"
        . "${CONTRIB_PATH}/completion/git-prompt.sh"
        . "${CONTRIB_PATH}/completion/git-completion.bash"
    fi
fi

#
# aws cli completion
#
has aws_completer && complete -C aws_completer aws

#
# GCP
#

if is_darwin && [ -d "${HOME}/google-cloud-sdk" ]; then
    source "${HOME}/google-cloud-sdk/path.bash.inc"
    source "${HOME}/google-cloud-sdk/completion.bash.inc"
fi

#
# acme.sh
#
[ -d "${HOME}/.acme.sh" ] && . "${HOME}/.acme.sh/acme.sh.env"

#
# psone
#
psone(){
    GIT_PS1_SHOWDIRTYSTATE=true
    GIT_PS1_SHOWUNTRACKEDFILES=true
    GIT_PS1_SHOWUPSTREAM="auto"
    GIT_PS1_SHOWCOLORHINTS=true

    # color config
    if [ $(id -u) = 0 ]; then
        local UNAME=196
        local SYMBOL=226
        local HOST=196
        local DIRNAME=196
        local PROMPT=196
    else
        if [ -f ${HOME}/.bash_color ]; then
            . ${HOME}/.bash_color
        else
            local UNAME=252
            local SYMBOL=3
            local HOST=252
            local DIRNAME=252
            local PROMPT=3
        fi
    fi

    # Double escape to suppress printf unicode warning
    pc_u=$(colortext "\\\u" "${UNAME}")
    pc_s=$(colortext "@"  "${SYMBOL}")
    pc_h=$(colortext "\h" "${HOST}")
    pc_d=$(colortext "\w" "${DIRNAME}")
    pc_p=$(colortext "$"  "${PROMPT}")

    # set PS1
    # reference: https://github.com/git/git/blob/v2.44.0/contrib/completion/git-prompt.sh#L23
    export PROMPT_COMMAND="__git_ps1 \"${pc_u}${pc_s}${pc_h}:${pc_d}\" \"\n${pc_p} \""
}

psone

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# For SSH commit signing
${DOTFILES_DIR}/bin/sshauthsock.sh

#
# env specific additions
#
[ -f "${HOME}/.bashrc.local" ] && . "${HOME}/.bashrc.local"

