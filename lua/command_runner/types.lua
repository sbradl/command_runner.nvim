---@meta command_runner types

---@alias BuiltinCommands string A builtin key: the basename (without `.lua`) of a module in `lua/command_runner/builtin/`, e.g. "ts_vitest".

---@class CommandRunnerOpts
---@field commands? table<string, CommandDescription[]> A table command descriptions by file-extension. For directory commands the special string ":directory" can be used.
---@field builtin? BuiltinOpts | false Options for the builtin commands. Pass `false` to disable all builtins at once.
---@field autoclose_on_success? boolean Close the terminal automatically when the command exits successfully. Defaults to true. Requires a shell where `<cmd> && sleep <n> && exit` (POSIX shells) or `<cmd> && sleep <n> && [Environment]::Exit(0)` (PowerShell 7+) is valid.
---@field autoclose_delay_in_seconds? integer How long the terminal stays open after a successful command before closing. Defaults to 3; 0 closes immediately. Ctrl-C during the delay cancels the close.
---@field history_size? integer Maximum number of recent commands kept for the history picker (see show_history()). Defaults to 10.

---@class BuiltinOpts
---@field disable? BuiltinCommands[] Builtin keys to disable. Any key not listed stays enabled.

---@alias CommandType "terminal" | "nvim" Specifies how the command should be executed - whether in a terminal or as a nvim command.

---@class Command
---@field dir? string The directory where the command should be executed. Only used for terminal comands.
---@field type? CommandType
---@field command_line string The actual string which represents the command to be executed.

---@class CommandDescription
---@field label string Label for displaying to the user.
---@field filter? fun(string): boolean A filter CommandDescription to further narrow when to offer this command
---@field cmd fun(filename: string, bufnr: integer): Command A function which builds the command details needed for execution based on the file and buffer for which the command should be executed. E.g. the filename could be used to calculate the execution directory or as a starting point to search the project it belongs to with vim.fs.root

return {}
