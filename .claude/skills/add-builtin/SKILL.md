---
name: add-builtin
description: Add a new builtin command module to command_runner.nvim — module layout, naming, testdata, and spec conventions. Use whenever asked to add a builtin (e.g. "add a builtin for X") or to add commands for a new ecosystem/tool.
---

# Adding a builtin

A builtin is one Lua module per ecosystem/tool that contributes commands for
specific file extensions. It is discovered automatically by filename — there is
no registry to wire into and no type to update.

## 1. Create the module

Create `lua/command_runner/builtin/<ext>_<name>.lua`, where `<ext>` is the
primary file extension and `<name>` the tool (e.g. `ts_vitest`, `cs_dotnet`,
`ex_mix`). The basename (without `.lua`) becomes the builtin's key, used in
`opts.builtin.disable` — choose it carefully, it is public API.

Template:

```lua
local U = require("command_runner.util")

local M = {}

M.extensions = { "ts" } -- all extensions the commands register under

-- Locate the project root by marker file. Always use U.find_root (NOT
-- vim.fs.root directly): it stops at the repo (.git) root so a stray marker
-- in a parent directory outside the repo is never picked up.
M.get_project_dir = function(filename)
	return U.find_root(filename, { "some.config.ts", "package.json" })
end

local function is_my_project(filename)
	return M.get_project_dir(filename) ~= nil
end

---@type CommandDescription[]
M.commands = {
	{
		label = "tool do-thing", -- shown to the user in vim.ui.select
		filter = is_my_project, -- optional; omit if always applicable
		cmd = function(filename, bufnr)
			return {
				dir = M.get_project_dir(filename), -- terminal cwd
				command_line = "tool do-thing",
			}
		end,
	},
}

return M
```

Conventions:

- Internal requires always use the full path (`require("command_runner.util")`),
  never `require("util")`.
- Tabs for indentation (match the existing files).
- The returned table from `cmd` is a `Command` (see
  `lua/command_runner/types.lua`): `type` defaults to `"terminal"` (runs
  `command_line` in a terminal at `dir`); `type = "nvim"` runs `command_line`
  via `vim.cmd` instead.
- To open a file in the editor, return `U.edit_file(path)` — it builds the
  `{ type = "nvim", command_line = "edit <escaped path>" }` command for you.
- Commands that need a file path relative to the project use
  `vim.fs.relpath(project_dir, filename)` (see `ts_vitest`).
- Commands available in extension-less buffers (e.g. a directory/netrw buffer)
  go into `M.directory_commands` instead of `M.commands`; their `cmd` receives
  the directory as its first argument (see `ex_mix`'s `mix new`).
- Shared, non-trivial helpers for one ecosystem live in
  `lua/command_runner/util/<ecosystem>.lua` (see `util/dotnet.lua`,
  `util/angular.lua`); simple root-finding stays in the builtin module as
  `get_project_dir`.

Do not touch `lua/command_runner.lua` or the README's builtin section — both
discover/point at the `builtin/` directory automatically. Only update
`types.lua` if you change the config schema (a new builtin doesn't).

## 2. Create testdata

Specs run against real files checked into `tests/testdata/<name>/`:

- `tests/testdata/<name>/proj/` — a minimal fake project: the marker file
  (may be empty) plus one source file in a subdirectory, e.g.
  `proj/package.json` + `proj/src/a.ts`.
- `tests/testdata/<name>/bare/` — a lone source file with no marker, used to
  assert the `filter` rejects files outside a project. Only needed when the
  builtin has a `filter`. This works because `U.find_root` stops at *this*
  repo's root — so don't add a marker file (e.g. a `package.json`) anywhere
  between `bare/` and the repo root, or every `bare` test breaks.

## 3. Write the spec

Create `tests/builtin/<name>_spec.lua`. Follow the existing given/should
structure exactly (`elixir_mix_spec.lua` is the fullest example):

```lua
local mod = require("command_runner.builtin.<ext>_<name>")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/<name>"

describe("command_runner.builtin.<ext>_<name>", function()
	describe("'<label>' command", function()
		local cmd

		before_each(function()
			cmd = find_command(mod.commands, "<label>")
		end)

		describe("given a file inside a <tool> project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/src/a.ts"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build the command rooted at the project", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("<expected command_line>", out.command_line)
			end)
		end)

		describe("given a file outside any <tool> project", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(data .. "/bare/a.ts"))
			end)
		end)
	end)
end)
```

Cover: `get_project_dir` (if exported), each command's `cmd` output (`dir`,
`command_line`, and `type` when it isn't the terminal default), and the
`filter` in both the proj and bare cases. Commands in `directory_commands`
are found via `find_command(mod.directory_commands, ...)` and called with a
directory path directly — no testdata needed.

## 4. Run the tests

```sh
nvim --headless --noplugin -u scripts/minimal_init.vim \
  -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"
```

Never drop the `{ minimal_init = ... }` argument — without it, specs that
require `test_util` error out and are *silently* excluded from the results.
Confirm the new spec file actually appears in the output and that every file
reports `Failed : 0` and `Errors : 0` (the suite prints per-file summaries,
not one global one).