local M = {}

local t = require("terminal")

local line_ending = vim.fn.has("win32") == 1 and "\r" or "\n"

M.open_terminal_and_run_command = function(command, opts)
	local command_line = command.command_line

	if opts.autoclose_on_success then
		local delay = opts.autoclose_delay_in_seconds
		command_line = command_line .. (delay > 0 and (" && sleep " .. delay .. " && exit") or " && exit")
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

		local selected_cmd = nil
		for _, choice in ipairs(choices) do
			if choice.label == selected_label then
				selected_cmd = choice.cmd
				break
			end
		end

		if selected_cmd and type(selected_cmd) == "function" then
			local command_description = selected_cmd(name, buf)
			local command_type = command_description.type or "terminal"

			if command_type == "terminal" then
				M.open_terminal_and_run_command(command_description, opts)
			elseif command_type == "nvim" then
				vim.cmd(command_description.command_line)
			end
		end
	end)
end

return M
