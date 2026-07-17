local dotnet = require("command_runner.builtin.cs_dotnet_test")

local data = vim.fn.getcwd() .. "/tests/testdata/dotnet_test"

local function buf_with(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	return buf
end

local function buf_from_file(path)
	return buf_with(vim.fn.readfile(path))
end

local function contains(s, needle)
	return string.find(s, needle, 1, true) ~= nil
end

local function assert_no_restore(cmd)
	assert.equals(true, contains(cmd, " --no-restore"))
end

local function assert_filter(cmd, expected_filter)
	assert.equals(true, contains(cmd, " --filter " .. expected_filter))
end

local function assert_project(cmd, project_file)
	assert.equals(true, vim.endswith(cmd, " " .. project_file))
end

local function assert_base_command(cmd, expected_base_command)
	assert.equals(true, vim.startswith(cmd, expected_base_command))
end

local find_command = require("tests/test_util").find_command

describe("command_runner.builtin.dotnet_test", function()
	describe("'dotnet test current class' command", function()
		local cmd

		before_each(function()
			cmd = find_command(dotnet.commands, "dotnet test current class")
		end)

		describe("given a test file inside a solution", function()
			local root
			local file
			local buf

			before_each(function()
				root = data .. "/classic_solution"
				file = root .. "/proj/FooTests.cs"
				buf = buf_with({ "class FooTests {}" })
			end)

			after_each(function()
				vim.api.nvim_buf_delete(buf, { force = true })
			end)

			it("should filter by the class name declared in the buffer", function()
				local out = cmd.cmd(file, buf)
				local command_line = out.command_line

				assert.equals(root, out.dir)
				assert_base_command(command_line, "dotnet test")
				assert_no_restore(command_line)
				assert_filter(command_line, "ClassName~FooTests")
				assert_project(command_line, "proj/proj.csproj")
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
				local command_line = out.command_line

				assert.equals(root, out.dir)
				assert_base_command(command_line, "dotnet test")
				assert_no_restore(command_line)
				assert_filter(command_line, "FullyQualifiedName~My.App.Tests")
				assert_project(command_line, "proj/proj.csproj")
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
				local command_line = out.command_line

				assert.equals(root, out.dir)
				assert_base_command(command_line, "dotnet test")
				assert_no_restore(command_line)
			end)
		end)
	end)
end)
