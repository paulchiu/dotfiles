-- Replaces nerdtree. <C-n> is preserved.
return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    cmd = "Neotree",
    keys = {
      { "<C-n>", "<Cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        -- leave_dirs_open keeps reveal-expanded directories open; without it
        -- every buffer switch collapses the tree back down.
        follow_current_file = { enabled = true, leave_dirs_open = true },
        filtered_items = { hide_dotfiles = false, hide_gitignored = true },
      },
    },
  },
}
