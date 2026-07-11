local playwright = require("command_runner.builtin.ts_playwright")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/playwright"

describe("command_runner.builtin.playwright", function()
	describe("get_project_dir", function()
		describe("given a project marked by playwright.config.ts", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/e2e/a.spec.ts"
			end)

			it("should return the directory containing playwright.config.ts", function()
				assert.equals(root, playwright.get_project_dir(file))
			end)
		end)
	end)

	describe("'Playwright current file' command", function()
		local cmd

		before_each(function()
			cmd = find_command(playwright.commands, "Playwright current file")
		end)

		describe("given a spec file inside a project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/e2e/a.spec.ts"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build the playwright test command", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("npx playwright test", out.command_line)
			end)
		end)

		describe("given a spec file outside any project", function()
			local file

			before_each(function()
				file = data .. "/bare/a.spec.ts"
				assert.is_nil(playwright.get_project_dir(file))
			end)

			it("should not be available", function()
				assert.is_false(cmd.filter(file))
			end)
		end)
	end)
end)
