-- oil.nvim — edit your filesystem like a normal buffer.
--  Press `-` to open the parent directory; navigate with normal motions,
--  rename by editing text, `:w` to apply changes. `g?` for help inside Oil.
vim.pack.add { 'https://github.com/stevearc/oil.nvim' }

require('oil').setup {
  -- Show hidden files (toggle in-buffer with `g.`)
  view_options = { show_hidden = true },
}

vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory (Oil)' })
