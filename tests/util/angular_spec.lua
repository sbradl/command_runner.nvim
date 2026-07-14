local angular = require("command_runner.util.angular")

local data = vim.fn.getcwd() .. "/tests/testdata/angular"

describe("command_runner.util.angular", function()
	describe("get_angular_dir", function()
		describe("given a file inside a project marked by angular.json", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/src/app/app.component.ts"
			end)

			it("should return the directory containing angular.json", function()
				assert.equals(root, angular.get_angular_dir(file))
			end)
		end)

		describe("given a file outside any project", function()
			local file

			before_each(function()
				file = data .. "/bare/a.ts"
			end)

			it("should return nil", function()
				assert.is_nil(angular.get_angular_dir(file))
			end)
		end)
	end)
end)