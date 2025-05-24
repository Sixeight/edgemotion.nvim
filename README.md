## edgemotion.nvim

A Neovim plugin that provides `j` and `k` motions that stop at edges only.

This plugin is a lua ported version of [Edgemotion](https://github.com/haya14busa/vim-edgemotion).

### Requirements

- Neovim 0.5+

### Installation

#### Installation

Using Lazy.nvim with default settings:

```lua
{
  'Sixeight/edgemotion.nvim',
  opts = {}, -- This will call setup() with default options
}
```

With custom key mappings:

```lua
{
  'Sixeight/edgemotion.nvim',
  opts = {
    forward = 'gj',
    backward = 'gk',
  },
}
```

Manual setup (if needed):

```lua
require('edgemotion').setup({
  forward = '<C-j>',  -- default
  backward = '<C-k>', -- default
})
```

### Testing

This plugin includes comprehensive tests using plenary.nvim:

```bash
# Install dependencies
make deps

# Run tests
make test
```

## Author

Sixeight (<https://github.com/Sixeight>)

## Document

[:h edgemotion.txt](doc/edgemotion.txt)
