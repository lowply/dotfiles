---
name: memo
description: Use when the user asks to remember or recall searchable repository-specific notes across sessions.
---

# Memo

Persist and recall repository-specific notes through canonical Markdown files.

## Storage

Markdown is the source of truth. `memo create` writes:

`~/.copilot/memo/YYYY-MM-DD-ID-owner-repository-kebab-case-title.md`

Each file requires YAML frontmatter containing `memo_id`, `repository`, `name`, `summary`, `status`, `created_at`, and `updated_at`, followed by an optional Markdown body. `~/.copilot/memo/memo.db` is a disposable FTS5 index rebuilt from these files. Every command reconciles direct changes first.

## Commands

| Task | Command |
| --- | --- |
| Create | `memo create "<title>"` |
| Search | `memo search [--limit N] [--status wip\|done] -- "<query>"` |
| Locate by ID | `memo get "<id>"` |
| Inspect quickly | `memo show "<id>"` |
| List | `memo list [--status wip\|done]` |
| Complete | `memo done "<id>"` |
| Delete | `memo remove "<id>"` |

Report command errors and stop. If `memo` is unavailable, rerun the dotfiles installer.

## Workflow

### Save a memo

Run from the repository the memo belongs to:

```bash
memo create "This is a title"
```

The command returns the canonical `path` and creates an empty body. When details exceed the title, immediately edit that path: add durable context, preserve `memo_id` and `created_at`, and refresh `updated_at` in UTC.

### Recall a memo

Search for the memo:

```bash
memo search --limit 1 -- "$query"
```

Search is global. Select by repository and summary, then read the canonical `path`. For a known ID:

```bash
memo get "$memo_id"
```

`memo get` returns only `{"path":"..."}`. `memo show "$memo_id"` prints the complete file for human or quick agent inspection. An ID query performs exact lookup; otherwise every term must match repository, name, summary, or body. Summary matches rank highest.

### Edit a memo

Search for the intended memo, or use `memo get "$memo_id"`, then read and edit its canonical `path` directly. Preserve `memo_id` and `created_at`, refresh `updated_at` in UTC, and leave status changes to `memo done`.

### Mark a memo done

Search and confirm the intended memo before mutation:

```bash
memo done "$memo_id"
```

### List memos

Run `memo list`, optionally with `--status wip` or `--status done`. The latest memo appears last.

### Delete a memo

Delete a memo by its exact ID:

```bash
memo remove "$memo_id"
```

`memo rm` is an alias. Only after the user explicitly confirms deletion may the prompt be skipped:

```bash
memo remove --force "$memo_id"
```

## Common Mistakes

- Do not stop after `memo create` when the user supplied body details; edit the returned file.
- Do not query SQLite for a known memo; use `memo get` and read its canonical path.
- Do not treat search terms as alternatives; FTS5 joins them with `AND`.
- Do not edit `memo.db`; fix canonical Markdown when files are malformed or IDs are duplicated.
- Keep memos repository-specific, write disambiguating summaries, and keep prose paragraphs on single lines.
