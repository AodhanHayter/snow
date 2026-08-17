return {
  {
    "iamcco/markdown-preview.nvim",
    -- not lazy: an `ft` trigger never fires for files opened from argv
    -- (`nvim foo.md`), and a `cmd` trigger loads a plugin that defines no
    -- command, so lazy errors with "Command `MarkdownPreview` not found".
    -- mkdp is vimscript only; node is spawned on demand.
    lazy = false,
    build = "cd app && yarn install",
    init = function()
      -- mdx.nvim sets ft to markdown.mdx; mkdp matches &filetype exactly.
      vim.g.mkdp_filetypes = { "markdown", "markdown.mdx" }
    end,
    keys = {
      {
        "<leader>mp",
        -- autoload function, not the buffer-local command
        function() vim.fn["mkdp#util#toggle_preview"]() end,
        desc = "Markdown preview toggle",
      },
    },
  }
}
