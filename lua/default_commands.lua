local M = {}

M.commands = {
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
