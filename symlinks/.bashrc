# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# ---------------------------------------------------------------
# Original Setting
# ---------------------------------------------------------------

#
# reset default path and adding /usr/local/bin and /usr/local/sbin at proper position
#
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:${HOME}/bin"

#
# functions
#
addpath(){
	# [ -d ${1} ] || { echo "[addpath] ${1} does not exist."; return; }
	if [ "${2}" == "man" ]; then
		# for MANPATH
		export MANPATH=${1}:${MANPATH//$1:/}
	else
		# for PATH
		export PATH=${1}:${PATH//$1:/}
	fi
}

has(){
	type ${1} > /dev/null 2>&1
	return $?
}

error(){
	echo "${1}"
	return 1
}

mcd(){
	mkdir ${1} && cd ${1}
}

mksha512(){
	has "pip" || { echo "Please install pip"; return; }
	python -c "from passlib.hash import sha512_crypt" > /dev/null 2>&1 || { echo "Please run \"pip install passlib\""; return; }
	python -c "from passlib.hash import sha512_crypt; import getpass; print(sha512_crypt.encrypt(getpass.getpass()))"
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

peco-src () {
	has "peco" || error "peco is not installed"
	has "ghq" || error "ghq is not installed"
	[ -z "${GOPATH}" ] && error '$GOPATH is empty'
	local DIR="$(ghq list -p | sed -e "s|${GOPATH}/src/||g" | peco)"
	if [ ! -z "${DIR}" ]; then
		cd "${GOPATH}/src/${DIR}"
	fi
}

pero(){
	has "peco-beta" || { echo "peco-beta is not installed"; return 1; }
	has "pt" || { echo "pt is not installed"; return 1; }
	exec pt "$@" . | peco-beta --exec 'awk -F : '"'"'{print "+" $2 " " $1}'"'"' | xargs less '
}

pyhttp(){
	has "python3" || { echo "python3 is not installed"; return 1; }
	[ $# -eq 1 ] || { echo "pyhttp <port>"; return 1; }
	python3 -m http.server $1
}

# ~/.inputrc
# "\C-]":"peco-src\n"

# http://qiita.com/yungsang/items/09890a06d204bf398eea
peco-history() {
	has "peco" || return
	local NUM=$(history | wc -l)
	local FIRST=$((-1*(NUM-1)))

	if [ $FIRST -eq 0 ] ; then
		# Remove the last entry, "peco-history"
		history -d $((HISTCMD-1))
		echo "No history" >&2
		return
	fi
	export LC_ALL='C'
	local CMD=$(fc -l $FIRST | sort -k 2 -k 1nr | uniq -f 1 | sort -nr | sed -r 's/^[0-9]+//' | peco | head -n 1)
	peco-run-cmd "$CMD"
	unset LC_ALL
}

# ~/.inputrc
# "\C-r":"peco-history\n"

peco-snippets() {
	has "peco" || return
	[ -f ${HOME}/.snippets ] || { echo "Couldn't find ~/.snippets"; return; }
	local CMD=$(grep -v "^#" ~/.snippets | sed '/^$/d' | peco)
	peco-run-cmd "$CMD"
}

# ~/.inputrc
# "\C-s":"peco-snippets\n"

backup() {
	cp -a $1{,.$(date +%y%m%d_%H%M%S)}
}

# Docker

clean_docker_images(){
	for x in $(docker images | grep "<none>" | awk '{print $3}'); do docker rmi $x; done
}

clean_docker_containers(){
	for x in $(docker ps -a | grep Exited | awk '{print $1}'); do docker rm $x; done
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
alias ag='ag --ignore-case --hidden --ignore .git'

if has nvim; then
	alias vim='nvim'
fi

has gsed && alias sed='gsed'
has colordiff && alias diff='colordiff'
has gls && alias ls='ls -v --color=auto'


# Use the latest openssl
# [ -f /usr/local/opt/openssl/bin/openssl ] && alias openssl='/usr/local/opt/openssl/bin/openssl'

#
# LANG
#
export LANG=en_US.UTF-8

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
export LESS='-X -R -i -P ?f%f:(stdin).  ?lb%lb?L/%L..  [?eEOF:?pb%pb\%..]'

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
[ -x "/usr/local/bin/nvim" ] && export EDITOR=/usr/local/bin/nvim
has less && export PAGER=/usr/bin/less

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

	# load color config if exists
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

	if [ $(id -u) == 0 ]; then
		local BACKGROUND=0
		local UNAME=196
		local SYMBOL=226
		local HOST=196
		local DIRNAME=196
		local PROMPT=196
		local BRANCH=226
	fi

	GIT_PS1_SHOWDIRTYSTATE=true

	# set PS1
	export PS1="$(bgcolor $BACKGROUND)\t:$(fgcolor $UNAME)\u$(fgcolor $SYMBOL)@$(fgcolor $HOST)\h$(fgcolor $BRANCH)"'$(__git_ps1 ":(%s)")'"$(fgcolor $PROMPT)\n\$ $(resetcolor)"
}

#
# path
#
case "${OSTYPE}" in
darwin*)
	#
	# htop
	#
	if has htop; then
		alias htop='sudo htop'
	fi

	#
	# coreutils
	#
	[ -d /usr/local/opt/coreutils ] && addpath /usr/local/opt/coreutils/libexec/gnubin
	[ -d /usr/local/opt/coreutils ] && addpath /usr/local/opt/coreutils/libexec/gnuman man

	#
	# bash completion (need brew install bash-completion)
	#
	if [ -f $(brew --prefix)/etc/bash_completion ]; then
		. $(brew --prefix)/etc/bash_completion
	fi

	#
	# For Python 3
	#
	export LC_ALL="en_US.UTF-8"
	;;
linux*)
	#
    # rbenv
    #
    [ -d ${HOME}/.rbenv ] && addpath ${HOME}/.rbenv/bin

	#
	# n
	#
	export N_PREFIX="$HOME/n"
	[ -d ${N_PREFIX} ] && addpath ${N_PREFIX}/bin
	;;
esac

#
# git prompt and bash completion
#
case "${OSTYPE}" in
darwin*)
	# On macOS - installing git via homebrew will do most of the things
	if [ -d /usr/local/opt/git/etc/bash_completion.d ]; then
		# On macOS - installing git via homebrew will do most of the things
		GIT_COMPLETION_PATH="/usr/local/opt/git/etc/bash_completion.d"
	fi
	;;
linux*)
	GIT_VERSION=$(git --version | sed -e "s/git version //")

	if [ -d /usr/local/git ]; then
		# Installed from source - expecting the contrib directory is in /usr/local/git
		CONTRIB_PATH="/usr/local/git/contrib"
	elif [ -d /usr/local/src/git-${GIT_VERSION} ]; then
		# Installed via package manager and missing the contrib directory
		# Downlaod git tarball to /usr/local/src and extract it
		# Use the same version as the installed git, otherwise this won't work
		# You don't have to install bash-completion
		CONTRIB_PATH="/usr/local/src/git-${GIT_VERSION}/contrib"
	fi

	GIT_COMPLETION_PATH="${CONTRIB_PATH}/completion"
	[ -x "${CONTRIB_PATH}/diff-highlight/diff-highlight" ] || echo "Build diff-highlight in ${CONTRIB_PATH}/diff-highlight and create a symlink to /usr/local/bin/diff-highlight"
	;;
esac

. ${GIT_COMPLETION_PATH}/git-prompt.sh
. ${GIT_COMPLETION_PATH}/git-completion.bash

#
# dotfiles
#
[ -d ${HOME}/dotfiles/bin ] && addpath ${HOME}/dotfiles/bin

#
# aws cli completion
#
has aws_completer && complete -C aws_completer aws

#
# rbenv
#
[ -d ${HOME}/.rbenv ] && eval "$(rbenv init -)"

#
# golang
#
if has go; then
	export GOPATH=${HOME}
fi

#
# GCP
#
case "${OSTYPE}" in
darwin*)
	# The next line updates PATH for the Google Cloud SDK.
	source '/Users/lowply/google-cloud-sdk/path.bash.inc'

	# The next line enables shell command completion for gcloud.
	source '/Users/lowply/google-cloud-sdk/completion.bash.inc'
	;;
esac

#
# files
#
if has files; then
	# https://github.com/mattn/files/blob/master/files.go#L15
	FILES_IGNORE_PATTERN_LIST="
		\.git
		\.hg
		\.svn
		\.bzr
		\.keep
		\.sass-cache
		\.npm
		\.mozilla
		\.local
		\.rbenv
		\.gem
		\.vim_tmp
		\.cache
		\.node-gyp
		\.apm
		_darcs
		node_modules
		n
		backup
		dotfiles
		pkg
		bin
		compile-cache
		vendor
		packages
	"
	export FILES_IGNORE_PATTERN="^($(echo ${FILES_IGNORE_PATTERN_LIST} | tr ' ', '|'))$"
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
