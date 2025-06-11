local diagnosticls = require("diagnosticls")

return {
  cmd = { "diagnostic-languageserver", "--stdio" },
  root_markers = { ".git" },
  filetypes = { unpack(diagnosticls.filetypes) },
  init_options = {
    linters = diagnosticls.linters,
    formatters = diagnosticls.formatters,
    filetypes = {
      sh = "shellcheck",
    },
    formatFiletypes = {
      javascript = "prettier",
      javascriptreact = "prettier",
      json = "prettier",
      typescript = "prettier",
      typescriptreact = "prettier",
      markdown = "prettier",
    }
  },
}
