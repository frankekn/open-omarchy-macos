#!/usr/bin/env bash
# PostToolUse hook: shellcheck on edited .sh files.
# Receives Claude Code tool payload as JSON on stdin.
# Non-blocking: prints findings, never exits non-zero so edits aren't rolled back.

set -u

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[[ -z "$file" ]] && exit 0
[[ "$file" != *.sh ]] && exit 0
[[ ! -f "$file" ]] && exit 0

if ! command -v shellcheck >/dev/null 2>&1; then
  exit 0
fi

# Pin --shell=bash because most scripts in this repo set bash via shebang or use [[ ]].
output=$(shellcheck --shell=bash --severity=warning "$file" 2>&1) || true

if [[ -n "$output" ]]; then
  printf '[hook] shellcheck on %s:\n%s\n' "$file" "$output" >&2
fi

exit 0
