---
name: bear
description: Use when the user asks to remember, recall, update, complete, or delete durable notes across sessions using Bear.
---

# Bear

Persist and recall durable memos through `bearcli`. Bear owns note IDs, timestamps, search, and storage.

## Storage

Each memo settles with one status tag:

- `memo/wip` for active memos
- `memo/done` for completed memos

Use a descriptive note title and put the durable details in the body. When available, start the body with only the applicable linkage metadata:

```yaml
---
repository: owner/name
copilot_session_id: session-id
---
```

Do not add a separate memo ID, status, summary, or timestamps. Bear already owns those fields.

## Commands

| Task | Command |
| --- | --- |
| Search | `bearcli search --query "#memo $query" --format json --fields id,title,tags,modified,matches` |
| Read | `bearcli cat "$id" --format json` |
| Inspect | `bearcli show "$id" --format json --fields all` |
| Outline | `bearcli outline "$id" --format json` |
| Search within note | `bearcli search-in "$id" --string "$text" --format json` |
| Create | `bearcli create "$title" --tags memo/wip --format json --fields id,title,tags` |
| Append | `bearcli append "$id"` |
| Exact edit | `bearcli edit "$id" --find "$old" --replace "$new"` |
| Complete | `bearcli tags add "$id" memo/done`, then `bearcli tags remove "$id" memo/wip` |
| Trash | `bearcli trash "$id"` |

Report command errors and stop. If `bearcli` is unavailable, read `https://bear.app/faq/command-line-interface/` and follow the current official installation instructions.

## Workflow

### Search only

For search, list, or find requests, run one `bearcli search` and return concise matches. Do not load note bodies or Copilot session history unless the user asks to recall, show, or inspect a result.

Search active `#memo` notes by default. Add `--location archive`, `trash`, or `all` only when requested. Prefer results for the current repository and use the returned Bear ID for follow-up operations. Ask the user to choose when multiple results remain plausible.

### Save

Search by title and distinctive body terms before creating a note. Update an existing memo when it captures the same fact.

Build the body with applicable repository and session linkage, then pipe it to create:

```bash
printf '%s' "$content" | bearcli create "$title" --tags memo/wip --format json --fields id,title,tags
```

Return the title and Bear ID. After an ambiguous timeout, search before retrying because the write may have succeeded.

### Recall

Search and select a result, then read it with `bearcli cat "$id" --format json`. When the note contains `copilot_session_id`, use `session_store_sql` to retrieve that exact session's summary, checkpoints, and ordered turns. Treat the Bear note as the curated record and session history as supporting context; report conflicts. If history is unavailable, recall the note and state the limitation.

Use `/resume <id>` only when the user explicitly asks to continue the original Copilot session.

### Update

Read before writing. Use `outline` and `search-in` to narrow repeated text, then use `edit --section` with a unique exact match. Use `append` for additive changes.

For whole-note or section replacement, obtain a fresh hash from `bearcli cat --format json` and pass it to `bearcli overwrite --base`. Never perform an unconditional overwrite. Preserve attachment links.

Most write commands return only an exit status. Verify writes with `cat`, `show`, or `tags list`.

### Complete

Add `memo/done`, then remove `memo/wip`. Verify with `bearcli tags list "$id" --format json` that unrelated tags remain, `memo/done` exists, and `memo/wip` does not.

### Delete

Show the active note's title and ID, then require a separate confirmation even when the original request says not to ask again. Trash by ID and verify its location with `bearcli show "$id" --format json --fields id,title,location`.

For attachment deletion, list attachments and require confirmation naming the file, then use `bearcli attachments delete`. Do not use `edit --force` or `overwrite --force` unless the user explicitly confirms the exact attachment removals reported by the safety rejection.

## Common Mistakes

- Loading note bodies and session history for a search-only request.
- Creating a duplicate without searching first.
- Using a title for mutation after search results provide a stable note ID.
- Storing repository URLs instead of `owner/name`.
- Writing `copilot_session` instead of `copilot_session_id`.
- Replacing repeated text without narrowing to a unique match or section.
- Running `overwrite` without a fresh `--base` hash.
- Assuming a successful exit means the intended tags or content were preserved.
- Treating status as inline body text instead of Bear tags.
- Dropping unrelated tags while completing a memo.
- Retrying an uncertain create without checking whether it succeeded.
