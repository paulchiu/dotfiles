-- Replaces vim-easymotion. `s` jumps, `S` jumps by treesitter node.
-- <leader><leader> is kept as a second entry point for the old ,, muscle memory.
return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "<leader><leader>", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
    },
  },
}
