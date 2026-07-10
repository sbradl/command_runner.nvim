local M = {}

M.directory_commands = {
	{
		label = "List Directory",
		cmd = function(filename)
			return {
				dir = vim.fs.dirname(filename),
				command_line = "ls -la",
			}
		end,
	},
}

return M
