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
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

#
# functions
#
addpath(){
	[ -d ${1} ] || return
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
alias make='gmake'

has gsed && alias sed='gsed'
has colordiff && alias diff='colordiff'
has gls && alias ls='ls -v --color=auto'
has ggrep && alias grep='ggrep'

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

	# set PS1
	export PS1="\t:$(fgcolor $UNAME)\u$(fgcolor $SYMBOL)@$(fgcolor $HOST)\h$(fgcolor $BRANCH)"'$(__git_ps1 ":(%s)")'"$(fgcolor $PROMPT)\n\$ $(resetcolor)"
}

#
# path
#
case "${OSTYPE}" in
darwin*)
	# coreutils
	addpath /usr/local/opt/coreutils/libexec/gnubin
	addpath /usr/local/opt/coreutils/libexec/gnuman man

	# Use OpenSSL
	addpath /usr/local/opt/openssl/bin

	#
	# bash completion (need brew install bash-completion)
	#
	if [ -f $(brew --prefix)/etc/bash_completion ]; then
		. $(brew --prefix)/etc/bash_completion
	fi
	;;
linux*)
	# rbenv
	addpath ${HOME}/.rbenv/bin

	# n
	export N_PREFIX="$HOME/n"
	addpath ${N_PREFIX}/bin
	;;
esac

# dotfiles/bin
addpath ${HOME}/ghq/github.com/lowply/dotfiles/bin

# ~/bin
addpath ${HOME}/bin

# golang
addpath ${HOME}/go/bin

#
# git prompt and bash completion
#
case "${OSTYPE}" in
darwin*)
	# On macOS - https://support.apple.com/en-us/HT208050
	export BASH_SILENCE_DEPRECATION_WARNING=1

	# On macOS - installing git via homebrew will do most of the things
	BREW_GIT="/usr/local/opt/git"
	CONTRIB_PATH="${BREW_GIT}/share/git-core/contrib"
	if [ -d ${BREW_GIT}/etc/bash_completion.d ]; then
		GIT_COMPLETION_PATH="${BREW_GIT}/etc/bash_completion.d"
	fi
	;;
linux*)
	GIT_VERSION=$(git --version | sed -e "s/git version //")

	if [ -d /usr/local/git ]; then
		# Installed from source - expecting the contrib directory is in /usr/local/git
		CONTRIB_PATH="/usr/local/git/contrib"
	elif [ -d /usr/share/git-core ]; then
		# Installed via package manager. Amazon Linux 2 for most cases
		CONTRIB_PATH="/usr/share/git-core/contrib"
	elif [ -d /usr/local/src/git-${GIT_VERSION} ]; then
		# Installed via package manager and missing the contrib directory

		# Downlaod git tarball to /usr/local/src and extract it
		# Use the same version as the installed git, otherwise this won't work
		# You don't have to install bash-completion
		CONTRIB_PATH="/usr/local/src/git-${GIT_VERSION}/contrib"
	fi

	GIT_COMPLETION_PATH="${CONTRIB_PATH}/completion"

	;;
esac

if [ ! -L "/usr/local/bin/diff-highlight" ]; then
	echo "Looking for diff-highlight in the ${CONTRIB_PATH} dir..."
	echo "============================================"
	find /usr/share/git-core -type f -name "diff-highlight"
	echo "============================================"
	echo "Run ln -s <PATH> /usr/local/bin/ to create a symlink"
fi

. ${GIT_COMPLETION_PATH}/git-prompt.sh

#
# aws cli completion
#
has aws_completer && complete -C aws_completer aws

#
# rbenv
#
[ -d ${HOME}/.rbenv ] && eval "$(rbenv init -)"

#
# GCP
#
case "${OSTYPE}" in
darwin*)
	if [ -d ${HOME}/google-cloud-sdk ]; then
		source "${HOME}/google-cloud-sdk/path.bash.inc"
		source "${HOME}/google-cloud-sdk/completion.bash.inc"
	fi
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
		\.nvim_tmp
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
