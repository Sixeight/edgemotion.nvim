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

    it('should return false for empty lines', function()
      -- Test line 2: empty line
      assert.False(core.island(2, 1))

      -- Test line 11: empty line
      assert.False(core.island(11, 1))
    end)

    it('should return false for whitespace at start of line', function()
      -- Test line 4: "  if 1"
      -- Columns 1-2 are whitespace at start of line
      assert.False(core.island(4, 1))
      assert.False(core.island(4, 2))
    end)

    it('should handle virtual columns beyond line length', function()
      -- Test with column beyond the line length
      assert.False(core.island(3, 100))
      assert.False(core.island(2, 100)) -- empty line
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

  describe('edge cases', function()
    it('should handle lines with only whitespace', function()
      -- Add a line with only spaces at the end
      vim.api.nvim_buf_set_lines(0, -1, -1, false, { '    ' })

      -- First column of whitespace-only line should not be an island
      local last_line = vim.api.nvim_buf_line_count(0)
      assert.False(core.island(last_line, 1))
      assert.False(core.island(last_line, 4))
    end)

    it('should handle buffer boundary conditions', function()
      -- Test invalid line numbers
      assert.False(core.island(0, 1)) -- line 0 doesn't exist
      assert.False(core.island(100, 1)) -- line 100 doesn't exist

      -- Test very large column numbers
      assert.False(core.island(1, 1000))
    end)
  end)

  describe('Japanese/English mixed text', function()
    it('should correctly handle full-width Japanese characters', function()
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
      assert.True(core.island(3, 1)) -- 'あ'
      assert.True(core.island(3, 2)) -- still 'あ'
      assert.False(core.island(3, 7)) -- space should not be an island
      assert.True(core.island(3, 8)) -- 'a'
    end)

    it('should handle edge detection with 3:5 ratio display', function()
      vim.cmd('enew')
      -- Test case specifically for fonts where full-width:half-width = 3:5
      local lines = {
        'function test() {', -- English text
        '  const 名前 = "田中";', -- Mixed with Japanese variable name
        '  // 日本語のコメント', -- Japanese comment
        '  return 名前;', -- Mixed return statement
        '}',
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Test edge detection at specific virtual columns
      -- Line 2: "  const 名前 = "田中";"
      -- The spaces at the beginning should not be islands
      assert.False(core.island(2, 1))
      assert.False(core.island(2, 2))

      -- 'const' starts at virtual column 3
      assert.True(core.island(2, 3))

      -- After 'const ' (column 9), we have '名'
      -- '名' should be detected correctly regardless of display width
      assert.True(core.island(2, 9))

      -- Line 3: "  // 日本語のコメント"
      -- Comment with Japanese text
      assert.False(core.island(3, 1)) -- space
      assert.False(core.island(3, 2)) -- space
      assert.True(core.island(3, 3)) -- '/'
      assert.True(core.island(3, 4)) -- '/'
      assert.False(core.island(3, 5)) -- space after '//'
      assert.True(core.island(3, 6)) -- '日' starts here
    end)

    it('should detect edges correctly between Japanese and English blocks', function()
      vim.cmd('enew')
      -- Test edge transitions between Japanese and English text blocks
      local lines = {
        '日本語テキスト', -- Japanese text block
        '', -- empty line (edge)
        'English text block', -- English text block
        '', -- empty line (edge)
        'ミックスされた mixed text', -- Mixed text block
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Verify edges are detected at empty lines
      assert.True(core.island(1, 1)) -- Japanese text is an island
      assert.False(core.island(2, 1)) -- Empty line is not an island
      assert.True(core.island(3, 1)) -- English text is an island
      assert.False(core.island(4, 1)) -- Empty line is not an island
      assert.True(core.island(5, 1)) -- Mixed text is an island
    end)

    it('should handle whitespace correctly in mixed width environments', function()
      vim.cmd('enew')
      -- Test whitespace handling with full/half width characters
      local lines = {
        'あ  い', -- Japanese with 2 spaces in between
        'a  b', -- English with 2 spaces in between
        'あ a い', -- Mixed with single spaces
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Line 1: 'あ' takes columns 1-2, spaces at 3-4, 'い' at 5-6
      assert.True(core.island(1, 1)) -- 'あ'
      assert.True(core.island(1, 2)) -- still 'あ'
      assert.False(core.island(1, 3)) -- space
      assert.False(core.island(1, 4)) -- space
      assert.True(core.island(1, 5)) -- 'い'

      -- Line 2: English characters with spaces
      assert.True(core.island(2, 1)) -- 'a'
      assert.False(core.island(2, 2)) -- space
      assert.False(core.island(2, 3)) -- space
      assert.True(core.island(2, 4)) -- 'b'
    end)
  end)
end)
