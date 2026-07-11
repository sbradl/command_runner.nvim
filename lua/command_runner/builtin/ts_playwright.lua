local M = {}

M.extensions = { "ts" }

M.get_project_dir = function(filename)
	return vim.fs.root(filename, { "playwright.config.ts" })
end

---@type CommandDescription[]
M.commands = {
	{
		filter = function(filename)
			return M.get_project_dir(filename) ~= nil
		end,
		label = "Playwright current file",
		cmd = function(filename)
			local project_dir = M.get_project_dir(filename)
			return {
				dir = project_dir,
				command_line = "npx playwright test",
			}
		end,
	},
}

return M
