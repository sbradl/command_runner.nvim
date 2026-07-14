local M = {}

M.get_angular_dir = function(filename)
	return vim.fs.root(filename, { "angular.json" })
end

return M