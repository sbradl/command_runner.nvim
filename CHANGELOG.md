# Changelog

## 2026-10-15

### Changed

- `mise` builtin: picker entries show the task description after the command
  (first line, truncated to 60 chars).

## 2026-10-03

### Removed

- **Breaking:** `opts.commands` and the project-local `.nvim/command_runner.lua`
  file. Define project-specific commands as [mise tasks](https://mise.jdx.dev/tasks/)
  in `mise.toml` instead.

## 2026-09-06

### Added

- `mise` builtin: lists every task from `mise tasks ls` in the picker for any
  buffer inside a mise project.

## 2026-08-30

### Added

- `go run` and `go build` builtin commands for go files.

## 2026-08-13

### Added

- `dotnet test` current project builtin command.

## 2026-08-06

### Fixed

- Directory commands (mix new, phx new) are only offered when relevant.
- Tests disable the swapfile to avoid CI-only failures.

## 2026-08-03

### Added

- `dotnet test` current method builtin command.

## 2026-07-23

### Added

- `docker_compose` builtin, triggered by the presence of a compose file.

## 2026-07-22

### Fixed

- Autoclose on Windows now deletes the terminal buffer itself.

### Changed

- History shows directories relative to the git root, otherwise relative to cwd.

## 2026-07-21

### Added

- Command history picker (`show_history`), replacing the "Rerun" picker entry.
- `rerun_command_description` for a dynamic which-key description.

### Changed

- History labels show the real command line.
- Plenary builtin commands use cwd-relative paths.

### Fixed

- Windows PowerShell 7 autoclose uses `[Environment]::Exit(0)`.

## 2026-07-17

### Added

- `rerun_command`, bindable to a keymap.
- Execute script builtin for `sh` and `ps1` files.
- `dotnet test` solution builtin command.

## 2026-07-15

### Added

- Autoclose terminal after a successful command
  (`autoclose_on_success`, `autoclose_delay_in_seconds`).
- Plenary test current file builtin command.

### Fixed

- Commands are executed immediately on Windows (`\r\n` line ending).

## 2026-07-14

### Added

- `dotnet`: open solution file and open project file; test current class and
  namespace scoped to the project with `--no-restore`.
- Angular `npm run build` and `edit package.json` builtins.

### Changed

- Commands are sorted alphabetically in the picker.
- Root lookup no longer escapes the git repository root.

## 2026-07-11

### Added

- Disable all builtins at once with `builtin = false`.
- Test suite and CI status badge.

### Changed

- Builtins declare their own file extensions and are prefixed by ecosystem
  (e.g. `ts_vitest`).

## 2026-07-10

### Added

- Initial release: `run_command` picks a command by the current file's
  extension and runs it in a terminal or as a Neovim command.
- Builtins: vitest, Playwright, dotnet test, Plenary, Elixir mix and Phoenix.
- `:directory` commands for buffers without an extension.
- Project-local `.nvim/command_runner.lua` and `opts.commands`.
- Builtins can be disabled individually via `builtin.disable`.
- GitHub Actions workflow.
