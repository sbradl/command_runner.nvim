local vitest = require("command_runner.builtin.vitest")

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

describe("command_runner.builtin.vitest", function()
	it("finds the project dir via package.json", function()
		local root = make_tree({ "package.json", "src/a.test.ts" })
		assert.equals(root, vitest.get_project_dir(root .. "/src/a.test.ts"))
		vim.fn.delete(root, "rf")
	end)

	it("finds the project dir via vitest.config.ts", function()
		local root = make_tree({ "vitest.config.ts", "a.test.ts" })
		assert.equals(root, vitest.get_project_dir(root .. "/a.test.ts"))
		vim.fn.delete(root, "rf")
	end)

	it("runs the current file with a project-relative path", function()
		local root = make_tree({ "package.json", "src/a.test.ts" })
		local c = vitest.commands[1]
		assert.equals("vitest current file", c.label)

		local out = c.cmd(root .. "/src/a.test.ts")
		assert.equals(root, out.dir)
		assert.equals("npx vitest src/a.test.ts", out.command_line)
		vim.fn.delete(root, "rf")
	end)

	it("runs the whole suite", function()
		local root = make_tree({ "package.json", "src/a.test.ts" })
		local c = vitest.commands[2]
		assert.equals("vitest all", c.label)

		local out = c.cmd(root .. "/src/a.test.ts")
		assert.equals(root, out.dir)
		assert.equals("npx vitest", out.command_line)
		vim.fn.delete(root, "rf")
	end)
end)