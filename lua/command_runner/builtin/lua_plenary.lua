local M = {}

local U = require("command_runner.util")

M.get_project_dir = function(filename)
	return U.get_git_dir(filename)
end

---@type CommandDescription[]
M.commands = {
	{
		label = "Plenary test all",
		cmd = function(filename)
			return {
				type = "nvim",
				command_line = "PlenaryBustedDirectory " .. M.get_project_dir(filename),
			}
		end,
	},
}

return M
