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

  -- For fonts where full-width:half-width = 3:5 ratio
  -- We need to calculate display width differently
  -- Half-width = 1.0, Full-width = 5/3 ≈ 1.67
  local function get_display_width(char)
    local width = vim.fn.strwidth(char)
    if width == 2 then
      -- Full-width character (e.g., Japanese)
      -- In 5:3 ratio, this should be 5/3 units
      return 5.0 / 3.0
    else
      -- Half-width character
      return 1.0
    end
  end

  -- Convert virtual column to byte position correctly
  -- We need to iterate through characters and their display widths
  local current_vcol = 1.0
  local byte_pos = 1

  while byte_pos <= #line do
    local char = vim.fn.strpart(line, byte_pos - 1, 1, true)
    local char_width = get_display_width(char)

    -- Check if the virtual column falls within this character's display range
    local char_start = current_vcol
    local char_end = current_vcol + char_width
    
    -- For the 5:3 ratio, we need to check if vcol is within the character's range
    -- A virtual column N belongs to a character if:
    -- - The character starts at or before column N (char_start <= N)
    -- - The character ends after column N (char_end > N)
    -- Special case: for full-width chars, if char_end is exactly an integer, include that column
    local epsilon = 1e-10
    if char_width == 1.0 then
      -- Half-width character: simple range check [start, end)
      if char_start <= vcol and vcol < char_end then
        return char
      end
    else
      -- Full-width character: may need to include the end column
      if char_start <= vcol and (vcol < char_end or 
         (math.abs(char_end - math.floor(char_end)) < epsilon and vcol == math.floor(char_end))) then
        return char
      end
    end

    current_vcol = current_vcol + char_width
    byte_pos = byte_pos + vim.fn.strlen(char)

    -- If we've passed the target column, we're done
    if math.floor(current_vcol) > vcol then
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
