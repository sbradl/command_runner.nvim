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
		describe("given default options", function()
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

				local ts_labels = labels("ts")
				local vitest = require("command_runner.builtin.ts_vitest")
				local playwright = require("command_runner.builtin.ts_playwright")

				for _, cmd in ipairs(vitest.commands) do
					assert.is_false(vim.tbl_contains(ts_labels, cmd.label), cmd.label .. " should be disabled")
				end
				for _, cmd in ipairs(playwright.commands) do
					assert.is_true(vim.tbl_contains(ts_labels, cmd.label), cmd.label .. " should remain registered")
				end
			end)

			it("should disable all builtins when opts.builtin is false", function()
				cr.setup({ builtin = false })

				assert.same({}, cr.get_commands())
			end)
		end)
	end)
end)
