local npm = require("command_runner.builtin.ts_npm")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/ts_npm"

describe("command_runner.builtin.ts_npm", function()
	describe("get_project_dir", function()
		it("should find the directory containing package.json", function()
			assert.equals(data .. "/proj", npm.get_project_dir(data .. "/proj/src/a.ts"))
		end)

		it("should return nil outside an npm project", function()
			assert.is_nil(npm.get_project_dir(data .. "/bare/a.ts"))
		end)
	end)

	describe("'edit package.json' command", function()
		local cmd

		before_each(function()
			cmd = find_command(npm.commands, "edit package.json")
		end)

		describe("given a file inside an npm project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/src/a.ts"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should edit the project's package.json", function()
				local out = cmd.cmd(file)

				assert.equals("nvim", out.type)
				assert.equals("edit " .. root .. "/package.json", out.command_line)
			end)
		end)

		describe("given a file outside any npm project", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(data .. "/bare/a.ts"))
			end)
		end)
	end)
end)