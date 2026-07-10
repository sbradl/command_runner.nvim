local M = {}

M.directory_commands = {
	{
		{
			label = "List Directory",
			cmd = function(_)
				return "ls -la"
			end,
		},
	},
}

return M
