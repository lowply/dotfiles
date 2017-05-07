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

symlinks(){
	local BACKUPDIR="${HOME}/.dotfiles_backup_${DATE}"
	mkdir ${BACKUPDIR}

	cd ${HOME}/dotfiles/symlinks
	local LIST_DIRS=$(find . -mindepth 1 -type d | sed -e 's/^\.\///')
	local LIST_FILES=$(find . -type f -not -name '.gitkeep' | sed -e 's/^\.\///')

	# make directories
	for D in ${LIST_DIRS}; do
		local DST="${HOME}/${D}"
		[ -l ${DST} ] && mv ${DST} ${BACKUPDIR}
		[ -d ${DST} ] || mkdir -p ${DST}
	done

	# make symlinks
	for F in ${LIST_FILES}; do
		local SRC="$(readlink -f ${F})"
		local DST="${HOME}/${F}"
		if [ -L ${DST} ] || [ -e ${DST} ]; then
			message warn "A symlink or a directory ${DST} already exists, moving to ${BACKUPDIR}"
			mv ${DST} ${BACKUPDIR}
		fi
		ln -s ${SRC} ${DST}
		message success "Created a symlink from ${SRC} to ${DST}"
	done
}

copies(){
	cd ${HOME}/dotfiles/copies
	local LIST_FILES=$(find . -type f -not -name '.gitkeep' | sed -e 's/^\.\///')
	
	for F in ${LIST_FILES}; do
		local SRC="$(readlink -f ${F})"
		local DST="${HOME}/${F}"
		if [ -L ${DST} ] || [ -e ${DST} ]; then
			message warn "A file or a directory ${DST} already exists, doing nothing"
		else
			cp ${SRC} ${DST}
			message success "Copied file from ${SRC} to ${DST}"
		fi
	done
}

unlink(){
	cd ${HOME}/dotfiles/symlinks
	local LIST_FILES=$(find . -type f -not -name '.gitkeep' | sed -e 's/^\.\///')

	for F in ${LIST_FILES}; do
		local DST="${HOME}/${F}"
		if [ -L ${DST} ]; then
			rm -f ${DST}
			message success "${DST} has been unlinked"
		else
			message warn "${DST} isn't a symlink, doing nothing"
		fi
	done
}

main(){
	[ $# -gt 1 ] && usage

	case "${1}" in
		"")
			symlinks
			copies
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
