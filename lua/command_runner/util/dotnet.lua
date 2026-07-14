local M = {}

M.get_solution_dir = function(filename)
	return vim.fs.root(filename, function(name, _)
		local ext = vim.fs.ext(name)
		return ext == "sln" or ext == "slnx"
	end)
end

M.get_project_dir = function(filename)
	return vim.fs.relpath(
		M.get_solution_dir(filename),
		assert(vim.fs.root(filename, function(name, _)
			return vim.fs.ext(name) == "csproj"
		end))
	)
end

M.get_project_file = function(filename)
	local project_dir = M.get_project_dir(filename)
	return vim.fs.joinpath(project_dir, vim.fs.basename(project_dir) .. ".csproj")
end

M.get_solution_file = function(filename)
	local solution_dir = M.get_solution_dir(filename)

	for name, type in vim.fs.dir(solution_dir) do
		local ext = vim.fs.ext(name)
		if type == "file" and (ext == "sln" or ext == "slnx") then
			return vim.fs.joinpath(solution_dir, name)
		end
	end

	return nil
end

M.get_project_file_abs = function(filename)
	return vim.fs.joinpath(M.get_solution_dir(filename), M.get_project_file(filename))
end

M.get_namespace = function(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	for _, line in ipairs(lines) do
		local namespace = line:match("^%s*namespace%s+([%w%.]+)")
		if namespace then
			return namespace
		end
	end

	return nil
end

M.get_class = function(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	for _, line in ipairs(lines) do
		local class = line:match("%f[%w]class%s+([%w_]+)")
		if class then
			return class
		end
	end

	return nil
end

return M
