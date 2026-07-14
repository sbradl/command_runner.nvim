local dotnet = require("command_runner.util.dotnet")

local M = {}

M.extensions = { "cs" }

---@type CommandDescription[]
M.commands = {
	{
		label = "dotnet test current file",
		cmd = function(filename)
			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test --filter ClassName~" .. vim.fn.fnamemodify(filename, ":t:r"),
			}
		end,
	},
	{
		label = "dotnet test current namespace",
		cmd = function(filename, buf)
			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test --filter FullyQualifiedName~" .. dotnet.get_namespace(filename, buf),
			}
		end,
	},
	{
		label = "dotnet test solution",
		cmd = function(filename, buf)
			return {
				dir = dotnet.get_solution_dir(filename),
				command_line = "dotnet test",
			}
		end,
	},
}

return M
