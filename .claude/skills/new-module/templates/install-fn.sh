# Append this function to scripts/install.sh and call it from `main`.

install_<NAME>() {
  log "Installing module: <NAME>"

  # Brew deps. Skip the block if <NAME> has none.
  if ! command -v <DEP_BIN> >/dev/null 2>&1; then
    run brew install <DEPS>
  else
    log "<DEP_BIN> already installed."
  fi

  install_file \
    "${REPO_DIR}/modules/<NAME>/<SRC_FILE>" \
    "<DEST_PATH>"

  log "<NAME> module installed."
}
