local core = {}

-- Check if string is whitespace
local function is_white(str)
  return str:match('^[ \t]$') ~= nil
end

-- Get character at specified virtual column (improved for multibyte)
local function get_virtcol_char(lnum, vcol)
  if vcol < 1 then
    return ''
  end

  local line = vim.fn.getline(lnum)
  if line == '' then
    return ''
  end

  -- Convert virtual column to byte position correctly
  -- We need to iterate through characters and their display widths
  local current_vcol = 1
  local byte_pos = 1

  while byte_pos <= #line do
    local char = vim.fn.strpart(line, byte_pos - 1, 1, true)
    local char_width = vim.fn.strwidth(char)

    -- If we're at the target virtual column, return the character
    if current_vcol == vcol then
      return char
    end

    -- If the target vcol is within this character's width, return the character
    if vcol > current_vcol and vcol < current_vcol + char_width then
      return char
    end

    current_vcol = current_vcol + char_width
    byte_pos = byte_pos + vim.fn.strlen(char)

    -- If we've passed the target column, we're done
    if current_vcol > vcol then
      break
    end
  end

  return ''
end

-- Check if position is in an island (code block)
function core.island(lnum, vcol)
  local c = get_virtcol_char(lnum, vcol)
  if c == '' then
    return false
  end

  -- Non-whitespace characters are always islands
  if not is_white(c) then
    return true
  end

  -- Whitespace is never an island
  -- The original edgemotion behavior treats whitespace as boundaries, not islands
  return false
end

-- Expose for testing
core._get_virtcol_char = get_virtcol_char

return core
