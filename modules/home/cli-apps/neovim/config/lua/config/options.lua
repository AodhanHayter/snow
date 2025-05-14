local o = vim.o
local opt = vim.opt
local wo = vim.wo
local bo = vim.bo
local diagnostic = vim.diagnostic

-- global options
opt.termguicolors = true
opt.guicursor = 'i-ci-ve:hor100'
opt.path = o.path .. ',**'
opt.cmdheight = 2
opt.showmode = false
opt.hidden = true
opt.mouse = 'a'
opt.updatetime = 300
opt.showmatch = true
opt.clipboard = 'unnamedplus'
opt.shortmess = opt.shortmess + { ['c'] = true }
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true
opt.undofile = true
opt.listchars = { tab = '>~', trail = '·' }
opt.laststatus = 3
opt.splitkeep = "screen"

-- window-local options
wo.number = true
wo.relativenumber = true
wo.wrap = false
wo.list = true
wo.signcolumn = 'auto:2'

-- buffer-local options
bo.tabstop = 2
bo.shiftwidth = 2
bo.expandtab = true
bo.smartindent = true
bo.autoindent = true
bo.undofile = true

-- diagnostic options
diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
  severity_sort = true
})


-- globals
-----------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
