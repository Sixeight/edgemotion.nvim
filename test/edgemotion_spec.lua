local edgemotion = require('edgemotion')
local helper = require('test.test_helper')

describe('edgemotion', function()
  before_each(function()
    helper.setup_test_buffer()
    -- Set cursor to beginning
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
  end)

  after_each(function()
    helper.cleanup_test_buffer()
  end)

  describe('constants', function()
    it('should have correct direction constants', function()
      assert.are.equal(1, edgemotion.DIRECTION.FORWARD)
      assert.are.equal(0, edgemotion.DIRECTION.BACKWARD)
    end)
  end)

  describe('move()', function()
    it('should return appropriate movement commands', function()
      -- Test cases for different movement scenarios
      local test_cases = {
        {
          name = 'forward from start',
          cursor = { 1, 0 },
          direction = edgemotion.DIRECTION.FORWARD,
          expect_string = true,
        },
        {
          name = 'backward from middle',
          cursor = { 5, 0 },
          direction = edgemotion.DIRECTION.BACKWARD,
          expect_string = true,
        },
        {
          name = 'at specific column',
          cursor = { 2, 4 },
          direction = edgemotion.DIRECTION.FORWARD,
          expect_string = true,
        },
      }

      for _, tc in ipairs(test_cases) do
        vim.api.nvim_win_set_cursor(0, tc.cursor)
        local cmd = edgemotion.move(tc.direction)
        assert.is_string(cmd, 'Failed for: ' .. tc.name)
      end

      -- Test no edge found scenario
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
    it('should handle various setup configurations', function()
      local test_cases = {
        {
          name = 'default options',
          opts = nil,
        },
        {
          name = 'custom key mappings',
          opts = {
            forward = '<C-n>',
            backward = '<C-p>',
          },
        },
        {
          name = 'partial options (merge with defaults)',
          opts = {
            forward = '<C-n>',
            -- backward not specified, should use default
          },
        },
      }

      for _, tc in ipairs(test_cases) do
        assert.has_no.errors(function()
          edgemotion.setup(tc.opts)
        end, 'Failed for: ' .. tc.name)
      end
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
    it('should handle navigation with mixed Japanese and ASCII text', function()
      -- Test comprehensive mixed content navigation
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

      -- Test specific edge case with Japanese characters
      vim.api.nvim_win_set_cursor(0, { 6, 0 }) -- Line with 'if (条件) {'
      local cmd = edgemotion.move(edgemotion.DIRECTION.FORWARD)
      assert.not_equal('', cmd, 'Movement command should not be empty with Japanese characters')
    end)

    it('should skip over lines with only indentation', function()
      -- Reproduce issue: cursor should skip from line with code to next line with code,
      -- skipping over lines that contain only indentation
      vim.cmd('enew')
      local lines = {
        '    if (condition) {', -- Line 1: code with indentation
        '        ', -- Line 2: only indentation (spaces)
        '        ', -- Line 3: only indentation (spaces)
        '        ', -- Line 4: only indentation (spaces)
        '    }', -- Line 5: code with closing brace
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Start at line 1, column 5 (where 'i' in 'if' is located)
      -- Note: nvim_win_set_cursor uses 0-based column index
      vim.api.nvim_win_set_cursor(0, { 1, 4 })

      -- Execute forward movement
      edgemotion.move_forward()

      -- Get current cursor position
      local cursor = vim.api.nvim_win_get_cursor(0)

      -- Should have moved to line 5 (closing brace), not line 3
      assert.are.equal(5, cursor[1], 'Cursor should skip to line 5, not stop at line 3')
    end)

    it('should handle realistic code structure like in the issue', function()
      -- Reproduce the exact issue from the screenshot
      vim.cmd('enew')
      local lines = {
        '\t\tconfig := server.Config{', -- Line 1
        '\t\t\tHost: hostname,', -- Line 2
        '\t\t\tPort: port.Number(),', -- Line 3
        '\t\t\tTimeout: duration,', -- Line 4
        '\t\t}.Create()', -- Line 5
        '\t\tif _, err := client.Connect(ctx, config); err != nil {', -- Line 6
        '\t\t\tt.Errorf("ConnectionFailed")', -- Line 7
        '\t\t}', -- Line 8
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Set tab settings
      vim.bo.tabstop = 4
      vim.bo.shiftwidth = 4

      -- Start at line 1, at the beginning of the code (after tabs)
      -- Position cursor at first non-whitespace character
      vim.fn.cursor(1, 1)
      vim.cmd('normal! ^')

      -- Execute forward movement
      edgemotion.move_forward()

      -- Get current cursor position
      local cursor = vim.api.nvim_win_get_cursor(0)

      -- The algorithm finds that line 2-4 have tabs (not islands) at the cursor column,
      -- so it moves to line 5 where the next island is found
      assert.are.equal(5, cursor[1], 'Cursor should move to line 5 where the next island starts')
    end)
  end)
end)
