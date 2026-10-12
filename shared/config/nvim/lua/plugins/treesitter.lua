return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local treesitter = require('nvim-treesitter')

      treesitter.setup({})
      treesitter.install({
        'regex',
        'latex',
        'markdown',
        'markdown_inline',
        'lua',
      })

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup(
          'DotfilesTreesitter',
          { clear = true }
        ),
        pattern = { 'lua', 'markdown', 'tex', 'plaintex' },
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          local language = vim.treesitter.language.get_lang(
            vim.bo[bufnr].filetype
          )

          if language and vim.treesitter.language.add(language) then
            vim.treesitter.start(bufnr, language)
          end
        end,
      })
    end,
  },
}