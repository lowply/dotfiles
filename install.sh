#!/bin/bash

#/
#/ Usage: install.sh
#/
#/ install.sh          # Run install
#/ install.sh clean    # Cleanup symlinks
#/

. $(dirname $0)/bin/lib.sh

backup(){
    local TARGET=${1}
    local BACKUPDIR="${HOME}/.dotfiles_backup_$(date +%y%m%d_%H%M%S)"
    [ -d "${BACKUPDIR}" ] || mkdir "${BACKUPDIR}"
    mv "${TARGET}" "${BACKUPDIR}"
}

ghostty(){
    is_linux || return
    [ -f ${HOME}/.terminfo/x/xterm-ghostty ] || tic -x -o ${HOME}/.terminfo terminfo-ghostty
}

git_contrib(){
    is_linux || return
    [ -d /usr/local/git ] && return

    sudo git clone https://github.com/lowply/git-contrib.git /usr/local/git
    cd /usr/local/git || return
    sudo git checkout "$(git --version | sed -e 's/git version /v/')"
    cd contrib/diff-highlight || return
    sudo make
}

symlinks(){
    local SRC="${WORKDIR}/symlinks"

    find "${SRC}" -type f | while IFS= read -r FILE; do
        [ "$(basename ${FILE})" = ".gitkeep" ] && continue

        # Don't symlink these files on Linux
        if is_linux; then
            [ "$(basename ${FILE})" = ".bash_profile" ] && continue
            [ "$(basename ${FILE})" = "wezterm.lua" ] && continue
        fi

        DST="${FILE/${SRC}/${HOME}}"
        [ -d "$(dirname ${DST})" ] || mkdir -p "$(dirname ${DST})"

        if [ -L "${DST}" ]; then
            message info "A symlink ${DST} already exists, skipping"
        elif [ -e "${DST}" ]; then
            message warn "A file or a directory ${DST} already exists, taking a backup and creating a symlink"
            backup "${DST}"
            ln -s "${FILE}" "${DST}"
        else
            ln -s "${FILE}" "${DST}"
            message success "Created a symlink from ${FILE} to ${DST}"
        fi
    done
}

copies(){
    local SRC="${WORKDIR}/copies"

    find "${SRC}" -type f | while IFS= read -r FILE; do
        [ "$(basename ${FILE})" = ".gitkeep" ] && continue

        # Don't copy these files on Linux
        if is_linux; then
            echo "${FILE}" | grep -q "karabiner" && continue
        fi

        DST="${FILE/${SRC}/${HOME}}"
        [ -d "$(dirname ${DST})" ] || mkdir -p "$(dirname ${DST})"

        if [ -L "${DST}" ] || [ -e "${DST}" ]; then
            message info "A file or a directory ${DST} already exists, skipping"
        else
            cp "${FILE}" "${DST}"
            message success "Copied file from ${FILE} to ${DST}"
        fi
    done
}

unlink(){
    local SRC="${WORKDIR}/symlinks"

    find "${SRC}" -type f | while IFS= read -r FILE; do
        [ "$(basename ${FILE})" = ".gitkeep" ] && continue

        DST="${FILE/${SRC}/${HOME}}"

        if [ -L "${DST}" ]; then
            message success "${DST} has been unlinked"
        else
            message warn "${DST} isn't a symlink, doing nothing"
        fi
    done

    echo "Don't forget to delete the .bashrc_ line from your .bashrc"
}

brew_bundle(){
    is_darwin && brew bundle || true
}

bashrc_(){
    # Adds .bashrc_ at the end of the default .bashrc
    local ADDITION=". ${HOME}/.bashrc_"
    local TARGET="${HOME}/.bashrc"
    if ! grep -q "${ADDITION}" "${TARGET}"; then
        message info "Adding ${ADDITION} to ${TARGET}"
        echo -e "# Added by dotfiles installer\n${ADDITION}" >> "${TARGET}"
    fi
}

[ $# -gt 1 ] && usage

cd "$(dirname $0)" || return
WORKDIR="$(pwd)"

if is_darwin; then
    [ -d "/opt/homebrew" ] || abort "Install homebrew first."
    export PATH="/opt/homebrew/bin:$PATH"
    if [ ! -L "$(brew --prefix)/opt/coreutils" ]; then
        message info "Installing coreutils"
        brew install coreutils
    fi
    export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
else
    # Install peco
    has peco || { sudo apt update && sudo apt install peco; }
fi

case "${1}" in
    "clean")
        unlink
    ;;
    *)
        ghostty
        git_contrib
        copies
        symlinks
        bashrc_
        brew_bundle
    ;;
esac
