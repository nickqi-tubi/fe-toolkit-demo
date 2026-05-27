---
description: Create a git commit whose message follows the Conventional Commits v1.0.0 spec.
argument-hint: "[optional one-line hint for the message]"
---

Create a git commit for the current changes that strictly follows the Conventional Commits v1.0.0 specification.

If `$ARGUMENTS` is non-empty, treat it as a hint from the user about what the commit should be about (for example a type, scope, or summary). It is a hint, not the final message - you must still inspect the diff and draft a message that accurately describes the actual changes.

Invoke the `conventional-commit` skill and follow its workflow exactly. The skill covers:

- Inspecting `git status` / `git diff --cached` / `git diff` to understand what is actually changing.
- Refusing to commit secrets or unrelated noise.
- Picking the correct `<type>`, optional `<scope>`, optional `!` for breaking changes, and writing the subject and body.
- Showing the drafted message to the user for confirmation before running `git commit`.
- Never passing `--no-verify`, never amending pushed commits, never updating git config.
