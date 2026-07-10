describe("command_runner (setup & registration)", function()
	local cr
	local restores
	local root_ret

	local function replace(tbl, key, fn)
		local orig = tbl[key]
		table.insert(restores, function()
			tbl[key] = orig
		end)
		tbl[key] = fn
	end

	local function labels(ext)
		local out = {}
		for _, c in ipairs(cr._commands[ext] or {}) do
			out[#out + 1] = c.label
		end
		return out
	end

	before_each(function()
		restores = {}
		-- Modules log at DEBUG during registration; keep test output clean.
		replace(vim, "notify", function() end)

		-- Control the project-local config lookup (`vim.fs.root(0, ".nvim")`).
		root_ret = nil
		replace(vim.fs, "root", function()
			return root_ret
		end)

		-- Fresh module so `_commands` starts empty for every test.
		package.loaded["command_runner"] = nil
		cr = require("command_runner")
	end)

	after_each(function()
		for _, r in ipairs(restores) do
			r()
		end
		package.loaded["command_runner"] = nil
	end)

	it("registers all builtin commands by default", function()
		cr.setup()

		assert.same({ "vitest current file", "vitest all", "Playwright current file" }, labels("ts"))
		assert.same(
			{ "dotnet test current file", "dotnet test current namespace", "dotnet test solution" },
			labels("cs")
		)
		assert.same({ "Plenary test all" }, labels("lua"))
		assert.same({ "mix compile", "mix test", "mix release", "mix phx.server" }, labels("ex"))
		assert.same({ "mix compile", "mix test", "mix release", "mix phx.server" }, labels("exs"))
		assert.same({ "mix new", "phx new" }, labels(":directory"))
	end)

	it("lets a builtin be disabled via opts.builtin", function()
		cr.setup({ builtin = { ts_vitest = { enable = false } } })
		assert.same({ "Playwright current file" }, labels("ts"))
	end)

	it("registers user commands from opts.commands", function()
		local mycmd = {
			label = "run script",
			cmd = function()
				return { command_line = "python x.py" }
			end,
		}
		cr.setup({ commands = { py = { mycmd } } })
		assert.equals(mycmd, cr._commands.py[1])
	end)

	it("appends user commands to an existing builtin extension", function()
		cr.setup({
			commands = {
				ts = { { label = "tsc", cmd = function() return {} end } },
			},
		})
		assert.same({ "vitest current file", "vitest all", "Playwright current file", "tsc" }, labels("ts"))
	end)

	it("loads commands from a project-local .nvim/command_runner.lua", function()
		local proj = vim.fn.tempname()
		vim.fn.mkdir(proj .. "/.nvim", "p")
		local f = assert(io.open(proj .. "/.nvim/command_runner.lua", "w"))
		f:write('return { rb = { { label = "rake", cmd = function() return { command_line = "rake" } end } } }')
		f:close()

		root_ret = proj
		cr.setup()

		assert.same({ "rake" }, labels("rb"))
		vim.fn.delete(proj, "rf")
	end)

	it("ignores a project-local file that does not return a table", function()
		local proj = vim.fn.tempname()
		vim.fn.mkdir(proj .. "/.nvim", "p")
		local f = assert(io.open(proj .. "/.nvim/command_runner.lua", "w"))
		f:write("return 42")
		f:close()

		root_ret = proj
		assert.has_no.errors(function()
			cr.setup()
		end)

		vim.fn.delete(proj, "rf")
	end)

	it("_register creates a new extension list and appends to it", function()
		local a = { label = "a", cmd = function() return {} end }
		local b = { label = "b", cmd = function() return {} end }

		cr._register("go", { a })
		cr._register("go", { b })

		assert.same({ a, b }, cr._commands.go)
	end)
end)
