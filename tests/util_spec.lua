local util = require("command_runner.util")

local repo = vim.fn.getcwd()

describe("command_runner.util", function()
	describe("get_git_dir", function()
		describe("given a file inside a git repository", function()
			local file

			before_each(function()
				file = repo .. "/tests/testdata/util/src/a.lua"
				assert.equals(1, vim.fn.isdirectory(repo .. "/.git"))
			end)

			it("should return the repository root", function()
				assert.equals(repo, util.get_git_dir(file))
			end)
		end)

		describe("given a file that is not inside any git repository", function()
			local file

			before_each(function()
				file = "/no/such/repo/file.lua"
				assert.equals(0, vim.fn.isdirectory("/no"))
			end)

			it("should return nil", function()
				assert.is_nil(util.get_git_dir(file))
			end)
		end)
	end)

	describe("relative_to_git", function()
		describe("given a file inside a git repository", function()
			it("should return the path relative to the repository root", function()
				local file = repo .. "/tests/testdata/util/src/a.lua"
				assert.equals("tests/testdata/util/src/a.lua", util.relative_to_git(file))
			end)
		end)

		describe("given a file that is not inside any git repository", function()
			it("should return the path unchanged", function()
				local file = "/no/such/repo/file.lua"
				assert.equals(file, util.relative_to_git(file))
			end)
		end)
	end)

	describe("find_root", function()
		local data = repo .. "/tests/testdata/util/find_root"

		describe("given a marker inside the repository", function()
			it("should return the directory containing the marker", function()
				assert.equals(data .. "/proj", util.find_root(data .. "/proj/lib/foo.ex", { "mix.exs" }))
			end)
		end)

		describe("given a list of markers", function()
			it("should prefer earlier markers over nearer ones, like vim.fs.root", function()
				local root = util.find_root(data .. "/prio/sub/x.ts", { "vitest.config.ts", "package.json" })
				assert.equals(data .. "/prio", root)
			end)
		end)

		-- The scenarios below need a git repository boundary with files above
		-- it. Git refuses to track any path containing a `.git` component, so
		-- these trees cannot live in tests/testdata and are built in a temp
		-- directory instead.
		describe("given a repository boundary built in a temp directory", function()
			local outer

			local function mkdirs(dir)
				vim.fn.mkdir(dir, "p")
				return dir
			end

			local function touch(path)
				vim.fn.writefile({}, path)
			end

			before_each(function()
				outer = mkdirs(vim.fn.tempname())
			end)

			after_each(function()
				vim.fn.delete(outer, "rf")
			end)

			describe("and the marker only exists above the repository root", function()
				it("should ignore it and return nil", function()
					touch(outer .. "/mix.exs")
					local git_repo = mkdirs(outer .. "/repo")
					mkdirs(git_repo .. "/.git")
					local lib = mkdirs(git_repo .. "/lib")

					assert.is_nil(util.find_root(lib .. "/foo.ex", { "mix.exs" }))
				end)

				it("should honor the boundary for function markers as well", function()
					touch(outer .. "/App.sln")
					local git_repo = mkdirs(outer .. "/repo")
					mkdirs(git_repo .. "/.git")
					local src = mkdirs(git_repo .. "/src")

					local is_solution = function(name, _)
						return vim.fs.ext(name) == "sln"
					end

					assert.is_nil(util.find_root(src .. "/Foo.cs", is_solution))
				end)
			end)

			describe("and the file is not inside any git repository", function()
				it("should search upward without a boundary, like vim.fs.root", function()
					touch(outer .. "/mix.exs")
					local lib = mkdirs(outer .. "/proj/lib")

					assert.equals(outer, util.find_root(lib .. "/foo.ex", { "mix.exs" }))
				end)
			end)
		end)
	end)
end)
