stds.nvim = {
  globals = {
    "vim",
  },
  read_globals = {
    "describe",
    "it",
    "before_each",
    "after_each",
    "pending",
    "assert",
  },
}

std = "max+nvim"

exclude_files = {
  "deps/",
}

ignore = {
  "212/_.*",  -- allow unused arguments starting with underscore
  "631",      -- line too long
}

cache = true
