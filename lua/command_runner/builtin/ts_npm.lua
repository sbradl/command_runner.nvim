local U = require("command_runner.util")

local M = {}

M.extensions = { "ts" }

M.get_project_dir = function(filename)
	return U.find_root(filename, "package.json")
end

local function is_npm_project(filename)
	return M.get_project_dir(filename) ~= nil
end

---@type CommandDescription[]
M.commands = {
	{
		label = "edit package.json",
		filter = is_npm_project,
		cmd = function(filename, _)
			return U.edit_file(M.get_project_dir(filename) .. "/package.json")
		end,
	},
}

return M
