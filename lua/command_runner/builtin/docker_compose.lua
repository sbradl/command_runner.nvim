local M = {}

M.extensions = { "yml", "yaml" }

local compose_filenames = {
	["docker-compose.yml"] = true,
	["docker-compose.yaml"] = true,
	["compose.yml"] = true,
	["compose.yaml"] = true,
}

local function is_compose_file(filename)
	return compose_filenames[vim.fs.basename(filename)] == true
end

---@type CommandDescription[]
M.commands = {
	{
		label = "docker compose up -d",
		filter = is_compose_file,
		cmd = function(filename)
			return {
				dir = vim.fs.dirname(filename),
				command_line = "docker compose up -d",
			}
		end,
	},
	{
		label = "docker compose down",
		filter = is_compose_file,
		cmd = function(filename)
			return {
				dir = vim.fs.dirname(filename),
				command_line = "docker compose down",
			}
		end,
	},
	{
		label = "docker compose build",
		filter = is_compose_file,
		cmd = function(filename)
			return {
				dir = vim.fs.dirname(filename),
				command_line = "docker compose build",
			}
		end,
	},
	{
		label = "docker compose logs -f",
		filter = is_compose_file,
		cmd = function(filename)
			return {
				dir = vim.fs.dirname(filename),
				command_line = "docker compose logs -f",
			}
		end,
	},
	{
		label = "docker compose ps",
		filter = is_compose_file,
		cmd = function(filename)
			return {
				dir = vim.fs.dirname(filename),
				command_line = "docker compose ps",
			}
		end,
	},
	{
		label = "docker compose restart",
		filter = is_compose_file,
		cmd = function(filename)
			return {
				dir = vim.fs.dirname(filename),
				command_line = "docker compose restart",
			}
		end,
	},
}

return M
