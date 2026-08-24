-- Replaces vim-airline.
return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "dracula",
        globalstatus = true,
      },
    },
  },
}
