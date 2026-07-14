local dotnet = require("command_runner.util.dotnet")

local data = vim.fn.getcwd() .. "/tests/testdata/dotnet_test"

local function buf_with(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	return buf
end

describe("command_runner.util.dotnet", function()
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

			it("should return the directory containing the .csproj relative to the solution", function()
				assert.equals("proj", dotnet.get_project_dir(file))
			end)
		end)
	end)

	describe("get_project_file", function()
		describe("given a project marked by .csproj", function()
			local root
			local file

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should return path to csproj relative to solution directory", function()
				assert.equals("proj/proj.csproj", dotnet.get_project_file(file))
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
end)
