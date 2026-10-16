local U = require("command_runner.util")

local M = {}

M.templates_dir = vim.fs.normalize(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)) .. "/../../templates")

-- mise loads every *.toml in .mise/conf.d without a mise.toml, so installed
-- tasks show up in `mise tasks ls` (and our picker) right away.
M.target_subdir = ".mise/conf.d"

--- Markers (as understood by `vim.fs.root`) that pre-check a template in the
--- checklist. Templates without an entry are offered but never pre-checked.
---@type table<string, string | string[] | fun(name: string, path: string): boolean>
M.detect = {
	docker = { "compose.yml", "compose.yaml", "docker-compose.yml", "docker-compose.yaml" },
	dotnet = function(name)
		local ext = vim.fs.ext(name)
		return ext == "sln" or ext == "slnx" or ext == "csproj"
	end,
	go = { "go.mod" },
	mix = { "mix.exs" },
	npm = { "package.json" },
	phoenix = { "mix.exs" },
	playwright = { "playwright.config.ts" },
	vitest = { "vitest.config.ts", "vitest.config.js" },
}

---@return string[] Template names (filenames without `.toml`), sorted.
M.list_templates = function()
	local names = {}
	for name, type in vim.fs.dir(M.templates_dir) do
		local key = type == "file" and name:match("^(.+)%.toml$")
		if key then
			table.insert(names, key)
		end
	end
	table.sort(names)
	return names
end

---@param root string
---@param name string
---@return string
M.target_path = function(root, name)
	return vim.fs.joinpath(root, M.target_subdir, "command_runner_" .. name .. ".toml")
end

--- Which templates apply to `filename`: those whose markers are found upward
--- from it (within its repository), plus those already installed in `root`.
---@param root string
---@param filename string
---@return table<string, boolean>
M.detected = function(root, filename)
	local result = {}
	for _, name in ipairs(M.list_templates()) do
		local marker = M.detect[name]
		result[name] = vim.uv.fs_stat(M.target_path(root, name)) ~= nil
			or (marker ~= nil and U.find_root(filename, marker) ~= nil)
	end
	return result
end

--- Copy the named templates into `root`'s .mise/conf.d and `mise trust` them.
--- Already installed files are left alone so local edits survive.
---@param root string
---@param names string[]
---@return string[] installed Template names that were newly written.
M.install = function(root, names)
	vim.fn.mkdir(vim.fs.joinpath(root, M.target_subdir), "p")

	local installed = {}
	for _, name in ipairs(names) do
		local target = M.target_path(root, name)
		if not vim.uv.fs_stat(target) then
			assert(vim.uv.fs_copyfile(vim.fs.joinpath(M.templates_dir, name .. ".toml"), target))
			-- Untrusted config files make every mise command in the project fail.
			local ok, res = pcall(function()
				return vim.system({ "mise", "trust", "--quiet", target }, { cwd = root }):wait()
			end)
			if not ok or res.code ~= 0 then
				vim.notify("command_runner: could not `mise trust` " .. target, vim.log.levels.WARN)
			end
			table.insert(installed, name)
		end
	end
	return installed
end

local checklist_pattern = "^%[([ xX])%]%s+(%S+)"

--- Parse checklist buffer lines into the checked template names.
---@param lines string[]
---@return string[]
M.parse_checklist = function(lines)
	local names = {}
	for _, line in ipairs(lines) do
		local mark, name = line:match(checklist_pattern)
		if mark and mark ~= " " then
			table.insert(names, name)
		end
	end
	return names
end

--- Open a checklist of task templates for the current buffer's project
--- (git root, else cwd). Detected ones are pre-checked; `x` toggles a line,
--- `:w` installs the checked ones.
M.open_checklist = function()
	local filename = vim.api.nvim_buf_get_name(0)
	local root = U.get_git_dir(filename ~= "" and filename or vim.fn.getcwd()) or vim.fn.getcwd()
	local detected = M.detected(root, filename ~= "" and filename or vim.fs.joinpath(root, "_"))

	local lines = {
		"# Install mise tasks into " .. vim.fs.joinpath(root, M.target_subdir),
		"# x: toggle   :w install checked   (installed files are never overwritten)",
		"",
	}
	for _, name in ipairs(M.list_templates()) do
		table.insert(lines, (detected[name] and "[x] " or "[ ] ") .. name)
	end

	vim.cmd("botright new")
	local buf = vim.api.nvim_get_current_buf()
	vim.bo[buf].buftype = "acwrite"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.api.nvim_buf_set_name(buf, "command_runner://install")
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modified = false

	vim.keymap.set("n", "x", function()
		local line = vim.api.nvim_get_current_line()
		local toggled = line:gsub("^%[ %]", "[x]", 1)
		if toggled == line then
			toggled = line:gsub("^%[[xX]%]", "[ ]", 1)
		end
		vim.api.nvim_set_current_line(toggled)
	end, { buffer = buf, desc = "Toggle task template" })

	vim.api.nvim_create_autocmd("BufWriteCmd", {
		buffer = buf,
		callback = function()
			local installed = M.install(root, M.parse_checklist(vim.api.nvim_buf_get_lines(buf, 0, -1, false)))
			vim.bo[buf].modified = false
			vim.notify(
				#installed > 0 and ("command_runner: installed " .. table.concat(installed, ", "))
					or "command_runner: nothing new to install"
			)
		end,
	})
end

return M
