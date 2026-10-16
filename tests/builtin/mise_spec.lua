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

			it("should show the task description after the command", function()
				stub_mise({
					code = 0,
					stdout = vim.json.encode({
						{ name = "build", description = "Build it\nmore detail" },
						{ name = "test", description = "" },
						{ name = "long", description = string.rep("x", 70) },
					}),
				})

				local out = cmd.expand(file)

				assert.same(
					{ "mise run build — Build it", "mise run test", "mise run long — " .. string.rep("x", 59) .. "…" },
					vim.tbl_map(function(d)
						return d.label
					end, out)
				)
				assert.equals("mise run build", out[1].cmd(file).command_line)
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

		describe("filling task usage args from the current buffer", function()
			local sln = vim.fn.getcwd() .. "/tests/testdata/dotnet_test/mtp_solution"
			local test_file = sln .. "/proj/FooTests.cs"

			-- Answers `mise tasks ls` with `tasks` and `mise tasks info` with `info`.
			local function stub_mise_tasks(tasks, info)
				local orig = vim.system
				restore_system = function()
					vim.system = orig
				end
				vim.system = function(argv)
					local stdout = vim.json.encode(argv[3] == "info" and (info or {}) or tasks)
					return {
						wait = function()
							return { code = 0, stdout = stdout }
						end,
					}
				end
			end

			--- Labels offered for `file` with the cursor on `line`.
			local function offered(file, line)
				vim.cmd("edit " .. vim.fn.fnameescape(file))
				vim.api.nvim_win_set_cursor(0, { line or 1, 0 })
				return vim.tbl_map(function(d)
					return d.label
				end, cmd.expand(file, vim.api.nvim_get_current_buf()))
			end

			local function pick(file, task, line)
				vim.cmd("edit " .. vim.fn.fnameescape(file))
				vim.api.nvim_win_set_cursor(0, { line or 1, 0 })
				local buf = vim.api.nvim_get_current_buf()
				return find_command(cmd.expand(file, buf), "mise run " .. task).cmd(file, buf)
			end

			after_each(function()
				vim.cmd("%bwipeout!")
			end)

			it("should pass dotnet context relative to the task dir, plus provided flags", function()
				local usage = 'flag "--mtp"\narg "<test_class>"\narg "<test_method>"\narg "<project>"\n'
				stub_mise_tasks({ { name = "dotnet:test-method", usage = usage, dir = sln } }, {
					usage_spec = {
						cmd = {
							flags = { { name = "mtp" } },
							args = { { name = "test_class" }, { name = "test_method" }, { name = "project" } },
						},
					},
				})

				assert.equals(
					"mise run dotnet:test-method --mtp 'FooTests' 'Should_Return_True' 'proj/proj.csproj'",
					pick(test_file, "dotnet:test-method", 8).command_line
				)
			end)

			it("should stop at the first arg no provider can fill", function()
				local root = data .. "/proj"
				stub_mise_tasks({ { name = "x", dir = root } }, {
					usage_spec = { cmd = { args = { { name = "file" }, { name = "unknown" }, { name = "line" } } } },
				})

				assert.equals("mise run x 'src/a.ts'", pick(root .. "/src/a.ts", "x").command_line)
			end)

			it("should pass the file's package dir './'-prefixed", function()
				local root = data .. "/proj"
				stub_mise_tasks({ { name = "go:run", dir = root } }, {
					usage_spec = { cmd = { args = { { name = "dir" } } } },
				})

				assert.equals("mise run go:run './src'", pick(root .. "/src/a.ts", "go:run").command_line)
			end)

			describe("availability", function()
				before_each(function()
					stub_mise_tasks({
						{ name = "needs-test-class", usage = 'arg "<test_class>"\n', dir = sln },
						{ name = "needs-test-method", usage = 'arg "<test_method>"\n', dir = sln },
						{ name = "optional-test-class", usage = 'arg "[test_class]"\n', dir = sln },
						{ name = "custom-arg", usage = 'arg "<environment>"\n', dir = sln },
						{ name = "no-usage", usage = "", dir = sln },
					})
				end)

				it("should offer tasks whose required args are all provided in a C# test file", function()
					assert.same({
						"mise run needs-test-class",
						"mise run needs-test-method",
						"mise run optional-test-class",
						"mise run custom-arg",
						"mise run no-usage",
					}, offered(test_file, 8))
				end)

				it("should hide test_* tasks outside C# test files", function()
					local plain = vim.fn.tempname() .. ".cs"
					vim.fn.writefile({ "namespace proj;", "public class Foo", "{", "    public void Bar() {}", "}" }, plain)

					assert.same(
						{ "mise run optional-test-class", "mise run custom-arg", "mise run no-usage" },
						offered(plain, 4)
					)
					assert.same(
						{ "mise run optional-test-class", "mise run custom-arg", "mise run no-usage" },
						offered(data .. "/proj/src/a.ts")
					)
				end)

				it("should hide test_method tasks when the cursor is above every method", function()
					assert.is_false(vim.tbl_contains(offered(test_file, 1), "mise run needs-test-method"))
					assert.is_true(vim.tbl_contains(offered(test_file, 1), "mise run needs-test-class"))
				end)
			end)
		end)

		describe("given a file outside any mise project", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(data .. "/bare/a.ts"))
			end)
		end)
	end)
end)
