local U = require("command_runner.util")

local M = {}

-- mise projects are polyglot, so its tasks are offered for every buffer that
-- lives inside a mise project, not one file extension.
M.extensions = { "*" }

local mise_markers = { "mise.toml", ".mise.toml", "mise.local.toml", ".mise.local.toml" }

M.get_project_dir = function(filename)
	return U.find_root(filename, mise_markers)
end

local function is_mise_project(filename)
	return M.get_project_dir(filename) ~= nil
end

--- Ask the mise CLI for the project's tasks. Shelling out (rather than parsing
--- mise.toml ourselves) picks up every task source mise knows about — inline
--- toml tasks, file tasks, includes — and always matches `mise run`'s own view.
---
---@param dir string The mise project root, used as the CLI's working directory.
---@return string[] task names, empty when mise is missing or reports an error.
local function list_tasks(dir)
	local ok, res = pcall(function()
		return vim.system({ "mise", "tasks", "ls", "--json" }, { cwd = dir, text = true }):wait()
	end)

	if not ok or res.code ~= 0 or not res.stdout or res.stdout == "" then
		return {}
	end

	local decoded, parsed = pcall(vim.json.decode, res.stdout)
	if not decoded or type(parsed) ~= "table" then
		return {}
	end

	local names = {}
	for _, task in ipairs(parsed) do
		if type(task) == "table" and type(task.name) == "string" then
			table.insert(names, task.name)
		end
	end
	return names
end

---@type CommandDescription[]
M.commands = {
	{
		label = "mise run", -- placeholder; the expanded entries carry the real labels
		filter = is_mise_project,
		expand = function(filename)
			local dir = M.get_project_dir(filename)

			local descriptions = {}
			for _, name in ipairs(list_tasks(dir)) do
				table.insert(descriptions, {
					label = "mise run " .. name,
					cmd = function()
						return {
							dir = dir,
							command_line = "mise run " .. name,
						}
					end,
				})
			end
			return descriptions
		end,
	},
}

return M
