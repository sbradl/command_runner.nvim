---@meta command_runner types

---@class CommandRunnerOpts
---@field commands? table<string, CommandDescription[]> A table command descriptions by file-extension. For directory commands the special string ":directory" can be used.
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
