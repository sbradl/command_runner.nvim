local vitest = require("command_runner.builtin.vitest")

local find_command = require("test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/vitest"

describe("command_runner.builtin.vitest", function()
	describe("get_project_dir", function()
		describe("given a project marked by package.json", function()
			local root
			local file

			before_each(function()
				root = data .. "/pkg"
				file = root .. "/src/a.test.ts"
			end)

			it("should return the directory containing package.json", function()
				assert.equals(root, vitest.get_project_dir(file))
			end)
		end)

		describe("given a project marked by vitest.config.ts", function()
			local root
			local file

			before_each(function()
				root = data .. "/config"
				file = root .. "/a.test.ts"
			end)

			it("should return the directory containing vitest.config.ts", function()
				assert.equals(root, vitest.get_project_dir(file))
			end)
		end)
	end)

	describe("'vitest current file' command", function()
		local cmd

		before_each(function()
			cmd = find_command(vitest.commands, "vitest current file")
		end)

		describe("given a test file inside a project", function()
			local root
			local file

			before_each(function()
				root = data .. "/pkg"
				file = root .. "/src/a.test.ts"
			end)

			it("should run vitest with the project-relative path", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("npx vitest src/a.test.ts", out.command_line)
			end)
		end)
	end)

	describe("'vitest all' command", function()
		local cmd

		before_each(function()
			cmd = find_command(vitest.commands, "vitest all")
		end)

		describe("given a test file inside a project", function()
			local root
			local file

			before_each(function()
				root = data .. "/pkg"
				file = root .. "/src/a.test.ts"
			end)

			it("should run the whole suite", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("npx vitest", out.command_line)
			end)
		end)
	end)
end)
