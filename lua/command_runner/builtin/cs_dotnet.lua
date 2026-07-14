local dotnet = require("command_runner.util.dotnet")

local M = {}

M.extensions = { "cs" }

---@type CommandDescription[]
M.commands = {
	{
		label = "open solution file",
		cmd = function(filename, _)
			return {
				type = "nvim",
				command_line = "edit " .. vim.fn.fnameescape(dotnet.get_solution_file(filename)),
			}
		end,
	},
	{
		label = "open project file",
		cmd = function(filename, _)
			return {
				type = "nvim",
				command_line = "edit " .. vim.fn.fnameescape(dotnet.get_project_file_abs(filename)),
			}
		end,
	},
}

return M
