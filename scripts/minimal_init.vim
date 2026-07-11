set rtp+=.
set rtp+=../plenary.nvim/

" Make test-only helper modules (tests/*.lua) requirable, e.g. require("test_util").
lua package.path = package.path .. ";" .. vim.fn.getcwd() .. "/tests/?.lua"

runtime! plugin/plenary.vim
runtime! lua/command_runner.lua
