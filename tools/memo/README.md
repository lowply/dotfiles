# Memo

`memo` stores scoped and unscoped notes as Markdown and provides an SQLite FTS5 index for fast search. Markdown files are the source of truth; the database is derived state that can be deleted and rebuilt.

## Storage

Canonical memos live under `~/.copilot/memo`:

```text
YYYY-MM-DD-ID-[owner-repository-]kebab-case-title.md
```

Each file contains required YAML frontmatter followed by an optional Markdown body:

```markdown
---
memo_id: "abc12345"
repository: "lowply/dotfiles"
name: "markdown-memos"
summary: "Use Markdown as the canonical memo store."
status: "wip"
created_at: "2026-08-22T12:00:00Z"
updated_at: "2026-08-22T12:00:00Z"
---

Memo details go here.
```

The frontmatter, not the filename, determines memo identity. IDs are globally unique, and status is either `wip` or `done`.
The `repository` value is an optional `owner/name`. Unscoped memos use an empty value:

```yaml
repository: ""
```

Set `MEMO_DIR` to override the canonical Markdown directory. Set
`MEMO_DB_PATH` to place the disposable SQLite index elsewhere. When only
`MEMO_DIR` is set, the database remains `<MEMO_DIR>/memo.db`.

## Commands

| Command | Purpose |
| --- | --- |
| `memo create [--repository owner/name \| --no-repository] <title>` | Create and index a `wip` memo, optionally reading its body from stdin. |
| `memo search [--limit N] [--status wip\|done] -- <query>` | Search IDs, repositories, names, summaries, and bodies. |
| `memo get <id>` | Return one memo's canonical path as JSON. |
| `memo show [--raw] <id>` | Print a memo body, or the complete canonical file with `--raw`. |
| `memo list [--status wip\|done]` | List indexed memos oldest first, with the latest at the bottom. |
| `memo done <id>` | Mark a memo done and update its timestamp. |
| `memo remove [--force] <id>` | Delete a memo file and index record after confirmation. |
| `memo rm [--force] <id>` | Alias for `memo remove`. |

Search and list results include the canonical path so the file can be read or edited directly. `memo get <id>` returns only `{"path":"..."}` for minimal machine-readable output. `memo show <id>` prints only the Markdown body. Use `memo show --raw <id>` to print the complete canonical file, including its YAML frontmatter.

By default, `memo create` uses `remote.origin.url` when the current directory is in a Git repository with a configured origin. It creates an unscoped memo when run outside Git or in a repository without an origin. Use `--repository owner/name` to set the repository explicitly, or `--no-repository` to create an unscoped memo even when an origin is available.

When stdin is piped or redirected, `memo create` preserves it as the initial Markdown body. Interactive terminal stdin is not read, so the command continues to create an empty body without waiting for EOF.

```bash
# Detect lowply/dotfiles from the current repository's origin.
memo create "Repository research"

# Associate a memo while outside the repository.
memo create --repository lowply/dotfiles "Repository research"

# Create a general research memo from any directory.
memo create --no-repository "General research"

# Create a memo with an initial body.
printf '# Findings\n\nDetails.\n' | memo create --no-repository "General research"

# Read a longer initial body from a file.
memo create --repository lowply/dotfiles "Repository research" < findings.md
```

## Search

`memo search` first treats the complete query as a possible memo ID. An exact ID match is returned immediately, subject to `--status`, without running a full-text search.

Otherwise, the query is split on whitespace and each term is quoted and joined with FTS5 `AND`. This means every term must appear somewhere in the indexed repository, name, summary, or body fields; terms do not need to appear in the same field or next to one another. Because terms are quoted, callers cannot supply FTS5 query syntax: operators such as `OR` and `NOT` and wildcard characters such as `*` are not interpreted specially.

```bash
# Matches a memo with this exact ID.
memo search -- abc12345

# Matches memos containing both "sqlite" and "index".
memo search -- sqlite index

# Applies the status filter to exact-ID and full-text searches.
memo search --status wip -- sqlite index
```

Full-text results are ordered by FTS5 `bm25()` relevance, then by `updated_at` newest first when scores tie. The ranking weights are repository `0.5`, name `1.0`, summary `2.0`, and body `1.0`, so summary matches contribute most strongly. An unscoped memo indexes an empty repository value. Search uses FTS5's `unicode61` tokenizer and returns five results by default; `--limit` accepts values from 1 through 100.

## Index and Consistency

Before operating, the CLI reconciles `~/.copilot/memo/*.md` with `memo.db`. For each path, it compares the current file size and `ModTime().UnixNano()` with the stored `file_size` and `mod_time_ns`. The file is skipped only when both values match; otherwise it is reparsed and reindexed. The index does not store content hashes.

Invalid files and duplicate IDs abort reconciliation rather than serving stale results. Mutations use atomic replacement where applicable. Status changes and removals revalidate the parsed memo before modifying it, so an intervening edit causes the operation to abort.

Canonical Markdown and SQLite behavior comes from the reusable
`github.com/lowply/markdownstore` module.

## Database Schema

`memo.db` is a disposable index whose schema is owned by the pinned
`github.com/lowply/markdownstore` module. Metadata is stored as normalized
key/value rows and search content is stored in weighted FTS slots. Table names
and columns are implementation details. An index created for an incompatible
configuration is replaced and rebuilt from canonical Markdown automatically.

The index stores file size and nanosecond modification time as filesystem
fingerprints. It represents an unscoped memo with an empty `repository`
string.

## Development

```bash
go test ./...
go build ./...
../../script/install-memo.sh
```

Run these commands from `tools/memo`.

## References

- [Markdown memo source-of-truth design](../../docs/superpowers/specs/2026-08-22-markdown-memo-source-of-truth-design.md)
- [Markdown memo implementation plan](../../docs/superpowers/plans/2026-08-22-markdown-memo-source-of-truth.md)
