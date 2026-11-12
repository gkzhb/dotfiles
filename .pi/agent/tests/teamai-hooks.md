# Pi TeamAI hooks

`../extensions/teamai-hooks.ts` is a user-managed adaptation of TeamAI's generated extension.
It deliberately omits the generated ownership marker while retaining the original filename.
The installed CLI's `injectPiHooks` preserves files without that marker (with a skip warning),
so sync cannot silently restore hard-coded paths or install a second bridge.
Do not add the generator marker back. Review protocol changes manually on TeamAI updates.
Automatic TeamAI removal also leaves this user-managed file in place; without the CLI it is inert.

## Optional loading

- The factory searches Pi's process `PATH` for an executable regular file named `teamai`.
- Missing CLI, empty/unset `PATH`, non-executable files, directories and broken symlinks result in no event handlers, processes or timers being registered/started.
- The first valid `PATH` entry wins. Executable symlinks are supported; relative entries resolve at extension load, before child processes switch to the project's working directory.
- The resolved CLI is invoked directly with argv and `shell: false`. Its launcher/shebang chooses the runtime; there is no hard-coded Node or CLI installation path.
- Team hook metadata is read from `~/.teamai/team-hooks/pi.json`, using the current user's home directory.
- Lookup is once per extension load. Install/remove the CLI or update Pi's `PATH`, then `/reload` (or restart Pi if its process environment needs updating).
- A CLI disappearing or failing to start after lookup retains the original fail-open behavior. Hook dispatch retains the existing timeouts and payloads.

The filesystem check establishes executable availability, not CLI version compatibility or the availability of a shebang's interpreter. Those execution errors are handled by the existing dispatch fallback.

## Regression tests

```sh
node --test dotfiles/.pi/agent/tests/test-teamai-hooks.mjs
```

Run from the outer nix-config repository (or omit `dotfiles/` from the dotfiles repository).
Tests execute the real extension source with temporary PATH/HOME and mocked child processes.
They never call the real TeamAI CLI, dispatch team hooks, or modify user configuration.
