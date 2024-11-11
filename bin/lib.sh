#/bin/bash

usage() {
    grep '^#/' < "${0}" | cut -c4-
    exit 1
}

logfile(){
    LOGDIR="${HOME}/.log/$(basename $0)"
    LOGFILE="${LOGDIR}/$(date +%y%m%d).log"

    mkdir -p "${LOGDIR}"
    [ -f "${LOGFILE}" ] || touch ${LOGFILE}
    echo "${LOGFILE}"
}

logger(){
    LOGFILE=$(logfile)
    echo "$(date): [Info] ${1}" | tee -a "${LOGFILE}"
}

logger_error(){
    LOGFILE=$(logfile)
    echo "$(date): [Error] ${1}" | tee -a "${LOGFILE}" 1>&2
    exit 1
}

abort(){
    message error "${1}"; exit 1
}

error(){
    message error "${1}"; return 1
}

has(){
    type "${1}" >/dev/null 2>&1; return $?
}

is_darwin(){
    echo "${OSTYPE}" | grep -q "darwin"; return $?
}

is_linux(){
    echo "${OSTYPE}" | grep -q "linux"; return $?
}

is_ubuntu(){
    [ "$(source /etc/os-release && echo $NAME)" = "Ubuntu" ]
}

is_codespaces(){
    [ "${CODESPACES}" = "true" ]
}

# ensure_* functions abort if the condition is not met

ensure_args(){
    [ "${1}" -eq "${2}" ] || abort "${3}"
}

ensure_dir(){
    [ -d "${1}" ] || abort "No such directory: ${1}"
}

ensure_file(){
    [ -f "${1}" ] || abort "No such file: ${1}"
}

color(){
    case "${1}" in
        black) local COLOR="\e[30m" ;;
        red) local COLOR="\e[31m" ;;
        green) local COLOR="\e[32m" ;;
        yellow) local COLOR="\e[33m" ;;
        blue) local COLOR="\e[34m" ;;
        magenta) local COLOR="\e[35m" ;;
        cyan) local COLOR="\e[36m" ;;
        white) local COLOR="\e[37m" ;;
        *) local COLOR="\e[37m" ;;
    esac
    local RESET="\e[39m"
    printf "${COLOR}${2}${RESET}\n"
}

message(){
    case "${1}" in
    success)
        echo "[ $(color green OK) ] ${2}"
    ;;
    info)
        echo "[ $(color blue INFO) ] ${2}"
    ;;
    user)
        echo "[ $(color yellow ??) ] ${2}"
    ;;
    warn)
        echo "[ $(color yellow WARN) ] ${2}"
    ;;
    error)
        echo "[ $(color red ERROR) ] ${2}"
    ;;
    fail)
        echo "[ $(color red FAIL) ] ${2}"
    ;;
    *)
        echo "Incorrect Argument"
    ;;
    esac
}
