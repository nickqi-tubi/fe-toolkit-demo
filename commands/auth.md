---
description: One-shot OAuth into every MCP server this plugin requires (Atlassian + Figma). Run this once after install.
---

Authenticate every MCP server that fe-toolkit needs in one shot. OAuth flows open in your browser; tokens are then cached in the system keychain and shared across sessions.

## Servers covered

| Logical name | Tool prefix | Provided by | Endpoint |
|---|---|---|---|
| `atlassian` | `mcp__atlassian__*` | this plugin's `.mcp.json` | `https://mcp.atlassian.com/v1/mcp/authv2` |
| `figma` | `mcp__figma__*` | the `figma@claude-plugins-official` dependency | `https://mcp.figma.com/mcp` |

## Procedure

For **each** of `atlassian` and `figma`, in order:

1. Check whether the server already has a working session by attempting a trivial read-only tool call:
   - For atlassian, prefer the smallest "ping"-like tool the server exposes (e.g. `mcp__atlassian__getAccessibleAtlassianResources`, `mcp__atlassian__getAtlassianUserInfo`, or whatever the server lists as cheapest in its tool descriptions). Pick by description, not by hard-coded name.
   - For figma, prefer the smallest read tool (e.g. `mcp__figma__get_me`, `mcp__figma__list_files`, or similar — again, pick by description).
   - If the call returns data successfully, mark the server as **already authenticated** and move on.

2. If the trivial call fails with a permissions / auth / not-authenticated error, invoke the auto-generated authenticate tool:
   - `mcp__atlassian__authenticate` for atlassian
   - `mcp__figma__authenticate` for figma

   This will open a browser tab to the provider's OAuth consent page. Tell the user in chat:

   > A browser tab has opened to authenticate `<server>`. Sign in and approve the requested scopes; this window will resume automatically when the OAuth callback completes.

3. After the authenticate tool returns, re-run the trivial read-only call from step 1 to confirm the token works. If it still fails, surface the verbatim error and stop — do not loop.

## Output

When all servers are confirmed authenticated, reply with a short status block. Use this exact format so downstream commands can parse it if needed:

```
fe-toolkit auth status
- atlassian: ✓ authenticated as <user/account if known>
- figma:     ✓ authenticated as <user/account if known>

Ready. You can now run /fe-toolkit:plan-ticket <TICKET-ID>.
```

If only one server authed successfully, still emit the block with the failed one marked `✘ <error>`, and tell the user the concrete next step (e.g. "Re-open `/mcp` interactively and click Authenticate on the figma row" or "Check `claude mcp list` to confirm the server is registered").

## Hard rules

- NEVER attempt to inject, paste, or read any OAuth bearer token directly. The only legitimate path is the browser flow triggered by `mcp__<server>__authenticate`.
- NEVER skip the post-auth verification call in step 3. Claude Code has known bugs where the UI says "authenticated" but the token isn't actually honored (see Claude Code issue #60260); the verification call catches this.
- If the user has not yet installed the `figma@claude-plugins-official` plugin (i.e. `mcp__figma__*` tools are not visible at all), say so explicitly and tell them to run `claude plugin marketplace update tubi-fe && claude plugin update fe-toolkit@tubi-fe` to pick up the dependency.
