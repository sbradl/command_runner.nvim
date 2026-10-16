local install = require("command_runner.install")

describe("command_runner.install", function()
	local root
	local restore_system

	before_each(function()
		root = vim.fn.tempname()
		vim.fn.mkdir(root .. "/.git", "p")
	end)

	after_each(function()
		if restore_system then
			restore_system()
			restore_system = nil
		end
		vim.fn.delete(root, "rf")
	end)

	-- Records the argv of every vim.system call instead of running mise.
	local function stub_system()
		local calls = {}
		local orig = vim.system
		restore_system = function()
			vim.system = orig
		end
		vim.system = function(argv)
			table.insert(calls, argv)
			return {
				wait = function()
					return { code = 0 }
				end,
			}
		end
		return calls
	end

	it("should ship a template for every detect entry", function()
		local templates = install.list_templates()
		for name in pairs(install.detect) do
			assert.is_true(vim.tbl_contains(templates, name), name)
		end
	end)

	it("should pre-check templates whose markers are found upward from the file", function()
		vim.fn.mkdir(root .. "/app", "p")
		vim.fn.writefile({}, root .. "/go.mod")
		vim.fn.writefile({}, root .. "/app/App.csproj")

		local detected = install.detected(root, root .. "/app/Foo.cs")

		assert.is_true(detected.go)
		assert.is_true(detected.dotnet)
		assert.is_false(detected.mix)
	end)

	it("should copy checked templates into .mise/conf.d and trust them", function()
		local calls = stub_system()

		local installed = install.install(root, { "go", "mix" })

		assert.same({ "go", "mix" }, installed)
		local target = install.target_path(root, "go")
		assert.same(vim.fn.readfile(install.templates_dir .. "/go.toml"), vim.fn.readfile(target))
		assert.same({ "mise", "trust", "--quiet", target }, calls[1])
	end)

	it("should never overwrite an installed file, and treat it as detected", function()
		stub_system()
		vim.fn.mkdir(root .. "/" .. install.target_subdir, "p")
		vim.fn.writefile({ "# edited" }, install.target_path(root, "go"))

		assert.same({}, install.install(root, { "go" }))
		assert.same({ "# edited" }, vim.fn.readfile(install.target_path(root, "go")))
		assert.is_true(install.detected(root, root .. "/x")["go"])
	end)

	it("should parse checked lines from the checklist", function()
		assert.same(
			{ "dotnet", "mix" },
			install.parse_checklist({ "# header", "", "[x] dotnet", "[ ] go", "[X] mix", "x not a line" })
		)
	end)
end)
