---
name: git-commit
description: >
  Stages changes, commits with a well-written message, sign the commit using SSH key.
---

# Git Commit

Stage current changes, commit them with a clear message, sign the commit using SSH key. Do not push or create a PR.

## Workflow

### 1. Review the changes

Run `git diff` (and `git diff --cached` if there are already staged changes) to
understand what has been modified. Read enough context to write an accurate
commit message.

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
source sshauthsock.sh
```

If sshauthsock.sh is not found, add `/workspaces/.codespaces/.persistedshare/dotfiles/bin` to the PATH and retry.

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

Later when creating a PR, the commit message will be referenced for the PR title and description, so make sure to write a clear and comprehensive message.

If commit signing still fails (e.g., `error: Load key ... No such file or
directory`), re-run the SSH auth socket fix above and retry once. If it fails
again, **stop and ask the user to SSH into the Codespace instance first**.

## Guidelines

- **Do not** commit unrelated changes — only stage what the user asked for.
- **Preserve** the existing code style and conventions.
- If the user provides a specific commit message, use it as-is.
