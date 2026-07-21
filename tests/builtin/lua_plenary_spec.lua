local plenary = require("command_runner.builtin.lua_plenary")

local repo = vim.fn.getcwd()
local fixture = repo .. "/tests/testdata/lua_plenary/lua/a.lua"

local find_command = require("tests/test_util").find_command

describe("command_runner.builtin.lua_plenary", function()
	describe("get_project_dir", function()
		describe("given a file inside a git repository", function()
			local file

			before_each(function()
				file = fixture
				assert.equals(1, vim.fn.isdirectory(repo .. "/.git"))
			end)

			it("should return the repository root", function()
				assert.equals(repo, plenary.get_project_dir(file))
			end)
		end)
	end)

	describe("Plenary test file", function()
		local cmd

		before_each(function()
			cmd = find_command(plenary.commands, "Plenary test file")
		end)

		describe("given a plenary spec file", function()
			local file

			before_each(function()
				-- a real spec file: this very spec
				file = repo .. "/tests/builtin/lua_plenary_spec.lua"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build a PlenaryBustedFile nvim command with a path relative to cwd", function()
				local out = cmd.cmd(file)

				assert.equals("nvim", out.type)
				assert.equals("PlenaryBustedFile tests/builtin/lua_plenary_spec.lua", out.command_line)
			end)
		end)

		describe("given a lua file that is not a spec", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(fixture))
			end)
		end)
	end)

	describe("Plenary test all", function()
		local cmd

		before_each(function()
			cmd = find_command(plenary.commands, "Plenary test all")
		end)

		describe("given a file inside a git repository", function()
			local file

			before_each(function()
				file = fixture
				assert.equals(1, vim.fn.isdirectory(repo .. "/.git"))
			end)

			it("should build a PlenaryBustedDirectory nvim command with a path relative to cwd", function()
				local out = cmd.cmd(file)

				assert.equals("nvim", out.type)
				assert.equals("PlenaryBustedDirectory .", out.command_line)
			end)
		end)
	end)
end)
