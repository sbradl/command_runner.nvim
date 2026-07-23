local compose = require("command_runner.builtin.docker_compose")

local find_command = require("tests/test_util").find_command

local data = vim.fn.getcwd() .. "/tests/testdata/docker_compose"

describe("command_runner.builtin.docker_compose", function()
	describe("get_project_dir", function()
		describe("given a directory inside a docker compose project", function()
			it("should return the directory containing docker-compose.yml", function()
				local root = data .. "/proj"
				assert.equals(root, compose.get_project_dir(root))
			end)
		end)

		describe("given a nested directory inside a docker compose project", function()
			it("should return the directory containing docker-compose.yml", function()
				local root = data .. "/proj"
				assert.equals(root, compose.get_project_dir(root .. "/services/web"))
			end)
		end)

		describe("given a directory outside any docker compose project", function()
			it("should return nil", function()
				assert.is_nil(compose.get_project_dir(data .. "/bare/sub"))
			end)
		end)

		-- Git refuses to track any path containing a `.git` component, so this
		-- tree cannot live in tests/testdata and is built in a temp directory
		-- instead. Mirrors util_spec's find_root boundary coverage.
		describe("given a repository boundary built in a temp directory", function()
			local outer

			before_each(function()
				outer = vim.fn.tempname()
				vim.fn.mkdir(outer, "p")
			end)

			after_each(function()
				vim.fn.delete(outer, "rf")
			end)

			it("should ignore a marker that only exists above the repository root", function()
				vim.fn.writefile({}, outer .. "/docker-compose.yml")
				local git_repo = outer .. "/repo"
				vim.fn.mkdir(git_repo .. "/.git", "p")
				local sub = git_repo .. "/sub"
				vim.fn.mkdir(sub, "p")

				assert.is_nil(compose.get_project_dir(sub))
			end)
		end)
	end)

	describe("'docker compose up -d' command", function()
		local cmd

		before_each(function()
			cmd = find_command(compose.directory_commands, "docker compose up -d")
		end)

		describe("given a directory inside a docker compose project", function()
			local root

			before_each(function()
				root = data .. "/proj"
			end)

			it("should be available", function()
				assert.is_true(cmd.filter(root .. "/services/web"))
			end)

			it("should build the command rooted at the project", function()
				local out = cmd.cmd(root .. "/services/web")

				assert.equals(root, out.dir)
				assert.equals("docker compose up -d", out.command_line)
			end)
		end)

		describe("given a directory outside any docker compose project", function()
			it("should not be available", function()
				assert.is_false(cmd.filter(data .. "/bare/sub"))
			end)
		end)
	end)

	local other_commands = {
		{ label = "docker compose down", command_line = "docker compose down" },
		{ label = "docker compose build", command_line = "docker compose build" },
		{ label = "docker compose logs -f", command_line = "docker compose logs -f" },
		{ label = "docker compose ps", command_line = "docker compose ps" },
		{ label = "docker compose restart", command_line = "docker compose restart" },
	}

	for _, spec in ipairs(other_commands) do
		describe("'" .. spec.label .. "' command", function()
			local cmd

			before_each(function()
				cmd = find_command(compose.directory_commands, spec.label)
			end)

			describe("given a directory inside a docker compose project", function()
				local root

				before_each(function()
					root = data .. "/proj"
				end)

				it("should be available", function()
					assert.is_true(cmd.filter(root .. "/services/web"))
				end)

				it("should build the command rooted at the project", function()
					local out = cmd.cmd(root .. "/services/web")

					assert.equals(root, out.dir)
					assert.equals(spec.command_line, out.command_line)
				end)
			end)

			describe("given a directory outside any docker compose project", function()
				it("should not be available", function()
					assert.is_false(cmd.filter(data .. "/bare/sub"))
				end)
			end)
		end)
	end
end)
