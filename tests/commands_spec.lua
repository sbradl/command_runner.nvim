describe("command_runner.commands (dispatch)", function()
	local commands
	local terminal_mock
	local restores
	local file_counter = 0

	local function replace(tbl, key, fn)
		local orig = tbl[key]
		table.insert(restores, function()
			tbl[key] = orig
		end)
		tbl[key] = fn
	end

	-- Make `basename` the current buffer. A per-test counter keeps buffer names
	-- unique (Neovim rejects two buffers with the same name). The extension of
	-- `basename` drives which command list is offered.
	local function set_current_file(basename)
		file_counter = file_counter + 1
		local name = string.format("/tmp/cr_spec_%d/%s", file_counter, basename)
		local buf = vim.api.nvim_create_buf(true, false)
		vim.api.nvim_buf_set_name(buf, name)
		vim.api.nvim_set_current_buf(buf)
		return buf
	end

	before_each(function()
		restores = {}

		terminal_mock = { calls = {} }
		terminal_mock.open_new_terminal = function(dir)
			table.insert(terminal_mock.calls, dir)
		end

		-- commands.lua captures `require("terminal")` at load time, so preload the
		-- mock and drop the cached module to rebind it to the fresh mock per test.
		package.loaded["terminal"] = terminal_mock
		package.loaded["command_runner.commands"] = nil
		commands = require("command_runner.commands")

		-- The terminal write is deferred; run it synchronously in tests.
		replace(vim, "defer_fn", function(fn)
			fn()
		end)
	end)

	after_each(function()
		for _, r in ipairs(restores) do
			r()
		end
		package.loaded["command_runner.commands"] = nil
		package.loaded["terminal"] = nil
	end)

	it("runs a terminal command: opens a terminal in dir and sends the command line", function()
		local buf = set_current_file("a.ts")
		vim.api.nvim_buf_set_var(buf, "terminal_job_id", 4242)

		local sent = {}
		replace(vim.api, "nvim_chan_send", function(id, data)
			table.insert(sent, { id = id, data = data })
		end)
		replace(vim.ui, "select", function(_, _, cb)
			cb("run")
		end)

		commands.choose_and_run_command({
			ts = {
				{
					label = "run",
					cmd = function()
						return { dir = "/proj", command_line = "npx vitest" }
					end,
				},
			},
		})

		assert.same({ "/proj" }, terminal_mock.calls)
		assert.same({ { id = 4242, data = "npx vitest\n" } }, sent)
	end)

	it("defaults to terminal execution when the type is omitted", function()
		local buf = set_current_file("a.ts")
		vim.api.nvim_buf_set_var(buf, "terminal_job_id", 7)

		local sent = {}
		replace(vim.api, "nvim_chan_send", function(_, data)
			sent[#sent + 1] = data
		end)
		replace(vim.ui, "select", function(_, _, cb)
			cb("run")
		end)

		commands.choose_and_run_command({
			ts = {
				{
					label = "run",
					cmd = function()
						return { dir = "/proj", command_line = "ls" }
					end,
				},
			},
		})

		assert.same({ "/proj" }, terminal_mock.calls)
		assert.same({ "ls\n" }, sent)
	end)

	it("runs an nvim command via vim.cmd and does not open a terminal", function()
		set_current_file("a.lua")

		local ran = {}
		replace(vim, "cmd", function(c)
			ran[#ran + 1] = c
		end)
		replace(vim.ui, "select", function(_, _, cb)
			cb("plenary")
		end)

		commands.choose_and_run_command({
			lua = {
				{
					label = "plenary",
					cmd = function()
						return { type = "nvim", command_line = "PlenaryBustedDirectory x" }
					end,
				},
			},
		})

		assert.same({ "PlenaryBustedDirectory x" }, ran)
		assert.equals(0, #terminal_mock.calls)
	end)

	it("only offers commands whose filter passes", function()
		set_current_file("a.ts")

		local offered
		replace(vim.ui, "select", function(items, _, _)
			offered = items
		end)

		commands.choose_and_run_command({
			ts = {
				{ label = "always", cmd = function() return {} end },
				{ label = "never", filter = function() return false end, cmd = function() return {} end },
				{ label = "yes", filter = function() return true end, cmd = function() return {} end },
			},
		})

		assert.same({ "always", "yes" }, offered)
	end)

	it("uses the ':directory' key for buffers without an extension", function()
		set_current_file("somedir")

		local offered
		replace(vim.ui, "select", function(items, _, _)
			offered = items
		end)

		commands.choose_and_run_command({
			[":directory"] = { { label = "mix new", cmd = function() return {} end } },
			ts = { { label = "ts-thing", cmd = function() return {} end } },
		})

		assert.same({ "mix new" }, offered)
	end)

	it("offers nothing for an extension with no registered commands", function()
		set_current_file("a.py")

		local offered
		replace(vim.ui, "select", function(items, _, _)
			offered = items
		end)

		commands.choose_and_run_command({
			ts = { { label = "x", cmd = function() return {} end } },
		})

		assert.same({}, offered)
	end)

	it("does nothing when the selection is cancelled", function()
		set_current_file("a.ts")

		replace(vim, "cmd", function()
			error("vim.cmd should not be called on cancel")
		end)
		replace(vim.ui, "select", function(_, _, cb)
			cb(nil)
		end)

		commands.choose_and_run_command({
			ts = {
				{
					label = "run",
					cmd = function()
						error("cmd should not be built on cancel")
					end,
				},
			},
		})

		assert.equals(0, #terminal_mock.calls)
	end)

	it("open_terminal_and_run_command sends the command line to the terminal channel", function()
		local buf = set_current_file("a.ts")
		vim.api.nvim_buf_set_var(buf, "terminal_job_id", 99)

		local sent = {}
		replace(vim.api, "nvim_chan_send", function(id, data)
			sent[#sent + 1] = { id, data }
		end)

		commands.open_terminal_and_run_command({ dir = "/work", command_line = "make" })

		assert.same({ "/work" }, terminal_mock.calls)
		assert.same({ { 99, "make\n" } }, sent)
	end)

	it("does not send anything when the new buffer has no terminal_job_id", function()
		set_current_file("a.ts")

		local sent = 0
		replace(vim.api, "nvim_chan_send", function()
			sent = sent + 1
		end)

		commands.open_terminal_and_run_command({ dir = "/work", command_line = "make" })

		assert.same({ "/work" }, terminal_mock.calls)
		assert.equals(0, sent)
	end)
end)
