local diagnosticls = require("diagnosticls")

vim.lsp.config('diagnosticls', {
  filetypes = { table.unpack(diagnosticls.filetypes) },
  init_options = {
    linters = diagnosticls.linters,
    formatters = diagnosticls.formatters,
    filetypes = {
      javascript = "eslint",
      javascriptreact = "eslint",
      typescript = "eslint",
      typescriptreact = "eslint",
      sh = "shellcheck",
      python = { "flake8" }
    },
    formatFiletypes = {
      javascript = "prettier",
      javascriptreact = "prettier",
      json = "prettier",
      typescript = "prettier",
      typescriptreact = "prettier",
      markdown = "prettier",
      python = { "isort", "black" }
    }
  },
})
