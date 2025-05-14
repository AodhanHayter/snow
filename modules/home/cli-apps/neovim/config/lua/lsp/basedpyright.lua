vim.lsp.config('basedpyright',{
  settings = {
    pyright = {
      -- Using Ruff's import organizer
      disableOrganizeImports = true,
    },
  }
})
