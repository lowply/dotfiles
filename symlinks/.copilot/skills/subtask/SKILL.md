---
name: subtask
description: Use when the user asks to launch a separate Copilot CLI session for a subtask in a new Herdr tab.
---

# Subtask

Create an unfocused Herdr tab in the current Git repository and start a named
Copilot CLI session for the requested subtask.

## Workflow

Resolve `script/start-subtask.sh` relative to this `SKILL.md` and execute it
directly from the user's current working directory. Pass the user's complete
`ARGUMENTS` as one quoted argument so it becomes the new session's initial
prompt:

```bash
script/start-subtask.sh "${ARGUMENTS:-}"
```

Invoke the script even when `ARGUMENTS` is empty. If it exits nonzero, report
its error and stop. On success, report the generated agent name and tab label
printed by the script, then return control to the user immediately. Do not poll,
wait for, inspect, or collect the sub-agent's result. Herdr sound notifications
let the user handle attention requests. Monitor the sub-agent only when the user
explicitly asks to wait for completion or results.

## Guarantees

The script:

- requires the current session to be running inside Herdr and the current
  directory to belong to a Git repository;
- chooses the first available numbered name against both live Herdr agent names
  and labels in the current workspace, within Herdr's 32-character limit;
- creates the tab without focusing it, preserves the current working directory,
  and does not create a Git worktree;
- retries only a structured `agent_pane_busy` startup error for a bounded period
  while reusing the same tab and pane;
- submits `ARGUMENTS`, including an empty value, only after Copilot is ready.
