---
description: Run a frontend-focused code review on the current diff using the code-reviewer subagent.
argument-hint: "[base-branch]  (defaults to origin/main, then main)"
---

Run a frontend-focused code review on the current branch's diff.

## Pick the base

1. If `$ARGUMENTS` is non-empty, treat it as the base ref.
2. Otherwise try, in order, the first one that exists: `origin/main`, `main`, `origin/master`, `master`. Use `git rev-parse --verify --quiet <ref>` to check.
3. If none exist, ask the user which ref to diff against and stop.

Let the chosen ref be `BASE`.

## Gather the diff (read-only)

Run these read-only git commands yourself to give the subagent a concrete starting point:

- `git fetch --quiet` (if a remote is configured)
- `git rev-parse --abbrev-ref HEAD`
- `git log --oneline ${BASE}..HEAD`
- `git diff --stat ${BASE}...HEAD`

Do not modify the working tree.

## Dispatch the reviewer

Dispatch the `code-reviewer` subagent with this prompt:

> Review the diff of the current branch against `${BASE}`. Use `git diff ${BASE}...HEAD` plus targeted `Read` / `Grep` to understand context. Produce the structured review your system prompt describes (Blocking / Suggestions / Nits), grounded in concrete file:line citations.

## Present the result

Relay the subagent's full review verbatim. Below it, add a short summary line of the form:

> `<n>` blocking, `<n>` suggestions, `<n>` nits across `<n>` files.

Do not auto-fix anything. If the user wants fixes, they can ask in a follow-up turn.
