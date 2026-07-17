local M = {}

M._commands = {}

M._opts = {
	autoclose_on_success = true,
	autoclose_delay_in_seconds = 3,
}

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

local builtin_dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/command_runner/builtin"

---@param disabled table<BuiltinCommands, boolean> Set of builtin keys to skip.
local function register_builtin_commands(disabled)
	local keys = {}
	for name, type in vim.fs.dir(builtin_dir) do
		if type == "file" then
			local key = name:match("^(.+)%.lua$")
			if key then
				table.insert(keys, key)
			end
		end
	end
	table.sort(keys)

	for _, key in ipairs(keys) do
		if not disabled[key] then
			local builtin = require("command_runner.builtin." .. key)

			if builtin.commands then
				for _, ext in ipairs(builtin.extensions) do
					M._register(ext, builtin.commands)
				end
			end

			if builtin.directory_commands then
				M._register(":directory", builtin.directory_commands)
			end
		end
	end
end

---
---@param opts CommandRunnerOpts
M.setup = function(opts)
	opts = opts or {}

	M._commands = {}

	M._opts = {
		autoclose_on_success = opts.autoclose_on_success ~= false,
		autoclose_delay_in_seconds = opts.autoclose_delay_in_seconds or 3,
	}

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
		local project_local_commands_file = project_local_nvim_config .. "/.nvim/command_runner.lua"

		if vim.fn.filereadable(project_local_commands_file) == 1 then
			vim.notify("Found project level command config", vim.log.levels.INFO)
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
	require("command_runner.commands").choose_and_run_command(M._commands, M._opts)
end

--- Rerun the last executed command without showing the picker.
M.rerun_command = function()
	require("command_runner.commands").rerun_command(M._opts)
end

return M
