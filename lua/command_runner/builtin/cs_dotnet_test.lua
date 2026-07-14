local dotnet = require("command_runner.util.dotnet")

local M = {}

M.extensions = { "cs" }

---@type CommandDescription[]
M.commands = {
	{
		label = "dotnet test current file",
		cmd = function(filename)
			local project_file = dotnet.get_project_file(filename)

			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test --no-restore --filter ClassName~"
					.. vim.fn.fnamemodify(filename, ":t:r")
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
				command_line = "dotnet test",
			}
		end,
	},
}

return M
