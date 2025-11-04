return {
  -- add gruvbox
  {
    "thedenisnikulin/vim-cyberpunk",
    "water-sucks/darkrose.nvim",
    "rose-pine/neovim",
  },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine",
    },
  },
}
