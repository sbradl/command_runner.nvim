local M = {}

local U = require("util")

M.get_project_dir = function(filename)
	return U.get_git_dir(filename)
end

M.commands = {
	{
		label = "Plenary test all",
		type = "nvim",
		cmd = function(filename)
			return {
				command_line = "PlenaryBustedDirectory " .. M.get_project_dir(filename),
			}
		end,
	},
}

return M
