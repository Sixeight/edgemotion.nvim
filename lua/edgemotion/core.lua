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

  -- Use standard vim virtual column handling
  local current_vcol = 1
  local byte_pos = 1

  while byte_pos <= #line do
    local char = vim.fn.strpart(line, byte_pos - 1, 1, true)
    local char_width = vim.fn.strwidth(char)

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
  -- Empty or whitespace = not an island
  return c ~= '' and c:match('^[ \t]$') == nil
end

-- Expose for testing
core._get_virtcol_char = get_virtcol_char

return core
