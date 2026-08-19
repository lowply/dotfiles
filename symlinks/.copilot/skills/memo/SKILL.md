---
name: memo
description: Use when the user asks to remember or recall repository-specific notes across sessions by saving and searching markdown memory files in the user home directory.
---

# Memo

Persist and recall repo-scoped notes across sessions.

## Storage layout

Save memory files under the memo directory:

`~/.copilot/memo/[DATE]-[ID]-[repo-owner]-[repo-name]-[name].md`

`[DATE]` uses `YYYY-MM-DD`. The current repository determines `[repo-owner]` and `[repo-name]`.

Using `~/.copilot/memo` keeps memos in a stable location that exists both locally and in Codespaces.

## File format

Each memory file must be markdown with YAML frontmatter that includes:

- `memo_id`: unix timestamp (`date +%s`)
- `summary`: searchable context summary (1-3 sentences, not just a title)
- `status`: `wip` or `done`
- `created_at`: ISO8601 timestamp
- `updated_at`: ISO8601 timestamp

The memo content belongs in the markdown body, not in frontmatter.

## Workflow

### 1. If user asks to **save memory**

Use this mode when the user says things like:
- “remember this”
- “save this for later”
- “memoize this decision”

#### Check if the current directory is a git repository. If not, stop.

```bash
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$repo_root" ]; then
  echo "Run inside a git repository."
  exit 1
fi
```

#### Get the repository metadata: Remote URL. If empty, stop.

```bash
remote_url="$(git -C "$repo_root" config --get remote.origin.url || true)"
if [ -z "$remote_url" ]; then
  echo "Could not resolve remote.origin.url."
  exit 1
fi
```

#### Get the repository metadata: Repository owner and name. If empty, stop.

```bash
repo_path="$(printf '%s\n' "$remote_url" | awk -F'[:/]' '{repo=$NF; sub(/\.git$/, "", repo); print $(NF-1) "/" repo}')"
repo_owner="${repo_path%/*}"
repo_name="${repo_path#*/}"
if [ -z "$repo_owner" ] || [ -z "$repo_name" ]; then
  echo "Could not parse repo owner/name."
  exit 1
fi
```

#### Determine the timestamp and ID

```bash
timestamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"
date_prefix="$(date +%Y-%m-%d)"
memo_id="$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 8; echo)"
```

#### Determine memory name from user input; otherwise come up with a short kebab-case name.

Use the user input or context to create a short, descriptive name for the memo. If no name is provided, generate one based on the topic or content.

#### Create a new memo file (run these in order, in one shell session):

```bash
memo_dir="$HOME/.copilot/memo"
mkdir -p "$memo_dir"

file_path="${memo_dir}/${date_prefix}-${memo_id}-${repo_owner}-${repo_name}-${name}.md"

cat >"$file_path" <<EOF
---
memo_id: "$memo_id"
summary: "TODO: add a 1-3 sentence summary"
status: "wip"
created_at: "$timestamp"
updated_at: "$timestamp"
---

# Memo note

TODO: add memo details.
EOF
echo "$file_path"
```

#### Fill in the generated file

Replace `summary` placeholder and memo body.

#### For updates

Find an existing file for the topic and edit it in place (preserve `memo_id` and `created_at`, update `updated_at`).

### 2. If user asks to **recall memory**

Use this mode when the user says things like:
- “remember what we decided about X”
- “what do you remember about Y”
- “recall notes for Z”

#### Get the repository metadata: Remote URL. If empty, stop.

```bash
remote_url="$(git -C "$repo_root" config --get remote.origin.url || true)"
if [ -z "$remote_url" ]; then
  echo "Could not resolve remote.origin.url."
  exit 1
fi
```

#### Get the repository metadata: Repository owner and name. If empty, stop.

```bash
repo_path="$(printf '%s\n' "$remote_url" | awk -F'[:/]' '{repo=$NF; sub(/\.git$/, "", repo); print $(NF-1) "/" repo}')"
repo_owner="${repo_path%/*}"
repo_name="${repo_path#*/}"
if [ -z "$repo_owner" ] || [ -z "$repo_name" ]; then
  echo "Could not parse repo owner/name."
  exit 1
fi
```

#### Find all memo files for the current repository. If none, stop.

```bash
memo_dir="$HOME/.copilot/memo"
shopt -s nullglob
files=( "$memo_dir"/*-"$repo_owner"-"$repo_name"-*.md )
shopt -u nullglob
if [ "${#files[@]}" -eq 0 ]; then
  echo "No memo files found for ${repo_owner}/${repo_name} in $memo_dir"
  exit 1
fi
```

#### Find the best match for the query in the memo files. If none, stop.

```bash
results_file="$(mktemp)"
summary_index_file="$(mktemp)"
trap 'rm -f "$results_file" "$summary_index_file"' EXIT

for file in "${files[@]}"; do
  memo_id_line="$(grep -m1 "^memo_id:" "$file")"
  summary_line="$(grep -m1 "^summary:" "$file")"
  printf "%s|%s|%s\n" "$file" "$memo_id_line" "$summary_line" >>"$summary_index_file"
done

id_hit="$(grep -iF -- "memo_id: \"$query\"" "$summary_index_file" | head -n 1 || true)"
if [ -n "$id_hit" ]; then
  file="$(echo "$id_hit" | cut -d"|" -f1)"
  line="$(echo "$id_hit" | cut -d"|" -f2)"
  echo "$file|id|$line" >>"$results_file"
else
  summary_hit="$(grep -iF -- "$query" "$summary_index_file" | head -n 1 || true)"
  if [ -n "$summary_hit" ]; then
    file="$(echo "$summary_hit" | cut -d"|" -f1)"
    line="$(echo "$summary_hit" | cut -d"|" -f3)"
    echo "$file|summary|$line" >>"$results_file"
  else
    likely_file="$(rg -i -l -F -- "$query" "${files[@]}" | head -n 1 || true)"
    if [ -n "$likely_file" ]; then
      content_line="$(rg -i -n -F -- "$query" "$likely_file" | head -n 1 || true)"
      if [ -n "$content_line" ]; then
        echo "$likely_file|content|$content_line" >>"$results_file"
      fi
    fi
  fi
fi

[ -s "$results_file" ] || { echo "No memo match for query: $query"; exit 1; }
```

#### Return the top match and candidates

```bash
top_row="$(head -n 1 "$results_file")"
top_path="$(echo "$top_row" | cut -d"|" -f1)"
reason="$(echo "$top_row" | cut -d"|" -f2)"
line="$(echo "$top_row" | cut -d"|" -f3-)"

echo "TOP_MATCH=$top_path"
echo "MATCH_COUNT=1"
echo "CANDIDATES:"
printf "1. [%s] %s :: %s\n" "$reason" "$top_path" "$line"
```

Default behavior: return top 1 best match, then ask if more are needed.

### 3. If user asks to **mark memory done**

Use this mode when the user says things like:
- “mark this as done”
- “this memo is done”
- “close out the note about X”

Locate the memo file (reuse the recall match logic above), then set its `status` to `done` and refresh `updated_at`. Preserve `memo_id` and `created_at`.

```bash
updated_at="$(date '+%Y-%m-%dT%H:%M:%S%z')"
sed -i '' \
  -e 's/^status:.*/status: "done"/' \
  -e "s/^updated_at:.*/updated_at: \"$updated_at\"/" \
  "$top_path"
echo "Marked done: $top_path"
```

## Guidelines

- Keep memories repository-scoped; do not mix notes across repos.
- Write `summary` as a compact paragraph with enough detail to disambiguate related notes.
- Do not hard-wrap prose around column 70; keep each paragraph on a single line.
- Preserve markdown readability so files are human-editable.
