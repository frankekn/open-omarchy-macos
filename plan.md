# open-omarchy-macos Plan

## Goal

Build a declarative, portable, reversible macOS workstation distro covering
desktop tiling, terminal, tmux, Neovim, and workspace workflow — inspired by
Omarchy but Mac-native, agent-aware, and fully modular.

## Core Model

- terminal app = shell launcher only
- tmux session = persistent workspace
- tmux window = project/task
- tmux pane = tool (editor / agent / shell)
- Neovim = editor
- agent pane = opencode / codex / claude (user-configured)
- project roots = user-configured; never hardcoded

## Constraints

- Mac-only — no Linux/Hyprland assumptions
- Repo name stays `open-omarchy-macos`
- Agent configurable: `opencode`, `codex`, `claude`
- Project root user-specified via config
- No SIP changes, no scripting addition, no sudoers edits
- All installs must backup + be reversible
- `--dry-run` must never change files
- Terminal tabs not used as project state — tmux windows are
- Default layout: left `nvim` 60% / right agent 40%, no bottom shell
- Bottom shell and vertical splits are on-demand only

## Phases

| # | Phase              | Status  |
|---|--------------------|---------|
| 1 | Repo restructure   | pending |
| 2 | Config model       | pending |
| 3 | Workspace CLI      | pending |
| 4 | tmux module        | pending |
| 5 | Neovim module      | pending |
| 6 | Terminal module    | pending |
| 7 | Installer/revert   | pending |
| 8 | Doctor/status      | pending |
| 9 | Portability        | pending |

## Acceptance Criteria

- User can configure project roots
- User can configure agent (opencode / codex / claude)
- `Alt+p` opens project picker via fzf in a tmux popup
- `Alt+c` clones current project layout to a new window
- New project window opens nvim + agent pane side by side
- Bottom shell pane is optional, toggled on demand (`Alt+s`)
- Active pane focus is visually distinct
- Install supports `--dry-run`
- Every touched dotfile/config is backed up before overwrite
- `revert` restores prior state from backup manifest

## Key Decisions

- tmux windows = projects (not terminal app tabs)
- No bottom shell by default — `Alt+s` on demand
- Helper scripts named `open-omarchy-*` (not `tmux-*`) in repo
- User config at `~/.config/open-omarchy-macos/config.toml`
- Repo provides `open-omarchy.example.toml` as canonical defaults
- Kaku config only documented/patched (not auto-overwritten) — Kaku app manages its own config
- Use `vim.pack` (Neovim 0.12 built-in) instead of lazy.nvim to minimize dependencies
- `OPEN_OMARCHY_PROJECT_PATH` env var overrides cwd in dev-window script
- `OPEN_OMARCHY_PROJECT_ROOT` env var overrides project scan root in project-window script
- `TMUX_DEV_AGENT` env var overrides agent command

## Critical Technical Notes

- `~/.tmux.conf` loads BEFORE `~/.config/tmux/tmux.conf` — Tokyo Night vars defined there may conflict
- `pane-active-border-format` is NOT a valid tmux option; use `pane-border-format` with `#{?pane_active,...}` conditional
- `tmux-dev-window` must use `tmux display-message -p '#{pane_id}'` (not `$TMUX_PANE`) to get active pane correctly
- `KAKU_NO_EDITOR=1` env var prevents auto-start of Neovim in Kaku right-side panes
- `~/.config/kaku/zsh/bin/yazi` is a wrapper; real binary is `/opt/homebrew/bin/yazi`
- `Ctrl+Space` is intercepted by macOS input source shortcut — not usable as tmux prefix

## Relevant Files (live dotfiles, not in repo yet)

- `~/.config/tmux/tmux.conf` — Omarchy-style tmux config
- `~/.config/nvim/init.lua` — Neovim config with Neo-tree via vim.pack
- `~/.config/ghostty/config` — Ghostty stable config
- `~/.config/kaku/kaku.lua` — Kaku (WezTerm-based) config
- `~/.local/bin/tmux-dev-window` — creates 2-pane project layout
- `~/.local/bin/tmux-project-window` — fzf project picker → dev window
- `~/.zshrc` — `t()` entry point, `_tmux_build_dev_layout`, shell integration
