#!/bin/bash

. $(dirname $0)/bin/lib.sh

#/
#/ Subcommands:
#/
#/ install.sh          # Run install
#/ install.sh clean    # Cleanup symlinks
#/

[ -f /etc/os-release ] && . /etc/os-release

backup(){
    local TARGET=${1}
    local BACKUPDIR="${HOME}/.dotfiles_backup_${DATE}"
    [ -d ${BACKUPDIR} ] || mkdir ${BACKUPDIR}
    mv ${TARGET} ${BACKUPDIR}
}

git-contrib(){
    [[ ${OSTYPE} =~ ^linux ]] || return
    [ -d /usr/local/git ] && return

    sudo git clone https://github.com/lowply/git-contrib.git /usr/local/git
    cd /usr/local/git
    sudo git checkout $(git --version | sed -e "s/git version /v/")
    cd contrib/diff-highlight
    sudo make
}

symlinks(){
    cd ${WORKDIR}/symlinks

    local LIST_DIRS=$(find . -mindepth 1 -type d | sed -e 's/^\.\///') local LIST_FILES=$(find . -type f -not -name '.gitkeep' | sed -e 's/^\.\///')

    # Exclude .bashrc for Codespaces
    if [ -n "$CODESPACES" ]; then
        local LIST_FILES=$(echo ${LIST_FILES} | sed -e 's/.bashrc//')
    fi

    # make directories
    for D in ${LIST_DIRS}; do
        local DST="${HOME}/${D}"
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
    cd ${WORKDIR}/copies
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
    cd ${WORKDIR}/symlinks
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

brew_bundle(){
    cd ${WORKDIR}
    [[ ${OSTYPE} =~ ^darwin ]] && brew bundle || true
}

main(){
    [ $# -gt 1 ] && usage

    WORKDIR=$(cd $(dirname $0); pwd)

    if [[ ${OSTYPE} =~ ^darwin ]]; then
        export PATH="/opt/homebrew/bin:${PATH}"
        type brew > /dev/null 2>&1 || { echo "Install homebrew first."; exit 1; }
        [ -L $(brew --prefix)/opt/coreutils ] || { echo "Install coreutils first."; exit 1; }
        export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
    else
        # Install Kitty terminfo and peco
        sudo apt update && sudo apt install kitty-terminfo peco

        # There's the Codespaces default .bashrc.
        # Instead of overriding it, this adds my .bashrc at the end of the default .bashrc
        [ -n "$CODESPACES" ] && \
            echo ". ${WORKDIR}/symlinks/.bashrc" >> ${HOME}/.bashrc
    fi

    case "${1}" in
        "clean")
            unlink
        ;;
        *)
            git-contrib
            symlinks
            copies
            brew_bundle
        ;;
    esac
}

main $@
