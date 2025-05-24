## edgemotion.nvim

A Neovim plugin that provides `j` and `k` motions that stop at edges only.

This plugin is a lua ported version of [Edgemotion](https://github.com/haya14busa/vim-edgemotion).

### Requirements

- Neovim 0.5+

### Installation

#### Installation

Manual setup

```lua
require('edgemotion').setup({
  forward = '<C-j>',  -- default
  backward = '<C-k>', -- default
})
```

##### TODO
- [ ] Support [lazy.nvim](https://github.com/folke/lazy.nvim)

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
