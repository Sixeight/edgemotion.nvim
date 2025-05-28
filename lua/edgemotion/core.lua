local core = {}

-- Get character at specified virtual column
local function get_virtcol_char(lnum, vcol)
  if vcol < 1 then
    return ''
  end

  local line = vim.fn.getline(lnum)
  if line == '' then
    return ''
  end

  -- Use proper vim virtual column handling with tab expansion
  local current_vcol = 1
  local byte_pos = 1

  while byte_pos <= #line do
    local char = vim.fn.strpart(line, byte_pos - 1, 1, true)
    local char_width

    -- Handle tab expansion properly
    if char == '\t' then
      local tabstop = vim.bo.tabstop or 8
      char_width = tabstop - ((current_vcol - 1) % tabstop)
    else
      char_width = vim.fn.strwidth(char)
    end

    -- Check if we're at the target column
    if current_vcol <= vcol and vcol < current_vcol + char_width then
      return char
    end

    current_vcol = current_vcol + char_width
    byte_pos = byte_pos + vim.fn.strlen(char)

    -- Early exit if we've passed the target
    if current_vcol > vcol then
      break
    end
  end

  return ''
end

-- Check if position is in an island (code block)
function core.island(lnum, vcol)
  local c = get_virtcol_char(lnum, vcol)

  -- Empty position = not an island
  if c == '' then
    return false
  end

  -- Non-whitespace = island
  if c:match('^[ \t]$') == nil then
    return true
  end

  -- Whitespace surrounded by non-whitespace = island
  -- (Original vim-edgemotion behavior)
  local prev_c = get_virtcol_char(lnum, vcol - 1)
  local next_c = get_virtcol_char(lnum, vcol + 1)

  if
    prev_c ~= ''
    and prev_c:match('^[ \t]$') == nil
    and next_c ~= ''
    and next_c:match('^[ \t]$') == nil
  then
    return true
  end

  -- Otherwise, whitespace = not an island
  return false
end

-- Expose for testing
core._get_virtcol_char = get_virtcol_char

return core
