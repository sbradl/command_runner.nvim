local M = {}

M._commands = {}

---@param ext string
---@param command_list CommandDescription[]
M._register = function(ext, command_list)
	if not M._commands[ext] then
		M._commands[ext] = {}
	end

	for _, cmd in ipairs(command_list) do
		table.insert(M._commands[ext], cmd)
	end
end

---@param disabled table<BuiltinCommands, boolean> Set of builtin keys to skip.
local function register_builtin_commands(disabled)
	if not disabled.ts_vitest then
		vim.notify("enable ts_vitest", vim.log.levels.DEBUG)
		M._register("ts", require("command_runner.builtin.vitest").commands)
	end

	if not disabled.ts_playwright then
		vim.notify("enable ts_playwright", vim.log.levels.DEBUG)
		M._register("ts", require("command_runner.builtin.playwright").commands)
	end

	if not disabled.cs_dotnet_test then
		vim.notify("enable cs_dotnet_test", vim.log.levels.DEBUG)
		M._register("cs", require("command_runner.builtin.dotnet_test").commands)
	end

	if not disabled.lua_plenary then
		vim.notify("enable lua_plenary", vim.log.levels.DEBUG)
		M._register("lua", require("command_runner.builtin.lua_plenary").commands)
	end

	if not disabled.elixir_mix then
		vim.notify("enable elixir_mix", vim.log.levels.DEBUG)
		local elixir = require("command_runner.builtin.elixir_mix")
		M._register(":directory", elixir.directory_commands)
		M._register("ex", elixir.commands)
		M._register("exs", elixir.commands)
	end

	if not disabled.elixir_phoenix then
		vim.notify("enable elixir_phoenix", vim.log.levels.DEBUG)
		local elixir_phoenix = require("command_runner.builtin.elixir_phoenix")
		M._register(":directory", elixir_phoenix.directory_commands)
		M._register("ex", elixir_phoenix.commands)
		M._register("exs", elixir_phoenix.commands)
	end
end

---
---@param opts CommandRunnerOpts
M.setup = function(opts)
	opts = opts or {}

	M._commands = {}

	-- `builtin = false` disables every builtin at once; otherwise builtins are
	-- opt-out via `builtin.disable`, a list of the keys to skip.
	if opts.builtin ~= false then
		local disabled = {}
		for _, key in ipairs((opts.builtin or {}).disable or {}) do
			disabled[key] = true
		end
		register_builtin_commands(disabled)
	end

	if opts.commands then
		for ext, command_list in pairs(opts.commands) do
			M._register(ext, command_list)
		end
	end

	local project_local_nvim_config = vim.fs.root(0, ".nvim")

	if project_local_nvim_config then
		vim.notify("Found project level nvim config", vim.log.levels.DEBUG)
		local project_local_commands_file = project_local_nvim_config .. "/.nvim/command_runner.lua"
		vim.notify("Searching " .. project_local_commands_file, vim.log.levels.DEBUG)

		if vim.fn.filereadable(project_local_commands_file) == 1 then
			vim.notify("Found project level command config", vim.log.levels.DEBUG)
			local chunk, err = loadfile(project_local_commands_file)
			if not chunk then
				vim.notify(
					"command_runner: failed to load " .. project_local_commands_file .. ": " .. tostring(err),
					vim.log.levels.ERROR
				)
				return
			end

			local project_local_commands = chunk()

			if type(project_local_commands) ~= "table" then
				vim.notify(
					("command_runner: %s must return a table, got %s"):format(
						project_local_commands_file,
						type(project_local_commands)
					),
					vim.log.levels.ERROR
				)
				return
			end

			for ext, command_list in pairs(project_local_commands) do
				M._register(ext, command_list)
			end
		end
	end
end

---@param ext? string
---@return CommandDescription[] | table<string, CommandDescription[]>
M.get_commands = function(ext)
	if ext == nil then
		return M._commands
	end

	return M._commands[ext] or {}
end

M.run_command = function()
	require("command_runner.commands").choose_and_run_command(M._commands)
end

return M
