local mod = require("command_runner.builtin.sh_script")

local find_command = require("tests/test_util").find_command

describe("command_runner.builtin.sh_script", function()
	it("should register for sh and ps1 files", function()
		assert.same({ "sh", "ps1" }, mod.extensions)
	end)

	describe("'execute script' command", function()
		local cmd

		before_each(function()
			cmd = find_command(mod.commands, "execute script")
		end)

		describe("given a .sh file", function()
			it("should run it via ./ in its own directory", function()
				local out = cmd.cmd("/some/dir/build.sh")

				assert.equals("/some/dir", out.dir)
				assert.equals("./build.sh", out.command_line)
			end)
		end)

		describe("given a .ps1 file", function()
			it("should run it via pwsh -File in its own directory", function()
				local out = cmd.cmd("/some/dir/deploy.ps1")

				assert.equals("/some/dir", out.dir)
				assert.equals("./deploy.ps1", out.command_line)
			end)
		end)
	end)
end)
