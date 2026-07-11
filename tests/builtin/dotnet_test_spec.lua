local dotnet = require("command_runner.builtin.cs_dotnet_test")

local data = vim.fn.getcwd() .. "/tests/testdata/dotnet_test"

local function buf_with(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	return buf
end

local find_command = require("tests/test_util").find_command

describe("command_runner.builtin.dotnet_test", function()
	describe("get_solution_dir", function()
		describe("given a solution marked by .sln", function()
			local root
			local file

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should return the directory containing the .sln", function()
				assert.equals(root, dotnet.get_solution_dir(file))
			end)
		end)

		describe("given a solution marked by .slnx", function()
			local root
			local file

			before_each(function()
				root = data .. "/xml_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should return the directory containing the .slnx", function()
				assert.equals(root, dotnet.get_solution_dir(file))
			end)
		end)
	end)

	describe("get_project_dir", function()
		describe("given a project marked by .csproj", function()
			local root
			local file

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should return the directory containing the .csproj", function()
				assert.equals(root .. "/proj", dotnet.get_project_dir(file))
			end)
		end)
	end)

	describe("get_namespace", function()
		describe("given a buffer containing a namespace declaration", function()
			local buf

			before_each(function()
				buf = buf_with({ "using System;", "", "namespace My.App.Tests", "{", "}" })
			end)

			after_each(function()
				vim.api.nvim_buf_delete(buf, { force = true })
			end)

			it("should return the declared namespace", function()
				assert.equals("My.App.Tests", dotnet.get_namespace(nil, buf))
			end)
		end)

		describe("given a buffer without a namespace declaration", function()
			local buf

			before_each(function()
				buf = buf_with({ "// nothing here" })
			end)

			after_each(function()
				vim.api.nvim_buf_delete(buf, { force = true })
			end)

			it("should return nil", function()
				assert.is_nil(dotnet.get_namespace(nil, buf))
			end)
		end)
	end)

	describe("'dotnet test current file' command", function()
		local cmd

		before_each(function()
			cmd = find_command(dotnet.commands, "dotnet test current file")
		end)

		describe("given a test file inside a solution", function()
			local root
			local file

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should filter by the class name derived from the file", function()
				local out = cmd.cmd(file)
				assert.equals(root, out.dir)
				assert.equals("dotnet test --filter ClassName~FooTests", out.command_line)
			end)
		end)
	end)

	describe("'dotnet test current namespace' command", function()
		local cmd

		before_each(function()
			cmd = find_command(dotnet.commands, "dotnet test current namespace")
		end)

		describe("given a buffer with a namespace inside a solution", function()
			local root
			local file
			local buf

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
				buf = buf_with({ "namespace My.App.Tests" })
			end)

			after_each(function()
				vim.api.nvim_buf_delete(buf, { force = true })
			end)

			it("should filter by the fully-qualified namespace", function()
				local out = cmd.cmd(file, buf)
				assert.equals(root, out.dir)
				assert.equals("dotnet test --filter FullyQualifiedName~My.App.Tests", out.command_line)
			end)
		end)
	end)

	describe("'dotnet test solution' command", function()
		local cmd

		before_each(function()
			cmd = find_command(dotnet.commands, "dotnet test solution")
		end)

		describe("given a test file inside a solution", function()
			local root
			local file

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should run the whole solution", function()
				local out = cmd.cmd(file)
				assert.equals(root, out.dir)
				assert.equals("dotnet test", out.command_line)
			end)
		end)
	end)
end)
