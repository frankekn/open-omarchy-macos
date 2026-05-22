#!/usr/bin/env bash
# PostToolUse hook: re-run smoke-keybindings repo checks after touching
# modules/{desktop,tmux,terminal}. Non-blocking.

set -u

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)

[[ -z "$file" ]] && exit 0

# Only fire on the three modules whose config the smoke test asserts about.
case "$file" in
  */modules/desktop/*|*/modules/tmux/*|*/modules/terminal/*) ;;
  *) exit 0 ;;
esac

repo_root="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)"
smoke="$repo_root/scripts/smoke-keybindings.sh"

[[ ! -x "$smoke" ]] && exit 0

if ! output=$("$smoke" --repo-only 2>&1); then
  printf '[hook] smoke-keybindings --repo-only FAILED after editing %s:\n%s\n' \
    "$file" "$output" >&2
fi

exit 0
