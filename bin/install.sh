#!/bin/bash

. $(dirname $0)/lib.sh

usage(){
	echo "Usage:"
	echo "    ${0}       # to run install"
	echo "    ${0} clean # to cleanup"
}

link(){
	local BACKUPDIR="${HOME}/dotfiles_backup_${DATE}"
	local LIST_SYMLINKS=$(find ${HOME}/dotfiles -name "*.symlink")
	for x in ${LIST_SYMLINKS}; do
		local SRC=${x}
		local DST=$(echo ${x} | sed -e "s|^.*\/|${HOME}/.|" | sed -e "s|\.symlink||")
		if [ -L ${DST} ]; then
			mv ${DST} ${BACKUPDIR}
			message warn "Symlink ${DST} already exists, moving to ${BACKUPDIR}"
		fi
		ln -s ${SRC} ${DST}
		message success "Created symlink from ${SRC} to ${DST}"
	done
}

unlink(){
	local BACKUPDIR="${HOME}/dotfiles_backup_${DATE}"
	local LIST_SYMLINKS=$(find ${HOME}/dotfiles -name "*.symlink")
	for x in ${LIST_SYMLINKS}; do
		local DST=$(echo ${x} | sed -e "s|^.*\/|${HOME}/.|" | sed -e "s|\.symlink||")
		if [ -L ${DST} ]; then
			rm -f ${DST}
			message success "${DST} has been unlinked"
		fi
	done
}

makedirs(){
	local DIRS="
		${HOME}/.config
		${HOME}/.config/nvim
		${HOME}/.cache
		${HOME}/.cache/dein
		${HOME}/.vim_tmp
	"
	for x in ${DIRS}; do
		[ -d ${x} ] || mkdir -p ${x}
	done
}

link_init_nvim(){
	local SRC="${HOME}/dotfiles/vim/vimrc.symlink"
	local DST="${HOME}/.config/nvim/init.vim"
	[ -L ${DST} ] || ln -s ${SRC} ${DST}
}

create_backupdir(){
	mkdir ${HOME}/dotfiles_backup_${DATE}
}

git_config_email(){
	echo "Type your email address for Git and hit [ENTER]:"
	read EMAIL
	git config --global user.email ${EMAIL}
}

post_install(){
	echo "Please install dein, pyenv, neovim, neovim pip module"
}

main(){
	[ $# -gt 1 ] && abort "Wrong number of arguments"

	create_backupdir
	case "${1}" in
	"")
		link
		makedirs
		link_init_nvim
		git_config_email
		post_install
		;;
	"clean")
		unlink
		;;
	*)
		abort "Incorrect argument: ${1}"
		;;
	esac
}

main $@
