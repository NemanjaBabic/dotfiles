local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

local config_dir = vim.fn.fnamemodify(
  debug.getinfo(1, 'S').source:sub(2),
  ':p:h:h'
)

require('lazy').setup('plugins', {
  lockfile = config_dir .. '/lazy-lock.json',
  rocks = { enabled = false },
  performance = {
    rtp = {
      reset = false,
    },
  },
})
