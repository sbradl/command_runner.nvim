local U = require("command_runner.util")

local M = {}

M.extensions = { "ex", "exs" }

M.get_project_dir = function(filename)
	return U.find_root(filename, { "mix.exs" })
end

local function is_elixir_project(filename)
	return M.get_project_dir(filename) ~= nil
end

M.directory_commands = {
	{
		label = "mix new",
		filter = function(filename)
			return not is_elixir_project(filename)
		end,
		cmd = function(filename)
			return {
				dir = vim.fn.fnamemodify(filename, ":p:h"),
				command_line = "mix new .",
			}
		end,
	},
}

---@type CommandDescription[]
M.commands = {
	{
		label = "mix compile",
		filter = is_elixir_project,
		cmd = function(filename)
			return {
				dir = M.get_project_dir(filename),
				command_line = "mix compile",
			}
		end,
	},
	{
		label = "mix test",
		filter = is_elixir_project,
		cmd = function(filename)
			return {
				dir = M.get_project_dir(filename),
				command_line = "mix test",
			}
		end,
	},
	{
		label = "mix release",
		filter = is_elixir_project,
		cmd = function(filename)
			return {
				dir = M.get_project_dir(filename),
				command_line = "mix release",
			}
		end,
	},
}

return M
