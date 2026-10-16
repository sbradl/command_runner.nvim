local U = require("command_runner.util")
local dotnet = require("command_runner.util.dotnet")

local M = {}

-- mise projects are polyglot, so its tasks are offered for every buffer that
-- lives inside a mise project, not one file extension.
M.extensions = { "*" }

-- ".mise" covers projects whose only tasks were copied into .mise/conf.d by install_tasks.
local mise_markers = { "mise.toml", ".mise.toml", "mise.local.toml", ".mise.local.toml", ".mise" }

M.get_project_dir = function(filename)
	return U.find_root(filename, mise_markers)
end

local function is_mise_project(filename)
	return M.get_project_dir(filename) ~= nil
end

--- Ask the mise CLI for the project's tasks. Shelling out (rather than parsing
--- mise.toml ourselves) picks up every task source mise knows about — inline
--- toml tasks, file tasks, includes — and always matches `mise run`'s own view.
---
---@param dir string The mise project root, used as the CLI's working directory.
---@return { name: string, description: string?, usage: string, dir: string? }[] tasks, empty when mise is missing or reports an error.
local function list_tasks(dir)
	local ok, res = pcall(function()
		return vim.system({ "mise", "tasks", "ls", "--json" }, { cwd = dir, text = true }):wait()
	end)

	if not ok or res.code ~= 0 or not res.stdout or res.stdout == "" then
		return {}
	end

	local decoded, parsed = pcall(vim.json.decode, res.stdout)
	if not decoded or type(parsed) ~= "table" then
		return {}
	end

	local tasks = {}
	for _, task in ipairs(parsed) do
		if type(task) == "table" and type(task.name) == "string" then
			table.insert(tasks, {
				name = task.name,
				description = type(task.description) == "string" and task.description or nil,
				usage = type(task.usage) == "string" and task.usage or "",
				dir = type(task.dir) == "string" and task.dir or nil,
			})
		end
	end
	return tasks
end

---@class MiseArgContext
---@field filename string Absolute path of the current buffer.
---@field bufnr integer
---@field line integer Cursor line (1-based).
---@field dir string The task's working directory; paths are passed relative to it.

--- Values for task usage args and flags, keyed by arg/flag name. A task opts
--- in by declaring e.g. `arg "<file>"`; the value is passed on `mise run`.
--- Returning nil (or erroring) leaves the arg out. Flags are passed when the
--- provider returns true.
---@type table<string, fun(ctx: MiseArgContext): string|boolean|nil>
local test_attributes = { "TestClass", "TestMethod", "TestFixture", "Test", "TestCase", "Fact", "Theory" }

--- A C# buffer declaring an MSTest/NUnit/xUnit test attribute.
local function is_dotnet_test_file(ctx)
	if vim.fs.ext(ctx.filename) ~= "cs" then
		return false
	end
	for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)) do
		for _, attr in ipairs(test_attributes) do
			if line:find("%[%s*" .. attr .. "%f[^%w_]") then
				return true
			end
		end
	end
	return false
end

M.providers = {
	file = function(ctx)
		if ctx.filename == "" then
			return nil
		end
		return vim.fs.relpath(ctx.dir, ctx.filename) or ctx.filename
	end,
	line = function(ctx)
		return tostring(ctx.line)
	end,
	-- "./"-prefixed so tools like `go run` treat it as a path, not an import path.
	dir = function(ctx)
		local rel = vim.fs.relpath(ctx.dir, vim.fs.dirname(ctx.filename))
		return (rel == nil or rel == ".") and "." or "./" .. rel
	end,
	-- Only in C# test files, so dotnet test tasks requiring them are hidden elsewhere.
	test_class = function(ctx)
		return is_dotnet_test_file(ctx) and dotnet.get_class(ctx.bufnr) or nil
	end,
	test_method = function(ctx)
		return is_dotnet_test_file(ctx) and dotnet.get_method(ctx.bufnr, ctx.line) or nil
	end,
	test_namespace = function(ctx)
		return is_dotnet_test_file(ctx) and dotnet.get_namespace(ctx.bufnr) or nil
	end,
	project = function(ctx)
		local abs = dotnet.get_project_file_abs(ctx.filename)
		return vim.fs.relpath(ctx.dir, abs) or abs
	end,
	mtp = function(ctx)
		return dotnet.uses_mtp(ctx.filename)
	end,
}

---@return string|boolean|nil
local function provide(name, ctx)
	local provider = M.providers[name]
	if not provider then
		return nil
	end
	local ok, value = pcall(provider, ctx)
	return ok and value or nil
end

--- Whether every required `arg "<name>"` in a task's usage spec that has a
--- provider gets a value for this buffer. Args without a provider don't gate
--- (mise reports them when run). Script tasks report an empty usage in
--- `mise tasks ls`, so they are always offered.
---@param usage string
---@param ctx MiseArgContext
local function is_available(usage, ctx)
	for name in usage:gmatch('arg%s+"<([^>]+)>') do
		if M.providers[name] and type(provide(name, ctx)) ~= "string" then
			return false
		end
	end
	return true
end

--- The task's usage spec (args/flags) from `mise tasks info`.
---@return { args: table[], flags: table[] }
local function task_info(dir, name)
	local ok, res = pcall(function()
		return vim.system({ "mise", "tasks", "info", name, "--json" }, { cwd = dir, text = true }):wait()
	end)
	local decoded, info = false, nil
	if ok and res.code == 0 and res.stdout then
		decoded, info = pcall(vim.json.decode, res.stdout)
	end
	if not decoded or type(info) ~= "table" then
		return { args = {}, flags = {} }
	end
	local cmd = vim.tbl_get(info, "usage_spec", "cmd") or {}
	return { args = cmd.args or {}, flags = cmd.flags or {} }
end

--- `mise run <name>` plus the flags and positional args the providers can fill.
--- Stops at the first arg without a value, since later positionals would shift.
local function build_command_line(name, info, ctx)
	local parts = { "mise run " .. name }
	for _, flag in ipairs(info.flags) do
		if provide(flag.name, ctx) == true then
			table.insert(parts, "--" .. flag.name)
		end
	end
	for _, arg in ipairs(info.args) do
		local value = provide(arg.name, ctx)
		if type(value) ~= "string" then
			break
		end
		table.insert(parts, vim.fn.shellescape(value))
	end
	return table.concat(parts, " ")
end

local max_description_length = 60

--- First line of the description, truncated so long ones don't swamp the picker.
---@param description string?
---@return string? nil when there is nothing to show.
local function format_description(description)
	local line = vim.trim(vim.split(description or "", "\n")[1])
	if line == "" then
		return nil
	end
	if vim.fn.strchars(line) > max_description_length then
		line = vim.fn.strcharpart(line, 0, max_description_length - 1) .. "…"
	end
	return line
end

---@type CommandDescription[]
M.commands = {
	{
		label = "mise run", -- placeholder; the expanded entries carry the real labels
		filter = is_mise_project,
		expand = function(filename, bufnr)
			local dir = M.get_project_dir(filename)
			local line = vim.api.nvim_win_get_cursor(0)[1]

			local descriptions = {}
			for _, task in ipairs(list_tasks(dir)) do
				local name = task.name
				local ctx = { filename = filename, bufnr = bufnr or 0, line = line, dir = task.dir or dir }
				if is_available(task.usage, ctx) then
					local description = format_description(task.description)
					table.insert(descriptions, {
						label = "mise run " .. name .. (description and " — " .. description or ""),
						cmd = function()
							return {
								dir = dir,
								command_line = build_command_line(name, task_info(dir, name), ctx),
							}
						end,
					})
				end
			end
			return descriptions
		end,
	},
}

return M
