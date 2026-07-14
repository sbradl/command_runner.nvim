local U = require("command_runner.util")

local M = {}

M.get_angular_dir = function(filename)
	return U.find_root(filename, { "angular.json" })
end

return M