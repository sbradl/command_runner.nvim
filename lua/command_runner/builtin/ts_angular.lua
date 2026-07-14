local angular = require("command_runner.util.angular")

local M = {}

M.extensions = { "ts" }

---@type CommandDescription[]
M.commands = {
	{
		label = "npm run build",
		cmd = function(filename)
			return {
				dir = angular.get_angular_dir(filename),
				command_line = "npm run build",
			}
		end,
	},
}

return M