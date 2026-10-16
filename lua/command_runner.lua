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
		history_size = opts.history_size or 10,
	}

	if opts.builtin ~= false then
		local disabled = {}
		for _, key in ipairs((opts.builtin or {}).disable or {}) do
			disabled[key] = true
		end
		register_builtin_commands(disabled)
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

--- Open a checklist of mise task templates (detected ones pre-checked) and
--- copy the checked ones into the project's .mise/conf.d on `:w`.
M.install_tasks = function()
	require("command_runner.install").open_checklist()
end

--- Rerun the last executed command without showing the picker.
M.rerun_command = function()
	require("command_runner.commands").rerun_command(M._opts)
end

--- Describes what rerun_command would execute (nil when history is empty).
--- Intended for a dynamic which-key desc.
---@return string?
M.rerun_command_description = function()
	return require("command_runner.commands").rerun_command_description()
end

--- Show a picker of recently executed commands.
M.show_history = function()
	require("command_runner.commands").show_history(M._opts)
end

return M
