local M = {}

local t = require("terminal")

local is_win32 = vim.fn.has("win32") == 1
local line_ending = is_win32 and "\r" or "\n"

-- PowerShell's `exit` is only recognized at the start of a full statement;
-- after `&&` it's resolved as a command name lookup and fails ("exit is not
-- recognized..."). `[Environment]::Exit(0)` is an expression, so it's valid there.
local exit_command = is_win32 and "[Environment]::Exit(0)" or "exit"

M.open_terminal_and_run_command = function(command, opts)
	local command_line = command.command_line

	if opts.autoclose_on_success then
		local delay = opts.autoclose_delay_in_seconds
		command_line = command_line
			.. (delay > 0 and (" && sleep " .. delay .. " && " .. exit_command) or (" && " .. exit_command))
	end

	t.open_new_terminal(command.dir)
	local new_buf = vim.api.nvim_get_current_buf()
	vim.defer_fn(function()
		local chan_id = vim.b[new_buf].terminal_job_id
		if chan_id then
			vim.api.nvim_chan_send(chan_id, command_line .. line_ending)
		end
	end, 50)
end

local function execute(command, opts)
	local command_type = command.type or "terminal"

	if command_type == "terminal" then
		M.open_terminal_and_run_command(command, opts)
	elseif command_type == "nvim" then
		vim.cmd(command.command_line)
	end
end

M._history = {}

--- Inserts entry at the front of history, moving it there instead of
--- duplicating it if a matching entry (same label and resolved command)
--- already exists, and trims anything beyond max_size.
local function record_history(entry, max_size)
	for i, existing in ipairs(M._history) do
		if
			existing.label == entry.label
			and existing.command.dir == entry.command.dir
			and existing.command.type == entry.command.type
			and existing.command.command_line == entry.command.command_line
		then
			table.remove(M._history, i)
			break
		end
	end

	table.insert(M._history, 1, entry)

	while #M._history > max_size do
		table.remove(M._history)
	end
end

M.rerun_command = function(opts)
	if #M._history == 0 then
		vim.notify("command_runner: no command to rerun", vim.log.levels.WARN)
		return
	end

	execute(M._history[1].command, opts)
end

local function format_history_label(entry)
	if entry.command.dir then
		return entry.label .. " — " .. entry.command.dir
	end
	return entry.label
end

M.show_history = function(opts)
	if #M._history == 0 then
		return
	end

	local labels = {}
	for _, entry in ipairs(M._history) do
		table.insert(labels, format_history_label(entry))
	end

	vim.ui.select(labels, {
		prompt = "Command history",
	}, function(selected_label)
		if not selected_label then
			return
		end

		for _, entry in ipairs(M._history) do
			if format_history_label(entry) == selected_label then
				record_history(entry, opts.history_size)
				execute(entry.command, opts)
				break
			end
		end
	end)
end

M.choose_and_run_command = function(commands, opts)
	local buf = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(buf)
	local ext = vim.fn.fnamemodify(name, ":e")

	if ext == "" then
		ext = ":directory"
	end

	local choices = commands[ext] or {}

	local options = {}
	for _, choice in ipairs(choices) do
		if choice.filter == nil or choice.filter(name) then
			table.insert(options, choice.label)
		end
	end

	table.sort(options)

	vim.ui.select(options, {
		prompt = name,
	}, function(selected_label)
		if not selected_label then
			return
		end

		local selected_choice = nil
		for _, choice in ipairs(choices) do
			if choice.label == selected_label then
				selected_choice = choice
				break
			end
		end

		if selected_choice and type(selected_choice.cmd) == "function" then
			local command_description = selected_choice.cmd(name, buf)

			record_history({ label = selected_label, command = command_description }, opts.history_size)

			execute(command_description, opts)
		end
	end)
end

return M
