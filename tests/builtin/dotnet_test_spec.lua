local dotnet = require("command_runner.builtin.dotnet_test")

local function make_tree(files)
	local root = vim.fn.tempname()
	vim.fn.mkdir(root, "p")
	for _, rel in ipairs(files or {}) do
		local full = root .. "/" .. rel
		vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
		local fd = assert(io.open(full, "w"))
		fd:close()
	end
	return root
end

local function buf_with(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	return buf
end

describe("command_runner.builtin.dotnet_test", function()
	it("finds the solution dir via .sln", function()
		local root = make_tree({ "App.sln", "proj/App.csproj", "proj/FooTests.cs" })
		assert.equals(root, dotnet.get_solution_dir(root .. "/proj/FooTests.cs"))
		vim.fn.delete(root, "rf")
	end)

	it("finds the solution dir via .slnx", function()
		local root = make_tree({ "App.slnx", "proj/FooTests.cs" })
		assert.equals(root, dotnet.get_solution_dir(root .. "/proj/FooTests.cs"))
		vim.fn.delete(root, "rf")
	end)

	it("finds the project dir via .csproj", function()
		local root = make_tree({ "App.sln", "proj/App.csproj", "proj/FooTests.cs" })
		assert.equals(root .. "/proj", dotnet.get_project_dir(root .. "/proj/FooTests.cs"))
		vim.fn.delete(root, "rf")
	end)

	it("reads the namespace from the buffer", function()
		local buf = buf_with({ "using System;", "", "namespace My.App.Tests", "{", "}" })
		assert.equals("My.App.Tests", dotnet.get_namespace(nil, buf))
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("returns nil when there is no namespace", function()
		local buf = buf_with({ "// nothing here" })
		assert.is_nil(dotnet.get_namespace(nil, buf))
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("filters tests by class name for the current file", function()
		local root = make_tree({ "App.sln", "proj/FooTests.cs" })
		local c = dotnet.commands[1]
		assert.equals("dotnet test current file", c.label)

		local out = c.cmd(root .. "/proj/FooTests.cs")
		assert.equals(root, out.dir)
		assert.equals("dotnet test --filter ClassName~FooTests", out.command_line)
		vim.fn.delete(root, "rf")
	end)

	it("filters tests by the namespace of the current buffer", function()
		local root = make_tree({ "App.sln", "proj/FooTests.cs" })
		local buf = buf_with({ "namespace My.App.Tests" })
		local c = dotnet.commands[2]
		assert.equals("dotnet test current namespace", c.label)

		local out = c.cmd(root .. "/proj/FooTests.cs", buf)
		assert.equals(root, out.dir)
		assert.equals("dotnet test --filter FullyQualifiedName~My.App.Tests", out.command_line)

		vim.api.nvim_buf_delete(buf, { force = true })
		vim.fn.delete(root, "rf")
	end)

	it("runs the whole solution", function()
		local root = make_tree({ "App.sln", "proj/FooTests.cs" })
		local c = dotnet.commands[3]
		assert.equals("dotnet test solution", c.label)

		local out = c.cmd(root .. "/proj/FooTests.cs")
		assert.equals(root, out.dir)
		assert.equals("dotnet test", out.command_line)
		vim.fn.delete(root, "rf")
	end)
end)