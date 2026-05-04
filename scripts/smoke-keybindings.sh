#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

MODE="all"
PASS=0
FAIL=0
WARN=0

usage() {
  cat >&2 <<EOF
Usage: smoke-keybindings.sh [--repo-only | --installed-only | --live-only]

Checks tmux and Ghostty keybinding assumptions that commonly break on macOS.
EOF
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-only)
      MODE="repo"
      shift
      ;;
    --installed-only)
      MODE="installed"
      shift
      ;;
    --live-only)
      MODE="live"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

ok() {
  echo "ok - $1"
  PASS=$((PASS + 1))
}

fail() {
  echo "not ok - $1" >&2
  FAIL=$((FAIL + 1))
}

warn() {
  echo "warn - $1" >&2
  WARN=$((WARN + 1))
}

assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if [ ! -f "$file" ]; then
    fail "$label missing file: $file"
    return
  fi

  if rg -q --fixed-strings -- "$pattern" "$file"; then
    ok "$label"
  else
    fail "$label missing: $pattern"
  fi
}

assert_output_contains() {
  local output="$1"
  local pattern="$2"
  local label="$3"

  if printf '%s\n' "$output" | rg -q --fixed-strings -- "$pattern"; then
    ok "$label"
  else
    fail "$label missing: $pattern"
  fi
}

check_ghostty_config() {
  local file="$1"
  local label="$2"

  assert_file_contains "$file" "macos-option-as-alt = true" "$label treats Option as terminal Alt"
  assert_file_contains "$file" "keybind = control+space=text:\\x00" "$label forwards Ctrl+Space to tmux"

  if command -v ghostty >/dev/null 2>&1; then
    if ghostty +validate-config --config-file="$file" >/dev/null 2>&1; then
      ok "$label validates with ghostty"
    else
      fail "$label does not validate with ghostty"
    fi
  else
    warn "$label skipped ghostty validation because ghostty is not on PATH"
  fi
}

check_tmux_config() {
  local file="$1"
  local label="$2"

  assert_file_contains "$file" "set -g prefix C-Space" "$label has Ctrl+Space prefix"
  assert_file_contains "$file" "set -g prefix2 C-b" "$label has Ctrl+b fallback prefix"
  assert_file_contains "$file" "bind -n M-c run-shell" "$label has Alt+c dev-window binding"
  assert_file_contains "$file" "bind -n M-p display-popup" "$label has Alt+p project picker binding"
  assert_file_contains "$file" "bind -n M-s split-window -v -p 50" "$label has Alt+s 50/50 horizontal split"
  assert_file_contains "$file" "bind -n M-v split-window -h -p 50" "$label has Alt+v 50/50 vertical split"
}

check_repo() {
  echo "== Repo keybinding config =="
  check_ghostty_config "${REPO_DIR}/modules/terminal/ghostty/config" "repo Ghostty config"
  check_tmux_config "${REPO_DIR}/modules/tmux/tmux.conf" "repo tmux config"
}

check_installed() {
  echo "== Installed keybinding config =="
  check_ghostty_config "${HOME}/.config/ghostty/config" "installed Ghostty config"
  check_tmux_config "${HOME}/.config/tmux/tmux.conf" "installed tmux config"
}

check_live_tmux() {
  echo "== Live tmux server =="

  if ! command -v tmux >/dev/null 2>&1; then
    fail "tmux is not on PATH"
    return
  fi

  if ! tmux list-sessions >/dev/null 2>&1; then
    warn "no live tmux server; skipping live binding checks"
    return
  fi

  local root_keys
  root_keys="$(tmux list-keys -T root 2>/dev/null)"
  assert_output_contains "$root_keys" "M-c" "live tmux has Alt+c binding"
  assert_output_contains "$root_keys" "open-omarchy-dev-window" "live tmux Alt+c calls dev-window"
  assert_output_contains "$root_keys" "M-p" "live tmux has Alt+p binding"
  assert_output_contains "$root_keys" "open-omarchy-project-window" "live tmux Alt+p calls project picker"
  assert_output_contains "$root_keys" "M-s" "live tmux has Alt+s split binding"
  assert_output_contains "$root_keys" "-p 50" "live tmux split bindings use 50 percent"

  local prefix
  prefix="$(tmux show-options -gqv prefix 2>/dev/null)"
  if [ "$prefix" = "C-Space" ]; then
    ok "live tmux primary prefix is Ctrl+Space"
  else
    fail "live tmux primary prefix is $prefix, expected C-Space"
  fi

  local prefix2
  prefix2="$(tmux show-options -gqv prefix2 2>/dev/null)"
  if [ "$prefix2" = "C-b" ]; then
    ok "live tmux fallback prefix is Ctrl+b"
  else
    fail "live tmux fallback prefix is $prefix2, expected C-b"
  fi
}

case "$MODE" in
  all)
    check_repo
    check_installed
    check_live_tmux
    ;;
  repo)
    check_repo
    ;;
  installed)
    check_installed
    ;;
  live)
    check_live_tmux
    ;;
  *)
    usage
    ;;
esac

echo ""
echo "Summary: ${PASS} passed, ${WARN} warnings, ${FAIL} failed"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
