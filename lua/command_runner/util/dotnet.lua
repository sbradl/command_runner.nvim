local U = require("command_runner.util")

local M = {}

M.get_solution_dir = function(filename)
	return U.find_root(filename, function(name, _)
		local ext = vim.fs.ext(name)
		return ext == "sln" or ext == "slnx"
	end)
end

M.get_project_dir = function(filename)
	return vim.fs.relpath(
		M.get_solution_dir(filename),
		assert(U.find_root(filename, function(name, _)
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

--- Extracts the identifier immediately followed by `(` from a line that
--- looks like a method signature, or nil if it doesn't look like one.
--- Rejects matches preceded by `=` (a field/property initializer calling a
--- constructor or method, e.g. `= new Regex(...)`), since a real method
--- signature never has `=` before its name.
local function method_name_from_signature(text)
	local start, _, method = text:find("([%w_]+)%s*%(")
	if not method then
		return nil
	end
	if text:sub(1, start - 1):find("=", 1, true) then
		return nil
	end
	return method
end

--- Walks backward from `line` (1-indexed, inclusive) for the nearest line
--- that looks like a method signature, and returns the captured name. Test
--- methods must be public, so this only considers lines with the `public`
--- modifier; it's a line-regex heuristic, not a real parser.
M.get_method = function(buf, line)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, line, false)

	for i = #lines, 1, -1 do
		local text = lines[i]
		if text:match("%f[%w]public%f[%W]") then
			local method = method_name_from_signature(text)
			if method then
				return method
			end
		end
	end

	return nil
end

return M
