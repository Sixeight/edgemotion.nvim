local core = require('edgemotion.core')

describe('edgemotion.core', function()
  before_each(function()
    -- Setup a buffer with test content similar to vimspec
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
  end)

  after_each(function()
    vim.cmd('bdelete!')
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
end)
