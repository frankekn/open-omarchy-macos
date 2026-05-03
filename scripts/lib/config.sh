#!/usr/bin/env bash
# scripts/lib/config.sh — minimal TOML key reader
# Usage: config_get <key> <file> [default]
# Supports simple key = "value" and key = true/false lines only.

config_get() {
  local key="$1"
  local file="$2"
  local default="${3:-}"

  if [ ! -f "$file" ]; then
    echo "$default"
    return
  fi

  local value
  value=$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$file" \
    | head -n1 \
    | sed -E 's/^[^=]+=\s*//' \
    | sed -E 's/^"(.*)"/\1/' \
    | sed -E "s/^'(.*)'/\1/" \
    | tr -d '\r')

  if [ -z "$value" ]; then
    echo "$default"
  else
    echo "$value"
  fi
}

# config_get_array <key> <file>
# Returns each quoted array element on its own line.
config_get_array() {
  local key="$1"
  local file="$2"

  if [ ! -f "$file" ]; then
    return
  fi

  # Match key = [ ... ] (single line) or multi-line array blocks
  grep -A 50 "^[[:space:]]*${key}[[:space:]]*=" "$file" \
    | awk '/\[/{found=1} found{print} /\]/{exit}' \
    | grep -oE '"[^"]+"' \
    | sed 's/"//g'
}
