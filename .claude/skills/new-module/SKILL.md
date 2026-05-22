---
name: new-module
description: Scaffold a new module for open-omarchy-macos. Creates modules/<name>/ skeleton, wires the installer entry, adds doctor checks, extends the smoke test, and updates the README keybindings table. Use when the user says "add a module" or "scaffold module <name>".
---

# new-module

Scaffold a new module end-to-end. This repo's modularity is the product;
adding a module touches more than one file and missing any one of them
silently breaks `doctor`, `revert`, or the smoke test.

## Inputs to collect from the user

Before scaffolding, you need:

1. **Module name** (lowercase, kebab-case, e.g. `karabiner`, `aerospace`, `raycast`).
2. **What it installs**: list of source-file → destination pairs.
   - Source paths live under `modules/<name>/`.
   - Destinations are usually under `~/.config/<app>/` or `~/.local/bin/`.
3. **Dependencies**: brew formulae or cask names this module requires.
4. **Optional keybindings**: if it adds shortcuts, what chords and what actions.

If any input is missing, ask in one batch via `AskUserQuestion`. Do not guess module names or destinations.

## Files to touch (checklist)

For every new module, all six steps must complete:

- [ ] `modules/<name>/` — directory with the config source(s)
- [ ] `modules/<name>/README.md` — one-paragraph description + what it installs
- [ ] `scripts/install.sh` — add `install_<name>` function and call it from `main`
- [ ] `scripts/doctor.sh` — add `=== <name> module ===` section with `[ok]/[fail]` checks
- [ ] `scripts/smoke-keybindings.sh` — if module adds keybindings, add a `check_<name>_config` block plus repo + installed assertions
- [ ] `README.md` — extend the keybindings table (if applicable) and the "Config Files" section
- [ ] `task.md` — add Phase entries marked `[x]` for each step that's done

Optional but recommended:

- [ ] `profiles/full.toml` — add `<name>` to enabled modules
- [ ] `docs/architecture.md` — extend the module list

## Templates

The directory next to this SKILL.md contains skeleton files:

- `templates/module-readme.md` — module README scaffold
- `templates/install-fn.sh` — bash function template for `install.sh`
- `templates/doctor-block.sh` — doctor.sh check block template

Copy these, fill in the placeholders (`<NAME>`, `<DESC>`, `<DEPS>`,
`<SRC_FILE>`, `<DEST_PATH>`), then run the install + smoke test to verify.

## Verification flow

After scaffolding:

```sh
./scripts/install.sh --dry-run            # check the new module is wired
./scripts/install.sh --module <name>      # actually install
./scripts/doctor.sh                       # all checks green
./scripts/smoke-keybindings.sh            # all assertions pass
```

If any of those fails, the scaffold is incomplete — go back and fix the
specific file the failure points at. Do not paper over with try/catch or
silenced errors; this distro is supposed to fail fast.

## Anti-patterns

- Don't add a module without a `doctor.sh` entry — silent breakage at install time is the worst failure mode for this product.
- Don't add keybindings without smoke-test assertions — past commits have hit exactly this regression.
- Don't write to user config paths from a module install function without backing the existing file up first; use `install_file` from `scripts/lib/*` if it exists.
- Don't hardcode `/opt/homebrew` vs `/usr/local` paths — use `command -v` discovery.
