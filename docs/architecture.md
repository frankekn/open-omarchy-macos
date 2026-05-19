# Architecture

## Directory Layout

```
open-omarchy-macos/
├── plan.md                          ← goal, phases, constraints, decisions
├── task.md                          ← per-phase task checklist
├── README.md                        ← quick-start and keybindings
├── open-omarchy.example.toml        ← canonical config template
├── bin/
│   └── open-omarchy                 ← CLI entrypoint; installed to ~/.local/bin
├── modules/
│   ├── desktop/                     ← tiling WM module
│   │   ├── yabai/yabairc
│   │   └── skhd/skhdrc
│   ├── tmux/                        ← tmux module
│   │   ├── tmux.conf
│   │   └── bin/
│   │       ├── open-omarchy-dev-window
│   │       ├── open-omarchy-project-window
│   │       └── open-omarchy-command-palette
│   ├── nvim/                        ← Neovim module
│   │   └── init.lua
│   └── terminal/                    ← terminal module
│       ├── ghostty/config
│       └── kaku/kaku.patch.lua
├── profiles/
│   ├── minimal.toml                 ← desktop only
│   └── full.toml                    ← desktop + tmux + nvim + terminal
├── scripts/
│   ├── install.sh
│   ├── revert.sh
│   ├── status.sh
│   ├── doctor.sh
│   └── lib/
│       └── config.sh                ← TOML config loader
├── docs/
│   ├── workflow.md
│   └── architecture.md
├── state/
│   └── example-manifest.json
└── tests/
    └── run.sh
```

## Module System

Each module is a self-contained directory under `modules/`. The installer
copies module files to their target dotfile locations and records every write in
a backup manifest.

```
install  → backup existing → write new → update manifest
revert   → read manifest   → restore backups
```

Modules installed by `--module <name>`:
- `desktop` — yabai + skhd configs
- `tmux` — tmux.conf + bin scripts
- `nvim` — init.lua
- `terminal` — Ghostty config (Kaku: docs/patch only)

## Config Model

User config lives at `~/.config/open-omarchy-macos/config.toml`. The repo
provides `open-omarchy.example.toml` as the canonical reference.

Key fields:
```toml
project_roots = ["~/Documents/GitHub"]
agent         = "opencode"   # opencode | codex | claude
editor        = "nvim"
[layout]
main_pct     = 60            # nvim pane width %
bottom_shell = false         # show bottom shell by default
```

## Env Var Overrides

| Variable | Overrides |
|----------|-----------|
| `OPEN_OMARCHY_PROJECT_PATH` | cwd in `open-omarchy-dev-window` |
| `OPEN_OMARCHY_PROJECT_ROOT` | project scan root in project-window picker |
| `TMUX_DEV_AGENT` | agent command in dev-window |

## tmux Palette

The command palette is a local `fzf` helper, not an external tmux plugin. It is
installed as `~/.local/bin/open-omarchy-command-palette` and bound to `Alt+a`.
It wraps Open Omarchy workflow actions, common tmux actions, macOS helpers,
yabai/skhd utilities, and context-aware project tools.

Desktop directional focus is intentionally not bound to `cmd+h/j/k/l` or
`cmd+Arrow`. The desktop module binds private `F13`-`F16` events in `skhd`; a
keyboard remapper such as Karabiner can emit those events from a Caps layer.

## Manifest Contract

Install writes schema v1 manifests under
`~/.local/state/open-omarchy-macos/backups/<timestamp>/manifest.json`.

The restore contract is the top-level `configs` array:

- `path` is the installed path.
- `existed_before` tells revert whether a pre-existing file was copied aside.
- `backup_path` points at that saved file when `existed_before` is true.
- `created_by_install` tells revert whether `--delete-created` may remove the
  file when no backup exists.

The manifest also records tap/package/service metadata for optional revert
flags such as `--remove-tap`, `--uninstall-packages`, and service restoration.

The shell module installs `~/.local/bin/open-omarchy` as a small wrapper that
execs the repo checkout, keeping command behavior tied to the current tree.

## Dependency Direction

```
bin/open-omarchy CLI
    → scripts/install.sh | revert.sh | status.sh | doctor.sh
        → scripts/lib/config.sh (config loader)
        → modules/* (source files)
        → state/manifest.json (backup registry)
```

## Known Constraints

- Kaku manages its own config file — the installer cannot safely overwrite it.
  The terminal module provides a patch snippet + documentation only.
- `Ctrl+Space` is avoided because macOS Input Source shortcuts can intercept it.
  Use `Ctrl+b` as the tmux prefix.
- `~/.tmux.conf` (e.g., Tokyo Night + TPM) loads before
  `~/.config/tmux/tmux.conf`. Variable conflicts are possible.
- `pane-active-border-format` is not a valid tmux option; use
  `pane-border-format` with `#{?pane_active,...}` conditional.
