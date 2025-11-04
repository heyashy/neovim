return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      pyright = {
        settings = {
          python = {
            venvPath = ".",
            venv = ".venv",
          },
        },
      },
    },
    overrides = {
      extensions = {
        env = "env",
      },
      complex = {
        [".env.**"] = "env",
      },
    },
  },
}
