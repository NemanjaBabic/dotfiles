return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      local configs = require('nvim-treesitter.configs')
      configs.setup({
        -- Explicitly list all required parsing engines here
        ensure_installed = { 'regex', 'latex', 'markdown', 'markdown_inline', 'lua' },
        auto_install = false,
        highlight = { enable = true },
      })
    end,
  },
}
