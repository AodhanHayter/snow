return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    opts = {
      options = {
        theme = 'auto'
      },
      extensions = { 'fugitive', 'fzf', 'lazy', 'quickfix' }
    }
  }
}
