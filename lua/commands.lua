local M = {}

local t = require("terminal")
local default_commands = require("default_commands").commands

M.open_terminal_and_run_command = function(command)
	t.open_new_terminal(command.dir)
	local new_buf = vim.api.nvim_get_current_buf()
	vim.defer_fn(function()
		local chan_id = vim.b[new_buf].terminal_job_id
		if chan_id then
			vim.api.nvim_chan_send(chan_id, command.command_line .. "\n")
		end
	end, 50)
end

M.choose_and_run_command = function(commands)
	local buf = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(buf)
	local ext = vim.fn.fnamemodify(name, ":e")

	local choices = commands[ext] or default_commands

	local options = {}
	for _, choice in ipairs(choices) do
		if choice.filter == nil or choice.filter(name) then
			table.insert(options, choice.label)
		end
	end

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
			vim.notify("determining command type", vim.log.levels.INFO)
			local command_type = command_description.type or "terminal"
			vim.notify("command type: " .. command_type, vim.log.levels.INFO)

			if command_type == "terminal" then
				M.open_terminal_and_run_command(command_description)
			elseif command_type == "nvim" then
				vim.cmd(command_description.command_line)
			end
		end
	end)
end

return M
