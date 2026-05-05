# Portability

## Tested Environments

| macOS version | Architecture | Status |
|---------------|-------------|--------|
| 15 Sequoia    | Apple Silicon (M-series) | tested |
| 14 Sonoma     | Apple Silicon | expected to work |
| 13 Ventura    | Apple Silicon / Intel | expected to work |
| 11 Big Sur    | Intel | minimum requirement |

## Known Gaps vs Linux Omarchy

| Feature | Linux (Hyprland) | macOS |
|---------|-----------------|-------|
| Window gaps | native | yabai BSP (no SIP required) |
| Move to Space | instant | limited without scripting addition |
| Native fullscreen | same Space | separate Space (macOS behavior) |
| Secure keyboard entry | n/a | blocks skhd in some terminals |
| Ctrl+Space prefix | n/a | not used; intercepted by macOS Input Source |

## Ctrl+Space Policy

macOS can intercept `Ctrl+Space` for Input Source switching. open-omarchy-macos
uses `Ctrl+b` as the tmux prefix instead.

If you want to use `Ctrl+Space` manually, disable **System Settings → Keyboard
→ Keyboard Shortcuts → Input Sources → Select the previous input source** first.

## Optional: tmux-resurrect + tmux-continuum

If you use TPM and want session persistence across reboots:

```sh
# In ~/.tmux.conf (your existing TPM config):
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @continuum-restore 'on'
```

Then run `Ctrl+b I` to install plugins.

Note: `~/.tmux.conf` loads before `~/.config/tmux/tmux.conf`. TPM plugins
defined there are available in the Omarchy config layer.

## Multi-Display

- Enable **"Displays have separate Spaces"** in System Settings → Desktop & Dock → Mission Control.
- Disable **"Automatically rearrange Spaces based on most recent use"**.

## Intel Macs

Homebrew prefix is `/usr/local/bin` instead of `/opt/homebrew/bin`. The
`open-omarchy-dev-window` script uses `EDITOR` env var (`nvim` resolved via
PATH), so Intel Macs work without changes as long as nvim is on PATH.
