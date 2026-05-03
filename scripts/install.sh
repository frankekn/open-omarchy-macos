#!/usr/bin/env sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="${HOME}/.local/state/open-omarchy-macos"
BACKUP_DIR="${STATE_DIR}/backups/$(date +%Y%m%d-%H%M%S)"
MANIFEST_FILE="${BACKUP_DIR}/manifest.json"

DRY_RUN=false

log() {
  echo "[open-omarchy] $1"
}

die() {
  echo "[open-omarchy] ERROR: $1" >&2
  exit 1
}

run() {
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would run: $*"
  else
    "$@"
  fi
}

preflight() {
  log "Running preflight checks..."

  if ! command -v brew >/dev/null 2>&1; then
    die "Homebrew not found. Install from https://brew.sh"
  fi

  local os_version
  os_version=$(sw_vers -productVersion)
  log "macOS version: $os_version"

  local arch
  arch=$(uname -m)
  log "Architecture: $arch"

  log "Preflight OK."
}

backup_config() {
  local src="$1"
  local backup_subdir="$2"

  if [ -f "$src" ]; then
    local dest="${BACKUP_DIR}/${backup_subdir}"
    run mkdir -p "$dest"
    run cp "$src" "$dest/"
    echo "true"
  else
    echo "false"
  fi
}

write_manifest() {
  local tap_existed="$1"
  local yabai_existed="$2"
  local skhd_existed="$3"
  local yabai_config_existed="$4"
  local yabai_backup_path="$5"
  local skhd_config_existed="$6"
  local skhd_backup_path="$7"
  local yabai_running="$8"
  local skhd_running="$9"

  run mkdir -p "$BACKUP_DIR"

  local manifest
  manifest=$(cat <<EOF
{
  "schema_version": 1,
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "repo": "open-omarchy-macos",
  "backup_dir": "${BACKUP_DIR}",
  "homebrew": {
    "tap_asmvik_formulae_existed_before": ${tap_existed},
    "tap_asmvik_formulae_added_by_install": $( [ "$tap_existed" = "true" ] && echo "false" || echo "true" )
  },
  "packages": {
    "yabai_existed_before": ${yabai_existed},
    "yabai_installed_by_install": $( [ "$yabai_existed" = "true" ] && echo "false" || echo "true" ),
    "skhd_existed_before": ${skhd_existed},
    "skhd_installed_by_install": $( [ "$skhd_existed" = "true" ] && echo "false" || echo "true" )
  },
  "configs": [
    {
      "path": "${HOME}/.config/yabai/yabairc",
      "existed_before": ${yabai_config_existed},
      "backup_path": $( [ -n "$yabai_backup_path" ] && echo "\"${yabai_backup_path}\"" || echo "null" ),
      "created_by_install": $( [ "$yabai_config_existed" = "true" ] && echo "false" || echo "true" )
    },
    {
      "path": "${HOME}/.config/skhd/skhdrc",
      "existed_before": ${skhd_config_existed},
      "backup_path": $( [ -n "$skhd_backup_path" ] && echo "\"${skhd_backup_path}\"" || echo "null" ),
      "created_by_install": $( [ "$skhd_config_existed" = "true" ] && echo "false" || echo "true" )
    }
  ],
  "services": {
    "yabai_was_running_before": ${yabai_running},
    "skhd_was_running_before": ${skhd_running}
  }
}
EOF
)

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would write manifest to ${MANIFEST_FILE}"
  else
    echo "$manifest" > "$MANIFEST_FILE"
    log "Manifest written to ${MANIFEST_FILE}"
  fi
}

install_homebrew() {
  log "Checking Homebrew tap..."

  local tap_existed="true"
  if ! brew tap | grep -q "^asmvik/formulae$"; then
    tap_existed="false"
    run brew tap asmvik/formulae
  else
    log "Tap asmvik/formulae already present."
  fi

  log "Checking packages..."

  local yabai_existed="true"
  if ! brew list yabai >/dev/null 2>&1; then
    yabai_existed="false"
    run brew install asmvik/formulae/yabai
  else
    log "Package yabai already installed."
  fi

  local skhd_existed="true"
  if ! brew list skhd >/dev/null 2>&1; then
    skhd_existed="false"
    run brew install asmvik/formulae/skhd
  else
    log "Package skhd already installed."
  fi

  echo "${tap_existed}|${yabai_existed}|${skhd_existed}"
}

install_configs() {
  log "Installing configs..."

  run mkdir -p "${HOME}/.config/yabai"
  run mkdir -p "${HOME}/.config/skhd"

  local yabai_backup_path=""
  local skhd_backup_path=""

  local yabai_existed
  yabai_existed=$(backup_config "${HOME}/.config/yabai/yabairc" "config/yabai")
  if [ "$yabai_existed" = "true" ]; then
    yabai_backup_path="${BACKUP_DIR}/config/yabai/yabairc"
  fi

  local skhd_existed
  skhd_existed=$(backup_config "${HOME}/.config/skhd/skhdrc" "config/skhd")
  if [ "$skhd_existed" = "true" ]; then
    skhd_backup_path="${BACKUP_DIR}/config/skhd/skhdrc"
  fi

  run cp "${REPO_DIR}/config/yabai/yabairc" "${HOME}/.config/yabai/yabairc"
  run cp "${REPO_DIR}/config/skhd/skhdrc" "${HOME}/.config/skhd/skhdrc"

  echo "${yabai_existed}|${yabai_backup_path}|${skhd_existed}|${skhd_backup_path}"
}

start_services() {
  log "Starting services..."

  local yabai_running="false"
  local skhd_running="false"

  if pgrep -x yabai >/dev/null 2>&1; then
    yabai_running="true"
    log "yabai was already running."
  fi

  if pgrep -x skhd >/dev/null 2>&1; then
    skhd_running="true"
    log "skhd was already running."
  fi

  run yabai --start-service
  run skhd --start-service

  echo "${yabai_running}|${skhd_running}"
}

post_install() {
  log "Install complete."
  echo ""
  echo "========================================"
  echo "IMPORTANT: Grant Accessibility permissions"
  echo "========================================"
  echo ""
  echo "1. Open System Settings → Privacy & Security → Accessibility"
  echo "2. Add and enable:"
  echo "   - $(brew --prefix)/bin/yabai"
  echo "   - $(brew --prefix)/bin/skhd"
  echo ""
  echo "3. Restart services:"
  echo "   yabai --restart-service"
  echo "   skhd --restart-service"
  echo ""
  echo "NOTE: SIP was not changed."
  echo "NOTE: Scripting addition was not installed."
  echo ""
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done

  if [ "$DRY_RUN" = true ]; then
    log "DRY RUN MODE — no changes will be made"
  fi

  preflight

  log "Creating backup directory: ${BACKUP_DIR}"
  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$BACKUP_DIR"
  fi

  local hb_result
  hb_result=$(install_homebrew)
  local tap_existed yabai_pkg_existed skhd_pkg_existed
  tap_existed=$(echo "$hb_result" | cut -d'|' -f1)
  yabai_pkg_existed=$(echo "$hb_result" | cut -d'|' -f2)
  skhd_pkg_existed=$(echo "$hb_result" | cut -d'|' -f3)

  local cfg_result
  cfg_result=$(install_configs)
  local yabai_cfg_existed yabai_backup skhd_cfg_existed skhd_backup
  yabai_cfg_existed=$(echo "$cfg_result" | cut -d'|' -f1)
  yabai_backup=$(echo "$cfg_result" | cut -d'|' -f2)
  skhd_cfg_existed=$(echo "$cfg_result" | cut -d'|' -f3)
  skhd_backup=$(echo "$cfg_result" | cut -d'|' -f4)

  local svc_result
  svc_result=$(start_services)
  local yabai_running skhd_running
  yabai_running=$(echo "$svc_result" | cut -d'|' -f1)
  skhd_running=$(echo "$svc_result" | cut -d'|' -f2)

  write_manifest \
    "$tap_existed" \
    "$yabai_pkg_existed" \
    "$skhd_pkg_existed" \
    "$yabai_cfg_existed" \
    "$yabai_backup" \
    "$skhd_cfg_existed" \
    "$skhd_backup" \
    "$yabai_running" \
    "$skhd_running"

  if [ "$DRY_RUN" = false ]; then
    post_install
  fi
}

main "$@"
