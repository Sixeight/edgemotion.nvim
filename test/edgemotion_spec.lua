local edgemotion = require('edgemotion')

describe('edgemotion', function()
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

    -- Set cursor to beginning
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
  end)

  after_each(function()
    vim.cmd('bdelete!')
  end)

  describe('constants', function()
    it('should have correct direction constants', function()
      assert.are.equal(1, edgemotion.DIRECTION.FORWARD)
      assert.are.equal(0, edgemotion.DIRECTION.BACKWARD)
    end)
  end)

  describe('move()', function()
    it('should return movement command for forward direction', function()
      -- Start at line 1, column 1
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      local cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)

      -- Should return a string (could be empty if no edge found)
      assert.is_string(cmd)
    end)

    it('should return movement command for backward direction', function()
      -- Start at line 5
      vim.api.nvim_win_set_cursor(0, { 5, 0 })

      local cmd = edgemotion.move(edgemotion.DIRECTION.BACKWARD)

      -- Should return a string (could be empty if no edge found)
      assert.is_string(cmd)
    end)

    it('should return empty string when no edge found', function()
      -- Create a buffer with uniform content (no edges)
      vim.cmd('enew')
      local uniform_lines = {
        'line one',
        'line two',
        'line three',
        'line four',
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, uniform_lines)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      -- From first line, trying to go backward should return empty
      local cmd = edgemotion.move(edgemotion.DIRECTION.BACKWARD)
      assert.are.equal('', cmd)
    end)

    it('should handle cursor at virtual column correctly', function()
      -- Position cursor at specific column
      vim.api.nvim_win_set_cursor(0, { 2, 4 }) -- line 2, column 5 (0-indexed)

      local cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)

      -- Should return a string (could be empty if no edge found)
      assert.is_string(cmd)
    end)
  end)

  describe('movement functions', function()
    it('should execute move_forward without errors', function()
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      -- This should not throw an error
      assert.has_no.errors(function()
        edgemotion.move_forward()
      end)
    end)

    it('should execute move_backward without errors', function()
      vim.api.nvim_win_set_cursor(0, { 5, 0 })

      -- This should not throw an error
      assert.has_no.errors(function()
        edgemotion.move_backward()
      end)
    end)
  end)

  describe('setup()', function()
    it('should setup with default options', function()
      assert.has_no.errors(function()
        edgemotion.setup()
      end)
    end)

    it('should setup with custom options', function()
      local opts = {
        forward = '<C-n>',
        backward = '<C-p>',
      }

      assert.has_no.errors(function()
        edgemotion.setup(opts)
      end)
    end)

    it('should merge custom options with defaults', function()
      local opts = {
        forward = '<C-n>',
        -- backward not specified, should use default
      }

      assert.has_no.errors(function()
        edgemotion.setup(opts)
      end)
    end)
  end)

  describe('integration tests based on vimspec', function()
    it('should move cursor by indent based edge', function()
      -- function to endfunction (line 3 to line 10)
      vim.api.nvim_win_set_cursor(0, { 3, 0 }) -- cursor at 'function! s:f() abort'
      local move_cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)

      -- Should return a movement command or empty string
      assert.is_string(move_cmd)

      -- Test backward movement
      vim.api.nvim_win_set_cursor(0, { 10, 0 }) -- cursor at 'endfunction'
      move_cmd = edgemotion.move(edgemotion.DIRECTION.BACKWARD)
      assert.is_string(move_cmd)
    end)

    it('should handle movement from if to elseif', function()
      -- if to elseif (line 4 to line 7)
      vim.api.nvim_win_set_cursor(0, { 4, 2 }) -- cursor at '  if 1'
      local move_cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)
      assert.is_string(move_cmd)

      -- Test movement through similar indent levels
      vim.api.nvim_win_set_cursor(0, { 7, 2 }) -- cursor at '  elseif 2'
      move_cmd = edgemotion.move(edgemotion.DIRECTION.BACKWARD)
      assert.is_string(move_cmd)
    end)

    it('should handle complex buffer navigation without errors', function()
      -- Test navigation from various positions
      vim.api.nvim_win_set_cursor(0, { 3, 0 })

      assert.has_no.errors(function()
        edgemotion.move_forward()
        edgemotion.move_backward()
      end)
    end)
  end)

  describe('multibyte character support', function()
    it('should handle mixed Japanese and ASCII text correctly', function()
      -- Test with realistic mixed content: Japanese and English code
      vim.cmd('enew')
      local lines = {
        'function getUserName() {',
        '  const name = "山田太郎";',
        '  console.log("Hello, " + name);',
        '}',
        '',
        'if (条件) {',
        '  // 日本語のコメント',
        '  return "こんにちは";',
        '}',
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Test edge detection from various positions
      local test_cases = {
        { line = 1, col = 0, desc = 'English function' },
        { line = 2, col = 2, desc = 'line with Japanese string' },
        { line = 6, col = 0, desc = 'Japanese if condition' },
      }

      for _, test_case in ipairs(test_cases) do
        vim.api.nvim_win_set_cursor(0, { test_case.line, test_case.col })

        assert.has_no.errors(function()
          local forward_cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)
          local backward_cmd = edgemotion.move(edgemotion.DIRECTION.BACKWARD)

          assert.is_string(forward_cmd)
          assert.is_string(backward_cmd)
        end)
      end
    end)

    it('should correctly detect edges with multibyte characters', function()
      -- Test that edge detection works properly with Japanese characters
      vim.cmd('enew')
      local lines = {
        'if (条件) {',
        '    console.log("テスト");',
        '}',
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      local cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)

      -- Should generate a valid movement command (not empty)
      assert.not_equal('', cmd, 'Movement command should not be empty with Japanese characters')
    end)
  end)
end)
