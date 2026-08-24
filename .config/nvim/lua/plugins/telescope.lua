--[[
Replaces ctrlp. <C-p> is preserved.

'autochdir' means cwd tracks the current buffer, so a plain find_files would
only ever search one directory. project_root() reproduces ctrlp's
g:ctrlp_working_path_mode = 'ra': walk up to the nearest VCS root.
--]]

local function project_root()
  local markers = { ".git", ".hg", ".svn", "package.json" }
  local found = vim.fs.find(markers, { upward = true, path = vim.fn.expand("%:p:h") })[1]
  return found and vim.fs.dirname(found) or vim.uv.cwd()
end

return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    cmd = "Telescope",
    keys = {
      {
        "<C-p>",
        function() require("telescope.builtin").find_files({ cwd = project_root() }) end,
        desc = "Find files (project root)",
      },
      {
        "<leader>fg",
        function() require("telescope.builtin").live_grep({ cwd = project_root() }) end,
        desc = "Live grep (project root)",
      },
      { "<leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Help tags" },
    },
    opts = {
      defaults = {
        -- Mirrors the old g:ctrlp_custom_ignore.
        file_ignore_patterns = {
          "node_modules/", "target/", "dist/",
          "%.swp$", "%.ico$", "%.git/", "%.svn/",
        },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
}
