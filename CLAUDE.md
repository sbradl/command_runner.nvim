# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`command_runner.nvim` is a Neovim plugin (Lua) that presents a filtered list of runnable commands based on the current buffer's file extension and executes the chosen one, either in a terminal or as a Neovim command.

## Commands

Run the test suite (this is exactly what CI runs):

```sh
nvim --headless --noplugin -u scripts/minimal_init.vim \
  -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"
```

Tests use [plenary.nvim](https://github.com/nvim-lua/plenary.nvim), which must be checked out at `../plenary.nvim` (a sibling of this repo) so `scripts/minimal_init.vim` can find it on the runtimepath. Specs live in `tests/**/*_spec.lua`.

**Always forward `scripts/minimal_init.vim` as plenary's `minimal_init`** (the `{ minimal_init = './scripts/minimal_init.vim' }` argument above). `minimal_init.vim` is the single source of test setup: it puts plenary on the runtimepath and adds `tests/` to `package.path` so shared helpers in `tests/test_util.lua` are requirable. Each spec runs in a fresh child nvim, and plenary only passes `minimal_init` down when it is given one — so a bare `PlenaryBustedDirectory tests/` (no `minimal_init`) spawns children without that setup, and specs that `require("test_util")` (the `builtin/*` ones) error out and get *silently* dropped from the aggregate output. For an editor test runner (e.g. neotest-plenary), point its `minimal_init` at `scripts/minimal_init.vim` for the same reason.

Specs run headless with no terminal available, so they mock at the boundaries: `require("terminal")` is preloaded into `package.loaded` before requiring `command_runner.commands`; filesystem-dependent helpers are exercised against real temp trees built with `vim.fn.tempname()` + `vim.fn.mkdir`; and `vim.ui.select` / `vim.defer_fn` are replaced to drive selection and run the deferred terminal write synchronously.

## Architecture

The flow is: `setup()` registers commands into a keyed table → `run_command()` filters by the current buffer's extension → `vim.ui.select` prompts the user → the chosen command is dispatched.

- **`lua/command_runner.lua`** — public API and the command registry (the module entry point; the sibling `lua/command_runner/` directory holds its internals). `M._commands` is a table keyed by file extension (e.g. `"ts"`, `"cs"`) or the special key `":directory"` (used when the buffer has no extension). `setup()` populates it from three sources, in order: enabled builtins, `opts.commands`, then a project-local `.nvim/command_runner.lua` file discovered via `vim.fs.root(0, ".nvim")`. The project-local file is `loadfile`'d and must return a table of the same `{ ext = CommandDescription[] }` shape.
- **`lua/command_runner/commands.lua`** — dispatch. `choose_and_run_command` computes the extension (`":directory"` when empty), applies each command's optional `filter(filename)`, shows the labels via `vim.ui.select`, then calls the selected command's `cmd(filename, bufnr)` to build a `Command`. Type `"terminal"` (default) opens a terminal in `command.dir` and sends `command_line`; type `"nvim"` runs `command_line` via `vim.cmd`.
- **`lua/command_runner/types.lua`** — `---@meta` LuaCATS annotations only (`CommandRunnerOpts`, `CommandDescription`, `Command`, etc.). No runtime code; keep it in sync when changing the config schema.
- **`lua/command_runner/util.lua`** — small shared helpers (e.g. `get_git_dir` via `vim.fs.root`).
- **`lua/command_runner/builtin/*.lua`** — one module per ecosystem (`ts_vitest`, `ts_playwright`, `cs_dotnet_test`, `lua_plenary`, `ex_mix`, `ex_phoenix`). Each exports `M.commands` plus `M.extensions` (the file extensions those commands register under), and optionally `M.directory_commands` (registered under `":directory"`). `register_builtin_commands` discovers these modules by scanning the `builtin/` directory (resolved relative to the source file, not the runtimepath) and sorting by filename, so the module basename is the builtin's key. Builtins are opt-out: each is enabled unless its key appears in `opts.builtin.disable` (or `opts.builtin == false` disables all).

Internal modules are required by their full path (`require("command_runner.<name>")`) to avoid polluting the global module namespace — plain `require("commands")`/`require("util")` would collide with other plugins.

### Key conventions

- A `CommandDescription` is `{ label, filter?, cmd }`. `filter(filename)` gates availability (typically "am I inside a project of this type?" via `vim.fs.root` for a marker file). `cmd(filename, bufnr)` is called only after selection and returns the concrete `{ dir?, type?, command_line }`.
- Builtin modules conventionally expose a `get_project_dir(filename)` helper that locates the relevant root by marker file (`mix.exs`, `playwright.config.ts`, `*.sln`/`*.csproj`, `package.json`, etc.), used both by `filter` and to set the terminal `dir`.
- The `"terminal"` executor depends on an external `terminal` module (`require("terminal")`, i.e. terminal.nvim) — it is a runtime dependency, not vendored in this repo.
- Debug tracing is done with `vim.notify(..., vim.log.levels.DEBUG)` throughout registration.

## Adding a builtin

1. Create `lua/command_runner/builtin/<name>.lua` exporting `M.commands` and `M.extensions` (and `M.directory_commands` if it registers under `":directory"`). The filename becomes the builtin's key (used in `opts.builtin.disable`).

That's it — `register_builtin_commands` discovers the module automatically by scanning the `builtin/` directory, so there is no registry to wire into and no type to update.