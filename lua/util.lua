local M = {}

M.get_git_dir = function(filename)
	return vim.fs.root(filename, { ".git" })
end

return M
