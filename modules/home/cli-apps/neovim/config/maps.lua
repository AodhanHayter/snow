local map = vim.api.nvim_set_keymap
local cmd = vim.cmd

-- leader maps
----------------
map('n', '<Space>', '', {})
vim.g.mapleader = ' '

local options = { noremap = true, silent = true }
map('n', '<leader>co', ':set cursorcolumn!<CR>', options)

map('v', '<', '<gv', options)
map('v', '>', '>gv', options)

-- coc.nvim maps
-- map('n', '<leader>gd', '<Plug>(coc-definition)', {})
-- map('n', '<leader>gt', '<Plug>(coc-type-definition)', {})
-- map('n', '<leader>gr', '<Plug>(coc-references)', {})
-- map('n', '<leader>gi', '<Plug>(coc-implementation)', {})
-- map('n', '<leader>rn', '<Plug>(coc-rename)', {})
-- map('n', '<leader>st', ':call CocAction("doHover")<cr>', options)
-- map('n', '<leader>qf', '<Plug>(coc-fix-current)', {})

-- cmd('command! -nargs=0 Format :call CocActionAsync("format")')
-- map('n', '<leader>af', ':Format<cr>', options)

-- file tree
map('n', '<leader>ff', ':NvimTreeFindFile<CR>', options)
map('n', '<C-\\>', ':NvimTreeToggle<CR>', options)

-- fuzzy finder
map('n', '<leader>t', ':lua require("telescope.builtin").find_files()<cr>', options)
map('n', '<leader>b', ':lua require("telescope.builtin").buffers()<cr>', options)
map('n', '<leader>g', ':lua require("telescope.builtin").live_grep()<cr>', options)
map('n', '<leader>ch', ':lua require("telescope.builtin").command_history()<cr>', options)
map('n', '<leader>sh', ':lua require("telescope.builtin").search_history()<cr>', options)

-- format
-- map('n', '<leader>an', ':ALENext<cr>', options)

