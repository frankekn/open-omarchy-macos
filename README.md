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
| `cmd + h/j/k/l` | Focus west/south/north/east |
| `cmd + shift + h/j/k/l` | Swap window west/south/north/east |
| `cmd + alt + shift + h/j/k/l` | Resize window (grow left/down/up/right by 30px) |
| `cmd + alt + h/j/k/l` | Focus a different display (west/south/north/east) |
| `cmd + 1`…`cmd + 9` | Focus Space N |
| `cmd + shift + q` | Close focused window |
| `cmd + f` | Toggle zoom fullscreen |
| `cmd + shift + space` | Toggle floating |
| `fn + click-drag` | Move/resize windows with mouse |

## Config Files

- `modules/desktop/yabai/yabairc` → installed to `~/.config/yabai/yabairc`
- `modules/desktop/skhd/skhdrc` → installed to `~/.config/skhd/skhdrc`

Edit these after install to customize behavior.

## Known Limitations

- macOS cannot exactly reproduce Hyprland/Omarchy.
- Moving windows between Spaces is limited without scripting addition.
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
