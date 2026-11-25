#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
export HOME="${TMP}/home"
WORKDIR="${TMP}/dotfiles"
mkdir -p "${HOME}/.copilot" "${HOME}/.local/bin" \
    "${WORKDIR}/symlinks/.copilot/skills/example" "${TMP}/old-skills"
printf 'skill\n' > "${WORKDIR}/symlinks/.copilot/skills/example/SKILL.md"
printf 'config\n' > "${WORKDIR}/symlinks/.config-test"
printf 'broken\n' > "${WORKDIR}/symlinks/.broken-test"
printf 'new\n' > "${WORKDIR}/symlinks/.new-test"
printf 'backup\n' > "${WORKDIR}/symlinks/.backup-test"
printf 'original\n' > "${TMP}/old-config"
printf 'keep\n' > "${TMP}/old-skills/keep"
printf 'executable\n' > "${TMP}/command"
printf '%s\n' "${TMP}/command" > "${WORKDIR}/binlinks.txt"
printf 'local\n' > "${HOME}/.backup-test"
ln -s "${TMP}/old-config" "${HOME}/.config-test"
ln -s "${TMP}/missing" "${HOME}/.broken-test"
ln -s "${TMP}/old-skills" "${HOME}/.copilot/skills"
ln -s "${TMP}/missing-command" "${HOME}/.local/bin/command"

run_links() (
    . "${ROOT}/bin/lib.sh"
    # Load functions and argument parsing, not the installer's system setup.
    . <(sed -e '/^\. /d' -e '/^cd /,$d' "${ROOT}/install.sh"; echo true)
    symlinks
    bin_link
)

assert_link() {
    if [ ! -L "$1" ] || [ "$(readlink "$1")" != "$2" ]; then
        printf 'FAIL: expected %s to link to %s\n' "$1" "$2" >&2
        exit 1
    fi
}

run_links > "${TMP}/default.log"
assert_link "${HOME}/.config-test" "${TMP}/old-config"
assert_link "${HOME}/.broken-test" "${TMP}/missing"
assert_link "${HOME}/.copilot/skills" "${TMP}/old-skills"
assert_link "${HOME}/.local/bin/command" "${TMP}/missing-command"
assert_link "${HOME}/.new-test" "${WORKDIR}/symlinks/.new-test"
assert_link "${HOME}/.backup-test" "${WORKDIR}/symlinks/.backup-test"
BACKUP="$(find "${HOME}" -name .backup-test -type f)"
[ "$(cat "${BACKUP}")" = local ]

run_links -f > "${TMP}/force.log"
assert_link "${HOME}/.config-test" "${WORKDIR}/symlinks/.config-test"
assert_link "${HOME}/.broken-test" "${WORKDIR}/symlinks/.broken-test"
assert_link "${HOME}/.copilot/skills" "${WORKDIR}/symlinks/.copilot/skills"
assert_link "${HOME}/.local/bin/command" "${TMP}/command"
[ "$(cat "${TMP}/old-config")" = original ]
[ "$(cat "${TMP}/old-skills/keep")" = keep ]
[ ! -e "${TMP}/old-skills/skills" ]
[ ! -e "${TMP}/missing" ]
[ ! -e "${TMP}/missing-command" ]

run_links -f > "${TMP}/repeat.log"
assert_link "${HOME}/.copilot/skills" "${WORKDIR}/symlinks/.copilot/skills"
[ ! -e "${WORKDIR}/symlinks/.copilot/skills/skills" ]

if run_links -z > "${TMP}/invalid.log" 2>&1; then
    echo 'FAIL: unknown option was accepted' >&2
    exit 1
fi

KARABINER=".config/karabiner/assets/complex_modifications/lowply.js"
mkdir -p "${WORKDIR}/symlinks/$(dirname "${KARABINER}")"
cp "${ROOT}/symlinks/${KARABINER}" "${WORKDIR}/symlinks/${KARABINER}"

HOME="${TMP}/linux-home" OSTYPE=linux-gnu run_links > "${TMP}/linux.log"
[ ! -e "${TMP}/linux-home/.config/karabiner" ]

mkdir -p "${TMP}/darwin-home/$(dirname "${KARABINER}")"
printf 'original rules\n' > "${TMP}/darwin-home/${KARABINER}"
HOME="${TMP}/darwin-home" OSTYPE=darwin run_links > "${TMP}/darwin.log"
assert_link "${TMP}/darwin-home/${KARABINER}" "${WORKDIR}/symlinks/${KARABINER}"
BACKUP="$(find "${TMP}/darwin-home" -name lowply.js -type f)"
[ "$(cat "${BACKUP}")" = 'original rules' ]

brew() {
    printf '%s\n' "$@" >> "${BREW_LOG}"
    return "${BREW_STATUS:-0}"
}
export -f brew
export BREW_LOG="${TMP}/brew.log"

mkdir -p "${WORKDIR}/bin" "${WORKDIR}/copies" "${WORKDIR}/script" \
    "${TMP}/install-home"
cp "${ROOT}/install.sh" "${WORKDIR}/install.sh"
cp "${ROOT}/bin/lib.sh" "${WORKDIR}/bin/lib.sh"
printf '#!/bin/bash\nexit 0\n' > "${WORKDIR}/script/setup-gh-auth.sh"
chmod +x "${WORKDIR}/script/setup-gh-auth.sh"
touch "${TMP}/install-home/.bashrc"
HOME="${TMP}/install-home" OSTYPE=darwin bash "${WORKDIR}/install.sh" > "${TMP}/install.log"
[ ! -e "${BREW_LOG}" ]

(cd "${TMP}" && OSTYPE=darwin bash "${ROOT}/script/brew.sh")
printf 'bundle\n--file=%s/Brewfile\n' "${ROOT}" > "${TMP}/expected-brew.log"
cmp "${BREW_LOG}" "${TMP}/expected-brew.log"

if BREW_STATUS=7 OSTYPE=darwin bash "${ROOT}/script/brew.sh"; then
    echo 'FAIL: Homebrew failure was ignored' >&2
    exit 1
else
    [ "$?" -eq 7 ]
fi

if BREW_LOG="${TMP}/linux-brew.log" OSTYPE=linux-gnu bash "${ROOT}/script/brew.sh" > "${TMP}/linux-brew-output.log" 2>&1; then
    echo 'FAIL: Homebrew setup ran on Linux' >&2
    exit 1
fi
[ ! -e "${TMP}/linux-brew.log" ]

echo 'Installer tests passed'
