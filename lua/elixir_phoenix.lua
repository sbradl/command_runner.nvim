local M = {}

M.get_project_dir = function(filename)
	return vim.fs.root(filename, { "mix.exs" })
end

local function is_elixir_project(filename)
	return M.get_project_dir(filename) ~= nil
end

M.directory_commands = {
	{
		label = "phx new",
		cmd = function(dir)
			return {
				dir = dir,
				command_line = "mix archive.install hex phx_new && mix phx.new .",
			}
		end,
	},
}

M.commands = {
	{
		label = "mix phx.server",
		filter = is_elixir_project,
		cmd = function(filename)
			return {
				dir = M.get_project_dir(filename),
				command_line = "mix phx.server",
			}
		end,
	},
}

return M
