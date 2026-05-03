# Terminal Module

## Ghostty (primary)

`ghostty/config` → installed to `~/.config/ghostty/config`

Install Ghostty stable via Homebrew:

```sh
brew install --cask ghostty
```

The config sets:
- Ghostty stable `1.3.1` (not `tip`)
- Dark palette aligned with Kaku Dark
- `Cmd+T` opens a new tab
- Split keybinds at 68/32 ratio

## Kaku (optional, docs/patch only)

Kaku is a WezTerm-based terminal that manages its own config file at
`~/.config/kaku/kaku.lua`. The installer does **not** overwrite it.

Instead, `kaku/kaku.patch.lua` contains a commented snippet you can
manually apply to your `kaku.lua`.

Key settings to apply:
- `config.color_scheme = "Kaku Dark"`
- Set `KAKU_NO_EDITOR=1` in agent/helper pane shells to prevent Kaku's
  built-in Neovim auto-start conflicting with the workspace layout.

## Notes

- The real `yazi` binary is `/opt/homebrew/bin/yazi`.
  `~/.config/kaku/zsh/bin/yazi` is a wrapper — prefer the real binary.
- `Ctrl+Space` is intercepted by macOS Input Source shortcut by default.
  Disable in **System Settings → Keyboard → Keyboard Shortcuts → Input Sources**,
  or use `Ctrl+b` as the tmux prefix.
