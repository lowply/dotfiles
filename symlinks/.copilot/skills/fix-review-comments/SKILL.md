---
name: fix-review-comments
description: >
  Reads unresolved code review comments from a GitHub pull request and fixes them.
  Use this skill when asked to fix, address, or resolve PR review comments, or when
  given a GitHub pull request URL with a request to fix the feedback.
---

# Fix Review Comments

Fix all unresolved code review comments on a GitHub pull request, then commit and push.

## Workflow

### 1. Parse the PR reference

Extract `owner`, `repo`, and `pull_number` from the user's input. Accepted formats:

- `https://github.com/{owner}/{repo}/pull/{number}`
- `{owner}/{repo}#{number}`
- A plain PR number (e.g., `42`)

If only a number is given, infer the repository from the current branch using
`gh pr view {number} --json url --jq .url` to resolve the full PR reference.

If the input doesn't match any format, ask the user for a valid PR reference.

### 2. Fetch the pull request

Use the `pull_request_read` tool (method: `get`) to retrieve the PR metadata.
Note the **head branch** (`head.ref`) and the **head repo clone URL** (`head.repo.clone_url`).

### 3. Check out the PR branch locally

```
git fetch origin pull/{number}/head:{branch}
git checkout {branch}
```

If the repo is not yet cloned, clone it first. Make sure the working tree is clean
before switching branches.

### 4. Fetch unresolved review comments

Use the `pull_request_read` tool with method `get_review_comments` to retrieve all
review comment threads. Paginate with `perPage: 100` and use the `after` cursor
until all threads are retrieved.

**Filter** to only threads where `isResolved` is `false` and `isOutdated` is `false`.
Skip resolved and outdated threads—they don't need action.

### 5. Understand each comment thread

For every unresolved thread, extract:

- **File path** and **line range** the comment applies to
- **Comment body** — the reviewer's feedback
- **Diff context** — the surrounding code shown in the review
- **Suggested changes** — if the reviewer used a ```suggestion block, prefer
  applying that exact change

Group comments by file so you can batch edits efficiently.

### 6. Fix the code

Before making any changes, verify the current branch matches the PR's head
branch. If it does not, **stop immediately** and inform the user — do not
proceed on the wrong branch.

For each unresolved comment:

1. Open the file at the referenced path.
2. Read enough context around the referenced lines to fully understand the code.
3. Apply the fix described by the reviewer:
   - If the comment contains a **suggestion block**, apply that suggestion exactly.
   - If the comment describes a change in prose, implement it faithfully.
   - If the comment asks a question or requests clarification, use your best
     judgment to improve the code in the spirit of the feedback. If truly ambiguous,
     skip it and note it for the user.
4. Validate that your edits don't break surrounding code (balanced braces, correct
   indentation, no syntax errors).

### 7. Verify changes

After all edits:

- Run any available linters or type-checkers for the affected files to catch
  obvious mistakes.
- Use `git diff` to review the full set of changes and confirm each comment is
  addressed.

### 8. Commit and push

Before committing, verify again that the current branch matches the PR's head
branch. Another agent or user may have switched branches in the meantime, which
could cause changes to be committed to the wrong branch. If the branch doesn't
match, **stop and inform the user**.

Commit all changes in a **single commit** with a clear message.

```
git add -A
git commit -m "Address PR review feedback

Resolve unresolved review comments from PR #{number}."
git push origin {branch}
```

If commit signing fails (e.g., `error: Load key ... No such file or directory`),
this likely means the SSH agent doesn't have the auth socket available. **Stop
and ask the user to SSH into the Codespace instance first**, then retry.

### 9. Report results

After pushing, provide a short summary to the user:

- Number of unresolved comments addressed
- List of files modified
- Any comments that were **skipped** (with reason — e.g., ambiguous, out-of-date
  file, question-only comment)

## Guidelines

- **Do not** modify files or lines unrelated to the review feedback.
- You **may** mark review threads as resolved after addressing them. If resolving
  fails (e.g., permission issues), do **not** retry via GraphQL — just inform the
  user that resolving the thread failed and include the reason.
- **Preserve** the existing code style (indentation, quotes, naming conventions).
- If a comment references code that no longer exists in the current branch, skip it
  and report it as outdated.
- If there are no unresolved comments, tell the user — no commit is needed.
