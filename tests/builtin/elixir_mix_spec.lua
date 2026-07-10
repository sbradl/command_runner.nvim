local mix = require("command_runner.builtin.elixir_mix")

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

describe("command_runner.builtin.elixir_mix", function()
	it("finds the project dir via mix.exs", function()
		local root = make_tree({ "mix.exs", "lib/foo.ex" })
		assert.equals(root, mix.get_project_dir(root .. "/lib/foo.ex"))
		vim.fn.delete(root, "rf")
	end)

	it("offers compile, test and release inside a project", function()
		local root = make_tree({ "mix.exs", "lib/foo.ex" })
		local file = root .. "/lib/foo.ex"

		local labels, results = {}, {}
		for _, c in ipairs(mix.commands) do
			assert.is_true(c.filter(file))
			labels[#labels + 1] = c.label
			results[c.label] = c.cmd(file)
		end

		assert.same({ "mix compile", "mix test", "mix release" }, labels)
		assert.equals(root, results["mix compile"].dir)
		assert.equals("mix compile", results["mix compile"].command_line)
		assert.equals("mix test", results["mix test"].command_line)
		assert.equals("mix release", results["mix release"].command_line)
		vim.fn.delete(root, "rf")
	end)

	it("filters out files that are not in a mix project", function()
		local bare = make_tree({ "foo.ex" })
		assert.is_false(mix.commands[1].filter(bare .. "/foo.ex"))
		vim.fn.delete(bare, "rf")
	end)

	it("offers 'mix new' as a directory command", function()
		local c = mix.directory_commands[1]
		assert.equals("mix new", c.label)

		local out = c.cmd("/some/dir")
		assert.equals("/some/dir", out.dir)
		assert.equals("mix new .", out.command_line)
	end)
end)