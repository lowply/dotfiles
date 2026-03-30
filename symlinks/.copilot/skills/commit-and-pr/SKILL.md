---
name: commit-and-pr
description: >
  Stages changes, commits with a well-written message, pushes to the remote, and
  creates a pull request with a clear title and comprehensive body. Use this skill
  when asked to commit, push, and open a PR for the current changes.
---

# Commit and Create PR

Stage current changes, commit them with a clear message, push to the remote, and
open a pull request.

## Workflow

### 1. Review the changes

Run `git diff` (and `git diff --cached` if there are already staged changes) to
understand what has been modified. Read enough context to write an accurate
commit message and PR description.

If there are no changes to commit, inform the user and stop.

### 2. Stage changes

```
git add -A
```

If the user asked to commit only specific files, stage only those files instead.

### 3. Fix SSH auth socket (Codespaces only)

If running in a Codespace (`$CODESPACES` is set), ensure the SSH agent socket is
available for commit signing **before** committing. Run the following once per session to set `SSH_AUTH_SOCK`:

```bash
source ~/.bashrc.sas
```

If no working socket is found, **stop and ask the user to SSH into the Codespace
instance first**, then retry.

### 4. Write and create the commit

Write a commit message following these conventions:

- **Subject line**: A concise imperative summary (≤ 72 characters). E.g.,
  `Add user authentication endpoint`.
- **Body** (separated by a blank line): Explain *what* changed and *why*. Keep
  each line ≤ 72 characters. Reference relevant context (issue numbers, review
  feedback, etc.) when applicable.

```
git commit -m "Subject line here

Body paragraph explaining what changed and why."
```

If commit signing still fails (e.g., `error: Load key ... No such file or
directory`), re-run the SSH auth socket fix above and retry once. If it fails
again, **stop and ask the user to SSH into the Codespace instance first**.

### 5. Push to the remote

```
git push origin HEAD
```

If the remote branch doesn't exist yet, use:

```
git push -u origin HEAD
```

### 6. Create a pull request

Use `gh pr create` to open the pull request:

```
gh pr create --title "PR title" --body "PR body"
```

**Title**: Use the same concise imperative style as the commit subject. If there
are multiple commits on the branch, write a title that summarises the overall
change.

**Body**: Write a comprehensive description that includes:

- A summary of what the PR does and why.
- A list of key changes (use bullet points).
- Any context the reviewer should know (related issues, trade-offs, follow-ups).
- Reference issues with `Closes #N` or `Relates to #N` when applicable.

If `gh pr create` fails because a PR already exists for this branch, inform the
user and provide the existing PR URL.

### 7. Report results

After creating the PR, provide a short summary:

- The commit SHA and message subject.
- The PR URL.
- Number of files changed.

## Guidelines

- **Do not** commit unrelated changes — only stage what the user asked for.
- **Preserve** the existing code style and conventions.
- If the user provides a specific commit message or PR title, use it as-is.
- If the branch has no upstream yet, set tracking with `-u` on push.
