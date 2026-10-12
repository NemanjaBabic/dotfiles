-- dofile() bootstraps need this directory on the runtime path to find lua/.
local config_dir = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
vim.opt.rtp:prepend(config_dir)

require('vim_config')
require('plugin')
require('keys')
