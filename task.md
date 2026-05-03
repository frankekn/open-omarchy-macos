# open-omarchy-macos Tasks

## Phase 1: Repo Structure

- [ ] Create `modules/` directory
- [ ] Move `config/yabai/` → `modules/desktop/yabai/`
- [ ] Move `config/skhd/` → `modules/desktop/skhd/`
- [ ] Add `docs/` directory
- [ ] Add `docs/workflow.md` — tmux session/window/pane model
- [ ] Add `docs/architecture.md` — module layout and dependency map
- [ ] Update `README.md` to reflect new structure

## Phase 2: Config Model

- [ ] Add `open-omarchy.example.toml` with all supported keys and comments
- [ ] Define `project_roots` (array of paths)
- [ ] Define `agent` (`opencode` | `codex` | `claude`)
- [ ] Define `editor` (default: `nvim`)
- [ ] Define `layout.main_pct` (default: 60)
- [ ] Define `layout.bottom_shell` (default: false)
- [ ] Add `scripts/lib/config.sh` — TOML loader (bash, minimal)

## Phase 3: Workspace CLI

- [ ] Add `bin/open-omarchy` entrypoint script
- [ ] Implement `open-omarchy install [--module <name>] [--dry-run]`
- [ ] Implement `open-omarchy revert [--module <name>]`
- [ ] Implement `open-omarchy status`
- [ ] Implement `open-omarchy doctor`
- [ ] Implement `open-omarchy work` — attach/create Work tmux session
- [ ] Implement `open-omarchy project` — fzf picker → dev window

## Phase 4: tmux Module

- [ ] Add `modules/tmux/tmux.conf` (copy from `~/.config/tmux/tmux.conf`)
- [ ] Add `modules/tmux/bin/open-omarchy-dev-window`
- [ ] Add `modules/tmux/bin/open-omarchy-project-window`
- [ ] Update installer to symlink/copy tmux module files
- [ ] Document `Alt+p`, `Alt+c`, `Alt+s`, `Alt+v` keybinds

## Phase 5: Neovim Module

- [ ] Add `modules/nvim/init.lua` (copy from `~/.config/nvim/init.lua`)
- [ ] Add `modules/nvim/README.md` — plugin bootstrap instructions
- [ ] Document `vim.pack` usage (Neovim 0.12+)
- [ ] Update installer to symlink `modules/nvim/init.lua` → `~/.config/nvim/init.lua`

## Phase 6: Terminal Module

- [ ] Add `modules/terminal/ghostty/config` (copy from `~/.config/ghostty/config`)
- [ ] Add `modules/terminal/kaku/kaku.patch.lua` — patch snippet (not full override)
- [ ] Add `modules/terminal/README.md` — Ghostty setup; Kaku caveats
- [ ] Update installer for Ghostty config; Kaku as docs/patch only

## Phase 7: Installer/Revert Upgrade

- [ ] Refactor `scripts/install.sh` to support `--module <name>`
- [ ] Refactor `scripts/install.sh` to support `--profile <name>`
- [ ] Ensure every write produces a backup entry in `state/manifest.json`
- [ ] Refactor `scripts/revert.sh` to restore from manifest per-module
- [ ] Add `--dry-run` flag that prints actions without executing

## Phase 8: Doctor/Status

- [ ] Add `scripts/doctor.sh`
- [ ] Check all required deps: `tmux`, `nvim`, `fzf`, `fd`, `git`, agent binary
- [ ] Check configured project roots exist
- [ ] Check agent binary is on PATH
- [ ] Show installed module status
- [ ] Exit non-zero if any required dep is missing

## Phase 9: Portability

- [ ] Add `docs/portability.md` — tested Mac versions, known gaps
- [ ] Document optional `tmux-resurrect` + `tmux-continuum` setup
- [ ] Add `profiles/minimal.toml` — desktop only
- [ ] Add `profiles/full.toml` — desktop + tmux + nvim + terminal
