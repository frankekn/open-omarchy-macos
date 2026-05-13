#!/usr/bin/env bash
# scripts/install.sh — open-omarchy-macos installer
# Usage: install.sh [--module <name>] [--dry-run]
# Modules: desktop | tmux | nvim | terminal | all (default)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STATE_DIR="${HOME}/.local/state/open-omarchy-macos"
BACKUP_DIR="${STATE_DIR}/backups/$(date +%Y%m%d-%H%M%S)"
MANIFEST_FILE="${BACKUP_DIR}/manifest.json"

DRY_RUN=false
MODULES=()

# Entries appended by each module install: "src|dest|existed_before|backup_path"
# `existed_before` = the dest file was present before we wrote it.
# `created_by_install` is derived as the negation of `existed_before` at manifest time.
INSTALLED_FILES=()

# Pre-mutation state captured at module entry. Used by write_manifest to
# populate the schema-v1 .packages / .homebrew / .services blocks that
# scripts/revert.sh reads.
TAP_WAS_PRESENT="false"
YABAI_WAS_INSTALLED="false"
SKHD_WAS_INSTALLED="false"
YABAI_WAS_RUNNING="false"
SKHD_WAS_RUNNING="false"
DESKTOP_MODULE_RAN="false"

# Set to "true" once write_manifest has succeeded. Used by partial_install_trap
# to guarantee a manifest is written even when a later step (e.g. service
# start) fails — so revert can roll back the configs that were already
# copied.
MANIFEST_WRITTEN="false"

log() {
  echo "[open-omarchy] $1" >&2
}

die() {
  echo "[open-omarchy] ERROR: $1" >&2
  exit 1
}

run() {
  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would run: $*" >&2
  else
    "$@"
  fi
}

# backup_file <src> <backup_subdir>
# Copies src to BACKUP_DIR/backup_subdir/ if it exists.
# Prints "true" if backed up, "false" otherwise.
backup_file() {
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

# install_file <src> <dest>
# Backs up dest if it exists, then copies src to dest.
# Records the operation in INSTALLED_FILES.
install_file() {
  local src="$1"
  local dest="$2"
  local subdir
  subdir="backup/$(basename "$(dirname "$dest")")"
  local existed_before
  existed_before=$(backup_file "$dest" "$subdir")
  local backup_path=""
  if [ "$existed_before" = "true" ]; then
    backup_path="${BACKUP_DIR}/${subdir}/$(basename "$dest")"
  fi

  run mkdir -p "$(dirname "$dest")"
  run cp "$src" "$dest"

  INSTALLED_FILES+=("${src}|${dest}|${existed_before}|${backup_path}")
  log "Installed: $dest"
}

# install_bin <src> <dest_dir>
# Copies src as executable to dest_dir/basename(src).
install_bin() {
  local src="$1"
  local dest_dir="$2"
  local dest
  dest="${dest_dir}/$(basename "$src")"

  local existed_before
  existed_before=$(backup_file "$dest" "backup/bin")
  local backup_path=""
  if [ "$existed_before" = "true" ]; then
    backup_path="${BACKUP_DIR}/backup/bin/$(basename "$dest")"
  fi

  run mkdir -p "$dest_dir"
  run cp "$src" "$dest"
  run chmod +x "$dest"

  INSTALLED_FILES+=("${src}|${dest}|${existed_before}|${backup_path}")
  log "Installed: $dest"
}

write_manifest() {
  if [ "$MANIFEST_WRITTEN" = true ]; then
    return 0
  fi

  run mkdir -p "$BACKUP_DIR"

  # Build .configs[] from INSTALLED_FILES.
  local configs_json="[]"
  for entry in "${INSTALLED_FILES[@]+"${INSTALLED_FILES[@]}"}"; do
    IFS='|' read -r _src dest existed_before backup_path <<< "$entry"
    local created_by_install="true"
    if [ "$existed_before" = "true" ]; then
      created_by_install="false"
    fi
    configs_json=$(echo "$configs_json" | jq \
      --arg path "$dest" \
      --argjson existed_before "$existed_before" \
      --arg backup_path "$backup_path" \
      --argjson created_by_install "$created_by_install" \
      '. + [{
        path: $path,
        existed_before: $existed_before,
        backup_path: (if $backup_path == "" then null else $backup_path end),
        created_by_install: $created_by_install
      }]')
  done

  # Derive *_by_install flags as the negation of pre-mutation state.
  # When the desktop module did not run, all desktop-related flags are false
  # so revert.sh treats them as no-ops.
  local yabai_installed_by_install="false"
  local skhd_installed_by_install="false"
  local tap_added_by_install="false"
  if [ "$DESKTOP_MODULE_RAN" = "true" ]; then
    [ "$YABAI_WAS_INSTALLED" = "false" ] && yabai_installed_by_install="true"
    [ "$SKHD_WAS_INSTALLED"  = "false" ] && skhd_installed_by_install="true"
    [ "$TAP_WAS_PRESENT"     = "false" ] && tap_added_by_install="true"
  fi

  local manifest
  manifest=$(jq -n \
    --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg backup_dir "$BACKUP_DIR" \
    --argjson configs "$configs_json" \
    --argjson yabai_installed "$yabai_installed_by_install" \
    --argjson skhd_installed "$skhd_installed_by_install" \
    --argjson tap_added "$tap_added_by_install" \
    --argjson yabai_was_running "$YABAI_WAS_RUNNING" \
    --argjson skhd_was_running "$SKHD_WAS_RUNNING" \
    '{
      schema_version: 1,
      created_at: $created_at,
      repo: "open-omarchy-macos",
      backup_dir: $backup_dir,
      configs: $configs,
      packages: {
        yabai_installed_by_install: $yabai_installed,
        skhd_installed_by_install: $skhd_installed
      },
      homebrew: {
        tap_asmvik_formulae_added_by_install: $tap_added
      },
      services: {
        yabai_was_running_before: $yabai_was_running,
        skhd_was_running_before: $skhd_was_running
      }
    }')

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would write manifest to ${MANIFEST_FILE}" >&2
  else
    echo "$manifest" > "$MANIFEST_FILE"
    log "Manifest written to ${MANIFEST_FILE}"
    MANIFEST_WRITTEN="true"
  fi
}

# EXIT trap — if install fails partway through, still record what we did so
# revert can roll back partial state. Runs at the end of any exit path.
partial_install_trap() {
  local rc=$?
  if [ "$rc" -ne 0 ] && [ "$MANIFEST_WRITTEN" = "false" ] && [ "$DRY_RUN" = "false" ]; then
    write_manifest 2>&1 || true
  fi
}

preflight() {
  log "Preflight checks..."

  if ! command -v brew >/dev/null 2>&1; then
    die "Homebrew not found. Install from https://brew.sh"
  fi

  if ! command -v jq >/dev/null 2>&1; then
    die "jq not found. Install with: brew install jq"
  fi

  log "macOS $(sw_vers -productVersion) / $(uname -m)"
  log "Preflight OK."
}

# ensure_formula <formula>
# Installs <formula> via Homebrew if `brew list <basename>` reports it absent.
# `<formula>` may be tap-qualified ("asmvik/formulae/yabai"); the basename is
# used for the presence check. Idempotent and dry-run aware via run().
ensure_formula() {
  local formula="$1"
  local name="${formula##*/}"
  if brew list "$name" >/dev/null 2>&1; then
    log "$name already installed."
  else
    run brew install "$formula"
  fi
}

# ── Module: desktop ──────────────────────────────────────────────────────────

install_desktop() {
  log "Installing module: desktop"

  # Capture pre-mutation state so revert can know what we changed.
  DESKTOP_MODULE_RAN="true"
  if brew tap | grep -q "^asmvik/formulae$"; then
    TAP_WAS_PRESENT="true"
  fi
  if brew list yabai >/dev/null 2>&1; then
    YABAI_WAS_INSTALLED="true"
  fi
  if brew list skhd >/dev/null 2>&1; then
    SKHD_WAS_INSTALLED="true"
  fi
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -x yabai >/dev/null 2>&1 && YABAI_WAS_RUNNING="true"
    pgrep -x skhd  >/dev/null 2>&1 && SKHD_WAS_RUNNING="true"
  fi

  # Homebrew tap + packages
  if [ "$TAP_WAS_PRESENT" = "false" ]; then
    run brew tap asmvik/formulae
  else
    log "Tap asmvik/formulae already present."
  fi

  if [ "$YABAI_WAS_INSTALLED" = "false" ]; then
    run brew install asmvik/formulae/yabai
  else
    log "yabai already installed."
  fi

  if [ "$SKHD_WAS_INSTALLED" = "false" ]; then
    run brew install asmvik/formulae/skhd
  else
    log "skhd already installed."
  fi

  install_file "${REPO_DIR}/modules/desktop/yabai/yabairc" "${HOME}/.config/yabai/yabairc"
  install_file "${REPO_DIR}/modules/desktop/skhd/skhdrc"   "${HOME}/.config/skhd/skhdrc"

  # Start services
  run yabai --start-service
  run skhd --start-service

  if [ "$DRY_RUN" = false ]; then
    echo ""
    echo "========================================"
    echo "IMPORTANT: Grant Accessibility permissions"
    echo "========================================"
    echo "System Settings → Privacy & Security → Accessibility"
    echo "Add and enable: $(brew --prefix)/bin/yabai  and  $(brew --prefix)/bin/skhd"
    echo "Then: yabai --restart-service && skhd --restart-service"
    echo "NOTE: SIP was not changed. Scripting addition was not installed."
    echo ""
  fi
}

# ── Module: tmux ─────────────────────────────────────────────────────────────

install_tmux() {
  log "Installing module: tmux"

  if ! command -v tmux >/dev/null 2>&1; then
    run brew install tmux
  else
    log "tmux already installed."
  fi

  # fzf and fd back the project picker (Alt+p) used by
  # open-omarchy-project-window. doctor.sh marks them required.
  ensure_formula fzf
  ensure_formula fd

  install_file \
    "${REPO_DIR}/modules/tmux/tmux.conf" \
    "${HOME}/.config/tmux/tmux.conf"

  install_bin \
    "${REPO_DIR}/modules/tmux/bin/open-omarchy-dev-window" \
    "${HOME}/.local/bin"

  install_bin \
    "${REPO_DIR}/modules/tmux/bin/open-omarchy-project-window" \
    "${HOME}/.local/bin"

  install_bin \
    "${REPO_DIR}/modules/tmux/bin/open-omarchy-command-palette" \
    "${HOME}/.local/bin"

  if [ -f "${HOME}/.tmux.conf" ]; then
    log ""
    log "WARNING: ${HOME}/.tmux.conf exists and tmux loads it BEFORE"
    log "         ~/.config/tmux/tmux.conf, so the Omarchy bindings may be"
    log "         shadowed. Consider:"
    log "             mv ~/.tmux.conf ~/.tmux.conf.pre-omarchy"
    log "         (Restore later with: mv ~/.tmux.conf.pre-omarchy ~/.tmux.conf)"
    log ""
  fi

  log "tmux module installed. Inside tmux, reload with Ctrl+b q."
  log "From a shell: tmux source-file ~/.config/tmux/tmux.conf"
}

# ── Module: nvim ─────────────────────────────────────────────────────────────

install_nvim() {
  log "Installing module: nvim"

  if ! command -v nvim >/dev/null 2>&1; then
    run brew install neovim
  else
    log "nvim already installed."
  fi

  install_file \
    "${REPO_DIR}/modules/nvim/init.lua" \
    "${HOME}/.config/nvim/init.lua"

  log "nvim module installed. Plugins install on first launch."
}

# ── Module: terminal ─────────────────────────────────────────────────────────

install_terminal() {
  log "Installing module: terminal"

  if ! command -v /Applications/Ghostty.app/Contents/MacOS/ghostty >/dev/null 2>&1 \
    && ! brew list --cask ghostty >/dev/null 2>&1; then
    run brew install --cask ghostty
  else
    log "Ghostty already installed."
  fi

  install_file \
    "${REPO_DIR}/modules/terminal/ghostty/config" \
    "${HOME}/.config/ghostty/config"

  log "Kaku: apply modules/terminal/kaku/kaku.patch.lua manually to ~/.config/kaku/kaku.lua"
  log "terminal module installed."
}

# ── Module: shell ────────────────────────────────────────────────────────────

# Marker block written into ~/.zshrc. Used to detect prior installs (for
# idempotency) and as a safe boundary if a future revert needs to strip it.
SHELL_MARKER_BEGIN="# >>> open-omarchy-macos >>>"
SHELL_MARKER_END="# <<< open-omarchy-macos <<<"

install_shell() {
  log "Installing module: shell"

  # 1. Helper functions live in a partial sourced from ~/.zshrc.
  install_file \
    "${REPO_DIR}/modules/shell/zshrc.partial" \
    "${HOME}/.config/open-omarchy-macos/shell.zsh"

  # 2. Wrapper for the open-omarchy CLI on PATH. The repo's bin/open-omarchy
  #    relies on its own location to find scripts/, so we install a tiny
  #    wrapper that exec's it rather than copying it (which would break
  #    relative-path lookups) or symlinking (which is fragile across BSD).
  local cli_wrapper="${HOME}/.local/bin/open-omarchy"
  local existed_before
  existed_before=$(backup_file "$cli_wrapper" "backup/bin")
  local backup_path=""
  if [ "$existed_before" = "true" ]; then
    backup_path="${BACKUP_DIR}/backup/bin/$(basename "$cli_wrapper")"
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "[DRY-RUN] Would write CLI wrapper at ${cli_wrapper}" >&2
  else
    mkdir -p "$(dirname "$cli_wrapper")"
    cat > "$cli_wrapper" <<WRAPPER
#!/usr/bin/env bash
# Generated by open-omarchy-macos install_shell.
exec "${REPO_DIR}/bin/open-omarchy" "\$@"
WRAPPER
    chmod +x "$cli_wrapper"
  fi
  INSTALLED_FILES+=("|${cli_wrapper}|${existed_before}|${backup_path}")
  log "Installed: $cli_wrapper"

  # 3. Append a marker block to ~/.zshrc that sources the partial.
  #    The whole pre-edit ~/.zshrc is backed up so revert can restore it
  #    byte-for-byte without any custom revert logic.
  local zshrc="${HOME}/.zshrc"
  local zshrc_existed_before
  zshrc_existed_before=$(backup_file "$zshrc" "backup")
  local zshrc_backup=""
  if [ "$zshrc_existed_before" = "true" ]; then
    zshrc_backup="${BACKUP_DIR}/backup/$(basename "$zshrc")"
  fi

  if [ -f "$zshrc" ] && grep -Fq -- "$SHELL_MARKER_BEGIN" "$zshrc"; then
    log "${zshrc} already contains open-omarchy-macos marker block; not appending."
  else
    if [ "$DRY_RUN" = true ]; then
      echo "[DRY-RUN] Would append open-omarchy-macos marker block to $zshrc" >&2
    else
      mkdir -p "$(dirname "$zshrc")"
      {
        printf '\n%s\n' "$SHELL_MARKER_BEGIN"
        printf '%s\n' "[ -f \"\$HOME/.config/open-omarchy-macos/shell.zsh\" ] && source \"\$HOME/.config/open-omarchy-macos/shell.zsh\""
        printf '%s\n' "$SHELL_MARKER_END"
      } >> "$zshrc"
    fi
  fi
  INSTALLED_FILES+=("|${zshrc}|${zshrc_existed_before}|${zshrc_backup}")
  log "Installed: $zshrc (marker block)"

  log "shell module installed. Open a new shell or run: source ~/.zshrc"
  log "Then: \`t\` attaches to the Work tmux session."
}

# ── Dispatch ─────────────────────────────────────────────────────────────────

install_module() {
  case "$1" in
    desktop)  install_desktop  ;;
    tmux)     install_tmux     ;;
    nvim)     install_nvim     ;;
    terminal) install_terminal ;;
    shell)    install_shell    ;;
    *) die "Unknown module: $1  (valid: desktop | tmux | nvim | terminal | shell)" ;;
  esac
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --module)
        [ $# -gt 1 ] || die "--module requires a value"
        MODULES+=("$2")
        shift 2
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done

  [ "$DRY_RUN" = true ] && log "DRY RUN MODE — no changes will be made"

  preflight

  if [ "$DRY_RUN" = false ]; then
    mkdir -p "$BACKUP_DIR"
  fi

  trap partial_install_trap EXIT

  if [ ${#MODULES[@]} -eq 0 ]; then
    MODULES=(desktop tmux nvim terminal shell)
  fi

  for module in "${MODULES[@]}"; do
    install_module "$module"
  done

  write_manifest

  log "Install complete."
}

main "$@"
