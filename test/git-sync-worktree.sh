#!/bin/bash

set -euo pipefail

TEST_ROOT=/tmp/lowply-dotfiles-git-sync-test
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cleanup() {
    rm -rf /tmp/lowply-dotfiles-git-sync-test
}
trap cleanup EXIT

cleanup
mkdir -p "${TEST_ROOT}"

git init --bare --initial-branch=main "${TEST_ROOT}/remote.git" > /dev/null
git clone --quiet "${TEST_ROOT}/remote.git" "${TEST_ROOT}/feature-worktree"
git -C "${TEST_ROOT}/feature-worktree" config user.name Test
git -C "${TEST_ROOT}/feature-worktree" config user.email test@example.com

echo base > "${TEST_ROOT}/feature-worktree/file"
git -C "${TEST_ROOT}/feature-worktree" add file
git -C "${TEST_ROOT}/feature-worktree" commit --quiet -m base
git -C "${TEST_ROOT}/feature-worktree" push --quiet -u origin main
git -C "${TEST_ROOT}/feature-worktree" remote set-head origin main

git -C "${TEST_ROOT}/feature-worktree" switch --quiet -c feature
echo feature >> "${TEST_ROOT}/feature-worktree/file"
git -C "${TEST_ROOT}/feature-worktree" commit --quiet -am feature
git -C "${TEST_ROOT}/feature-worktree" push --quiet -u origin feature

git -C "${TEST_ROOT}/feature-worktree" worktree add --quiet "${TEST_ROOT}/main-worktree" main
git -C "${TEST_ROOT}/main-worktree" merge --quiet --no-ff feature -m merge-feature
git -C "${TEST_ROOT}/main-worktree" push --quiet origin main
git -C "${TEST_ROOT}/main-worktree" push --quiet origin --delete feature

echo dirty >> "${TEST_ROOT}/feature-worktree/file"
echo untracked > "${TEST_ROOT}/feature-worktree/untracked"

(
    cd "${TEST_ROOT}/feature-worktree"
    "${SCRIPT_DIR}/bin/git-sync"
)

if git -C "${TEST_ROOT}/feature-worktree" show-ref --verify --quiet refs/heads/feature; then
    echo "Expected git-sync to delete the merged current branch" >&2
    exit 1
fi

if [[ -n "$(git -C "${TEST_ROOT}/feature-worktree" branch --show-current)" ]]; then
    echo "Expected the feature worktree to detach at the default branch" >&2
    exit 1
fi

main_commit=$(git -C "${TEST_ROOT}/feature-worktree" rev-parse main)
head_commit=$(git -C "${TEST_ROOT}/feature-worktree" rev-parse HEAD)
if [[ "${head_commit}" != "${main_commit}" ]]; then
    echo "Expected the detached worktree to point at the default branch commit" >&2
    exit 1
fi

if [[ "$(tail -n 1 "${TEST_ROOT}/feature-worktree/file")" != "dirty" ]]; then
    echo "Expected git-sync to restore tracked worktree changes" >&2
    exit 1
fi

if [[ "$(cat "${TEST_ROOT}/feature-worktree/untracked")" != "untracked" ]]; then
    echo "Expected git-sync to restore untracked worktree changes" >&2
    exit 1
fi
