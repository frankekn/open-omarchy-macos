# Neovim Module

## Requirements

- Neovim 0.12 or later (`brew install neovim`)
- No external plugin manager needed — uses the built-in `vim.pack` API

## What Gets Installed

`init.lua` → `~/.config/nvim/init.lua`

## Plugins

Plugins are installed via `vim.pack.add` to `~/.local/share/nvim/pack/` on
first launch. No manual bootstrap step is required.

| Plugin | Purpose |
|--------|---------|
| `nvim-neo-tree/neo-tree.nvim` | File tree sidebar |
| `nvim-lua/plenary.nvim` | Lua utility library (Neo-tree dep) |
| `MunifTanjim/nui.nvim` | UI components (Neo-tree dep) |
| `nvim-tree/nvim-web-devicons` | File icons |

## Key Bindings

| Binding | Action |
|---------|--------|
| `Space e` | Toggle Neo-tree sidebar |
| `:Neotree` | Open Neo-tree |

## Notes

- `netrw` is disabled in favour of Neo-tree.
- Running `nvim .` auto-opens the Neo-tree sidebar.
- Plugins install on first launch; subsequent launches are instant.
- `vim.pack` is a Neovim 0.12+ built-in. Do not replace with lazy.nvim
  unless you need features it provides.
