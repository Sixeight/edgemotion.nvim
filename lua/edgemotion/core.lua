local core = {}

-- Check if string is whitespace
local function is_white(str)
    return str:match('^[ \t]$') ~= nil
end

-- Get character at specified virtual column
local function get_virtcol_char(lnum, vcol)
    local pattern = string.format('^.-\\zs\\%%<%dv.\\%%>%dv', vcol + 1, vcol)
    return vim.fn.matchstr(vim.fn.getline(lnum), pattern)
end

-- Check if position is in an island (code block)
function core.island(lnum, vcol)
    local c = get_virtcol_char(lnum, vcol)
    if c == '' then
        return false
    end

    if not is_white(c) then
        return true
    end

    local pattern = string.format('^.-\\zs.\\%%<%dv.\\%%>%dv.', vcol + 1, vcol)
    local m = vim.fn.matchstr(vim.fn.getline(lnum), pattern)
    local chars = vim.split(m, '\\zs')

    if #chars ~= 3 then
        return false
    end

    return not is_white(chars[1]) and not is_white(chars[3])
end

return core
