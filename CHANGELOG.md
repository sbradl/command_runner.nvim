# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added

- `mise` builtin: lists every task from `mise tasks ls` in the picker.
- `go run` and `go build` builtin commands for go files.
- `dotnet test` current project builtin command.
- Command history (`show_history`), `rerun_command` and
  `rerun_command_description`.

### Removed

- **Breaking:** `opts.commands` and the project-local `.nvim/command_runner.lua`
  file. Define project-specific commands as [mise tasks](https://mise.jdx.dev/tasks/)
  in `mise.toml` instead.
