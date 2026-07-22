local M = {}

M.get_git_dir = function(filename)
	return vim.fs.root(filename, { ".git" })
end

--- Search upward from `filename` for `marker`, but never above the repository
--- (`.git`) root. This keeps project detection from latching onto a stray
--- marker (a `mix.exs`, `*.sln`, `package.json`, ...) that happens to live in
--- a parent directory outside the repo, e.g. the user's home directory.
---
--- When `filename` is not inside a git repository there is no boundary to
--- enforce and the search walks up to the filesystem root, like vim.fs.root.
---
---@param filename string
---@param marker string | string[] | fun(name: string, path: string): boolean Marker item(s) as understood by `vim.fs.root`.
---@return string? root The directory containing the marker, or nil when none was found within the repository.
M.find_root = function(filename, marker)
	local repo = M.get_git_dir(filename)
	-- vim.fs.find does not search the `stop` directory itself, so pass the
	-- repo root's parent to keep the repo root included in the search.
	local stop = repo and vim.fs.dirname(repo) or nil

	-- vim.fs.root has no `stop` option, so walk with vim.fs.find instead,
	-- mirroring vim.fs.root's priority semantics: each marker item is
	-- searched across all ancestors before falling back to the next item.
	local items = type(marker) == "table" and marker or { marker }
	for _, item in ipairs(items) do
		local found = vim.fs.find(item, {
			path = vim.fn.fnamemodify(filename, ":p:h"),
			upward = true,
			stop = stop,
			limit = 1,
		})[1]
		if found then
			return vim.fs.dirname(found)
		end
	end

	return nil
end

--- Shorten `path` against Neovim's cwd rather than a project root. Useful for
--- commands run via `vim.cmd` (not in a shell in some `dir`), which resolve
--- relative paths against cwd.
---
---@param path string
---@return string
M.relative_to_cwd = function(path)
	return vim.fs.relpath(vim.fn.getcwd(), path) or path
end

--- Shorten `path` against the git repository root containing it, falling
--- back to `path` unchanged when it's not inside a git repository.
---
---@param path string
---@return string
M.relative_to_git = function(path)
	local git_dir = M.get_git_dir(path)
	return git_dir and (vim.fs.relpath(git_dir, path) or path) or path
end

--- Build a Command that opens `filepath` in the current window via `:edit`.
---
---@param filepath string
---@return Command
M.edit_file = function(filepath)
	return {
		type = "nvim",
		command_line = "edit " .. vim.fn.fnameescape(filepath),
	}
end

return M
