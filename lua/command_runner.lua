local M = {}

local c = require("commands")

M._filetype_commands = {}

M.register = function(ext, command_list)
	if not M._filetype_commands[ext] then
		M._filetype_commands[ext] = {}
	end

	for _, cmd in ipairs(command_list) do
		table.insert(M._filetype_commands[ext], cmd)
	end
end

M.register("ts", require("vitest").commands)
M.register("ts", require("playwright").commands)
M.register("cs", require("dotnet_test").commands)
M.register("lua", require("lua_plenary").commands)

M.setup = function(opts)
	opts = opts or {}

	if opts.commands then
		for ext, command_list in pairs(opts.commands) do
			M.register(ext, command_list)
		end
	end

	local project_local_nvim_config = vim.fs.root(0, ".nvim")

	if project_local_nvim_config then
		vim.notify("Found project level nvim config", vim.log.levels.INFO)
		local project_local_commands_file = project_local_nvim_config .. "/.nvim/command_runner.lua"
		vim.notify("Searching " .. project_local_commands_file, vim.log.levels.INFO)

		if vim.fn.filereadable(project_local_commands_file) == 1 then
			vim.notify("Found project level command config", vim.log.levels.INFO)
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
	c.choose_and_run_command(M._filetype_commands)
end

return M
