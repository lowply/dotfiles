#!/bin/bash

set -u

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

run_herdr() {
  local description="$1"
  shift

  if ! HERDR_RESULT="$(herdr "$@" 2>&1)"; then
    printf '%s\n' "$HERDR_RESULT" >&2
    fail "$description failed."
  fi
}

if [ "${HERDR_ENV:-}" != "1" ]; then
  fail "This skill must be run inside Herdr."
fi

if [ -z "${HERDR_WORKSPACE_ID:-}" ]; then
  fail "Herdr did not provide a workspace ID."
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" ||
  fail "Run this skill inside a Git repository."

repo_name="$(basename "$repo_root" | tr '[:upper:]' '[:lower:]' | sed \
  -e 's/[^a-z0-9_-]/-/g' \
  -e '/^[^a-z]/ s/^/r-/' \
  -e 's/-*$//')"

run_herdr "Listing live Herdr agents" agent list
agent_list="$HERDR_RESULT"
if ! printf '%s\n' "$agent_list" |
  jq -e '.result.agents | type == "array"' >/dev/null 2>&1; then
  fail "Herdr returned an invalid agent list."
fi

run_herdr "Listing Herdr tabs" tab list --workspace "$HERDR_WORKSPACE_ID"
tab_list="$HERDR_RESULT"
if ! printf '%s\n' "$tab_list" |
  jq -e '.result.tabs | type == "array"' >/dev/null 2>&1; then
  fail "Herdr returned an invalid tab list."
fi

number=1
while :; do
  suffix="-$number"
  max_prefix_length=$((32 - ${#suffix}))
  prefix="${repo_name:0:$max_prefix_length}"
  agent_name="${prefix}${suffix}"

  if ! printf '%s\n' "$agent_list" |
    jq -e --arg name "$agent_name" \
      'any(.result.agents[]?; .name? == $name)' >/dev/null &&
    ! printf '%s\n' "$tab_list" |
      jq -e --arg name "$agent_name" \
        'any(.result.tabs[]?; .label? == $name)' >/dev/null; then
    break
  fi

  number=$((number + 1))
done

run_herdr "Creating the Herdr tab" tab create \
  --workspace "$HERDR_WORKSPACE_ID" \
  --cwd "$PWD" \
  --label "$agent_name" \
  --no-focus
tab_result="$HERDR_RESULT"

pane_id="$(printf '%s\n' "$tab_result" |
  jq -er '.result.root_pane.pane_id | select(type == "string" and length > 0)' \
    2>/dev/null)" ||
  fail "Herdr created the tab but did not return its root pane ID."

attempt=1
while :; do
  if start_result="$(herdr agent start "$agent_name" \
    --kind copilot \
    --pane "$pane_id" \
    --timeout 60000 2>&1)"; then
    break
  fi

  if ! printf '%s\n' "$start_result" |
    jq -e '.error.code == "agent_pane_busy"' >/dev/null 2>&1; then
    printf '%s\n' "$start_result" >&2
    fail "Starting the Copilot session failed."
  fi

  if [ "$attempt" -ge 60 ]; then
    printf '%s\n' "$start_result" >&2
    fail "The new pane did not reach an interactive shell prompt."
  fi

  sleep 0.5
  attempt=$((attempt + 1))
done

arguments="${1-}"
if [ "$#" -gt 1 ]; then
  shift
  arguments="$arguments $*"
fi

if ! prompt_result="$(herdr agent prompt "$agent_name" "$arguments" 2>&1)"; then
  printf '%s\n' "$prompt_result" >&2
  fail "Submitting the subtask prompt failed."
fi

printf 'Agent name: %s\nTab label: %s\n' "$agent_name" "$agent_name"
