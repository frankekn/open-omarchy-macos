# Workflow Model

## Mental Model

```
Mac session
└── tmux Work session
    ├── window 1: project-a    ← tmux window = project
    │   ├── pane left: nvim    ← editor
    │   └── pane right: agent  ← opencode / codex / claude
    ├── window 2: project-b
    │   ├── pane left: nvim
    │   └── pane right: agent
    └── window 3: scratch      ← on-demand shell
```

Terminal tabs are NOT used as project state. A single terminal window runs the
Work tmux session. All context lives in tmux windows and panes.

## Entry Point

Run `t` in any shell to attach to (or create) the Work session with a seeded layout.

```sh
t
```

## Creating a Project Window

`Alt+p` — opens an fzf popup over your configured project roots. Select a
directory to open a new tmux window with the standard dev layout.

```
Alt+p   → fzf project picker → new window (nvim + agent)
```

## Command Palette

`Alt+a` — opens a repo-native command palette for common tmux and project
actions.

```
Alt+a   → command palette
```

The palette is intentionally local and shell-based. It uses `fzf`, `tmux`, and
the existing Open Omarchy helper scripts instead of installing a third-party
plugin. Actions with direct shortcuts show their key binding in the picker, so
the palette also works as a quick key reference.

It includes pane/window/session actions, Open Omarchy workflow actions, macOS
helpers, yabai/skhd utilities, and context-aware project tools such as file
search, git branch checkout, Neovim actions, npm scripts, Docker logs, GitHub
PRs, and process monitors when those commands are available.

## Desktop Focus

Window focus uses a private key layer instead of global `cmd+h/j/k/l`.
Configure Karabiner so `Caps+h/j/k/l` emits `F13/F14/F15/F16`; `skhd` maps
those private keys to yabai west/south/north/east focus. This keeps the
Vim-style direction model without stealing macOS app shortcuts such as
`cmd+h`.

## Cloning the Current Layout

`Alt+c` — duplicates the current window's layout into a new window pointing at
the same directory.

```
Alt+c   → clone current project window
```

## On-Demand Panes

```
Alt+s   → split current pane top/bottom 50/50
Alt+v   → split current pane left/right 50/50
```

## Shell Shortcuts

zsh shortcuts such as `cdx` and `claudeskip` work only in a shell pane. They do
not run inside full-screen TUI programs such as `opencode`, `codex`, `claude`,
or `nvim`.

Use `Alt+s` or `Alt+v` to open a shell pane, then run the shortcut there.

## Switching Windows

```
Alt+1 … Alt+9   → switch to window 1–9
Alt+Left/Right  → switch to previous/next window
Alt+Shift+Left  → move current window left
Alt+Shift+Right → move current window right
Ctrl+b k        → kill current window
```

## Prefix

The tmux prefix is `Ctrl+b`.

`Ctrl+Space` is not used because macOS input source switching can intercept it.

## Reloading tmux Config

Inside tmux:

```
Ctrl+b q
```

From a shell:

```sh
tmux source-file ~/.config/tmux/tmux.conf
```

## Keybinding Smoke Test

Run this after changing Ghostty or tmux bindings:

```sh
./scripts/smoke-keybindings.sh
```

It checks the repo config, installed config, and live tmux server bindings. It
cannot prove macOS delivered a physical keypress, but it catches the common
breakages: Option not treated as Alt, missing `Ctrl+b` prefix, stale installed
tmux config, and live tmux not loading `Alt+a` / `Alt+c` / `Alt+p`.

## Agent

The agent pane runs whichever binary is configured in `~/.config/open-omarchy-macos/config.toml`:

```toml
agent = "opencode"   # or "codex" or "claude"
```

The `TMUX_DEV_AGENT` env var overrides this per-shell.

## Project Root

The project picker scans directories configured in `config.toml`:

```toml
project_roots = [
  "~/Documents/GitHub",
  "~/projects",
]
```

The `OPEN_OMARCHY_PROJECT_ROOT` env var overrides this per-shell.
