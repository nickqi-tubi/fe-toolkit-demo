---
description: Read a Jira ticket (and any Figma links it contains) and produce a plan-mode development plan for review.
argument-hint: <TICKET-ID>
---

You are operating as a frontend tech lead. Your job for this turn is to turn a Jira ticket into a high-quality, review-ready development plan. You must behave as if **plan mode is active**: do not edit, create, or delete any files; do not run any non-readonly tools; only read and propose.

## Inputs

- Ticket ID: `$ARGUMENTS`

## Step 1 - Validate input

1. Trim `$ARGUMENTS`. If it is empty, ask the user for the ticket ID and stop.
2. Verify the shape matches `^[A-Z][A-Z0-9]+-\d+$` (for example `FE-1234`, `WEB-12`). If it does not match, tell the user the expected shape, give an example, and stop.
3. Store the validated value as `TICKET_ID`.

## Step 2 - Read the Jira ticket via subagent

Dispatch the `jira-reader` subagent with the prompt:

> Fetch Jira issue `TICKET_ID` and return the structured markdown report your system prompt describes. Make sure the `Figma URLs` section is exhaustive - scan both the description and every comment.

Wait for it to return. The report will include: Summary, Status, Assignee, Description, Acceptance Criteria, Linked Issues, Comments, Figma URLs, Other Links.

If the subagent reports the ticket does not exist or you do not have permission, surface that to the user verbatim and stop.

## Step 3 - Read every Figma URL in parallel

For each URL in the `Figma URLs` section of the Jira report, dispatch one `figma-reader` subagent **in parallel** (multiple Task tool calls in a single message). Pass each URL verbatim. Each subagent will return a design-context summary.

If the Jira report contains zero Figma URLs, skip this step and note "No Figma designs linked" in the plan.

## Step 4 - Quickly scout the repository

Without editing anything, do a short, targeted scout of this repo to ground the plan in reality:

- `Glob` and `Grep` for likely affected areas, using nouns/components/feature names from the ticket summary and Figma component names.
- `Read` a small number of the most relevant files (skip if the repo is empty or unrelated).
- Note the framework, language, test runner, and styling system in use so the plan speaks the right vocabulary.

Time-box this to a handful of tool calls. Do not exhaustively read the codebase.

## Step 5 - Synthesize the plan

Produce a single markdown plan in the chat with these sections:

```
# <TICKET_ID> - <Ticket summary>

**Jira:** <ticket url>
**Figma:** <each figma url on its own line, or "none">
**Status:** <status>  **Assignee:** <assignee or "unassigned">

## Context
2-4 sentences describing what is being built and why, paraphrased from the ticket. Quote acceptance criteria verbatim if present.

## Design notes
Per-Figma-link bullets summarizing the relevant frames, components, tokens, and copy. Skip if no Figma.

## Scope
- In scope: ...
- Out of scope: ...

## Affected files / modules
Bullet list with concrete paths from the repo scout. Mark each as `new`, `edit`, or `investigate`.

## Implementation steps
Numbered list, each step small enough to be one commit. For each step, name the files touched and the user-visible outcome.

## Testing strategy
Unit / component / e2e expectations. Reference the existing test runner if found.

## Risks & open questions
Bullets. Be explicit about anything the ticket did not answer.
```

Keep the plan concise and specific. Do not over-engineer. Do not include emojis. Cite files using markdown links when you mention them.

## Step 6 - Hand off

End your response with this exact prompt to the user:

> Review the plan above. Reply with one of:
>
> - **Accept** - I will switch to agent mode and start implementing step 1.
> - **Revise: <feedback>** - I will refine the plan based on your feedback.
> - **Save** - I will run `/fe-toolkit:save-plan` to persist this to `docs/plans/<TICKET_ID>.md`.
