local dotnet = require("command_runner.util.dotnet")
local util = require("command_runner.util")

local M = {}

M.extensions = { "cs" }

---@type CommandDescription[]
M.commands = {
	{
		label = "open solution file",
		cmd = function(filename, _)
			return util.edit_file(dotnet.get_solution_file(filename))
		end,
	},
	{
		label = "open project file",
		cmd = function(filename, _)
			return util.edit_file(dotnet.get_project_file_abs(filename))
		end,
	},
}

return M
