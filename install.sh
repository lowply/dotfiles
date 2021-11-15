#!/bin/bash

. $(dirname $0)/bin/lib.sh

#/
#/ Subcommands:
#/ 
#/ install.sh          # Run install
#/ install.sh clean    # Cleanup symlinks
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

deps(){
    if [ "${OSTYPE}" == "linux-gnu" -a ! -d /usr/local/git ]; then
        if [ -f /etc/arch-release ]; then
            CONTRIB_PATH=/usr/share/git
        else
            GIT_VERSION=$(git --version | sed -e "s/git version //")
            cd /usr/local/src
            sudo curl -OL https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz
            sudo tar xzf git-${GIT_VERSION}.tar.gz
            sudo mv git-${GIT_VERSION} /usr/local/git
            CONTRIB_PATH="/usr/local/git/contrib"
            cd ${CONTRIB_PATH}/diff-highlight
            sudo make
        fi
        sudo ln -s ${CONTRIB_PATH}/diff-highlight/diff-highlight /usr/local/bin
    fi
}

symlinks(){
    cd ${WORKDIR}/symlinks

    local LIST_DIRS=$(find . -mindepth 1 -type d | sed -e 's/^\.\///')
    local LIST_FILES=$(find . -type f -not -name '.gitkeep' | sed -e 's/^\.\///')

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

main(){
    [ $# -gt 1 ] && usage

    WORKDIR=$(cd $(dirname $0); pwd)

    if [[ ${OSTYPE} =~ ^darwin ]]; then
        [[ ${HOSTTYPE} = "arm64" ]] && export PATH="/opt/homebrew/bin:${PATH}"
        type brew > /dev/null 2>&1 || { echo "Install homebrew first."; exit 1; }
        [ -d $(brew --prefix)/opt/coreutils ] || { echo "Install coreutils first."; exit 1; }
        export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
    fi

    case "${1}" in
        "clean")
            unlink
        ;;
        *)
            deps
            symlinks
            copies
        ;;
    esac
}

main $@
