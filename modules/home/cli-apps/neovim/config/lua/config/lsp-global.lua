-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Disable hover in favor of Pyright for python files
  -- if client.name == 'ruff' then
  --   client.server_capabilities.hoverProvider = false
  -- end
  -- Enable completion triggered by <c-x><c-o>
  -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any of the below functions
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', '<leader>gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', '<leader>st', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<leader><C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<leader>af', function() vim.lsp.buf.format { async = true } end, bufopts)
end

local capabilities = require("blink.cmp").get_lsp_capabilities()
-- vim.lsp.config("*", {
--   on_attach = on_attach,
--   capabilities = capabilities,
-- })

local lsps = {
  "basedpyright",
  "bashls",
  "diagnosticls",
  -- "dockerls",
  -- "elixirls",
  "eslint",
  "lua_ls",
  -- "marksman",
  "nixd",
  -- "terraformls",
  -- "ruff",
  -- "rust_analyzer",
  "ts_ls",
}

for _, lsp in ipairs(lsps) do
  vim.lsp.config(lsp, { on_attach = on_attach, capabilities = capabilities })
  vim.lsp.enable(lsp)
end
