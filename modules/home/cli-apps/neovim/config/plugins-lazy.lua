local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Install lazy.nvim if not already installed
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)


require("lazy").setup({
  -- {
  --   "trevordmiller/nova-vim",
  --   priority = 1000,
  --   lazy = false,
  --   config = function()
  --     vim.cmd([[colorscheme nova]])
  --     vim.cmd([[highlight clear SignColumn]])
  --   end
  -- },
  {
    'maxmx03/solarized.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      -- vim.o.background = 'light'
      -- vim.cmd('colorscheme solarized')
    end
  },
  {
    'projekt0n/github-nvim-theme',
    lazy = false,    -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('github-theme').setup({
        -- ...
      })

      vim.cmd('colorscheme github_dark')
    end,
  },
  { "rebelot/kanagawa.nvim" },
  { "nordtheme/vim" },
  { "numToStr/Comment.nvim",       lazy = false, config = true },
  { "tmhedberg/matchit",           lazy = false },
  { "tpope/vim-surround",          lazy = false },
  { "tpope/vim-endwise",           lazy = false },
  { "tpope/vim-dadbod" },
  { "kristijanhusak/vim-dadbod-ui" },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    config = function()
      require('lualine').setup({
        options = {
          theme = 'auto'
        },
        extensions = { 'nvim-tree', 'fugitive', 'fzf', 'lazy', 'quickfix' }
      })
    end
  },
  { "norcalli/nvim-colorizer.lua", lazy = false,  config = true },
  { "junegunn/vim-slash",          lazy = false },
  { "sheerun/vim-polyglot",        lazy = false },
  { "lithammer/nvim-diagnosticls", lazy = false },
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
  {
    "zbirenbaum/copilot.lua",
    config = function()
      require("copilot").setup({})
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    config = function()
      require("copilot_cmp").setup()
    end,
  },
  {
    "elixir-tools/elixir-tools.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local elixir = require("elixir")
      local elixirls = require("elixir.elixirls")

      elixir.setup({
        nextls = { enable = true },
        credo = {},
        elixirls = {
          enable = true,
          settings = elixirls.settings {
            dialyzerEnabled = false,
            enableTestLenses = false,
          }
        }
      })
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    }
  },
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    config = function()
      require('nvim-tree').setup({
        view = { side = "right" }
      })
    end,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    tag = "nightly"
  },
  {
    "L3MON4D3/LuaSnip",
    lazy = false,
    version = "1.2.1",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function() require("luasnip.loaders.from_vscode").lazy_load() end
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "neovim/nvim-lspconfig", "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline", "saadparwaiz1/cmp_luasnip" },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end
        },
        window = {
          completion = cmp.config.window.bordered()
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" })
        }),
        sources = {
          -- Copilot Source
          { name = "copilot",  group_index = 2 },
          -- Other Sources
          { name = "nvim_lsp", group_index = 2 },
          { name = "path",     group_index = 2 },
          { name = "luasnip",  group_index = 2 },
        }
      })
    end
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local telescope = require('telescope')
      local telescopeConfig = require('telescope.config')

      local vimgrep_args = { unpack(telescopeConfig.values.vimgrep_arguments) }
      table.insert(vimgrep_args, '--hidden') -- Search for hidden files

      -- Don't search these
      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/.git/*')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/.idea/*')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/.vscode/*')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/build/*')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/dist/*')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/yarn.lock')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/package-lock.json')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/devenv.lock')

      table.insert(vimgrep_args, '--glob')
      table.insert(vimgrep_args, '!**/node_modules/*')
      --

      telescope.setup({
        defaults = {
          vimgrep_arguments = vimgrep_args
        },
        pickers = {
          find_files = {
            -- needed to exclude some files & dirs from general search
            -- when not included or specified in .gitignore
            find_command = {
              'rg',
              '--files',
              '--hidden',
              '--glob=!**/.git/*',
              '--glob=!**/.idea/*',
              '--glob=!**/.vscode/*',
              '--glob=!**/build/*',
              '--glob=!**/dist/*',
              '--glob=!**/yarn.lock',
              '--glob=!**/package-lock.json',
              '--glob=!**/devenv.lock'
            }
          }
        }
      })
    end
  },
  {
    "lewis6991/gitsigns.nvim",
    config = true,
    dependencies = { "nvim-lua/plenary.nvim" }
  },
  "tpope/vim-fugitive",
  "ellisonleao/glow.nvim",
  {
    "iamcco/markdown-preview.nvim",
    build = ":call mkdp#util#install()",
    ft = "markdown",
    config = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end
  },
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    opts = { provider = "copilot" },
    build = "make",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "zbirenbaum/copilot.lua",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      }
    }
  }
})

-- Mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
local opts = { noremap = true, silent = true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '<leader>ap', vim.diagnostic.goto_prev, opts)
vim.keymap.set('n', '<leader>an', vim.diagnostic.goto_next, opts)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, opts)

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  -- Disable hover in favor of Pyright for python files
  if client.name == 'ruff_lsp' then
    client.server_capabilities.hoverProvider = false
  end
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

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

local lsp_flags = {
  -- This is the default in Nvim 0.7+
  debounce_text_changes = 150,
}

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require('lspconfig')['ts_ls'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities
}

require('lspconfig')['pyright'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
  settings = {
    pyright = {
      -- Using Ruff's import organizer
      disableOrganizeImports = true,
    },
  }
}

require('lspconfig')['elixirls'].setup {
  cmd = { "elixir-ls" },
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
}

require('lspconfig')['lua_ls'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT"
      },
      diagnostics = {
        globals = { "vim" }
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true)
      }
    }
  }
}

require('lspconfig')['bashls'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
}

require('lspconfig')['nixd'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
}

require('lspconfig')['marksman'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
}

local diagnosticls = require("diagnosticls")
require('lspconfig')['diagnosticls'].setup {
  filetypes = { unpack(diagnosticls.filetypes) },
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
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
  }
}

require('lspconfig')['terraformls'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
}

require('lspconfig')['dockerls'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
}

require('lspconfig')['rust_analyzer'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities
}

require('lspconfig')['ruff_lsp'].setup {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities
}
