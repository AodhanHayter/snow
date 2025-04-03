local o = vim.o
local opt = vim.opt
local wo = vim.wo
local bo = vim.bo
local cmd = vim.cmd
local api = vim.api
local diagnostic = vim.diagnostic

-- global options
o.termguicolors = true
o.guicursor = 'i-ci-ve:hor100'
o.path = o.path .. ',**'
o.cmdheight = 2
o.showmode = false
o.hidden = true
o.mouse = 'a'
o.updatetime = 300
o.showmatch = true
o.clipboard = 'unnamedplus'
o.winborder = 'rounded'
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

cmd('syntax enable')


-- autocmds
------------
cmd('au InsertEnter * set cul')
cmd('au InsertLeave * set nocul')
cmd('au BufWritePre * :%s/\\s\\+$//e') -- remove whitespace on save
cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

local function open_nvim_tree(data)
  -- buffer is a [No Name]
  local no_name = data.file == "" and vim.bo[data.buf].buftype == ""

  -- buffer is a directory
  local directory = vim.fn.isdirectory(data.file) == 1

  if not no_name and not directory then
    return
  end

  if directory then
    vim.cmd.cd(data.file)
  end

  require("nvim-tree.api").tree.open()
end

api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

-- globals
-----------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
