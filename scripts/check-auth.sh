#!/usr/bin/env bash
#
# check-auth.sh - SessionStart hook for the fe-toolkit plugin.
# Inspects `claude mcp list` for MCP servers provided by this plugin (and its
# Figma dependency) that are in the "Needs authentication" state, and prints
# a single-line reminder telling the user how to fix it.
#
# Silent (no output) when everything is already authenticated.
# Silent (no output) when the `claude` CLI is missing or returns non-zero.

set -u

claude_bin="$(command -v claude || true)"
[[ -z "$claude_bin" ]] && exit 0

list_output="$("$claude_bin" mcp list 2>/dev/null || true)"
[[ -z "$list_output" ]] && exit 0

needs=$(printf '%s\n' "$list_output" \
  | grep -E '^plugin:(fe-toolkit|figma):' \
  | grep -F 'Needs authentication' \
  | awk -F: '{print $3}' \
  | awk '{print $1}' \
  | sort -u \
  | tr '\n' ' ' \
  | sed 's/ $//')

if [[ -n "$needs" ]]; then
  printf 'fe-toolkit: MCP server(s) not yet authenticated: %s\n' "$needs"
  printf '            run /fe-toolkit:auth to complete OAuth in one step.\n'
fi

exit 0
