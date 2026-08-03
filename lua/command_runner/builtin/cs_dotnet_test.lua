local dotnet = require("command_runner.util.dotnet")

local M = {}

M.extensions = { "cs" }

---@type CommandDescription[]
M.commands = {
	{
		label = "dotnet test current class",
		cmd = function(filename, buf)
			local project_file = dotnet.get_project_file(filename)

			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test --no-restore --filter ClassName~"
					.. dotnet.get_class(buf)
					.. " "
					.. project_file,
			}
		end,
	},
	{
		label = "dotnet test current method",
		cmd = function(filename, buf)
			local project_file = dotnet.get_project_file(filename)
			local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test --no-restore --filter FullyQualifiedName~"
					.. dotnet.get_class(buf)
					.. "."
					.. dotnet.get_method(buf, cursor_line)
					.. " "
					.. project_file,
			}
		end,
	},
	{
		label = "dotnet test current namespace",
		cmd = function(filename, buf)
			local project_file = dotnet.get_project_file(filename)

			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test --no-restore --filter FullyQualifiedName~"
					.. dotnet.get_namespace(buf)
					.. " "
					.. project_file,
			}
		end,
	},
	{
		label = "dotnet test solution",
		cmd = function(filename, _)
			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test --no-restore",
			}
		end,
	},
}

return M
