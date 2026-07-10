local util = require("command_runner.util")

describe("command_runner.util", function()
	local restores

	local function replace(tbl, key, fn)
		local orig = tbl[key]
		table.insert(restores, function()
			tbl[key] = orig
		end)
		tbl[key] = fn
	end

	before_each(function()
		restores = {}
	end)

	after_each(function()
		for _, r in ipairs(restores) do
			r()
		end
	end)

	it("get_git_dir looks for the nearest .git via vim.fs.root", function()
		local got_args
		replace(vim.fs, "root", function(name, markers)
			got_args = { name, markers }
			return "/repo"
		end)

		assert.equals("/repo", util.get_git_dir("/repo/src/a.lua"))
		assert.same({ "/repo/src/a.lua", { ".git" } }, got_args)
	end)

	it("get_git_dir returns nil when there is no repo", function()
		replace(vim.fs, "root", function()
			return nil
		end)

		assert.is_nil(util.get_git_dir("/tmp/loose/file.lua"))
	end)
end)