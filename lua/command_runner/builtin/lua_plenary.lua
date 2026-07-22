local M = {}

M.extensions = { "lua" }

local U = require("command_runner.util")

M.get_project_dir = function(filename)
	return U.get_git_dir(filename)
end

local function is_spec_file(filename)
	return filename:match("_spec%.lua$") ~= nil
end

---@type CommandDescription[]
M.commands = {
	{
		label = "Plenary test all",
		cmd = function(filename)
			return {
				type = "nvim",
				command_line = "PlenaryBustedDirectory " .. U.relative_to_cwd(M.get_project_dir(filename)),
			}
		end,
	},
	{
		label = "Plenary test file",
		filter = is_spec_file,
		cmd = function(filename)
			return {
				type = "nvim",
				command_line = "PlenaryBustedFile " .. U.relative_to_cwd(filename),
			}
		end,
	},
}

return M
