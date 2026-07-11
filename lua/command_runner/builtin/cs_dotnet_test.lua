local M = {}

M.extensions = { "cs" }

M.get_solution_dir = function(filename)
	return vim.fs.root(filename, function(name, _)
		local ext = vim.fs.ext(name)
		return ext == "sln" or ext == "slnx"
	end)
end

M.get_project_dir = function(filename)
	return vim.fs.root(filename, function(name, _)
		return vim.fs.ext(name) == "csproj"
	end)
end

M.get_namespace = function(_, buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	for _, line in ipairs(lines) do
		local namespace = line:match("^%s*namespace%s+([%w%.]+)")
		if namespace then
			return namespace
		end
	end

	return nil
end

---@type CommandDescription[]
M.commands = {
	{
		label = "dotnet test current file",
		cmd = function(filename)
			return {
				dir = M.get_solution_dir(filename),
				command_line = "dotnet test --filter ClassName~" .. vim.fn.fnamemodify(filename, ":t:r"),
			}
		end,
	},
	{
		label = "dotnet test current namespace",
		cmd = function(filename, buf)
			return {
				dir = M.get_solution_dir(filename),
				command_line = "dotnet test --filter FullyQualifiedName~" .. M.get_namespace(filename, buf),
			}
		end,
	},
	{
		label = "dotnet test solution",
		cmd = function(filename, buf)
			return {
				dir = M.get_solution_dir(filename),
				command_line = "dotnet test",
			}
		end,
	},
}

return M
