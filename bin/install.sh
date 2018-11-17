#!/bin/bash

. $(dirname $0)/lib.sh

#/
#/ Subcommands:
#/ 
#/ install.sh          # create symlinks
#/ install.sh clean    # cleanup symlinks
#/

usage() {
	grep '^#/' < ${0} | cut -c4-
	exit 1
}

backup(){
	local TARGET=${1}
	local BACKUPDIR="${HOME}/.dotfiles_backup_${DATE}"
	[ -d ${BACKUPDIR} ] || mkdir ${BACKUPDIR}
	mv ${TARGET} ${BACKUPDIR}
}

symlinks(){
	cd ${HOME}/dotfiles/symlinks
	local LIST_DIRS=$(find . -mindepth 1 -type d | sed -e 's/^\.\///')
	local LIST_FILES=$(find . -type f -not -name '.gitkeep' | sed -e 's/^\.\///')

	# make directories
	for D in ${LIST_DIRS}; do
		local DST="${HOME}/${D}"
		[ -L ${DST} ] && backup ${DST}
		[ -d ${DST} ] || mkdir -p ${DST}
	done

	# make symlinks
	for F in ${LIST_FILES}; do
		local SRC="$(readlink -f ${F})"
		local DST="${HOME}/${F}"
		if [ -L ${DST} ]; then
			message info "A symlink ${DST} already exists, skipping"
		elif [ -e ${DST} ]; then
			message warn "A file or a directory ${DST} already exists, moving to backup and create a symlink"
			backup ${TARGET} ${DST}
			ln -s ${SRC} ${DST}
		else
			ln -s ${SRC} ${DST}
			message success "Created a symlink from ${SRC} to ${DST}"
		fi
	done
}

copies(){
	cd ${HOME}/dotfiles/copies
	local LIST_FILES=$(find . -type f -not -name '.gitkeep' | sed -e 's/^\.\///')
	
	for F in ${LIST_FILES}; do
		local SRC="$(readlink -f ${F})"
		local DST="${HOME}/${F}"
		if [ -L ${DST} ] || [ -e ${DST} ]; then
			message info "A file or a directory ${DST} already exists, skipping"
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

	case "${OSTYPE}" in
	darwin*)
		[ -d /usr/local/opt/coreutils ] || { echo "Install coreutils first."; exit 1; }
		export PATH=$PATH:/usr/local/opt/coreutils/libexec/gnubin
	esac

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
