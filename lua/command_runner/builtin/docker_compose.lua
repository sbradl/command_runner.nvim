local U = require("command_runner.util")

local M = {}

local markers = { "docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml" }

-- vim.fs.root has no `stop` option (unlike U.find_root's vim.fs.find-based
-- search), so a repo boundary is enforced afterwards: discard a root found
-- above the repository, so a stray marker outside it is never picked up.
M.get_project_dir = function(dir)
	local root = vim.fs.root(dir, markers)
	if not root then
		return nil
	end

	local repo = U.get_git_dir(dir)
	if repo and root ~= repo and not vim.startswith(root, repo .. "/") then
		return nil
	end

	return root
end

local function is_compose_project(dir)
	return M.get_project_dir(dir) ~= nil
end

---@type CommandDescription[]
M.directory_commands = {
	{
		label = "docker compose up -d",
		filter = is_compose_project,
		cmd = function(dir)
			return {
				dir = M.get_project_dir(dir),
				command_line = "docker compose up -d",
			}
		end,
	},
	{
		label = "docker compose down",
		filter = is_compose_project,
		cmd = function(dir)
			return {
				dir = M.get_project_dir(dir),
				command_line = "docker compose down",
			}
		end,
	},
	{
		label = "docker compose build",
		filter = is_compose_project,
		cmd = function(dir)
			return {
				dir = M.get_project_dir(dir),
				command_line = "docker compose build",
			}
		end,
	},
	{
		label = "docker compose logs -f",
		filter = is_compose_project,
		cmd = function(dir)
			return {
				dir = M.get_project_dir(dir),
				command_line = "docker compose logs -f",
			}
		end,
	},
	{
		label = "docker compose ps",
		filter = is_compose_project,
		cmd = function(dir)
			return {
				dir = M.get_project_dir(dir),
				command_line = "docker compose ps",
			}
		end,
	},
	{
		label = "docker compose restart",
		filter = is_compose_project,
		cmd = function(dir)
			return {
				dir = M.get_project_dir(dir),
				command_line = "docker compose restart",
			}
		end,
	},
}

return M
