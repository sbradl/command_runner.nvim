local dotnet = require("command_runner.builtin.cs_dotnet")

local data = vim.fn.getcwd() .. "/tests/testdata/dotnet_test"

local find_command = require("tests/test_util").find_command

describe("command_runner.builtin.dotnet", function()
	describe("'open solution file' command", function()
		local cmd

		before_each(function()
			cmd = find_command(dotnet.commands, "open solution file")
		end)

		describe("given a file inside a classic solution", function()
			local root
			local file

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should edit the .sln file", function()
				local out = cmd.cmd(file)
				assert.equals("nvim", out.type)
				assert.equals("edit " .. root .. "/App.sln", out.command_line)
			end)
		end)

		describe("given a file inside an xml solution", function()
			local root
			local file

			before_each(function()
				root = data .. "/xml_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should edit the .slnx file", function()
				local out = cmd.cmd(file)
				assert.equals("nvim", out.type)
				assert.equals("edit " .. root .. "/App.slnx", out.command_line)
			end)
		end)
	end)

	describe("'open project file' command", function()
		local cmd

		before_each(function()
			cmd = find_command(dotnet.commands, "open project file")
		end)

		describe("given a file inside a solution", function()
			local root
			local file

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
			end)

			it("should edit the .csproj file", function()
				local out = cmd.cmd(file)
				assert.equals("nvim", out.type)
				assert.equals("edit " .. root .. "/proj/proj.csproj", out.command_line)
			end)
		end)
	end)
end)
