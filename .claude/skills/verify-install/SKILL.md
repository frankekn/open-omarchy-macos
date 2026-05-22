---
name: verify-install
description: Verify a freshly installed (or updated) open-omarchy-macos setup by chaining status, doctor, and smoke-keybindings. Use after running ./scripts/install.sh or when the user asks "is everything wired up?", "verify install", or "is my setup healthy?".
disable-model-invocation: true
---

# verify-install

Chain the three verification surfaces this repo already ships, so a "did
that install actually work?" check is one prompt instead of three commands
the user has to remember.

## What it runs

In order, blocking on the first failure:

1. `./scripts/status.sh` — every config file, service, and binary present
2. `./scripts/doctor.sh` — required deps, project roots, agent binary on PATH
3. `./scripts/smoke-keybindings.sh` — repo + installed config assertions; live tmux assertions if a tmux server is up

## Output

Summarize as a table:

| Check | Result |
|---|---|
| `status.sh` | ✅ or count of missing items |
| `doctor.sh` | ✅ or `N failed / M passed` |
| `smoke-keybindings.sh` | ✅ or `N failed / M passed` |

If anything fails, surface the first failing line verbatim and stop —
don't try to fix it from inside this skill. Hand back to the user (or
suggest the relevant module to reinstall).

## What it does NOT do

- Does not modify any file.
- Does not re-run the installer.
- Does not chase down causes — the existing scripts have specific error
  messages; trust them and surface those messages.

## Why user-only

`disable-model-invocation: true` because the verification surface is a
deliberate user-driven decision point. The model running this on its own
during normal work would just be noise. The user asks; the skill runs.
