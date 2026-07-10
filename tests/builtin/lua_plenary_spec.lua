local plenary = require("command_runner.builtin.lua_plenary")

local function make_tree(files)
	local root = vim.fn.tempname()
	vim.fn.mkdir(root, "p")
	for _, rel in ipairs(files or {}) do
		local full = root .. "/" .. rel
		vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
		local fd = assert(io.open(full, "w"))
		fd:close()
	end
	return root
end

describe("command_runner.builtin.lua_plenary", function()
	it("uses the git root as the project dir", function()
		local root = make_tree({ ".git/HEAD", "lua/a.lua" })
		assert.equals(root, plenary.get_project_dir(root .. "/lua/a.lua"))
		vim.fn.delete(root, "rf")
	end)

	it("builds a PlenaryBustedDirectory nvim command rooted at the repo", function()
		local root = make_tree({ ".git/HEAD", "lua/a.lua" })
		local c = plenary.commands[1]
		assert.equals("Plenary test all", c.label)

		local out = c.cmd(root .. "/lua/a.lua")
		assert.equals("nvim", out.type)
		assert.equals("PlenaryBustedDirectory " .. root, out.command_line)
		vim.fn.delete(root, "rf")
	end)
end)