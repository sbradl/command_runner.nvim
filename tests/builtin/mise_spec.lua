local mise = require("command_runner.builtin.mise")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/mise"

describe("command_runner.builtin.mise", function()
	it("should register for every extension", function()
		assert.same({ "*" }, mise.extensions)
	end)

	describe("get_project_dir", function()
		it("should find the directory containing mise.toml", function()
			assert.equals(data .. "/proj", mise.get_project_dir(data .. "/proj/src/a.ts"))
		end)

		it("should return nil outside a mise project", function()
			assert.is_nil(mise.get_project_dir(data .. "/bare/a.ts"))
		end)
	end)

	describe("the mise tasks command", function()
		local cmd
		local restore_system

		before_each(function()
			cmd = find_command(mise.commands, "mise run")
		end)

		after_each(function()
			if restore_system then
				restore_system()
				restore_system = nil
			end
		end)

		-- The builtin shells out to the mise CLI, which is not available in CI.
		local function stub_mise(result, capture)
			local orig = vim.system
			restore_system = function()
				vim.system = orig
			end
			vim.system = function(argv, opts)
				if capture then
					capture.argv = argv
					capture.opts = opts
				end
				return {
					wait = function()
						return result
					end,
				}
			end
		end

		describe("given a file inside a mise project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/src/a.ts"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should offer one 'mise run <task>' entry per task reported by mise", function()
				local capture = {}
				stub_mise({
					code = 0,
					stdout = vim.json.encode({
						{ name = "build", source = root .. "/mise.toml" },
						{ name = "test", source = root .. "/mise.toml" },
					}),
				}, capture)

				local out = cmd.expand(file)

				assert.same({ "mise", "tasks", "ls", "--json" }, capture.argv)
				assert.equals(root, capture.opts.cwd)
				assert.same(
					{ "mise run build", "mise run test" },
					vim.tbl_map(function(d)
						return d.label
					end, out)
				)
			end)

			it("should build each entry rooted at the project", function()
				stub_mise({
					code = 0,
					stdout = vim.json.encode({ { name = "build" } }),
				})

				local out = cmd.expand(file)
				local built = find_command(out, "mise run build").cmd(file)

				assert.equals(root, built.dir)
				assert.equals("mise run build", built.command_line)
			end)

			it("should offer nothing when mise exits non-zero", function()
				stub_mise({ code = 1, stdout = "" })

				assert.same({}, cmd.expand(file))
			end)

			it("should offer nothing when mise output is not valid json", function()
				stub_mise({ code = 0, stdout = "not json" })

				assert.same({}, cmd.expand(file))
			end)
		end)

		describe("given a file outside any mise project", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(data .. "/bare/a.ts"))
			end)
		end)
	end)
end)
