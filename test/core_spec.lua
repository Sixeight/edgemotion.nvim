local core = require('edgemotion.core')
local helper = require('test.test_helper')

describe('edgemotion.core', function()
  before_each(function()
    helper.setup_test_buffer()
  end)

  after_each(function()
    helper.cleanup_test_buffer()
  end)

  describe('island()', function()
    it('should work as a core function without errors', function()
      -- Basic functionality test - just ensure it doesn't crash
      local result1 = core.island(3, 1)
      local result2 = core.island(4, 3)

      -- Should return boolean values
      assert.is_boolean(result1)
      assert.is_boolean(result2)
    end)

    it('should return false for empty or whitespace-only lines', function()
      -- Test line 2: empty line
      assert.False(core.island(2, 1))

      -- Test line 11: empty line
      assert.False(core.island(11, 1))

      -- Test line 4: "  if 1"
      -- Columns 1-2 are whitespace at start of line
      assert.False(core.island(4, 1))
      assert.False(core.island(4, 2))

      -- Add a line with only spaces
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { '    ' })
      local last_line = vim.api.nvim_buf_line_count(0)
      assert.False(core.island(last_line, 1))
      assert.False(core.island(last_line, 4))
    end)

    it('should handle positions beyond content boundaries', function()
      -- Test columns beyond line length
      assert.False(core.island(3, 100))
      assert.False(core.island(2, 100)) -- empty line
      
      -- Test invalid line numbers
      assert.False(core.island(0, 1)) -- line 0 doesn't exist
      assert.False(core.island(100, 1)) -- line 100 doesn't exist
      
      -- Test very large column numbers
      assert.False(core.island(1, 1000))
    end)

    it('should function consistently with various inputs', function()
      -- Test various positions across different lines
      for lnum = 1, 13 do
        for col = 1, 5 do
          local result = core.island(lnum, col)
          assert.is_boolean(result)
        end
      end
    end)
  end)


  describe('Character width and edge detection', function()
    it('should calculate character widths correctly', function()
      vim.cmd('enew')
      -- Test case: Japanese characters take up more visual space
      -- Full-width "あ" takes 2 display columns, half-width "a" takes 1
      local lines = {
        'あいうえお', -- 5 Japanese characters = 10 display columns
        'abcde', -- 5 English characters = 5 display columns
        'あいう abc', -- Mixed: 3 Japanese (6 cols) + space + 3 English (3 cols) = 10 cols
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Test line 1: pure Japanese
      -- Virtual column 1 should be on 'あ'
      assert.True(core.island(1, 1))
      -- Virtual column 2 should still be on 'あ' (since it takes 2 display columns)
      assert.True(core.island(1, 2))
      -- Virtual column 3 should be on 'い'
      assert.True(core.island(1, 3))

      -- Test line 2: pure English
      assert.True(core.island(2, 1)) -- 'a'
      assert.True(core.island(2, 2)) -- 'b'
      assert.True(core.island(2, 3)) -- 'c'

      -- Test line 3: mixed Japanese/English with space
      -- Standard display: 'あいう' = 3 chars × 2 = 6 display columns
      assert.True(core.island(3, 1)) -- 'あ'
      assert.True(core.island(3, 2)) -- still 'あ'
      assert.True(core.island(3, 3)) -- 'い'
      assert.True(core.island(3, 4)) -- still 'い'
      assert.True(core.island(3, 5)) -- 'う'
      assert.True(core.island(3, 6)) -- still 'う'
      assert.True(core.island(3, 7)) -- space between Japanese and English text (surrounded by non-whitespace)
      assert.True(core.island(3, 8)) -- 'a'
    end)

    it('should detect edges in code with mixed character widths', function()
      vim.cmd('enew')
      -- Test edge detection in realistic code scenarios
      local lines = {
        'function test() {',
        '  const 名前 = "田中";', -- Mixed with Japanese variable name
        '  // 日本語のコメント', -- Japanese comment
        '  return 名前;',
        '}',
        '', -- empty line (edge)
        'ミックスされた mixed text', -- Mixed text block
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Test edge detection at various positions
      -- Line 2: "  const 名前 = "田中";"
      assert.False(core.island(2, 1)) -- leading space
      assert.False(core.island(2, 2)) -- leading space
      assert.True(core.island(2, 3)) -- 'c' from 'const'
      assert.True(core.island(2, 9)) -- '名' (Japanese character)

      -- Line 3: Japanese comment
      assert.False(core.island(3, 1)) -- space
      assert.True(core.island(3, 3)) -- '/'
      assert.True(core.island(3, 5)) -- space between '//' and Japanese (surrounded)
      assert.True(core.island(3, 6)) -- '日' starts here

      -- Verify edges at empty lines
      assert.False(core.island(6, 1)) -- Empty line is not an island
      assert.True(core.island(7, 1)) -- Mixed text is an island
    end)


    it('should handle whitespace and surrounded whitespace correctly', function()
      vim.cmd('enew')
      -- Test whitespace handling with full/half width characters
      local lines = {
        'あ  い', -- Japanese with 2 spaces in between
        'a  b', -- English with 2 spaces in between
        'あ a い', -- Mixed with single spaces
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Line 1: 'あ' cols 1-2, spaces 3-4, 'い' cols 5-6
      assert.True(core.island(1, 1)) -- 'あ'
      assert.True(core.island(1, 2)) -- still 'あ'
      assert.False(core.island(1, 3)) -- space
      assert.False(core.island(1, 4)) -- space
      assert.True(core.island(1, 5)) -- 'い'
      assert.True(core.island(1, 6)) -- still 'い'

      -- Line 2: English characters with spaces
      assert.True(core.island(2, 1)) -- 'a'
      assert.False(core.island(2, 2)) -- space
      assert.False(core.island(2, 3)) -- space
      assert.True(core.island(2, 4)) -- 'b'

      -- Line 3: Mixed with single spaces (surrounded whitespace)
      -- 'あ' cols 1-2, space 3, 'a' col 4, space 5, 'い' cols 6-7
      assert.True(core.island(3, 1)) -- 'あ'
      assert.True(core.island(3, 3)) -- space (surrounded by non-whitespace)
      assert.True(core.island(3, 4)) -- 'a'
      assert.True(core.island(3, 5)) -- space (surrounded by non-whitespace)
      assert.True(core.island(3, 6)) -- 'い'
    end)

    it('should handle standard display widths correctly', function()
      vim.cmd('enew')
      -- Test standard display: full-width = 2 columns, half-width = 1 column
      local lines = {
        'aaaaa', -- 5 half-width = 5 display columns
        'あああ', -- 3 full-width = 6 display columns
        'bbbbb', -- 5 half-width = 5 display columns
        'いいい', -- 3 full-width = 6 display columns
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Test that columns align correctly
      -- Column 1: should all be characters
      assert.True(core.island(1, 1)) -- 'a'
      assert.True(core.island(2, 1)) -- 'あ'
      assert.True(core.island(3, 1)) -- 'b'
      assert.True(core.island(4, 1)) -- 'い'

      -- Column 5: last 'a' in line 1, within last 'あ' in line 2
      assert.True(core.island(1, 5)) -- last 'a'
      assert.True(core.island(2, 5)) -- last 'あ' (cols 5-6)
      assert.True(core.island(3, 5)) -- last 'b'
      assert.True(core.island(4, 5)) -- last 'い' (cols 5-6)

      -- Column 6: beyond English chars, still within last Japanese char
      assert.False(core.island(1, 6)) -- beyond 'aaaaa'
      assert.True(core.island(2, 6)) -- still within last 'あ'
      assert.False(core.island(3, 6)) -- beyond 'bbbbb'
      assert.True(core.island(4, 6)) -- still within last 'い'

      -- Column 7: beyond all characters
      assert.False(core.island(1, 7)) -- beyond 'aaaaa'
      assert.False(core.island(2, 7)) -- beyond 'あああ'
      assert.False(core.island(3, 7)) -- beyond 'bbbbb'
      assert.False(core.island(4, 7)) -- beyond 'いいい'
    end)
  end)
end)
