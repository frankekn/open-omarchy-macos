# Goal: Mac-native Omarchy Workstation Command Layer

Turn `open-omarchy-macos` into a polished, Mac-native Omarchy workstation
command layer for Frank's personal development workflow.

## Intent

This is not a generic tmux plugin and not a clone of `tmux-palette`.

The product goal is a safe, reversible, Omarchy-inspired macOS distro where:

- macOS desktop control is handled by yabai/skhd, with private key-layer
  bindings where native `cmd` shortcuts would conflict.
- Ghostty/Terminal is only a launcher, not project state.
- tmux is the persistent workspace layer.
- tmux sessions are workspaces.
- tmux windows are projects/tasks.
- tmux panes are tools.
- the default project window is editor left, agent right.
- the editor and agent are configurable.
- `Alt+p` opens the project picker.
- `Alt+c` clones the current project layout.
- `Alt+a` opens the main command palette.
- the command palette is the unified Mac + Omarchy + project command surface.

## Implementation Direction

Use our own lightweight runtime: bash + tmux + fzf + macOS CLIs.

Do not vendor `tmux-palette`, do not add Bun/TypeScript, and do not build a
speculative plugin framework. Prefer simple, context-aware shell actions that
are easy to audit, install, and revert.

## Command Palette Target

Make `open-omarchy-command-palette` feel like a Mac-native Omarchy control
center, not just a tmux command list.

It should include:

- Open Omarchy actions: work session, project picker, clone project window,
  scratch window, reload/reinstall/status/doctor shortcuts where appropriate.
- tmux actions: pane/window/session navigation, splits, zoom, copy mode, rename,
  move/swap, find pane, and safe confirmed destructive actions.
- project actions: file picker, git branch checkout, npm scripts, GitHub PRs,
  Docker logs, LazyGit, process monitor, current repo/path helpers.
- macOS actions: open current project in Finder, copy current path to clipboard,
  open repo in browser, launch Ghostty/Raycast/System Settings when useful.
- yabai/skhd actions where they fit: focus/swap/toggle float/balance/restart
  services/status.
- context-aware visibility: show git actions only in repos, npm only with
  `package.json`, Docker only when containers exist, GitHub only when `gh`
  works, and macOS/yabai actions only when tools exist.

## Hard Constraints

- Keep the repo Mac-only and Mac-native.
- Do not make Linux/Hyprland assumptions.
- Do not change SIP.
- Do not install the yabai scripting addition.
- Do not edit sudoers.
- Install must always back up touched files before overwrite.
- Revert must actually restore from the manifest written by the current
  installer.
- `--dry-run` must never write files.
- Do not use `Ctrl+Space`; macOS input source shortcuts can intercept it.
- Keep `Ctrl+b` as the tmux prefix.
- Touch only necessary files.
- Avoid speculative abstractions.
- Use existing repo conventions: bash scripts, module layout,
  `open-omarchy-*` helper names, and config under
  `~/.config/open-omarchy-macos/config.toml`.

## Immediate Priorities

1. Make the current `Alt+a` palette first-class: robust categories, previews,
   context-aware actions, safe confirmations, clean shell quoting, and
   deterministic `--list`/test mode.
2. Add Mac-native/Open Omarchy actions that make the palette clearly better than
   a generic tmux menu.
3. Preserve install/revert/test consistency around the schema v2 `files`
   manifest contract. If the manifest changes, update install, revert, tests,
   and docs together.
4. Update docs so README, workflow, architecture, portability, task/plan status,
   and smoke tests describe the real behavior.
5. Verify with the narrowest realistic checks:
   - `bash -n` for touched scripts
   - `shellcheck` for new/changed shell helpers where practical
   - `./tests/run.sh`
   - `./scripts/smoke-keybindings.sh --repo-only`
   - installed/live smoke checks only when explicitly installing locally

## Success Criteria

- A fresh install can install desktop/tmux/nvim/terminal modules with backups.
- Revert restores the files written by that same install manifest.
- `Alt+a` opens a useful Mac + Omarchy command palette inside tmux.
- `Alt+p`, `Alt+c`, `Alt+s`, `Alt+v`, `Ctrl+b` prefix, and the no-`Ctrl+Space`
  policy remain intact.
- Palette actions work from the active tmux pane path and do not assume hardcoded
  project roots.
- Docs match actual command behavior.
- Tests and smoke checks pass, or any blocker is clearly reported with exact
  failing command/output.
