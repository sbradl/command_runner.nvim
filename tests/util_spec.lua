local util = require("command_runner.util")

local repo = vim.fn.getcwd()

describe("command_runner.util", function()
	describe("get_git_dir", function()
		describe("given a file inside a git repository", function()
			local file

			before_each(function()
				file = repo .. "/tests/testdata/util/src/a.lua"
				assert.equals(1, vim.fn.isdirectory(repo .. "/.git"))
			end)

			it("should return the repository root", function()
				assert.equals(repo, util.get_git_dir(file))
			end)
		end)

		describe("given a file that is not inside any git repository", function()
			local file

			before_each(function()
				file = "/no/such/repo/file.lua"
				assert.equals(0, vim.fn.isdirectory("/no"))
			end)

			it("should return nil", function()
				assert.is_nil(util.get_git_dir(file))
			end)
		end)
	end)
end)
