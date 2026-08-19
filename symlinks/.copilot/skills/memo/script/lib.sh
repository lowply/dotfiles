#!/bin/bash

resolve_repository() {
  repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$repo_root" ]; then
    echo "Run inside a git repository."
    return 1
  fi

  remote_url="$(git -C "$repo_root" config --get remote.origin.url || true)"
  if [ -z "$remote_url" ]; then
    echo "Could not resolve remote.origin.url."
    return 1
  fi

  repo_path="$(printf '%s\n' "$remote_url" | awk -F'[:/]' '{repo=$NF; sub(/\.git$/, "", repo); print $(NF-1) "/" repo}')"
  repo_owner="${repo_path%/*}"
  repo_name="${repo_path#*/}"
  if [ -z "$repo_owner" ] || [ -z "$repo_name" ]; then
    echo "Could not parse repo owner/name."
    return 1
  fi
}

find_repository_memos() {
  memo_dir="${HOME}/.copilot/memo"
  shopt -s nullglob
  files=( "$memo_dir"/*-"$repo_owner"-"$repo_name"-*.md )
  shopt -u nullglob

  if [ "${#files[@]}" -eq 0 ]; then
    echo "No memo files found for ${repo_owner}/${repo_name} in $memo_dir"
    return 1
  fi
}

find_memo_match() {
  local query="$1"
  local file memo_id_line summary_line likely_file content_line

  for file in "${files[@]}"; do
    memo_id_line="$(grep -m1 '^memo_id:' "$file" || true)"
    if printf '%s\n' "$memo_id_line" | grep -iFq -- "memo_id: \"$query\""; then
      top_path="$file"
      match_reason="id"
      match_line="$memo_id_line"
      return 0
    fi
  done

  for file in "${files[@]}"; do
    summary_line="$(grep -m1 '^summary:' "$file" || true)"
    if printf '%s\n' "$summary_line" | grep -iFq -- "$query"; then
      top_path="$file"
      match_reason="summary"
      match_line="$summary_line"
      return 0
    fi
  done

  likely_file="$(grep -ilF -- "$query" "${files[@]}" | head -n 1 || true)"
  if [ -n "$likely_file" ]; then
    content_line="$(grep -inF -- "$query" "$likely_file" | head -n 1 || true)"
    if [ -n "$content_line" ]; then
      top_path="$likely_file"
      match_reason="content"
      match_line="$content_line"
      return 0
    fi
  fi

  echo "No memo match for query: $query"
  return 1
}
