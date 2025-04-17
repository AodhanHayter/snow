local map = vim.api.nvim_set_keymap

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

--- Show / Hide dotfiles in explorer
local show_dotfiles = true

local filter_show = function(fs_entry) return true end

local filter_hide = function(fs_entry)
  return not vim.startswith(fs_entry.name, '.')
end

local toggle_dotfiles = function()
  show_dotfiles = not show_dotfiles
  local new_filter = show_dotfiles and filter_show or filter_hide
  MiniFiles.refresh({ content = { filter = new_filter } })
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id
    -- Tweak left-hand side of mapping to your liking
    vim.keymap.set('n', 'H', toggle_dotfiles, { buffer = buf_id })
  end,
})
---
--- Open file in split
local map_split = function(buf_id, lhs, direction)
  local rhs = function()
    -- Make new window and set it as target
    local cur_target = MiniFiles.get_explorer_state().target_window
    local new_target = vim.api.nvim_win_call(cur_target, function()
      vim.cmd(direction .. ' split')
      return vim.api.nvim_get_current_win()
    end)

    MiniFiles.set_target_window(new_target)

    -- This intentionally doesn't act on file under cursor in favor of
    -- explicit "go in" action (`l` / `L`). To immediately open file,
    -- add appropriate `MiniFiles.go_in()` call instead of this comment.
    MiniFiles.go_in({ close_on_file = true })
  end

  -- Adding `desc` will result into `show_help` entries
  local desc = 'Split ' .. direction
  vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'MiniFilesBufferCreate',
  callback = function(args)
    local buf_id = args.data.buf_id
    -- Tweak keys to your liking
    map_split(buf_id, '<C-s>', 'belowright horizontal')
    map_split(buf_id, '<C-v>', 'belowright vertical')
  end,
})
---

-- fuzzy finder
map('n', '<leader>t', ':lua require("telescope.builtin").find_files()<cr>', options)
map('n', '<leader>b', ':lua require("telescope.builtin").buffers()<cr>', options)
map('n', '<leader>g', ':lua require("telescope.builtin").live_grep()<cr>', options)
map('n', '<leader>ch', ':lua require("telescope.builtin").command_history()<cr>', options)
map('n', '<leader>sh', ':lua require("telescope.builtin").search_history()<cr>', options)

-- format
-- map('n', '<leader>an', ':ALENext<cr>', options)
