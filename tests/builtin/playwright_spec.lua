local playwright = require("command_runner.builtin.playwright")

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

describe("command_runner.builtin.playwright", function()
	it("detects a playwright project via playwright.config.ts", function()
		local root = make_tree({ "playwright.config.ts", "e2e/a.spec.ts" })
		assert.equals(root, playwright.get_project_dir(root .. "/e2e/a.spec.ts"))
		vim.fn.delete(root, "rf")
	end)

	it("filter is true inside a project and false outside", function()
		local c = playwright.commands[1]

		local proj = make_tree({ "playwright.config.ts", "e2e/a.spec.ts" })
		assert.is_true(c.filter(proj .. "/e2e/a.spec.ts"))

		local bare = make_tree({ "a.spec.ts" })
		assert.is_false(c.filter(bare .. "/a.spec.ts"))

		vim.fn.delete(proj, "rf")
		vim.fn.delete(bare, "rf")
	end)

	it("builds the playwright test command", function()
		local root = make_tree({ "playwright.config.ts", "e2e/a.spec.ts" })
		local c = playwright.commands[1]
		assert.equals("Playwright current file", c.label)

		local out = c.cmd(root .. "/e2e/a.spec.ts")
		assert.equals(root, out.dir)
		assert.equals("npx playwright test", out.command_line)
		vim.fn.delete(root, "rf")
	end)
end)