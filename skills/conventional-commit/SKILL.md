---
name: conventional-commit
description: Use this skill whenever the user asks to create, draft, or write a git commit. Produces commit messages that strictly follow Conventional Commits v1.0.0 - structured types, optional scope, optional `!` for breaking changes, and proper `BREAKING CHANGE:` footers. Inspects the diff, refuses to commit secrets, and shows the message to the user before committing.
---

# Conventional Commit skill

You create commits whose messages comply with **Conventional Commits v1.0.0** (<https://www.conventionalcommits.org/en/v1.0.0/>). The full spec is bundled at [reference.md](reference.md); load it on demand for edge cases (rare types, multi-paragraph bodies, multiple footers, multiple breaking changes).

## Hard rules

- NEVER pass `--no-verify` (or any other hook-skipping flag).
- NEVER update git config.
- NEVER amend a commit that has been pushed to a remote without an explicit user request.
- NEVER `git push` from this skill - committing only.
- NEVER commit obvious secret files: `.env`, `.env.*` (except `.env.example`), `*credentials*`, `*.pem`, `*.key`, `id_rsa*`, `*.p12`, files inside `.aws/`, `.ssh/`. If the user explicitly asks to commit one, warn them clearly and require a second confirmation.
- ALWAYS show the drafted message to the user before running `git commit`.
- ALWAYS use a HEREDOC for the commit message so multi-line bodies survive shell quoting.

## Workflow

### 1. Survey

Run these in parallel:

- `git status`
- `git diff --cached`
- `git diff` (only if `git diff --cached` is empty)
- `git log -1 --format='%h %an %ae %s'` (to check the previous author and identify whether we created the last commit)
- `git status --porcelain=v1 -b` (to learn `ahead/behind`)

If `git diff --cached` is empty AND `git diff` shows nothing either, stop and tell the user there are no changes to commit.

### 2. Decide what to stage

- If files are already staged, use them as-is. Do not auto-stage more.
- If nothing is staged and the working tree is dirty:
  - List the modified files to the user.
  - Ask: "Stage all of these and commit? (yes / no / specific files)" - do NOT stage automatically.
  - On `yes`: run `git add -A`. On a list of files: stage only those. On `no`: stop.
- Re-run `git diff --cached` after staging.

### 3. Filter secrets

Scan staged paths against the deny list above. If any match, refuse and explain. If the diff contains lines that look like API keys (`AKIA[0-9A-Z]{16}`, long hex tokens labeled `secret`/`token`/`api_key`, JWTs), refuse and tell the user which file and line.

### 4. Draft the message

Pick the type from the staged diff (not from the user's hint - the hint is a tiebreaker only):

| Type | Use when |
|------|----------|
| `feat` | A new user-visible feature. |
| `fix` | A bug fix. |
| `perf` | A performance improvement with no behavior change. |
| `refactor` | Restructuring without behavior change. |
| `style` | Formatting / whitespace / lint, no logic change. |
| `test` | Adding or correcting tests only. |
| `docs` | Documentation only. |
| `build` | Build system, dependencies, bundler config. |
| `ci` | CI configuration and scripts only. |
| `chore` | Repo housekeeping that does not fit elsewhere. |
| `revert` | Reverts a previous commit; body must include `Refs: <sha>`. |

`feat` and `fix` are the only two types the spec itself defines; the rest are widely accepted conventions. When in doubt between `feat` and `chore`, ask whether a release-note reader would care.

Pick the scope from the actual paths touched:

- Single-area diff: scope is the top-level area (e.g. `feat(player): ...`).
- Cross-cutting diff: omit the scope.
- Scope is always lowercase, kebab-case, no spaces.

Detect breaking changes:

- A removed or renamed exported symbol.
- A removed/renamed CLI flag or env var.
- A change to public API shape (response field, prop name, route).
- A bumped major version of a peer dependency that affects consumers.

If breaking: add `!` after the type/scope and include a `BREAKING CHANGE: <impact + migration>` footer.

Compose the header:

```
<type>[(<scope>)][!]: <subject>
```

- Subject: imperative mood ("add" not "added"), no trailing period, <= 72 chars, sentence-case but no leading capital after the colon ("add" not "Add").

Body (optional, recommended for non-trivial changes):

- Blank line after header.
- Explain **why**, not **what** the diff already shows. 1-3 short paragraphs.
- Wrap at ~72 columns.

Footers (optional):

- `BREAKING CHANGE: <description>` (or repeat for multiple breakings).
- Issue refs: `Refs: PROJ-123`, `Closes: PROJ-123` - use the project's convention. If you see a `docs/plans/<TICKET>.md` file or the conversation has an active ticket ID, include `Refs: <TICKET>`.
- Co-authors: `Co-authored-by: Name <email>` if the user gave one.

### 5. Show the user, then commit

Present the full message inside a fenced block and ask: "Commit with this message? (yes / edit / cancel)".

- `yes` or implicit approval: commit it.
- `edit`: incorporate their feedback and re-show. Loop.
- `cancel`: stop without committing.

Commit using a HEREDOC:

```bash
git commit -m "$(cat <<'EOF'
<full message here>
EOF
)"
```

### 6. Confirm

After `git commit` exits 0:

- Run `git status` and report the new HEAD's short SHA + subject.
- If a pre-commit hook modified files, follow the rules in the surrounding agent instructions: only amend if the commit succeeded but the hook auto-modified files and the commit was made by you in this conversation and has not been pushed.
- If the pre-commit hook failed, fix the issue and create a NEW commit; do not amend.

## Quick examples

- `feat(auth): add SSO login button on /login`
- `fix(player): prevent infinite buffering when manifest 404s`
- `refactor(api): extract pagination cursor helper`
- `feat(api)!: switch /users response to camelCase`
   plus footer: `BREAKING CHANGE: response keys changed from snake_case to camelCase; update clients.`
- `chore(deps): bump typescript 5.4 -> 5.6`
- `docs(plans): add FE-1234 development plan`

## Tooling helper

A small shell wrapper is bundled at [scripts/commit.sh](scripts/commit.sh). Prefer it when you have a clean, single-paragraph message - it handles HEREDOC quoting for you. For multi-paragraph bodies or multiple footers, call `git commit` directly with the HEREDOC pattern above.

Always invoke it with an explicit `bash` prefix so the script does not need to be marked executable on the user's filesystem (plugin caches on some systems lose the exec bit):

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/conventional-commit/scripts/commit.sh" \
  --type feat \
  --scope player \
  --subject "add picture-in-picture toggle" \
  --body "Lets users keep watching while browsing other apps." \
  --refs FE-1234
```
