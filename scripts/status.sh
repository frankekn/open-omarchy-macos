#!/usr/bin/env sh

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${HOME}/.local/state/open-omarchy-macos"

log() {
  echo "[open-omarchy] $1"
}

print_section() {
  echo ""
  echo "== $1 =="
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    echo "installed ($($1 --version 2>&1 | head -n1))"
  else
    echo "not installed"
  fi
}

check_service() {
  local svc="$1"
  if pgrep -x "$svc" >/dev/null 2>&1; then
    echo "running"
  else
    echo "not running"
  fi
}

main() {
  print_section "System"
  echo "macOS: $(sw_vers -productVersion)"
  echo "Arch:  $(uname -m)"

  print_section "Homebrew"
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew: installed ($(brew --version | head -n1))"
    if brew tap | grep -q "^asmvik/formulae$"; then
      echo "Tap asmvik/formulae: present"
    else
      echo "Tap asmvik/formulae: not present"
    fi
  else
    echo "Homebrew: not installed"
  fi

  print_section "Packages"
  echo "yabai: $(check_command yabai)"
  echo "skhd:  $(check_command skhd)"

  print_section "Services"
  echo "yabai: $(check_service yabai)"
  echo "skhd:  $(check_service skhd)"

  print_section "Config Files"
  for f in \
    "${HOME}/.config/yabai/yabairc" \
    "${HOME}/.config/skhd/skhdrc" \
    "${HOME}/.yabairc" \
    "${HOME}/.skhdrc"; do
    if [ -f "$f" ]; then
      echo "$(basename "$f"): ${f}"
    fi
  done

  print_section "Backups"
  if [ -d "${STATE_DIR}/backups" ]; then
    local latest
    latest=$(find "${STATE_DIR}/backups" -name "manifest.json" -type f 2>/dev/null | sort | tail -n1)
    if [ -n "$latest" ]; then
      echo "Latest manifest: ${latest}"
    else
      echo "No backups found."
    fi
  else
    echo "No backup directory."
  fi

  print_section "Manual Steps Remaining"
  echo "1. Grant Accessibility permissions to yabai and skhd:"
  echo "   System Settings → Privacy & Security → Accessibility"
  echo ""
  echo "2. Restart services after granting permissions:"
  echo "   yabai --restart-service"
  echo "   skhd --restart-service"
  echo ""
  echo "3. Recommended macOS settings:"
  echo "   - Enable 'Displays have separate Spaces'"
  echo "   - Disable 'Automatically rearrange Spaces based on most recent use'"
  echo ""
}

main "$@"
