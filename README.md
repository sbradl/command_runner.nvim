# command_runner.nvim

Configure and execute project-level and global commands.

## run_command

Based on the current file a selection of commands is displayed.
![image](./screenshot_commands.png)

The selected command will be executed.
![image](./screenshot_commands_executed.png)

Commands can be specified in a file called ```command_runner.lua``` inside a ```.nvim``` directory. The file must return a table. The keys are the extensions of the files for which commands should be specified.
Every command needs a ```label``` which is displayed in the user selection.
The ```cmd``` is a function which returns a table with the description of the commands. The type determines how to execute the command. At the moment ```terminal``` and ```nvim``` are supported. If omitted ```terminal``` execution will be assumed. For ```terminal``` commands the ```dir``` specifies where the command should be executed. Every command needs a ```command_line``` string for the actual command.
Optionally a ```filter``` function can be specified to further narrow down for which files the command should be offered.

An example for running playwright tests could look like this:

```
local function get_project_dir(filename)
 return vim.fs.root(filename, { "playwright.config.ts" })
end

return {
 ts = {
  {
   label = "Playwright",
   filter = function(filename)
    return get_project_dir(filename) ~= nil
   end,
   cmd = function(filename)
    local project_dir = get_project_dir(filename)

    return {
     dir = project_dir,
     command_line = "npx playwright test",
    }
   end,
  },
 },
}
```

The ```filter``` looks for a playwright.config.ts file above the current file's directory. If it exists the Playwright command will be available.
