-- open-omarchy-macos Kaku patch
-- Apply these settings to your kaku.lua to align with the Omarchy workflow.
-- Do NOT replace your full kaku.lua with this file.
-- Kaku manages its own config; the installer cannot overwrite it safely.

-- Color scheme
config.color_scheme = "Kaku Dark"

-- Font (adjust path/name to your installed font)
-- config.font = wezterm.font("Berkeley Mono", { weight = "Regular" })

-- Split pane ratio: 68% editor / 32% helper
config.initial_cols = 220
config.initial_rows = 50

-- Prevent Kaku's right-side pane from auto-launching Neovim
-- Set KAKU_NO_EDITOR=1 in your shell for helper/agent panes.
-- Example in tmux: `tmux send-keys "KAKU_NO_EDITOR=1 opencode" C-m`

-- Pass Ctrl+Space through to tmux
-- config.keys = config.keys or {}
-- table.insert(config.keys, {
--   key = "Space",
--   mods = "CTRL",
--   action = wezterm.action.SendKey { key = "Space", mods = "CTRL" },
-- })
