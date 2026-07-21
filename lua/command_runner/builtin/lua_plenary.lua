local M = {}

M.extensions = { "lua" }

local U = require("command_runner.util")

M.get_project_dir = function(filename)
	return U.get_git_dir(filename)
end

local function is_spec_file(filename)
	return filename:match("_spec%.lua$") ~= nil
end

-- :Plenary{BustedFile,BustedDirectory} resolve relative paths against
-- Neovim's cwd (they're run via vim.cmd, not in a shell in `dir`), so
-- shorten against cwd rather than the project root to keep labels short.
local function relative_to_cwd(path)
	return vim.fs.relpath(vim.fn.getcwd(), path) or path
end

---@type CommandDescription[]
M.commands = {
	{
		label = "Plenary test all",
		cmd = function(filename)
			return {
				type = "nvim",
				command_line = "PlenaryBustedDirectory " .. relative_to_cwd(M.get_project_dir(filename)),
			}
		end,
	},
	{
		label = "Plenary test file",
		filter = is_spec_file,
		cmd = function(filename)
			return {
				type = "nvim",
				command_line = "PlenaryBustedFile " .. relative_to_cwd(filename),
			}
		end,
	},
}

return M
