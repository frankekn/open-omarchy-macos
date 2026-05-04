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

## Switching Windows

```
Alt+1 … Alt+9   → switch to window 1–9
Ctrl+b k        → kill current window
```

## Prefix

The tmux prefix is `Ctrl+b` (standard) or `Ctrl+Space` if not intercepted by macOS.

Note: macOS Input Source shortcut intercepts `Ctrl+Space` by default. Disable
it in **System Settings → Keyboard → Keyboard Shortcuts → Input Sources** or
use `Ctrl+b`.

## Keybinding Smoke Test

Run this after changing Ghostty or tmux bindings:

```sh
./scripts/smoke-keybindings.sh
```

It checks the repo config, installed config, and live tmux server bindings. It
cannot prove macOS delivered a physical keypress, but it catches the common
breakages: Option not treated as Alt, missing `Ctrl+b` fallback, stale installed
tmux config, and live tmux not loading `Alt+c` / `Alt+p`.

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
