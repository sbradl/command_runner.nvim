local U = require("command_runner.util")

local M = {}

M.extensions = { "ts" }

M.get_project_dir = function(filename)
	return U.find_root(filename, { "vitest.config.ts", "vitest.config.js", "package.json" })
end

---@type CommandDescription[]
M.commands = {
	{
		label = "vitest current file",
		cmd = function(filename)
			local project_dir = M.get_project_dir(filename)
			local relative_path = vim.fs.relpath(project_dir, filename)
			return {
				dir = project_dir,
				command_line = "npx vitest " .. relative_path,
			}
		end,
	},
	{
		label = "vitest all",
		cmd = function(filename)
			local project_dir = M.get_project_dir(filename)
			return {
				dir = project_dir,
				command_line = "npx vitest",
			}
		end,
	},
}

return M
