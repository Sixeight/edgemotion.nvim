" Minimal init.vim for testing
set noswapfile
set nobackup
set rtp+=.
set rtp+=./deps/plenary.nvim

runtime! plugin/plenary.vim

lua << EOF
-- Add current directory to package path
package.path = package.path .. ";" .. vim.fn.getcwd() .. "/lua/?.lua"
package.path = package.path .. ";" .. vim.fn.getcwd() .. "/lua/?/init.lua"

-- Make sure we can require our plugin
require('edgemotion')
EOF
