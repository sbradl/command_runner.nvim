local M = {}

M._commands = {}

---@param ext string
---@param command_list CommandDescription[]
local function register(ext, command_list)
	if not M._commands[ext] then
		M._commands[ext] = {}
	end

	vim.notify("registering commands for " .. ext, vim.log.levels.DEBUG)
	for _, cmd in ipairs(command_list) do
		vim.notify("registering command " .. cmd.label, vim.log.levels.DEBUG)
		table.insert(M._commands[ext], cmd)
	end
end

---@param opts table<BuiltinCommands, BuiltinCommandOpts>
local function register_builtin_commands(opts)
	if opts.ts_vitest == nil or opts.ts_vitest.enable then
		vim.notify("enable ts_vitest", vim.log.levels.DEBUG)
		register("ts", require("builtin.vitest").commands)
	end

	if opts.ts_playwright == nil or opts.ts_playwright.enable then
		vim.notify("enable ts_playwright", vim.log.levels.DEBUG)
		register("ts", require("builtin.playwright").commands)
	end

	if opts.cs_dotnet_test == nil or opts.cs_dotnet_test.enable then
		vim.notify("enable cs_dotnet_test", vim.log.levels.DEBUG)
		register("cs", require("builtin.dotnet_test").commands)
	end

	if opts.lua_plenary == nil or opts.lua_plenary.enable then
		vim.notify("enable lua_plenary", vim.log.levels.DEBUG)
		register("lua", require("builtin.lua_plenary").commands)
	end

	if opts.elixir_mix == nil or opts.elixir_mix.enable then
		vim.notify("enable elixir_mix", vim.log.levels.DEBUG)
		local elixir = require("builtin.elixir_mix")
		register(":directory", elixir.directory_commands)
		register("ex", elixir.commands)
		register("exs", elixir.commands)
	end

	if opts.elixir_phoenix == nil or opts.elixir_phoenix.enable then
		vim.notify("enable elixir_phoenix", vim.log.levels.DEBUG)
		local elixir_phoenix = require("builtin.elixir_phoenix")
		register(":directory", elixir_phoenix.directory_commands)
		register("ex", elixir_phoenix.commands)
		register("exs", elixir_phoenix.commands)
	end
end

---
---@param opts CommandRunnerOpts
M.setup = function(opts)
	opts = opts or {}
	register_builtin_commands(opts.builtin or {})

	if opts.commands then
		for ext, command_list in pairs(opts.commands) do
			M.register(ext, command_list)
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
			if chunk then
				local project_local_commands = chunk()

				if type(project_local_commands) == "table" then
					for ext, command_list in pairs(project_local_commands) do
						M.register(ext, command_list)
					end
				end
			else
				vim.notify("Error loading project local commands: " .. tostring(err), vim.log.levels.ERROR)
			end
		end
	end
end

M.run_command = function()
	require("commands").choose_and_run_command(M._commands)
end

return M
