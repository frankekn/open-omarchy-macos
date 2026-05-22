# open-omarchy-macos

A safe, reversible, Omarchy-inspired macOS desktop setup using [yabai](https://github.com/asmvik/yabai) for tiling window management and [skhd](https://github.com/asmvik/skhd) for keyboard-driven hotkeys.

## What This Does

- Provides BSP tiling with gaps and padding.
- Maps Omarchy `SUPER` keybindings to macOS `cmd`.
- Keeps install safe: no SIP changes, no scripting addition, no sudoers edits.
- Backs up existing configs before overwriting.
- Provides a clean revert path.

## What This Does Not Do

- Disable System Integrity Protection (SIP).
- Install yabai scripting addition.
- Modify `sudoers`.
- Reset Accessibility/TCC permissions automatically.
- Reproduce full Linux Hyprland behavior on macOS.

## Requirements

- macOS 11+ (Big Sur or later).
- Apple Silicon or Intel Mac.
- [Homebrew](https://brew.sh) installed.
- `jq` installed for manifest and revert support (`brew install jq`).

## Install

```sh
./scripts/install.sh
```

Dry-run to preview actions without changing anything:

```sh
./scripts/install.sh --dry-run
```

After install, you must manually grant Accessibility permissions:

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Add and enable:
   - `/opt/homebrew/bin/yabai` (Apple Silicon)
   - `/opt/homebrew/bin/skhd` (Apple Silicon)
   - Or `/usr/local/bin/yabai` and `/usr/local/bin/skhd` on Intel.
3. Restart services:
   ```sh
   yabai --restart-service
   skhd --restart-service
   ```

## Manual macOS Settings

For best results, set these before or after install:

- **System Settings → Desktop & Dock → Mission Control**
  - Enable **"Displays have separate Spaces"**.
  - Disable **"Automatically rearrange Spaces based on most recent use"**.
- **System Settings → Desktop & Dock → Desktop & Stage Manager**
  - Enable **"Show Items On Desktop"** (multi-display reliability).
  - Set **"Click wallpaper to reveal Desktop"** to **"Only in Stage Manager"**.

## Revert

Restore previous state:

```sh
./scripts/revert.sh
```

Options:

```sh
./scripts/revert.sh --dry-run              # preview
./scripts/revert.sh --backup <path>        # use specific backup
./scripts/revert.sh --uninstall-packages   # also uninstall yabai/skhd
./scripts/revert.sh --remove-tap           # also remove asmvik/formulae tap
./scripts/revert.sh --delete-created       # remove configs created by install
```

## Status

Check current setup state:

```sh
./scripts/status.sh
```

## Keybindings

| Binding | Action |
|---------|--------|
| `cmd + return` | Open terminal (Ghostty → Terminal fallback) |
| `cmd + space` | Open launcher (Raycast → Spotlight fallback) |
| `Caps + h/j/k/l` | Focus west/south/north/east via Karabiner → F13/F14/F15/F16 |
| `cmd + shift + h/j/k/l` | Swap window west/south/north/east |
| `cmd + alt + shift + h/j/k/l` | Resize window (grow left/down/up/right by 30px) |
| `cmd + alt + h/j/k/l` | Focus a different display (west/south/north/east) |
| `cmd + ctrl + 1`…`cmd + ctrl + 9` | Focus Space N (cmd+N is left for app tabs) |
| `cmd + shift + ctrl + 1`…`cmd + shift + ctrl + 9` | Move focused window to Space N and follow it |
| `cmd + shift + q` | Close focused window |
| `cmd + f` | Toggle zoom fullscreen |
| `cmd + shift + space` | Toggle floating |
| `fn + click-drag` | Move/resize windows with mouse |

The desktop focus layer avoids `cmd + h/j/k/l` because `cmd+h` is a native
macOS hide-app shortcut. Configure Karabiner or another keyboard remapper to
send `F13/F14/F15/F16` from `Caps+h/j/k/l`; `skhd` binds those private keys to
yabai directional focus.

Inside tmux:

| Binding | Action |
|---------|--------|
| `Alt + a` | Open command palette |
| `Alt + p` | Open project picker |
| `Alt + c` | Clone current project window |
| `Alt + s` | Split top/bottom 50/50 |
| `Alt + v` | Split left/right 50/50 |

The command palette shows known direct shortcuts beside actions and includes
Neovim quick actions when `nvim` is installed.

## Config Files

- `bin/open-omarchy` → installed to `~/.local/bin/open-omarchy`
- `modules/desktop/yabai/yabairc` → installed to `~/.config/yabai/yabairc`
- `modules/desktop/skhd/skhdrc` → installed to `~/.config/skhd/skhdrc`
- `modules/tmux/tmux.conf` → installed to `~/.config/tmux/tmux.conf`
- `modules/tmux/bin/*` → installed to `~/.local/bin/`
- `modules/nvim/init.lua` → installed to `~/.config/nvim/init.lua`
- `modules/terminal/ghostty/config` → installed to `~/.config/ghostty/config`

Edit these after install to customize behavior.

## Known Limitations

- macOS cannot exactly reproduce Hyprland/Omarchy.
- Creating new Spaces still requires Mission Control (no scripting addition).
- Native fullscreen creates a separate Space and may feel different from Hyprland fullscreen.
- Some apps with native tabs (Terminal, Finder) may not tile predictably.
- Terminal apps with Secure Keyboard Entry can block `skhd` from receiving keys.

## Structure

```
open-omarchy-macos/
  README.md
  plan.md
  task.md
  open-omarchy.example.toml
  bin/open-omarchy
  modules/
    desktop/
      yabai/yabairc
      skhd/skhdrc
    tmux/
      tmux.conf
      bin/open-omarchy-command-palette
    nvim/
    terminal/
  scripts/
    install.sh
    revert.sh
    status.sh
    doctor.sh
  docs/
    workflow.md
    architecture.md
  state/
    example-manifest.json
```

See [docs/workflow.md](docs/workflow.md) for the tmux session/window/pane model.
See [docs/architecture.md](docs/architecture.md) for the module system and config model.

## License

MIT
