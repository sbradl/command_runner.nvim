set rtp+=.
set rtp+=../plenary.nvim/

" Test buffers are throwaway; avoid swapfile creation so CI environments with
" a quirky nvim state dir (e.g. E303 on ~/.local/state/nvim/swap) can't fail
" tests unrelated to the code under test.
set noswapfile

" Make test-only helper modules (tests/*.lua) requirable, e.g. require("test_util").
lua package.path = package.path .. ";" .. vim.fn.getcwd() .. "/tests/?.lua"

runtime! plugin/plenary.vim
runtime! lua/command_runner.lua
