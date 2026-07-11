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

			it("should build a PlenaryBustedDirectory nvim command rooted at the repo", function()
				local out = cmd.cmd(file)

				assert.equals("nvim", out.type)
				assert.equals("PlenaryBustedDirectory " .. repo, out.command_line)
			end)
		end)
	end)
end)
