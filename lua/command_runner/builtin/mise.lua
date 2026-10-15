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
---@return { name: string, description: string? }[] tasks, empty when mise is missing or reports an error.
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

	local tasks = {}
	for _, task in ipairs(parsed) do
		if type(task) == "table" and type(task.name) == "string" then
			local description = type(task.description) == "string" and task.description or nil
			table.insert(tasks, { name = task.name, description = description })
		end
	end
	return tasks
end

local max_description_length = 60

--- First line of the description, truncated so long ones don't swamp the picker.
---@param description string?
---@return string? nil when there is nothing to show.
local function format_description(description)
	local line = vim.trim(vim.split(description or "", "\n")[1])
	if line == "" then
		return nil
	end
	if vim.fn.strchars(line) > max_description_length then
		line = vim.fn.strcharpart(line, 0, max_description_length - 1) .. "…"
	end
	return line
end

---@type CommandDescription[]
M.commands = {
	{
		label = "mise run", -- placeholder; the expanded entries carry the real labels
		filter = is_mise_project,
		expand = function(filename)
			local dir = M.get_project_dir(filename)

			local descriptions = {}
			for _, task in ipairs(list_tasks(dir)) do
				local name = task.name
				local description = format_description(task.description)
				table.insert(descriptions, {
					label = "mise run " .. name .. (description and " — " .. description or ""),
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
