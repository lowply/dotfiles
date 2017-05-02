#!/bin/bash

. $(dirname $0)/lib.sh

usage(){
	cat <<- EOS
	Usage:
	$(basename ${0})          # create symlinks
	$(basename ${0}) cleanup  # cleanup symlinks
	EOS
	exit 1
}

symlink(){
	local SYMLINK_DIR="${HOME}/dotfiles/symlinks"
	for D in $(find ${SYMLINK_DIR} -mindepth 1 -type d); do
		local DST="${HOME}/${D##*/}"
		[ -d ${DST} ] || mkdir ${DST}
	done
	for F in $(find ${SYMLINK_DIR} -type f -not -name '.gitkeep'); do
		local SRC="${F}"
		local DST="$(echo ${F} | sed -e 's/\/dotfiles\/symlinks//g')"
		if [ -L ${DST} ] || [ -e ${DST} ]; then
			message warn "A symlink or a directory ${DST} already exists, moving to ${BACKUPDIR}"
			mv ${DST} ${BACKUPDIR}
		fi
		ln -s ${SRC} ${DST}
		message success "Created symlink from ${SRC} to ${DST}"
	done
}

symlink_nvim(){
	[ -d ${HOME}/.config/nvim ] || mkdir ${HOME}/.config/nvim
	local SRC="${HOME}/dotfiles/symlinks/.vimrc"
	local DST="${HOME}/.config/nvim/init.vim"
	[ -L ${DST} ] || ln -s ${SRC} ${DST}
}

copies(){
	local COPY_DIR="${HOME}/dotfiles/copies"
	for F in $(find ${COPY_DIR} -type f); do
		local SRC="${F}"
		local DST="$(echo ${F} | sed -e 's/\/dotfiles\/copies//g')"
		if [ -L ${DST} ] || [ -e ${DST} ]; then
			message warn "A file or a directory ${DST} already exists, do nothing"
		else
			cp ${SRC} ${DST}
			message success "Copied file from ${SRC} to ${DST}"
		fi
	done
}

unlink(){
	local SYMLINK_DIR="${HOME}/dotfiles/symlinks"
	for F in $(find ${SYMLINK_DIR} -type f -not -name '.gitkeep'); do
		local DST="$(echo ${F} | sed -e 's/\/dotfiles\/symlinks//g')"
		if [ -L ${DST} ]; then
			rm -f ${DST}
			message success "${DST} has been unlinked"
		fi
	done
}

main(){
	[ $# -gt 1 ] && usage

	BACKUPDIR="${HOME}/.dotfiles_backup_${DATE}"
	mkdir ${BACKUPDIR}

	case "${1}" in
		"")
			symlink
			symlink_nvim
			copies
			echo "Please install dein, pyenv, python3, neovim and its pip module"
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
