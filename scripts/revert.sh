#!/usr/bin/env sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="${HOME}/.local/state/open-omarchy-macos"

DRY_RUN=false
BACKUP_PATH=""
UNINSTALL_PACKAGES=false
REMOVE_TAP=false
DELETE_CREATED=false

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

find_latest_manifest() {
  local latest
  latest=$(find "${STATE_DIR}/backups" -name "manifest.json" -type f 2>/dev/null | sort | tail -n1)
  if [ -z "$latest" ]; then
    die "No backup manifest found in ${STATE_DIR}/backups"
  fi
  echo "$latest"
}

parse_manifest() {
  local manifest="$1"
  local field="$2"
  jq -r "$field" "$manifest"
}

stop_services() {
  log "Stopping services..."

  if command -v yabai >/dev/null 2>&1; then
    run yabai --stop-service || true
  fi

  if command -v skhd >/dev/null 2>&1; then
    run skhd --stop-service || true
  fi
}

restore_configs() {
  local manifest="$1"

  log "Restoring configs..."

  local configs_count
  configs_count=$(jq '.configs | length' "$manifest")

  local i=0
  while [ "$i" -lt "$configs_count" ]; do
    local path existed_before backup_path created_by_install
    path=$(jq -r ".configs[${i}].path" "$manifest")
    existed_before=$(jq -r ".configs[${i}].existed_before" "$manifest")
    backup_path=$(jq -r ".configs[${i}].backup_path" "$manifest")
    created_by_install=$(jq -r ".configs[${i}].created_by_install" "$manifest")

    if [ "$existed_before" = "true" ] && [ -n "$backup_path" ] && [ "$backup_path" != "null" ]; then
      if [ -f "$backup_path" ]; then
        run cp "$backup_path" "$path"
        log "Restored ${path} from backup."
      else
        log "Backup missing for ${path}, skipping restore."
      fi
    elif [ "$created_by_install" = "true" ]; then
      if [ "$DELETE_CREATED" = "true" ]; then
        if [ -f "$path" ]; then
          run rm "$path"
          log "Removed created file ${path}."
        fi
      else
        log "Leaving created file ${path} in place (pass --delete-created to remove)."
      fi
    fi

    i=$((i + 1))
  done
}

uninstall_packages() {
  local manifest="$1"

  if [ "$UNINSTALL_PACKAGES" != "true" ]; then
    return 0
  fi

  log "Uninstalling packages (if installed by this install)..."

  local yabai_installed skhd_installed
  yabai_installed=$(jq -r '.packages.yabai_installed_by_install' "$manifest")
  skhd_installed=$(jq -r '.packages.skhd_installed_by_install' "$manifest")

  if [ "$yabai_installed" = "true" ] && brew list yabai >/dev/null 2>&1; then
    run brew uninstall yabai
    log "Uninstalled yabai."
  fi

  if [ "$skhd_installed" = "true" ] && brew list skhd >/dev/null 2>&1; then
    run brew uninstall skhd
    log "Uninstalled skhd."
  fi
}

remove_tap() {
  local manifest="$1"

  if [ "$REMOVE_TAP" != "true" ]; then
    return 0
  fi

  log "Removing tap (if added by this install)..."

  local tap_added
  tap_added=$(jq -r '.homebrew.tap_asmvik_formulae_added_by_install' "$manifest")

  if [ "$tap_added" = "true" ]; then
    run brew untap asmvik/formulae || true
    log "Removed tap asmvik/formulae."
  fi
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --backup)
        if [ $# -lt 2 ]; then
          die "--backup requires a path"
        fi
        BACKUP_PATH="$2"
        shift 2
        ;;
      --uninstall-packages)
        UNINSTALL_PACKAGES=true
        shift
        ;;
      --remove-tap)
        REMOVE_TAP=true
        shift
        ;;
      --delete-created)
        DELETE_CREATED=true
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

  local manifest
  if [ -n "$BACKUP_PATH" ]; then
    if [ -f "$BACKUP_PATH" ]; then
      manifest="$BACKUP_PATH"
    elif [ -f "${BACKUP_PATH}/manifest.json" ]; then
      manifest="${BACKUP_PATH}/manifest.json"
    else
      die "Backup path not found: $BACKUP_PATH"
    fi
  else
    manifest=$(find_latest_manifest)
  fi

  log "Using manifest: ${manifest}"

  stop_services
  restore_configs "$manifest"
  uninstall_packages "$manifest"
  remove_tap "$manifest"

  log "Revert complete."
  echo ""
  echo "NOTE: Backup data was not deleted."
  echo "NOTE: Accessibility permissions were not reset."
  echo "      Remove yabai/skhd from System Settings → Privacy & Security → Accessibility manually if desired."
  echo ""
}

main "$@"
