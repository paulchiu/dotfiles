return {
  {
    "dracula/vim",
    name = "dracula",
    lazy = false,
    priority = 1000, -- load before anything that reads highlight groups
    config = function()
      vim.cmd.colorscheme("dracula")
      vim.opt.background = "dark"
    end,
  },
}
