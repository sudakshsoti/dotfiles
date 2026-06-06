-- lualine.nvim — statusline. Replaces kickstart's mini.statusline
--  (mini.statusline is intentionally left disabled in init.lua).
vim.pack.add { 'https://github.com/nvim-lualine/lualine.nvim' }

require('lualine').setup {
  options = {
    icons_enabled = vim.g.have_nerd_font,
    theme = 'auto', -- follows the active colorscheme (tokyonight)
    section_separators = '',
    component_separators = '',
  },
}
