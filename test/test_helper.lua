local M = {}

M.setup_test_buffer = function()
  vim.cmd('enew')
  local lines = {
    '" Line 1',
    '',
    'function! s:f() abort',
    '  if 1',
    '    " if 1',
    '    " b',
    '  elseif 2',
    '    " elseif 2',
    '  endif',
    'endfunction',
    '',
    '',
    '" END',
  }
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

M.cleanup_test_buffer = function()
  vim.cmd('bdelete!')
end

return M