local data = vim.fn.getcwd() .. "/tests/testdata/command_runner"

local cr = require("command_runner")

describe("command_runner", function()
	local function labels(ext)
		local out = {}
		for _, c in ipairs(cr.get_commands(ext)) do
			out[#out + 1] = c.label
		end
		return out
	end

	before_each(function()
		vim.cmd("enew")
	end)

	describe("setup", function()
		describe("given no project-local config", function()
			before_each(function()
				assert.is_nil(vim.fs.root(0, ".nvim"))
			end)

			it("should register every builtin's commands by default", function()
				cr.setup()

				local registered = {}
				for _, command_list in pairs(cr.get_commands()) do
					for _, cmd in ipairs(command_list) do
						registered[cmd] = true
					end
				end

				local builtin_dir = vim.fn.getcwd() .. "/lua/command_runner/builtin"
				for name, kind in vim.fs.dir(builtin_dir) do
					if kind == "file" and name:match("%.lua$") then
						local mod = require("command_runner.builtin." .. name:gsub("%.lua$", ""))
						for _, cmd in ipairs(mod.commands or {}) do
							assert.is_true(registered[cmd], name .. " commands should be registered")
						end
						for _, cmd in ipairs(mod.directory_commands or {}) do
							assert.is_true(registered[cmd], name .. " directory_commands should be registered")
						end
					end
				end
			end)

			it("should let builtins be disabled via opts.builtin.disable", function()
				cr.setup({ builtin = { disable = { "ts_vitest" } } })

				assert.same({ "Playwright current file" }, labels("ts"))
			end)

			it("should disable all builtins when opts.builtin is false", function()
				cr.setup({ builtin = false })

				assert.same({}, cr.get_commands())
			end)

			it("should register user commands from opts.commands", function()
				local mycmd = {
					label = "run script",
					cmd = function()
						return { command_line = "python x.py" }
					end,
				}

				cr.setup({ commands = { py = { mycmd } } })

				assert.equals(mycmd, cr.get_commands("py")[1])
			end)

			it("should append user commands to an existing builtin extension", function()
				cr.setup({
					commands = {
						ts = {
							{
								label = "tsc",
								cmd = function()
									return {}
								end,
							},
						},
					},
				})
				assert.same({ "vitest current file", "vitest all", "Playwright current file", "tsc" }, labels("ts"))
			end)
		end)

		describe("given a project with a .nvim/command_runner.lua", function()
			before_each(function()
				vim.cmd.edit(data .. "/with_config/src/foo.rb")
				assert.equals(data .. "/with_config", vim.fs.root(0, ".nvim"))
			end)

			it("should register the commands it returns", function()
				cr.setup()
				assert.same({ "rake" }, labels("rb"))
			end)
		end)

		describe("given a project whose .nvim/command_runner.lua does not return a table", function()
			before_each(function()
				vim.cmd.edit(data .. "/bad_config/src/foo.rb")
				assert.equals(data .. "/bad_config", vim.fs.root(0, ".nvim"))
			end)

			it("should report an error so the user knows their config is faulty", function()
				local notified_level
				local original_notify = vim.notify
				vim.notify = function(_, level)
					if level == vim.log.levels.ERROR then
						notified_level = level
					end
				end

				local ok, err = pcall(cr.setup)

				vim.notify = original_notify

				assert.is_true(ok, err) -- reported, not raised
				assert.equals(vim.log.levels.ERROR, notified_level)
			end)
		end)

		describe("given a project whose .nvim/command_runner.lua returns an empty table", function()
			before_each(function()
				vim.cmd.edit(data .. "/empty_config/src/foo.rb")
				assert.equals(data .. "/empty_config", vim.fs.root(0, ".nvim"))
			end)

			it("should accept it without raising an error", function()
				assert.has_no.errors(function()
					cr.setup()
				end)
			end)
		end)
	end)
end)
