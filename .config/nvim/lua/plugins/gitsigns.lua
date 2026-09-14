--[[
Gutter hunk signs, plus blame: virtual text on the current line and a
scroll-locked full-file view. Closest equivalent to VS Code's GitLens.
--]]
return {
  {
    "lewis6991/gitsigns.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true,
      current_line_blame_opts = {
        -- Long enough that the text does not flicker while moving the cursor.
        delay = 500,
        virt_text_pos = "eol",
      },
      current_line_blame_formatter = "  <author>, <author_time:%R> - <summary>",
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- ]c and [c already mean "next/previous change" in diff mode; defer to
        -- the builtin there rather than shadowing it.
        local function nav(direction, builtin)
          return function()
            if vim.wo.diff then
              vim.cmd.normal({ builtin, bang = true })
            else
              gs.nav_hunk(direction)
            end
          end
        end
        map("n", "]c", nav("next", "]c"), "Next hunk")
        map("n", "[c", nav("prev", "[c"), "Previous hunk")

        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line (popup)")
        map("n", "<leader>gB", gs.blame, "Blame file")
        map("n", "<leader>gt", gs.toggle_current_line_blame, "Toggle inline blame")
      end,
    },
  },
}
