local angular = require("command_runner.builtin.ts_angular")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/angular"

describe("command_runner.builtin.ts_angular", function()
	describe("'npm run build' command", function()
		local cmd

		before_each(function()
			cmd = find_command(angular.commands, "npm run build")
		end)

		describe("given a file inside an angular project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/src/app/app.component.ts"
			end)

			it("should run the build in the project directory", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("npm run build", out.command_line)
			end)
		end)
	end)
end)
