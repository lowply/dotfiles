#!/usr/bin/env bash
#
# reference: https://github.com/holman/dotfiles
#

info () {
	printf "	[ \033[00;34m..\033[0m ] $1"
}

user () {
	printf "\r	[ \033[0;33m?\033[0m ] $1 "
}

success () {
	printf "\r\033[2K	[ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
	printf "\r\033[2K	[\033[0;31mFAIL\033[0m] $1\n"
	echo ''
	exit
}

link_file () {
	local src=$1 dst=$2 copy=$3

	if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]; then
		[ -d ${HOME}/dotfiles_backup_${DATE} ] || mkdir ${HOME}/dotfiles_backup_${DATE}
		user "File already exists: $dst ($(basename "$src")) \n"
		mv "$dst" ${HOME}/dotfiles_backup_${DATE}/
		success "moved $dst to ~/dotfiles_backup_${DATE}/"
	fi

	if [ $copy == true ]; then
		cp -a "$src" "$dst"
		success "copied $src to $dst"
	else
		ln -s "$src" "$dst"
		success "linked $src to $dst"
	fi
}

install_dotfiles () {
	cd "$(dirname "$0")/.."

	DATE=$(date +%y%m%d-%H%M%S)
	DOTFILES_ROOT=$(pwd)

	info "installing dotfiles..."

	for src in $(find "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink')
	do
		dst="$HOME/.$(basename "${src%.*}")"
		link_file "$src" "$dst" false
	done

	for src in $(find "$DOTFILES_ROOT" -maxdepth 2 -name '*.copy')
	do
		dst="$HOME/.$(basename "${src%.*}")"
		link_file "$src" "$dst" true
	done

	if [ ! -d "$HOME/.vim_tmp" ]; then
		mkdir $HOME/.vim_tmp
		info "created $HOME/.vim_tmp"
	fi
}

install_dotfiles
