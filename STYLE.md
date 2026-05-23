# LUCKy Style Guide

Conventions for developers and agents adding or modifying modules in this
repository.

## How the framework works

- `lucky.sh install` writes `~/.bashrc` from `dotfiles/bashrc`.
- That `.bashrc` sources every `*.sh` in `mods-enabled/` in ascending
  filename order.
- `mods-available/` holds every module; `mods-enabled/` holds symlinks to
  the ones that load. `lucky.sh enable` / `disable` manage the symlinks.
- Modules are **sourced** into the user's shell, not executed. Use
  `return` to stop early, never `exit`.

## File naming

- Modules are named `NN_modname.sh`, where `NN` is a two-digit priority.
- `00` is reserved for `lucky_core.sh`.
- Otherwise: pick a number lower than any module that depends on you and
  higher than any module you depend on.
- `modname` is also the module's log namespace and the argument to
  `lucky.sh enable` / `disable` / `locate` / `reload`.

## Logging

- Use `logmsg <namespace>::<level> <message>` for every message.
- The namespace must match the module's filename minus the `NN_` prefix
  and `.sh` suffix.
- Levels: `error`, `warn`, `info`, `debug`. Default verbosity is `2`
  (errors + warnings). Routine load chatter is `debug`.
- A `logmsg <ns>::debug Loaded ...` line near the top is the standard
  "I'm here" marker.

## Capability gates

A module must load cleanly on a system that doesn't have its tool.
Pattern: detect, log at `debug`, return.

- Use `command -v <tool> >/dev/null` for command detection.
- Use `[ -d "$DIR" ]` / `[ -f "$FILE" ]` for filesystem checks.

```bash
if ! command -v lean >/dev/null; then
    logmsg lean::debug lean not installed, skipping
    return
fi
```

## Interactive-only guards

Modules that only affect interactive behavior (prompt, aliases, banner,
history) early-return for non-interactive shells:

```bash
[[ "$-" != *i* ]] && return
```

Modules that export environment for downstream tools (PATH, EDITOR,
LUCKY_*, etc.) omit the guard so non-interactive shells inherit the
exports.

## Functions

- Use `function name() { ... }` for declarations.
- Function names use kebab-case (e.g., `words-split-by-hyphen`).
- Internal-only functions are prefixed with `_`.
- User-facing helpers exposed by a module are named
  `lucky-<modname>-<verb>` (e.g., `lucky-ssh-install`,
  `lucky-kitty-install`). Module name first keeps things hierarchical
  and tab-completion predictable: typing `lucky-ssh-<TAB>` shows
  everything the `ssh` module exposes.

## Variables

- Lucky-owned exports use the `LUCKY_` prefix.
- Every variable assigned inside a function must be declared `local`
  unless it is intentionally exported.

## PATH and other path-like variables

- Append by default: `PATH=$PATH:$NEW_DIR`.
- Prepend only when the module's intent is to shadow a system binary;
  add a one-line comment saying so.
- Re-`export` after mutating (`PATH`, `LD_LIBRARY_PATH`, `MANPATH`, …).

## Reusable helpers

- Catch-all helpers live in `01_utils.sh`.
- A coherent cluster of reusable helpers (color/RGB math, JSON, …) gets
  its own foundational-priority module (e.g., `01_color_utils.sh`).
- Module-specific helpers stay in their module.

## Banners and stdout

- A successful load is silent. Use `logmsg <ns>::debug` instead of
  `echo`.
- Anything that must reach the terminal goes to stderr (`>&2`).
- Banners and welcome text belong in `lucky.sh` subcommands or prompt
  modules, not in module load paths.

## Checklist for a new module

1. Pick a priority `NN` that orders correctly relative to your deps;
   name the file `NN_<modname>.sh` under `mods-available/`.
2. Open with `logmsg <modname>::debug <one-line summary>`.
3. If the module only affects interactive shells, add
   `[[ "$-" != *i* ]] && return` near the top.
4. Gate external tools and directories with `command -v` / `[ -d ... ]`,
   log at `debug`, and `return` cleanly if missing.
5. Declare in-function variables as `local`.
6. Prefix new lucky-owned exports with `LUCKY_`. Append to `PATH`.
7. Use `function kebab-name() { ... }`; prefix internal-only helpers
   with `_`.
8. `lucky.sh enable <modname>`, open a new shell, and confirm:
   - Silent at the default `LUCKY_VERBOSITY=2`.
   - `LUCKY_VERBOSITY=4 bash -i` shows your `debug` line with the
     correct namespace.
   - Shell still starts cleanly on a host without your tool installed.
