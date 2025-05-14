return {
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
  }
}
