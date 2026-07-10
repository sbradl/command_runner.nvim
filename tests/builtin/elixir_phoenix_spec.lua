local phx = require("command_runner.builtin.elixir_phoenix")

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

describe("command_runner.builtin.elixir_phoenix", function()
	it("finds the project dir via mix.exs", function()
		local root = make_tree({ "mix.exs", "lib/app.ex" })
		assert.equals(root, phx.get_project_dir(root .. "/lib/app.ex"))
		vim.fn.delete(root, "rf")
	end)

	it("offers 'mix phx.server' inside a project", function()
		local root = make_tree({ "mix.exs", "lib/app.ex" })
		local c = phx.commands[1]
		assert.equals("mix phx.server", c.label)
		assert.is_true(c.filter(root .. "/lib/app.ex"))

		local out = c.cmd(root .. "/lib/app.ex")
		assert.equals(root, out.dir)
		assert.equals("mix phx.server", out.command_line)
		vim.fn.delete(root, "rf")
	end)

	it("does not offer the server command outside a mix project", function()
		local bare = make_tree({ "app.ex" })
		assert.is_false(phx.commands[1].filter(bare .. "/app.ex"))
		vim.fn.delete(bare, "rf")
	end)

	it("offers 'phx new' as a directory command", function()
		local c = phx.directory_commands[1]
		assert.equals("phx new", c.label)

		local out = c.cmd("/dir")
		assert.equals("/dir", out.dir)
		assert.equals("mix archive.install hex phx_new && mix phx.new .", out.command_line)
	end)
end)