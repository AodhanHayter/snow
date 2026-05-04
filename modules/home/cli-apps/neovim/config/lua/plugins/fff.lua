return {
  dir = vim.g.fff_nvim_dir,
  name = 'fff',
  build = false,
  event = 'VeryLazy',
  config = function()
    require('fff').setup({})
  end,
  keys = {
    { '<leader>t', function() require('fff').find_files() end, desc = 'fff: find files' },
    { '<leader>g', function() require('fff').live_grep() end, desc = 'fff: live grep' },
  },
}
