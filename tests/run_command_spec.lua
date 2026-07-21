describe("command_runner.run_command", function()
	local cr
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

	local function register(commands, opts)
		local setup_opts = {
			builtin = false,
			commands = commands,
		}
		for k, v in pairs(opts or {}) do
			setup_opts[k] = v
		end
		cr.setup(setup_opts)
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

		-- The dispatch module captures `require("terminal")` at load time, so
		-- preload the mock and drop the cached modules to rebind them per test.
		-- (terminal.nvim is a runtime dependency that cannot run headless.)
		package.loaded["terminal"] = terminal_mock
		package.loaded["command_runner.commands"] = nil
		package.loaded["command_runner"] = nil
		cr = require("command_runner")

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
		package.loaded["command_runner"] = nil
		package.loaded["terminal"] = nil
	end)

	describe("given a terminal command is selected for the current file", function()
		local buf
		local sent

		before_each(function()
			buf = set_current_file("a.ts")
			vim.api.nvim_buf_set_var(buf, "terminal_job_id", 4242)
			-- precondition: the current buffer carries a running terminal job
			assert.equals(4242, vim.b[buf].terminal_job_id)

			sent = {}
			replace(vim.api, "nvim_chan_send", function(id, data)
				table.insert(sent, { id = id, data = data })
			end)
			replace(vim.ui, "select", function(_, _, cb)
				cb("run")
			end)
		end)

		it("should open a terminal in the command's dir and send the command line", function()
			register({
				ts = {
					{
						label = "run",
						cmd = function()
							return { type = "terminal", dir = "/proj", command_line = "npx vitest" }
						end,
					},
				},
			})

			cr.run_command()

			assert.same({ "/proj" }, terminal_mock.calls)
			assert.same({ { id = 4242, data = "npx vitest && sleep 3 && exit\n" } }, sent)
		end)

		it("should default to terminal execution when the command type is omitted", function()
			register({
				ts = {
					{
						label = "run",
						cmd = function()
							return { dir = "/proj", command_line = "ls" }
						end,
					},
				},
			})

			cr.run_command()

			assert.same({ "/proj" }, terminal_mock.calls)
			assert.same({ { id = 4242, data = "ls && sleep 3 && exit\n" } }, sent)
		end)

		describe("autoclose", function()
			local commands = {
				ts = {
					{
						label = "run",
						cmd = function()
							return { dir = "/proj", command_line = "make" }
						end,
					},
				},
			}

			it("should not append anything when autoclose_on_success is false", function()
				register(commands, { autoclose_on_success = false })

				cr.run_command()

				assert.same({ { id = 4242, data = "make\n" } }, sent)
			end)

			it("should exit without a sleep when the delay is 0", function()
				register(commands, { autoclose_delay_in_seconds = 0 })

				cr.run_command()

				assert.same({ { id = 4242, data = "make && exit\n" } }, sent)
			end)

			it("should sleep for the configured delay", function()
				register(commands, { autoclose_delay_in_seconds = 10 })

				cr.run_command()

				assert.same({ { id = 4242, data = "make && sleep 10 && exit\n" } }, sent)
			end)
		end)
	end)

	describe("on win32", function()
		local buf
		local sent

		before_each(function()
			replace(vim.fn, "has", function(feature)
				if feature == "win32" then
					return 1
				end
				return 0
			end)

			-- `is_win32`/`line_ending` are computed once at module load time,
			-- so the mock above must be in place before the module (re)loads.
			package.loaded["command_runner.commands"] = nil
			package.loaded["command_runner"] = nil
			cr = require("command_runner")

			buf = set_current_file("a.ts")
			vim.api.nvim_buf_set_var(buf, "terminal_job_id", 4242)

			sent = {}
			replace(vim.api, "nvim_chan_send", function(id, data)
				table.insert(sent, { id = id, data = data })
			end)
			replace(vim.ui, "select", function(_, _, cb)
				cb("run")
			end)

			register({
				ts = {
					{
						label = "run",
						cmd = function()
							return { dir = "/proj", command_line = "make" }
						end,
					},
				},
			}, { autoclose_delay_in_seconds = 10 })
		end)

		it("should use [Environment]::Exit(0) instead of exit and \\r as the line ending", function()
			cr.run_command()

			assert.same(
				{ { id = 4242, data = "make && sleep 10 && [Environment]::Exit(0)\r" } },
				sent
			)
		end)
	end)

	describe("given an nvim command is selected for the current file", function()
		local ran

		before_each(function()
			set_current_file("a.lua")

			ran = {}
			replace(vim, "cmd", function(c)
				ran[#ran + 1] = c
			end)
			replace(vim.ui, "select", function(_, _, cb)
				cb("plenary")
			end)
		end)

		it("should run the command line via vim.cmd and not open a terminal", function()
			register({
				lua = {
					{
						label = "plenary",
						cmd = function()
							return { type = "nvim", command_line = "PlenaryBustedDirectory x" }
						end,
					},
				},
			})

			cr.run_command()

			assert.same({ "PlenaryBustedDirectory x" }, ran)
			assert.equals(0, #terminal_mock.calls)
		end)
	end)

	describe("given the current buffer has a registered extension", function()
		local offered

		before_each(function()
			local buf = set_current_file("a.ts")
			assert.equals("ts", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":e"))

			offered = nil
			replace(vim.ui, "select", function(items, _, _)
				offered = items
			end)
		end)

		it("should only offer commands whose filter passes", function()
			register({
				ts = {
					{
						label = "always",
						cmd = function()
							return {}
						end,
					},
					{
						label = "never",
						filter = function()
							return false
						end,
						cmd = function()
							return {}
						end,
					},
					{
						label = "yes",
						filter = function()
							return true
						end,
						cmd = function()
							return {}
						end,
					},
				},
			})

			cr.run_command()

			assert.same({ "always", "yes" }, offered)
		end)

		it("should offer the commands in alphabetical order", function()
			register({
				ts = {
					{
						label = "run tests",
						cmd = function()
							return {}
						end,
					},
					{
						label = "build",
						cmd = function()
							return {}
						end,
					},
					{
						label = "lint",
						cmd = function()
							return {}
						end,
					},
				},
			})

			cr.run_command()

			assert.same({ "build", "lint", "run tests" }, offered)
		end)
	end)

	describe("given the current buffer has no extension", function()
		local offered

		before_each(function()
			local buf = set_current_file("somedir")
			assert.equals("", vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":e"))

			offered = nil
			replace(vim.ui, "select", function(items, _, _)
				offered = items
			end)
		end)

		it("should offer the ':directory' command list", function()
			register({
				[":directory"] = { {
					label = "mix new",
					cmd = function()
						return {}
					end,
				} },
				ts = { {
					label = "ts-thing",
					cmd = function()
						return {}
					end,
				} },
			})

			cr.run_command()

			assert.same({ "mix new" }, offered)
		end)
	end)

	describe("given the current buffer's extension has no registered commands", function()
		local offered

		before_each(function()
			set_current_file("a.py")

			offered = nil
			replace(vim.ui, "select", function(items, _, _)
				offered = items
			end)
		end)

		it("should offer nothing", function()
			register({
				ts = { {
					label = "x",
					cmd = function()
						return {}
					end,
				} },
			})

			cr.run_command()

			assert.same({}, offered)
		end)
	end)

	describe("given a command was run before", function()
		local sent
		local select_response

		before_each(function()
			local buf = set_current_file("a.ts")
			vim.api.nvim_buf_set_var(buf, "terminal_job_id", 4242)

			sent = {}
			replace(vim.api, "nvim_chan_send", function(id, data)
				table.insert(sent, { id = id, data = data })
			end)
			replace(vim.ui, "select", function(_, _, cb)
				cb(select_response)
			end)

			register({
				ts = {
					{
						label = "run",
						cmd = function()
							return { dir = "/proj", command_line = "make" }
						end,
					},
					{
						label = "build",
						cmd = function()
							return { dir = "/elsewhere", command_line = "build" }
						end,
					},
				},
			})

			select_response = "run"
			cr.run_command()
			assert.same({ "/proj" }, terminal_mock.calls)
		end)

		it("should describe what rerun_command would execute", function()
			assert.equals("Rerun: run — make — /proj", cr.rerun_command_description())
		end)

		it("should replay the stored command via rerun_command without showing the picker", function()
			local buf2 = set_current_file("b.py")
			vim.api.nvim_buf_set_var(buf2, "terminal_job_id", 777)
			replace(vim.ui, "select", function()
				error("the picker should not be shown on rerun_command")
			end)

			cr.rerun_command()

			assert.same({ "/proj", "/proj" }, terminal_mock.calls)
			assert.same({ id = 777, data = "make && sleep 3 && exit\n" }, sent[#sent])
		end)

		it("should offer the executed command in show_history", function()
			local offered
			replace(vim.ui, "select", function(items, _, cb)
				offered = items
				cb(nil)
			end)

			cr.show_history()

			assert.same({ "run — make — /proj" }, offered)
		end)

		it("should replay the selected history entry verbatim regardless of the current buffer", function()
			local buf2 = set_current_file("b.py")
			vim.api.nvim_buf_set_var(buf2, "terminal_job_id", 777)
			replace(vim.ui, "select", function(_, _, cb)
				cb("run — make — /proj")
			end)

			cr.show_history()

			assert.same({ "/proj", "/proj" }, terminal_mock.calls)
			assert.same({ id = 777, data = "make && sleep 3 && exit\n" }, sent[#sent])
		end)

		it("should not duplicate a repeated command, moving it to the front instead", function()
			select_response = "build"
			cr.run_command()

			select_response = "run"
			cr.run_command()

			local offered
			replace(vim.ui, "select", function(items, _, cb)
				offered = items
				cb(nil)
			end)

			cr.show_history()

			assert.same({ "run — make — /proj", "build — build — /elsewhere" }, offered)
		end)

		it("should move a selected history entry to the front", function()
			select_response = "build"
			cr.run_command()
			-- history is now [build — build — /elsewhere, run — make — /proj]

			replace(vim.ui, "select", function(_, _, cb)
				cb("run — make — /proj")
			end)
			cr.show_history()
			-- selecting the older "run" entry should move it back to the front

			local buf2 = set_current_file("b.py")
			vim.api.nvim_buf_set_var(buf2, "terminal_job_id", 777)
			replace(vim.ui, "select", function()
				error("the picker should not be shown on rerun_command")
			end)

			cr.rerun_command()

			assert.same({ id = 777, data = "make && sleep 3 && exit\n" }, sent[#sent])
		end)

		it("should keep same-label commands as distinct entries when their resolved dir differs", function()
			register({
				ts = {
					{
						label = "run",
						cmd = function(filename)
							return { dir = vim.fs.dirname(filename), command_line = "make" }
						end,
					},
				},
			})

			local buf1 = set_current_file("x.ts")
			local dir1 = vim.fs.dirname(vim.api.nvim_buf_get_name(buf1))
			select_response = "run"
			cr.run_command()

			local buf2 = set_current_file("y.ts")
			local dir2 = vim.fs.dirname(vim.api.nvim_buf_get_name(buf2))
			cr.run_command()

			local offered
			replace(vim.ui, "select", function(items, _, cb)
				offered = items
				cb(nil)
			end)

			cr.show_history()

			assert.same({
				"run — make — " .. dir2,
				"run — make — " .. dir1,
				"run — make — /proj",
			}, offered)
		end)
	end)

	describe("given history_size is configured", function()
		it("should drop the oldest entries beyond the configured cap", function()
			set_current_file("a.ts")

			local select_response
			replace(vim.ui, "select", function(items, _, cb)
				cb(select_response)
			end)

			register({
				ts = {
					{
						label = "one",
						cmd = function()
							return { dir = "/one", command_line = "one" }
						end,
					},
					{
						label = "two",
						cmd = function()
							return { dir = "/two", command_line = "two" }
						end,
					},
					{
						label = "three",
						cmd = function()
							return { dir = "/three", command_line = "three" }
						end,
					},
				},
			}, { history_size = 2 })

			select_response = "one"
			cr.run_command()
			select_response = "two"
			cr.run_command()
			select_response = "three"
			cr.run_command()

			local offered
			replace(vim.ui, "select", function(items, _, cb)
				offered = items
				cb(nil)
			end)

			cr.show_history()

			assert.same({ "three — three — /three", "two — two — /two" }, offered)
		end)
	end)

	describe("given no command was run before", function()
		it("should warn and run nothing when rerun_command is called", function()
			set_current_file("a.ts")
			register({})

			local notified
			replace(vim, "notify", function(msg, level)
				notified = { msg = msg, level = level }
			end)
			replace(vim.ui, "select", function()
				error("the picker should not be shown on rerun_command")
			end)

			cr.rerun_command()

			assert.equals(0, #terminal_mock.calls)
			assert.equals(vim.log.levels.WARN, notified.level)
		end)

		it("should return nil from rerun_command_description", function()
			set_current_file("a.ts")
			register({})

			assert.is_nil(cr.rerun_command_description())
		end)

		it("should do nothing when show_history is called", function()
			set_current_file("a.ts")
			register({})

			replace(vim.ui, "select", function()
				error("the picker should not be shown when history is empty")
			end)

			cr.show_history()

			assert.equals(0, #terminal_mock.calls)
		end)
	end)

	describe("given the user cancels the selection", function()
		before_each(function()
			set_current_file("a.ts")

			replace(vim, "cmd", function()
				error("vim.cmd should not be called on cancel")
			end)
			replace(vim.ui, "select", function(_, _, cb)
				cb(nil)
			end)
		end)

		it("should not run anything", function()
			register({
				ts = {
					{
						label = "run",
						cmd = function()
							error("cmd should not be built on cancel")
						end,
					},
				},
			})

			cr.run_command()

			assert.equals(0, #terminal_mock.calls)
		end)
	end)
end)
