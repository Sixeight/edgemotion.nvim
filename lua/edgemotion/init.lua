local edgemotion = {}

-- Direction constants
edgemotion.DIRECTION = {
  FORWARD = 1,
  BACKWARD = 0,
}

-- Default options
local DEFAULT_OPTS = {
  forward = '<C-j>',
  backward = '<C-k>',
}

-- Import core logic
local core = require('edgemotion.core')

-- Calculate display column for 5:3 ratio fonts
local function get_display_col()
  local line = vim.fn.getline('.')
  local col = vim.fn.col('.') - 1  -- 0-based byte position
  
  if col == 0 then
    return 1
  end
  
  local display_col = 1.0
  local byte_pos = 0
  
  while byte_pos < col do
    local char = vim.fn.strpart(line, byte_pos, 1, true)
    local char_len = vim.fn.strlen(char)
    local char_width = vim.fn.strwidth(char)
    
    if char_width == 2 then
      -- Full-width character (5/3 display units)
      display_col = display_col + (5.0 / 3.0)
    else
      -- Half-width character (1 display unit)
      display_col = display_col + 1.0
    end
    
    byte_pos = byte_pos + char_len
  end
  
  return math.floor(display_col)
end

-- Move forward
function edgemotion.move_forward()
  local cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)
  if cmd ~= '' then
    vim.cmd('normal! ' .. cmd)
  end
end

-- Move backward
function edgemotion.move_backward()
  local cmd = edgemotion.move(edgemotion.DIRECTION.BACKWARD)
  if cmd ~= '' then
    vim.cmd('normal! ' .. cmd)
  end
end

-- Main movement function
function edgemotion.move(dir)
  local delta = dir == edgemotion.DIRECTION.FORWARD and 1 or -1
  local curswant = vim.fn.getcurpos()[4]

  if curswant > 100000 then
    vim.fn.winrestview({ curswant = #vim.fn.getline('.') - 1 })
  end

  -- Use our custom display column calculation for 5:3 ratio
  local vcol = get_display_col()
  local orig_lnum = vim.fn.line('.')

  local island_start = core.island(orig_lnum, vcol)
  local island_next = core.island(orig_lnum + delta, vcol)

  local should_move_to_land = not (island_start and island_next)
  local lnum = orig_lnum
  local last_lnum = vim.fn.line('$')

  if should_move_to_land then
    if island_start and not island_next then
      lnum = lnum + delta
    end

    while lnum ~= 0 and lnum <= last_lnum and not core.island(lnum, vcol) do
      lnum = lnum + delta
    end
  else
    while lnum ~= 0 and lnum <= last_lnum and core.island(lnum, vcol) do
      lnum = lnum + delta
    end
    lnum = lnum - delta
  end

  -- Edge not found
  if lnum == 0 or lnum == last_lnum + 1 then
    return ''
  end

  local move_cmd = dir == edgemotion.DIRECTION.FORWARD and 'j' or 'k'
  return math.abs(lnum - orig_lnum) .. move_cmd
end

-- Set up key mappings
function edgemotion.setup(opts)
  opts = vim.tbl_deep_extend('force', DEFAULT_OPTS, opts or {})

  vim.keymap.set('n', opts.forward, edgemotion.move_forward, {
    noremap = true,
    silent = true,
    desc = 'Edgemotion: Move forward to next edge',
  })
  vim.keymap.set('n', opts.backward, edgemotion.move_backward, {
    noremap = true,
    silent = true,
    desc = 'Edgemotion: Move backward to previous edge',
  })
end

return edgemotion
