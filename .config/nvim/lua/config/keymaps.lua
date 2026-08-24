--[[
Ported from ~/.vimrc. Plugin-owned mappings (<C-p>, <C-n>, the <leader>
jump prefix) live with their plugin spec instead of here.
--]]

local map = vim.keymap.set

-- System clipboard
map("v", "<C-c>", '"+yi')
map("v", "<C-x>", '"+c')
map("v", "<C-v>", '<Esc>"+p')
map("i", "<C-v>", '<Esc>"+pa')

-- Cmd-key bindings; only reachable in a GUI (Neovide, MacVim).
map("", "<D-c>", "y")
map("", "<D-v>", "p")
map({ "i", "c" }, "<D-v>", '<Esc>"+p')
map("", "<D-x>", "x")
map("", "<D-s>", "<Cmd>w<CR>")

-- Window navigation without the <C-w> prefix
map("", "<C-j>", "<C-w>j")
map("", "<C-k>", "<C-w>k")
map("", "<C-l>", "<C-w>l")
map("", "<C-h>", "<C-w>h")

-- Move by screen line over wrapped text
map("", "j", "gj", { remap = false })
map("", "k", "gk", { remap = false })

-- Yank to end of line, consistent with C and D
map("n", "Y", "y$", { remap = false })

-- Abbreviations
vim.cmd([[
  ab xtd - [ ]
  ab xlk [foo]()
  ab xref ([foo]())
]])
