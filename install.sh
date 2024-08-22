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
    SRC="${WORKDIR}/symlinks"

    find ${SRC} -type f | while IFS= read -r FILE; do
        [ $(echo $FILE | xargs basename) = ".gitkeep" ] && continue

        # Exclude .bashrc for Codespaces
        [ -n "$CODESPACES" ] && [ $(echo $FILE | xargs basename) = ".bashrc" ] && continue

        DST="${FILE/${SRC}/${HOME}}"
        [ -d $(dirname ${DST}) ] || mkdir -p $(dirname ${DST})

        if [ -L ${DST} ]; then
            message info "A symlink ${DST} already exists, skipping"
        elif [ -e ${DST} ]; then
            message warn "A file or a directory ${DST} already exists, moving to backup and create a symlink"
            backup ${DST}
            ln -s ${FILE} ${DST}
        else
            ln -s ${FILE} ${DST}
            message success "Created a symlink from ${FILE} to ${DST}"
        fi
    done
}

copies(){
    SRC="${WORKDIR}/copies"

    find ${SRC} -type f | while IFS= read -r FILE; do
        [ $(echo $FILE | xargs basename) = ".gitkeep" ] && continue

        DST="${FILE/${SRC}/${HOME}}"
        [ -d $(dirname ${DST}) ] || mkdir -p $(dirname ${DST})

        if [ -L ${DST} ] || [ -e ${DST} ]; then
            message info "A file or a directory ${DST} already exists, skipping"
        else
            cp ${FILE} ${DST}
            message success "Copied file from ${FILE} to ${DST}"
        fi
    done
}

unlink(){
    SRC="${WORKDIR}/symlinks"

    find ${SRC} -type f | while IFS= read -r FILE; do
        [ $(echo $FILE | xargs basename) = ".gitkeep" ] && continue

        DST="${FILE/${SRC}/${HOME}}"

        if [ -L ${DST} ]; then
            message success "${DST} has been unlinked"
        else
            message warn "${DST} isn't a symlink, doing nothing"
        fi
    done
}

brew_bundle(){
    [[ ${OSTYPE} =~ ^darwin ]] && brew bundle || true
}

main(){
    [ $# -gt 1 ] && usage

    cd $(dirname $0)
    WORKDIR=$(pwd)

    if [[ ${OSTYPE} =~ ^darwin ]]; then
        export PATH="/opt/homebrew/bin:${PATH}"
        type brew > /dev/null 2>&1 || { echo "Install homebrew first."; exit 1; }
        [ -L $(brew --prefix)/opt/coreutils ] || { echo "Install coreutils first."; exit 1; }
        export PATH="$(brew --prefix)/opt/coreutils/libexec/gnubin:$PATH"
    else
        # Install peco
        has peco || { sudo apt update && sudo apt install peco; }
    fi

    # There's the Codespaces default .bashrc.
    # Instead of overriding it, this adds my .bashrc at the end of the default .bashrc
    [ -n "$CODESPACES" ] && echo ". ${WORKDIR}/symlinks/.bashrc" >> ${HOME}/.bashrc

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
