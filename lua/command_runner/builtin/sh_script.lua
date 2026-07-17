local M = {}

M.extensions = { "sh", "ps1" }

---@type CommandDescription[]
M.commands = {
	{
		label = "execute script",
		cmd = function(filename)
			local name = vim.fs.basename(filename)

			return {
				dir = vim.fs.dirname(filename),
				command_line = "./" .. name,
			}
		end,
	},
}

return M
