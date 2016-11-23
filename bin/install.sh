#!/bin/bash

. $(dirname $0)/lib.sh

BACKUPDIR="${HOME}/dotfiles_backup_${DATE}"

usage(){
	echo "Usage:"
	echo "    ${0}       # to run install"
	echo "    ${0} clean # to cleanup"
	exit 1
}

link(){
	local LIST_SYMLINKS=$(find ${HOME}/dotfiles -name "*.symlink")
	for x in ${LIST_SYMLINKS}; do
		local SRC=${x}
		local DST=$(echo ${x} | sed -e "s|^.*\/|${HOME}/.|" | sed -e "s|\.symlink||")
		if [ -r ${DST} ]; then
			mv ${DST} ${BACKUPDIR}
			message warn "A File, Symlink or Directory ${DST} already exists, moving to ${BACKUPDIR}"
		fi
		ln -s ${SRC} ${DST}
		message success "Created symlink from ${SRC} to ${DST}"
	done
}

unlink(){
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

check_old_file(){
	local TARGET=${1}
	if [ -f ${TARGET} ]; then
		mv ${TARGET} ${BACKUPDIR}
		message warn "${TARGET} already exists, moving to ${BACKUPDIR}"
	fi
}

create_bash_color(){
	check_old_file "${HOME}/.bash_color"
	cat <<- EOF > ${TARGET}
		#
		# bash color config
		# type "psone" to take effect immediately
		#

		local BACKGROUND=0
		local UNAME=198
		local SYMBOL=147
		local HOST=173
		local DIRNAME=120
		local PROMPT=129
		local BRANCH=111
	EOF
	echo "${TARGET} is created"
}

create_bashrc_local(){
	check_old_file "${HOME}/.bashrc.local"
	cat <<- EOF > ${TARGET}
		# env specific configs
	EOF
	echo "${TARGET} is created"
}

create_gitconfig_local(){
	check_old_file "${HOME}/.gitconfig.local"

	local EMAIL
	echo "Type your email address for git and hit [ENTER]:"
	read EMAIL

	cat <<- EOF > ${TARGET}
	[user]
		name = Sho Mizutani
		email = ${EMAIL}
	EOF
	echo "${TARGET} is created"
}

create_vimrc_local(){
	check_old_file "${HOME}/.vimrc.local"

	cat <<- EOF > ${TARGET}
		" env specific configs
	EOF
	echo "${TARGET} is created"
}

post_install(){
	echo "Please install dein, pyenv, python3, neovim and its pip module"
}

main(){
	[ $# -gt 1 ] && usage

	create_backupdir
	case "${1}" in
	"")
		link
		makedirs
		link_init_nvim

		create_bash_color
		create_bashrc_local
		create_gitconfig_local
		create_vimrc_local

		post_install
		;;
	"clean")
		unlink
		;;
	*)
		usage
		;;
	esac
}

main $@
