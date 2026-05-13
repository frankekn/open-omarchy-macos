#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ORIGINAL_PATH="$PATH"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/open-omarchy-tests.XXXXXX")"

CASE_DIR=""
BIN_DIR=""
FAKE_STATE=""
LAST_STDOUT=""
LAST_STDERR=""

cleanup() {
  rm -rf "$TEST_ROOT"
}

fail() {
  echo "not ok - $1" >&2
  if [ -n "$LAST_STDOUT" ] && [ -f "$LAST_STDOUT" ]; then
    echo "--- stdout ---" >&2
    sed 's/^/  /' "$LAST_STDOUT" >&2
  fi
  if [ -n "$LAST_STDERR" ] && [ -f "$LAST_STDERR" ]; then
    echo "--- stderr ---" >&2
    sed 's/^/  /' "$LAST_STDERR" >&2
  fi
  exit 1
}

pass() {
  echo "ok - $1"
}

write_file() {
  local path="$1"
  local content="$2"

  mkdir -p "$(dirname "$path")"
  printf '%s' "$content" > "$path"
}

assert_file_exists() {
  local path="$1"

  [ -f "$path" ] || fail "expected file to exist: $path"
}

assert_file_not_exists() {
  local path="$1"

  [ ! -e "$path" ] || fail "expected path not to exist: $path"
}

assert_contains() {
  local path="$1"
  local expected="$2"

  grep -Fq -- "$expected" "$path" || fail "expected $path to contain: $expected"
}

assert_not_contains() {
  local path="$1"
  local unexpected="$2"

  if grep -Fq -- "$unexpected" "$path"; then
    fail "expected $path not to contain: $unexpected"
  fi
}

assert_file_content() {
  local path="$1"
  local expected="$2"
  local actual

  actual="$(< "$path")"
  [ "$actual" = "$expected" ] || fail "unexpected file content for $path"
}

assert_jq_value() {
  local path="$1"
  local query="$2"
  local expected="$3"
  local actual

  actual="$(jq -r "$query" "$path")"
  [ "$actual" = "$expected" ] || fail "expected $query in $path to be $expected, got $actual"
}

write_fake_tools() {
  cat > "${BIN_DIR}/brew" <<'FAKE_BREW'
#!/usr/bin/env bash
set -euo pipefail

log() {
  printf 'brew %s\n' "$*" >> "${FAKE_STATE}/commands.log"
}

case "${1:-}" in
  --prefix)
    echo "${FAKE_BREW_PREFIX:-/opt/homebrew}"
    ;;
  --version)
    echo "Homebrew 9.9.9"
    ;;
  tap)
    if [ "$#" -eq 1 ]; then
      if [ -f "${FAKE_STATE}/tap-asmvik-formulae" ]; then
        echo "asmvik/formulae"
      fi
      exit 0
    fi
    if [ "${2:-}" = "asmvik/formulae" ]; then
      touch "${FAKE_STATE}/tap-asmvik-formulae"
      log "$*"
      exit 0
    fi
    exit 1
    ;;
  list)
    [ -f "${FAKE_STATE}/package-${2:-}" ]
    ;;
  install)
    formula="${2:-}"
    package="${formula##*/}"
    touch "${FAKE_STATE}/package-${package}"
    log "$*"
    ;;
  uninstall)
    rm -f "${FAKE_STATE}/package-${2:-}"
    log "$*"
    ;;
  untap)
    if [ "${FAIL_UNTAP:-false}" = true ]; then
      log "$* failed"
      exit 1
    fi
    rm -f "${FAKE_STATE}/tap-asmvik-formulae"
    log "$*"
    ;;
  *)
    log "$*"
    ;;
esac
FAKE_BREW

  cat > "${BIN_DIR}/yabai" <<'FAKE_SERVICE'
#!/usr/bin/env bash
set -euo pipefail

service_name="$(basename "$0")"
printf '%s %s\n' "$service_name" "$*" >> "${FAKE_STATE}/commands.log"

case "${1:-}" in
  --version)
    echo "${service_name} 9.9.9"
    ;;
  --start-service)
    if [ "${FAIL_START_SERVICE:-}" = "$service_name" ] || [ "${FAIL_START_SERVICE:-}" = all ]; then
      exit 42
    fi
    touch "${FAKE_STATE}/running-${service_name}"
    ;;
  --stop-service)
    rm -f "${FAKE_STATE}/running-${service_name}"
    ;;
esac
FAKE_SERVICE

  cp "${BIN_DIR}/yabai" "${BIN_DIR}/skhd"

  cat > "${BIN_DIR}/pgrep" <<'FAKE_PGREP'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-x" ] && [ -n "${2:-}" ]; then
  [ -f "${FAKE_STATE}/running-${2}" ]
  exit $?
fi

exit 1
FAKE_PGREP

  cat > "${BIN_DIR}/sw_vers" <<'FAKE_SW_VERS'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "-productVersion" ]; then
  echo "14.0"
  exit 0
fi

exit 1
FAKE_SW_VERS

  chmod +x "${BIN_DIR}/brew" "${BIN_DIR}/yabai" "${BIN_DIR}/skhd" "${BIN_DIR}/pgrep" "${BIN_DIR}/sw_vers"
}

new_case() {
  local name="$1"

  CASE_DIR="${TEST_ROOT}/${name}"
  BIN_DIR="${CASE_DIR}/bin"
  FAKE_STATE="${CASE_DIR}/state"
  HOME="${CASE_DIR}/home"
  mkdir -p "$BIN_DIR" "$FAKE_STATE" "$HOME"
  write_fake_tools
  export HOME FAKE_STATE
  PATH="${BIN_DIR}:${ORIGINAL_PATH}"
  export PATH
}

run_success() {
  LAST_STDOUT="${CASE_DIR}/stdout.log"
  LAST_STDERR="${CASE_DIR}/stderr.log"

  if ! (cd "$REPO_DIR" && "$@") > "$LAST_STDOUT" 2> "$LAST_STDERR"; then
    fail "expected command to succeed: $*"
  fi
}

run_failure() {
  LAST_STDOUT="${CASE_DIR}/stdout.log"
  LAST_STDERR="${CASE_DIR}/stderr.log"

  if (cd "$REPO_DIR" && "$@") > "$LAST_STDOUT" 2> "$LAST_STDERR"; then
    fail "expected command to fail: $*"
  fi
}

latest_manifest() {
  find "${HOME}/.local/state/open-omarchy-macos/backups" -name manifest.json -type f | sort | tail -n1
}

test_install_dry_run_does_not_write() {
  new_case "install-dry-run"
  run_success ./scripts/install.sh --dry-run

  assert_file_not_exists "${HOME}/.config/yabai/yabairc"
  assert_file_not_exists "${HOME}/.config/skhd/skhdrc"
  assert_file_not_exists "${HOME}/.local/state/open-omarchy-macos"
  assert_contains "$LAST_STDERR" "Would write manifest"
  pass "install dry-run does not write files"
}

test_install_writes_valid_manifest() {
  new_case "install-real"
  run_success ./scripts/install.sh

  local manifest
  manifest="$(latest_manifest)"
  assert_file_exists "$manifest"
  jq empty "$manifest"
  assert_file_exists "${HOME}/.config/yabai/yabairc"
  assert_file_exists "${HOME}/.config/skhd/skhdrc"
  assert_file_exists "${FAKE_STATE}/running-yabai"
  assert_file_exists "${FAKE_STATE}/running-skhd"
  assert_jq_value "$manifest" '.schema_version' 1
  assert_jq_value "$manifest" '.homebrew.tap_asmvik_formulae_added_by_install' true
  assert_jq_value "$manifest" ".configs[] | select(.path == \"${HOME}/.local/bin/open-omarchy\") | .created_by_install" true
  pass "install writes valid manifest"
}

test_existing_configs_are_backed_up() {
  new_case "existing-configs"
  write_file "${HOME}/.config/yabai/yabairc" "original yabai"
  write_file "${HOME}/.config/skhd/skhdrc" "original skhd"

  run_success ./scripts/install.sh

  local manifest yabai_backup skhd_backup
  manifest="$(latest_manifest)"
  yabai_backup="$(jq -r --arg path "${HOME}/.config/yabai/yabairc" '.configs[] | select(.path == $path) | .backup_path' "$manifest")"
  skhd_backup="$(jq -r --arg path "${HOME}/.config/skhd/skhdrc" '.configs[] | select(.path == $path) | .backup_path' "$manifest")"

  assert_file_content "$yabai_backup" "original yabai"
  assert_file_content "$skhd_backup" "original skhd"
  assert_jq_value "$manifest" ".configs[] | select(.path == \"${HOME}/.config/yabai/yabairc\") | .existed_before" true
  assert_jq_value "$manifest" ".configs[] | select(.path == \"${HOME}/.config/skhd/skhdrc\") | .existed_before" true
  pass "existing configs are backed up"
}

test_service_failure_leaves_manifest() {
  new_case "service-failure"
  export FAIL_START_SERVICE=yabai

  run_failure ./scripts/install.sh
  unset FAIL_START_SERVICE

  local manifest
  manifest="$(latest_manifest)"
  assert_file_exists "$manifest"
  jq empty "$manifest"
  pass "service failure leaves valid manifest"
}

test_revert_no_backup_error() {
  new_case "revert-no-backup"
  run_failure ./scripts/revert.sh --dry-run

  assert_contains "$LAST_STDERR" "No backup manifest found"
  pass "revert reports missing backup"
}

test_revert_restores_configs() {
  new_case "revert-restores"
  write_file "${HOME}/.config/yabai/yabairc" "original yabai"
  write_file "${HOME}/.config/skhd/skhdrc" "original skhd"
  run_success ./scripts/install.sh

  local manifest
  manifest="$(latest_manifest)"
  run_success ./scripts/revert.sh --backup "$manifest"

  assert_file_content "${HOME}/.config/yabai/yabairc" "original yabai"
  assert_file_content "${HOME}/.config/skhd/skhdrc" "original skhd"
  pass "revert restores configs"
}

test_revert_deletes_created_files_when_requested() {
  new_case "revert-delete-created"
  run_success ./scripts/install.sh

  local manifest
  manifest="$(latest_manifest)"
  run_success ./scripts/revert.sh --backup "$manifest" --delete-created

  assert_file_not_exists "${HOME}/.local/bin/open-omarchy"
  assert_file_not_exists "${HOME}/.config/yabai/yabairc"
  assert_file_not_exists "${HOME}/.config/skhd/skhdrc"
  assert_file_not_exists "${HOME}/.config/tmux/tmux.conf"
  assert_file_not_exists "${HOME}/.local/bin/open-omarchy-command-palette"
  pass "revert deletes created files when requested"
}

test_revert_dry_run_tap_wording() {
  new_case "revert-dry-run-tap"
  run_success ./scripts/install.sh

  local manifest
  manifest="$(latest_manifest)"
  run_success ./scripts/revert.sh --dry-run --backup "$manifest" --remove-tap

  assert_contains "$LAST_STDERR" "Would remove tap asmvik/formulae."
  assert_not_contains "$LAST_STDERR" "Removed tap asmvik/formulae."
  pass "revert dry-run tap wording is literal"
}

test_home_with_quote_has_valid_manifest() {
  new_case "quoted-home"
  local quote
  quote="$(printf '%b' '\042')"
  HOME="${CASE_DIR}/home with ${quote}quote${quote}"
  mkdir -p "$HOME"
  export HOME

  run_success ./scripts/install.sh

  local manifest
  manifest="$(latest_manifest)"
  assert_file_exists "$manifest"
  jq empty "$manifest"
  local actual
  actual="$(jq -r --arg path "${HOME}/.config/yabai/yabairc" '.configs[] | select(.path == $path) | .path' "$manifest")"
  [ "$actual" = "${HOME}/.config/yabai/yabairc" ] || fail "manifest did not preserve quoted home path"
  pass "manifest handles quoted home path"
}

test_revert_round_trip_full_install() {
  new_case "revert-roundtrip-full"

  # Pre-populate every module's install destination with sentinel content so
  # we can verify revert restores all of them (not just yabai/skhd).
  write_file "${HOME}/.config/yabai/yabairc"  "sentinel yabai"
  write_file "${HOME}/.config/skhd/skhdrc"    "sentinel skhd"
  write_file "${HOME}/.config/tmux/tmux.conf" "sentinel tmux"
  write_file "${HOME}/.config/nvim/init.lua"  "sentinel nvim"
  write_file "${HOME}/.config/ghostty/config" "sentinel ghostty"

  run_success ./scripts/install.sh

  # Sanity: install actually overwrote them.
  local current
  current="$(< "${HOME}/.config/yabai/yabairc")"
  if [ "$current" = "sentinel yabai" ]; then
    fail "install did not overwrite yabairc"
  fi

  # Revert with default backup discovery (no --backup flag).
  run_success ./scripts/revert.sh

  assert_file_content "${HOME}/.config/yabai/yabairc"  "sentinel yabai"
  assert_file_content "${HOME}/.config/skhd/skhdrc"    "sentinel skhd"
  assert_file_content "${HOME}/.config/tmux/tmux.conf" "sentinel tmux"
  assert_file_content "${HOME}/.config/nvim/init.lua"  "sentinel nvim"
  assert_file_content "${HOME}/.config/ghostty/config" "sentinel ghostty"
  pass "revert round-trip restores all module configs"
}

test_revert_uninstalls_only_what_install_added() {
  new_case "revert-preserves-preinstalled"

  # Pre-existing yabai + tap; skhd is fresh. Install should record:
  #   yabai_installed_by_install: false
  #   skhd_installed_by_install:  true
  #   tap_added_by_install:       false
  touch "${FAKE_STATE}/package-yabai"
  touch "${FAKE_STATE}/tap-asmvik-formulae"

  run_success ./scripts/install.sh

  local manifest
  manifest="$(latest_manifest)"
  assert_jq_value "$manifest" '.packages.yabai_installed_by_install' false
  assert_jq_value "$manifest" '.packages.skhd_installed_by_install'  true
  assert_jq_value "$manifest" '.homebrew.tap_asmvik_formulae_added_by_install' false

  run_success ./scripts/revert.sh --uninstall-packages --remove-tap

  [ -f "${FAKE_STATE}/package-yabai" ] || fail "revert removed pre-existing yabai package"
  if [ -f "${FAKE_STATE}/package-skhd" ]; then
    fail "revert failed to remove install-added skhd package"
  fi
  [ -f "${FAKE_STATE}/tap-asmvik-formulae" ] || fail "revert removed pre-existing tap"

  pass "revert uninstalls only what install added"
}

test_tmux_module_installs_fzf_fd() {
  new_case "tmux-installs-fzf-fd"
  run_success ./scripts/install.sh --module tmux

  assert_contains "${FAKE_STATE}/commands.log" "install fzf"
  assert_contains "${FAKE_STATE}/commands.log" "install fd"
  assert_file_exists "${HOME}/.local/bin/open-omarchy-command-palette"
  pass "tmux module installs fzf and fd"
}

test_tmux_warns_when_tmux_conf_exists() {
  new_case "tmux-warn-shadow"
  write_file "${HOME}/.tmux.conf" "user kaku tmux config"

  run_success ./scripts/install.sh --module tmux

  assert_contains "$LAST_STDERR" "~/.tmux.conf"
  assert_contains "$LAST_STDERR" "shadowed"
  pass "tmux module warns when ~/.tmux.conf shadows new config"
}

test_tmux_no_warn_when_tmux_conf_absent() {
  new_case "tmux-no-warn"
  run_success ./scripts/install.sh --module tmux

  assert_not_contains "$LAST_STDERR" "shadowed"
  pass "tmux module does not warn when ~/.tmux.conf is absent"
}

test_shell_module_installs_t_alias() {
  new_case "shell-installs-t"
  run_success ./scripts/install.sh --module shell

  assert_file_exists "${HOME}/.config/open-omarchy-macos/shell.zsh"
  assert_contains    "${HOME}/.config/open-omarchy-macos/shell.zsh" "t() {"
  assert_file_exists "${HOME}/.local/bin/open-omarchy"
  assert_file_exists "${HOME}/.zshrc"
  assert_contains    "${HOME}/.zshrc" "# >>> open-omarchy-macos >>>"
  assert_contains    "${HOME}/.zshrc" "# <<< open-omarchy-macos <<<"
  pass "shell module installs t alias and CLI wrapper"
}

test_shell_module_idempotent() {
  new_case "shell-idempotent"
  run_success ./scripts/install.sh --module shell
  run_success ./scripts/install.sh --module shell

  local marker_count
  marker_count=$(grep -cF -- "# >>> open-omarchy-macos >>>" "${HOME}/.zshrc")
  if [ "$marker_count" -ne 1 ]; then
    fail "expected exactly one marker block in ~/.zshrc, found $marker_count"
  fi
  pass "shell module install is idempotent"
}

stub_tmux_for_work_test() {
  # Tmux stub that logs argv and forces cmd_work into the new-session branch
  # by failing has-session. attach/switch/new-session succeed.
  cat > "${BIN_DIR}/tmux" <<'FAKE_TMUX'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${FAKE_STATE}/tmux-argv.log"
case "${1:-}" in
  has-session) exit 1 ;;
  *) exit 0 ;;
esac
FAKE_TMUX
  chmod +x "${BIN_DIR}/tmux"
  unset TMUX
}

test_open_omarchy_work_respects_config_session_name() {
  new_case "open-omarchy-work-config"
  stub_tmux_for_work_test

  mkdir -p "${HOME}/.config/open-omarchy-macos"
  printf '%s\n' 'session_name = "Foo"' > "${HOME}/.config/open-omarchy-macos/config.toml"

  run_success ./bin/open-omarchy work

  assert_contains "${FAKE_STATE}/tmux-argv.log" "new-session -s Foo"
  pass "open-omarchy work uses session_name from config.toml"
}

test_open_omarchy_work_defaults_to_work_session() {
  new_case "open-omarchy-work-default"
  stub_tmux_for_work_test

  run_success ./bin/open-omarchy work

  assert_contains "${FAKE_STATE}/tmux-argv.log" "new-session -s Work"
  pass "open-omarchy work defaults to Work session when no config"
}

test_shell_module_revert_restores_zshrc() {
  new_case "shell-revert-zshrc"
  write_file "${HOME}/.zshrc" "# user's original zshrc"

  run_success ./scripts/install.sh --module shell

  # Sanity: install actually appended the marker.
  assert_contains "${HOME}/.zshrc" "# >>> open-omarchy-macos >>>"

  run_success ./scripts/revert.sh

  assert_file_content "${HOME}/.zshrc" "# user's original zshrc"
  pass "shell module revert restores original ~/.zshrc"
}

trap cleanup EXIT

test_install_dry_run_does_not_write
test_install_writes_valid_manifest
test_existing_configs_are_backed_up
test_service_failure_leaves_manifest
test_revert_no_backup_error
test_revert_restores_configs
test_revert_deletes_created_files_when_requested
test_revert_dry_run_tap_wording
test_home_with_quote_has_valid_manifest
test_revert_round_trip_full_install
test_revert_uninstalls_only_what_install_added
test_tmux_module_installs_fzf_fd
test_tmux_warns_when_tmux_conf_exists
test_tmux_no_warn_when_tmux_conf_absent
test_shell_module_installs_t_alias
test_shell_module_idempotent
test_shell_module_revert_restores_zshrc
test_open_omarchy_work_respects_config_session_name
test_open_omarchy_work_defaults_to_work_session

echo "All tests passed."
