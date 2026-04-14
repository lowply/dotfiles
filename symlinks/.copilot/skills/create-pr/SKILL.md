---
name: create-pr
description: >
  Pushes commits to the remote and creates a pull request with a clear title
  and comprehensive body. Use this skill when asked to push and open a PR
  for the current changes.
---

# Create PR

Push commits to the remote and open a pull request.

## Workflow

### 1. Create a branch if needed

If the current branch is `main` or there is no branch for the changes yet,
create a new branch before committing. The branch name must:

- Start with the `lowply/` prefix.
- Use kebab-case (hyphen-delimited) for the rest of the name.
- Be a short, descriptive slug summarising the change.

Examples: `lowply/auto-resolve`, `lowply/fix-login-redirect`, `lowply/add-retry-logic`.

```
git switch -c lowply/<descriptive-slug>
```

If the current branch already follows this convention, skip this step.

### 2. Commit changes

Use the `git-commit` skill to stage and commit the changes. The commit message
will be referenced for the PR title and description, so make sure to write a
clear and comprehensive message.

### 3. Push to the remote

```
git push origin HEAD
```

If the remote branch doesn't exist yet, use:

```
git push -u origin HEAD
```

### 4. Create a pull request

Reference the commit messages on the branch and the plan document in the current
session directory (if one exists) to craft the PR title and body. If the plan
links to a tracking issue, read the issue as well for additional context.
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

### 5. Report results

After creating the PR, provide a short summary:

- The PR URL.
- Number of files changed.

## Guidelines

- If the user provides a specific PR title, use it as-is.
- If the branch has no upstream yet, set tracking with `-u` on push.
