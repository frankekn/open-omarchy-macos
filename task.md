# open-omarchy-macos Tasks

## Phase 1: Repo Structure

- [x] Create `modules/` directory
- [x] Move `config/yabai/` → `modules/desktop/yabai/`
- [x] Move `config/skhd/` → `modules/desktop/skhd/`
- [x] Add `docs/` directory
- [x] Add `docs/workflow.md` — tmux session/window/pane model
- [x] Add `docs/architecture.md` — module layout and dependency map
- [x] Update `README.md` to reflect new structure

## Phase 2: Config Model

- [x] Add `open-omarchy.example.toml` with all supported keys and comments
- [x] Define `project_roots` (array of paths)
- [x] Define `agent` (`opencode` | `codex` | `claude`)
- [x] Define `editor` (default: `nvim`)
- [x] Define `layout.main_pct` (default: 60)
- [x] Define `layout.bottom_shell` (default: false)
- [x] Add `scripts/lib/config.sh` — TOML loader (bash, minimal)

## Phase 3: Workspace CLI

- [x] Add `bin/open-omarchy` entrypoint script
- [x] Implement `open-omarchy install [--module <name>] [--dry-run]`
- [ ] Implement `open-omarchy revert [--module <name>]`
- [x] Implement `open-omarchy status`
- [x] Implement `open-omarchy doctor`
- [x] Implement `open-omarchy work` — attach/create Work tmux session
- [x] Implement `open-omarchy project` — fzf picker → dev window
- [x] Implement `open-omarchy palette` — command palette launcher

## Phase 4: tmux Module

- [x] Add `modules/tmux/tmux.conf` (copy from `~/.config/tmux/tmux.conf`)
- [x] Add `modules/tmux/bin/open-omarchy-dev-window`
- [x] Add `modules/tmux/bin/open-omarchy-project-window`
- [x] Add `modules/tmux/bin/open-omarchy-command-palette`
- [x] Update installer to symlink/copy tmux module files
- [x] Document `Alt+a`, `Alt+p`, `Alt+c`, `Alt+s`, `Alt+v` keybinds

## Phase 5: Neovim Module

- [x] Add `modules/nvim/init.lua` (copy from `~/.config/nvim/init.lua`)
- [x] Add `modules/nvim/README.md` — plugin bootstrap instructions
- [x] Document `vim.pack` usage (Neovim 0.12+)
- [x] Update installer to copy `modules/nvim/init.lua` → `~/.config/nvim/init.lua`

## Phase 6: Terminal Module

- [x] Add `modules/terminal/ghostty/config` (copy from `~/.config/ghostty/config`)
- [x] Add `modules/terminal/kaku/kaku.patch.lua` — patch snippet (not full override)
- [x] Add `modules/terminal/README.md` — Ghostty setup; Kaku caveats
- [x] Update installer for Ghostty config; Kaku as docs/patch only

## Phase 7: Installer/Revert Upgrade

- [x] Refactor `scripts/install.sh` to support `--module <name>`
- [ ] Refactor `scripts/install.sh` to support `--profile <name>`
- [x] Ensure every write produces a backup entry in `state/manifest.json`
- [ ] Refactor `scripts/revert.sh` to restore from manifest per-module
- [x] Add `--dry-run` flag that prints actions without executing
- [x] Align install/revert/tests on schema v2 `files` manifest

## Phase 8: Doctor/Status

- [x] Add `scripts/doctor.sh`
- [x] Check all required deps: `tmux`, `nvim`, `fzf`, `fd`, `git`, agent binary
- [x] Check configured project roots exist
- [x] Check agent binary is on PATH
- [x] Show installed module status
- [x] Exit non-zero if any required dep is missing

## Phase 9: Portability

- [x] Add `docs/portability.md` — tested Mac versions, known gaps
- [x] Document optional `tmux-resurrect` + `tmux-continuum` setup
- [x] Add `profiles/minimal.toml` — desktop only
- [x] Add `profiles/full.toml` — desktop + tmux + nvim + terminal
