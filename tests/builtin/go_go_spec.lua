local go = require("command_runner.builtin.go_go")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/go_go"

describe("command_runner.builtin.go_go", function()
	describe("get_project_dir", function()
		describe("given a file inside a go module", function()
			it("should return the directory containing go.mod", function()
				assert.equals(data .. "/proj", go.get_project_dir(data .. "/proj/cmd/app/main.go"))
			end)
		end)

		describe("given a file outside any go module", function()
			it("should return nil", function()
				assert.is_nil(go.get_project_dir(data .. "/bare/main.go"))
			end)
		end)
	end)

	describe("'go run current package' command", function()
		local cmd

		before_each(function()
			cmd = find_command(go.commands, "go run current package")
		end)

		describe("given a file inside a go module", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/cmd/app/main.go"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should run the package holding the file, rooted at the module", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("go run ./cmd/app", out.command_line)
			end)

			it("should use '.' for a file at the module root", function()
				local out = cmd.cmd(root .. "/main.go")

				assert.equals("go run .", out.command_line)
			end)
		end)

		describe("given a file outside any go module", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(data .. "/bare/main.go"))
			end)
		end)
	end)

	describe("'go build' command", function()
		local cmd

		before_each(function()
			cmd = find_command(go.commands, "go build")
		end)

		describe("given a file inside a go module", function()
			local root
			local file

			before_each(function()
				root = data .. "/proj"
				file = root .. "/cmd/app/main.go"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(file))
			end)

			it("should build the whole module rooted at the module", function()
				local out = cmd.cmd(file)

				assert.equals(root, out.dir)
				assert.equals("go build ./...", out.command_line)
			end)
		end)

		describe("given a file outside any go module", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(data .. "/bare/main.go"))
			end)
		end)
	end)
end)
