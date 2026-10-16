-- End-to-end check against real mise, go and dotnet: install task templates
-- into a fresh project, then build each command from a real buffer (as the
-- picker would) and run it through 'shell'. Run from the repo root:
--   nvim -l scripts/e2e.lua
vim.opt.rtp:prepend(vim.fn.getcwd())

local install = require("command_runner.install")
local mise = require("command_runner.builtin.mise")

local root = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(root, "p")

local function sh(argv, dir)
	local res = vim.system(argv, { cwd = dir or root, text = true }):wait()
	assert(res.code == 0, table.concat(argv, " ") .. " failed:\n" .. (res.stdout or "") .. (res.stderr or ""))
end

local function write(path, lines)
	vim.fn.mkdir(vim.fs.dirname(path), "p")
	vim.fn.writefile(lines, path)
end

local function step(msg)
	io.stdout:write("==> " .. msg .. "\n")
end

-- Fixtures --------------------------------------------------------------------

step("creating go and dotnet fixtures in " .. root)
write(root .. "/go.mod", { "module e2e", "", "go 1.21" })
write(root .. "/cmd/app/main.go", {
	"package main",
	"",
	'import "fmt"',
	"",
	"func main() {",
	'	fmt.Println("e2e-go-ok")',
	"}",
})

sh({ "dotnet", "new", "sln", "-n", "App" })
sh({ "dotnet", "new", "mstest", "-n", "App.Tests", "-o", "App.Tests" })
for name in vim.fs.dir(root) do
	if name:match("^App%.slnx?$") then
		sh({ "dotnet", "sln", name, "add", "App.Tests/App.Tests.csproj" })
	end
end
local test_file = root .. "/App.Tests/E2eTests.cs"
write(test_file, {
	"namespace App.Tests;",
	"",
	"[TestClass]",
	"public sealed class E2eTests",
	"{",
	"    [TestMethod]",
	"    public void Passes()", -- line 7
	"    {",
	"    }",
	"",
	"    [TestMethod]",
	"    public void Fails()", -- line 12
	"    {",
	'        Assert.Fail("expected");',
	"    }",
	"}",
})
sh({ "dotnet", "restore" })

-- Setup -----------------------------------------------------------------------

step("detecting templates")
local detected = install.detected(root, test_file)
assert(detected.go and detected.dotnet, "go and dotnet should be detected: " .. vim.inspect(detected))
assert(not detected.mix, "mix should not be detected")

step("installing templates")
local installed = install.install(root, { "go", "dotnet" })
assert(vim.deep_equal(installed, { "go", "dotnet" }), vim.inspect(installed))

local res = vim.system({ "mise", "tasks", "ls", "--json" }, { cwd = root, text = true }):wait()
assert(res.code == 0, "mise tasks ls failed (untrusted?):\n" .. (res.stderr or ""))
local names = vim.tbl_map(function(t)
	return t.name
end, vim.json.decode(res.stdout))
for _, want in ipairs({ "go:run", "go:build", "dotnet:test-method", "dotnet:test-project" }) do
	assert(vim.tbl_contains(names, want), want .. " missing from " .. vim.inspect(names))
end

-- Commands --------------------------------------------------------------------

--- Pick `task` for `file` with the cursor on `line` and run it like the
--- terminal executor would: in the command's dir, through 'shell'.
local function run(file, line, task)
	vim.cmd.edit(vim.fn.fnameescape(file))
	vim.api.nvim_win_set_cursor(0, { line, 0 })
	local buf = vim.api.nvim_get_current_buf()

	local choice
	for _, d in ipairs(mise.commands[1].expand(file, buf)) do
		if d.label == "mise run " .. task or vim.startswith(d.label, "mise run " .. task .. " ") then
			choice = d
		end
	end
	assert(choice, task .. " not offered in the picker")

	local command = choice.cmd(file, buf)
	step(command.command_line)
	vim.fn.chdir(command.dir)
	local out = vim.fn.system(command.command_line)
	return vim.v.shell_error, out, command.command_line
end

local code, out = run(root .. "/cmd/app/main.go", 1, "go:run")
assert(code == 0 and out:find("e2e-go-ok", 1, true), "go:run failed (exit " .. code .. "):\n" .. out)

-- dotnet test tasks need a C# test file, so they're hidden for main.go.
for _, d in ipairs(mise.commands[1].expand(root .. "/cmd/app/main.go", vim.api.nvim_get_current_buf())) do
	assert(not d.label:find("dotnet:test-method", 1, true), "dotnet:test-method offered for main.go")
end

code, out = run(test_file, 7, "dotnet:test-method")
assert(code == 0 and not out:find("expected", 1, true), "dotnet:test-method Passes should pass alone:\n" .. out)

-- Proves the class/method filter reaches dotnet: only Fails runs, and fails.
code, out = run(test_file, 12, "dotnet:test-method")
assert(code ~= 0 and out:find("expected", 1, true), "dotnet:test-method Fails should fail on its assert:\n" .. out)

step("ok")
