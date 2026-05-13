#!/usr/bin/env bash
# scripts/doctor.sh — check dependencies and config validity

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=scripts/lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"

CONFIG_FILE="${HOME}/.config/open-omarchy-macos/config.toml"
PASS=0
FAIL=0

ok()   { echo "  [ok]   $1"; ((PASS++)) || true; }
fail() { echo "  [FAIL] $1"; ((FAIL++)) || true; }
info() { echo "  [info] $1"; }
section() { echo ""; echo "=== $1 ==="; }

check_bin() {
  local name="$1"
  local hint="${2:-}"
  if command -v "$name" >/dev/null 2>&1; then
    ok "$name ($(command -v "$name"))"
  else
    fail "$name not found${hint:+ — $hint}"
  fi
}

check_file() {
  local path="$1"
  local label="${2:-$path}"
  if [ -f "$path" ]; then
    ok "$label"
  else
    fail "$label not found"
  fi
}

section "Required dependencies"
check_bin "tmux"     "brew install tmux"
check_bin "nvim"     "brew install neovim"
check_bin "fzf"      "brew install fzf"
check_bin "fd"       "brew install fd"
check_bin "git"      "xcode-select --install"
check_bin "jq"       "brew install jq"
check_bin "brew"     "https://brew.sh"

section "CLI"
check_file "${HOME}/.local/bin/open-omarchy" "$HOME/.local/bin/open-omarchy"

section "Desktop module (yabai / skhd)"
check_bin "yabai"    "open-omarchy install --module desktop"
check_bin "skhd"     "open-omarchy install --module desktop"
check_file "${HOME}/.config/yabai/yabairc" "~/.config/yabai/yabairc"
check_file "${HOME}/.config/skhd/skhdrc"   "~/.config/skhd/skhdrc"

section "tmux module"
check_file "${HOME}/.config/tmux/tmux.conf"                 "~/.config/tmux/tmux.conf"
check_file "${HOME}/.local/bin/open-omarchy-dev-window"     "~/.local/bin/open-omarchy-dev-window"
check_file "${HOME}/.local/bin/open-omarchy-project-window" "~/.local/bin/open-omarchy-project-window"
check_file "${HOME}/.local/bin/open-omarchy-command-palette" "$HOME/.local/bin/open-omarchy-command-palette"

section "nvim module"
check_file "${HOME}/.config/nvim/init.lua" "~/.config/nvim/init.lua"

section "terminal module"
if [ -d "/Applications/Ghostty.app" ]; then
  ok "Ghostty.app"
else
  fail "Ghostty.app not found — brew install --cask ghostty"
fi
check_file "${HOME}/.config/ghostty/config" "~/.config/ghostty/config"

section "shell module"
check_file "${HOME}/.config/open-omarchy-macos/shell.zsh" "~/.config/open-omarchy-macos/shell.zsh"
check_file "${HOME}/.local/bin/open-omarchy"               "~/.local/bin/open-omarchy"
if [ -f "${HOME}/.zshrc" ] && grep -Fq -- "# >>> open-omarchy-macos >>>" "${HOME}/.zshrc"; then
  ok "~/.zshrc sources the open-omarchy shell partial"
else
  fail "~/.zshrc missing open-omarchy marker — open-omarchy install --module shell"
fi

section "Agent"
agent="$(config_get "agent" "$CONFIG_FILE" "opencode")"
info "Configured agent: $agent"
check_bin "$agent" "check open-omarchy.example.toml for supported agents"

section "Project roots"
if [ -f "$CONFIG_FILE" ]; then
  while IFS= read -r root; do
    expanded="${root/\~/$HOME}"
    if [ -d "$expanded" ]; then
      ok "project root: $root"
    else
      fail "project root not found: $root"
    fi
  done < <(config_get_array "project_roots" "$CONFIG_FILE")
else
  info "No config file at $CONFIG_FILE — using defaults"
  info "Copy open-omarchy.example.toml to $CONFIG_FILE to configure"
fi

section "Summary"
echo ""
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Run 'open-omarchy install' to fix missing modules." >&2
  exit 1
else
  echo "All checks passed."
fi
