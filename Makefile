SHELL := /bin/bash

# Install dependencies for testing
deps:
	mkdir -p deps
	cd deps && git clone https://github.com/nvim-lua/plenary.nvim.git

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory test/ {minimal_init = 'scripts/minimal_init.vim'}"

.PHONY: test deps
