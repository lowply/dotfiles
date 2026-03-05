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

### 1. Parse the PR URL

Extract `owner`, `repo`, and `pull_number` from the URL. Accepted formats:

- `https://github.com/{owner}/{repo}/pull/{number}`
- `{owner}/{repo}#{number}`

If the input doesn't match, ask the user for a valid PR URL.

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

Commit all changes in a **single commit** with a clear message.

When running in **Codespaces** (`$CODESPACES` is `true`), run
`source ${DOTFILES_DIR}/bin/sshauthsock.sh` before `git commit` so the SSH
agent socket is available for commit signing.

```
# Codespaces only — set up SSH agent for commit signing
source ${DOTFILES_DIR}/bin/sshauthsock.sh

git add -A
git commit -m "Address PR review feedback

Resolve unresolved review comments from PR #{number}.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
git push origin {branch}
```

### 9. Report results

After pushing, provide a short summary to the user:

- Number of unresolved comments addressed
- List of files modified
- Any comments that were **skipped** (with reason — e.g., ambiguous, out-of-date
  file, question-only comment)

## Guidelines

- **Do not** modify files or lines unrelated to the review feedback.
- **Do not** mark review threads as resolved — let the reviewer do that.
- **Preserve** the existing code style (indentation, quotes, naming conventions).
- If a comment references code that no longer exists in the current branch, skip it
  and report it as outdated.
- If there are no unresolved comments, tell the user — no commit is needed.
