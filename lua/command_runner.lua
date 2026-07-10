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
		table.insert(M._filetype_commands[ext], cmd)
	end
end

local function register_builtin_commands()
	register(":directory", require("default_commands").directory_commands)
	register("ts", require("vitest").commands)
	register("ts", require("playwright").commands)
	register("cs", require("dotnet_test").commands)
	register("lua", require("lua_plenary").commands)

	local elixir = require("elixir_mix")
	local elixir_phoenix = require("elixir_phoenix")
	register(":directory", elixir.directory_commands)
	register(":directory", elixir_phoenix.directory_commands)
	register("ex", elixir.commands)
	register("exs", elixir.commands)
	register("ex", elixir_phoenix.commands)
	register("exs", elixir_phoenix.commands)
end

---
---@param opts CommandRunnerOpts
M.setup = function(opts)
	opts = opts or {}
	register_builtin_commands()

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
	require("commands").choose_and_run_command(M._filetype_commands)
end

return M
