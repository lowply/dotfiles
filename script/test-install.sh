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

echo 'Installer symlink tests passed'
