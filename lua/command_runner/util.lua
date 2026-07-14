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

return M
