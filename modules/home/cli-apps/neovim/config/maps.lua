local map = vim.api.nvim_set_keymap
local cmd = vim.cmd

local minifiles_toggle = function(...)
  if not MiniFiles.close() then MiniFiles.open(...) end
end

-- leader maps
----------------
map('n', '<Space>', '', {})
vim.g.mapleader = ' '

local options = { noremap = true, silent = true }
map('n', '<leader>co', ':set cursorcolumn!<CR>', options)

map('v', '<', '<gv', options)
map('v', '>', '>gv', options)

-- file tree
map('n', '<leader>ff', ':lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<cr>', options)
map('n', '<C-\\>', ':lua if not MiniFiles.close() then MiniFiles.open() end<cr>', options)

-- fuzzy finder
map('n', '<leader>t', ':lua require("telescope.builtin").find_files()<cr>', options)
map('n', '<leader>b', ':lua require("telescope.builtin").buffers()<cr>', options)
map('n', '<leader>g', ':lua require("telescope.builtin").live_grep()<cr>', options)
map('n', '<leader>ch', ':lua require("telescope.builtin").command_history()<cr>', options)
map('n', '<leader>sh', ':lua require("telescope.builtin").search_history()<cr>', options)

-- format
-- map('n', '<leader>an', ':ALENext<cr>', options)
