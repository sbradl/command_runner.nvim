local mix = require("command_runner.builtin.ex_mix")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/elixir_mix"

describe("command_runner.builtin.elixir_mix", function()
	describe("get_project_dir", function()
		describe("given a file inside a mix project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/lib/foo.ex"
			end)

			it("should return the directory containing mix.exs", function()
				assert.equals(root, mix.get_project_dir(file))
			end)
		end)
	end)

	describe("mix compile", function()
		local cmd

		before_each(function()
			cmd = find_command(mix.commands, "mix compile")
		end)

		describe("given a file inside a mix project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/lib/foo.ex"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build the mix compile command rooted at the project", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("mix compile", out.command_line)
			end)
		end)

		describe("given a file outside any mix project", function()
			local file

			before_each(function()
				file = data .. "/bare/foo.ex"

				assert.is_nil(mix.get_project_dir(file))
			end)

			it("should not be available", function()
				assert.is_false(cmd.filter(file))
			end)
		end)
	end)

	describe("mix test", function()
		local cmd

		before_each(function()
			cmd = find_command(mix.commands, "mix test")
		end)

		describe("given a file inside a mix project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/lib/foo.ex"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build the mix test command rooted at the project", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("mix test", out.command_line)
			end)
		end)

		describe("given a file outside any mix project", function()
			local file

			before_each(function()
				file = data .. "/bare/foo.ex"

				assert.is_nil(mix.get_project_dir(file))
			end)

			it("should not be available", function()
				assert.is_false(cmd.filter(file))
			end)
		end)
	end)

	describe("mix release", function()
		local cmd

		before_each(function()
			cmd = find_command(mix.commands, "mix release")
		end)

		describe("given a file inside a mix project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/lib/foo.ex"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build the mix release command rooted at the project", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("mix release", out.command_line)
			end)
		end)

		describe("given a file outside any mix project", function()
			local file

			before_each(function()
				file = data .. "/bare/foo.ex"

				assert.is_nil(mix.get_project_dir(file))
			end)

			it("should not be available", function()
				assert.is_false(cmd.filter(file))
			end)
		end)
	end)

	describe("mix new", function()
		local cmd

		before_each(function()
			cmd = find_command(mix.directory_commands, "mix new")
		end)

		it("should build 'mix new .' in the given directory", function()
			local out = cmd.cmd("/some/dir")

			assert.equals("/some/dir", out.dir)
			assert.equals("mix new .", out.command_line)
		end)
	end)
end)
