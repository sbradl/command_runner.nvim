local M = {}

function M.find_command(commands, label)
	for _, cmd in ipairs(commands) do
		if cmd.label == label then
			return cmd
		end
	end

	error("no command with label " .. label)
end

return M
