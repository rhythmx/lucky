return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        integrations = {
          treesitter = true,
          native_lsp = { enabled = true },
          telescope = { enabled = true },
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}

