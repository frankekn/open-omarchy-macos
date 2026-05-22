# Append this block to scripts/doctor.sh inside the module-checks section.

check_<NAME>_module() {
  printf '\n=== <NAME> module ===\n'

  if command -v <DEP_BIN> >/dev/null 2>&1; then
    pass "<DEP_BIN> (`command -v <DEP_BIN>`)"
  else
    fail "<DEP_BIN> not on PATH (brew install <DEPS>)"
  fi

  if [ -f "<DEST_PATH>" ]; then
    pass "<DEST_PATH>"
  else
    fail "<DEST_PATH> not installed (run: open-omarchy install --module <NAME>)"
  fi
}
