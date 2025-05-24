SHELL := /bin/bash

# Install dependencies for testing and development
deps: deps/plenary.nvim stylua

# Install plenary.nvim for testing
deps/plenary.nvim:
	mkdir -p deps
	cd deps && git clone https://github.com/nvim-lua/plenary.nvim.git

# Install stylua for code formatting
stylua:
	@if ! command -v stylua >/dev/null 2>&1; then \
		echo "Installing stylua..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install stylua; \
		elif command -v cargo >/dev/null 2>&1; then \
			cargo install stylua; \
		else \
			echo "Error: Neither Homebrew nor Cargo found. Please install one of them to install stylua."; \
			exit 1; \
		fi; \
	else \
		echo "stylua already installed, skipping..."; \
	fi

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory test/ {minimal_init = 'scripts/minimal_init.vim'}"

# Format Lua code with stylua
format:
	stylua --check .

format-fix:
	stylua .

.PHONY: test deps stylua format format-fix
