local mod = require("command_runner.builtin.docker_compose")

local find_command = require("tests/test_util").find_command

describe("command_runner.builtin.docker_compose", function()
	it("should register for yml and yaml files", function()
		assert.same({ "yml", "yaml" }, mod.extensions)
	end)

	local commands = {
		{ label = "docker compose up -d", command_line = "docker compose up -d" },
		{ label = "docker compose down", command_line = "docker compose down" },
		{ label = "docker compose build", command_line = "docker compose build" },
		{ label = "docker compose logs -f", command_line = "docker compose logs -f" },
		{ label = "docker compose ps", command_line = "docker compose ps" },
		{ label = "docker compose restart", command_line = "docker compose restart" },
	}

	local compose_filenames = {
		"docker-compose.yml",
		"docker-compose.yaml",
		"compose.yml",
		"compose.yaml",
	}

	for _, spec in ipairs(commands) do
		describe("'" .. spec.label .. "' command", function()
			local cmd

			before_each(function()
				cmd = find_command(mod.commands, spec.label)
			end)

			for _, name in ipairs(compose_filenames) do
				describe("given a " .. name .. " file", function()
					it("should be available", function()
						assert.is_true(cmd.filter("/some/dir/" .. name))
					end)

					it("should build the command rooted at the file's directory", function()
						local out = cmd.cmd("/some/dir/" .. name)

						assert.equals("/some/dir", out.dir)
						assert.equals(spec.command_line, out.command_line)
					end)
				end)
			end

			describe("given an unrelated yaml file", function()
				it("should not be available", function()
					assert.is_false(cmd.filter("/some/dir/values.yaml"))
				end)
			end)
		end)
	end
end)
