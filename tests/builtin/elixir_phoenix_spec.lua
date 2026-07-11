local phx = require("command_runner.builtin.ex_phoenix")

local data = vim.fn.getcwd() .. "/tests/testdata/elixir_phoenix"

local find_command = require("tests/test_util").find_command

describe("command_runner.builtin.elixir_phoenix", function()
	describe("get_project_dir", function()
		describe("given a file inside a mix project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/lib/app.ex"
			end)

			it("should return the directory containing mix.exs", function()
				assert.equals(root, phx.get_project_dir(file))
			end)
		end)
	end)

	describe("mix phx.server", function()
		local cmd

		before_each(function()
			cmd = find_command(phx.commands, "mix phx.server")
		end)

		describe("given a file inside a mix project", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/lib/app.ex"
			end)

			it("should be offered by the filter", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build the mix phx.server command", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("mix phx.server", out.command_line)
			end)
		end)

		describe("given a file outside any mix project", function()
			local file

			before_each(function()
				file = data .. "/bare/app.ex"

				assert.is_nil(phx.get_project_dir(file))
			end)

			it("should not be offered by the filter", function()
				assert.is_false(cmd.filter(file))
			end)
		end)
	end)

	describe("phx new", function()
		local cmd

		before_each(function()
			cmd = find_command(phx.directory_commands, "phx new")
		end)

		it("should build the phx.new command in the given directory", function()
			local out = cmd.cmd("/dir")

			assert.equals("/dir", out.dir)
			assert.equals("mix archive.install hex phx_new && mix phx.new .", out.command_line)
		end)
	end)
end)
