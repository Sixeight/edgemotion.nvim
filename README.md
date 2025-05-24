## edgemotion.nvim

A Neovim plugin that provides `j` and `k` motions that stop at edges only.

This plugin is a lua ported version of [Edgemotion](https://github.com/haya14busa/vim-edgemotion).

### Requirements

- Neovim 0.5+

### Installation

#### Using Lazy.nvim

Simple installation with default settings:

```lua
{
  'Sixeight/edgemotion.nvim',
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
