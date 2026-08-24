-- Replaces vim-javascript (and gives every other language the same treatment).
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "typescript", "tsx", "javascript", "jsdoc", "json", "jsonc",
        "html", "css", "lua", "vim", "vimdoc", "markdown", "markdown_inline",
        "bash", "yaml", "toml",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
