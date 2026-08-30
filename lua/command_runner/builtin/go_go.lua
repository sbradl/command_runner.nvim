local U = require("command_runner.util")

local M = {}

M.extensions = { "go" }

M.get_project_dir = function(filename)
	return U.find_root(filename, { "go.mod" })
end

local function is_go_project(filename)
	return M.get_project_dir(filename) ~= nil
end

--- The package spec (relative to the module root) for the directory holding
--- `filename`, e.g. "./cmd/app", or "." when the file sits at the module root.
local function package_spec(project_dir, filename)
	local rel = vim.fs.relpath(project_dir, vim.fs.dirname(filename))
	if rel == nil or rel == "." then
		return "."
	end
	return "./" .. rel
end

---@type CommandDescription[]
M.commands = {
	{
		label = "go run current package",
		filter = is_go_project,
		cmd = function(filename)
			local project_dir = M.get_project_dir(filename)
			return {
				dir = project_dir,
				command_line = "go run " .. package_spec(project_dir, filename),
			}
		end,
	},
	{
		label = "go build",
		filter = is_go_project,
		cmd = function(filename)
			return {
				dir = M.get_project_dir(filename),
				command_line = "go build ./...",
			}
		end,
	},
}

return M
