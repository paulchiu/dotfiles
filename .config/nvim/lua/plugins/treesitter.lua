--[[
Replaces vim-javascript (and gives every other language the same treatment).

Pinned to `main`, not `master`. The master branch is frozen and its queries
predate Neovim 0.12: its markdown injection query shadows the bundled one and
makes the injection scan hand the highlighter a rootless tree, which errors on
every markdown buffer.

Only languages Neovim does not already bundle are installed here; c, lua,
markdown, markdown_inline, query, vim and vimdoc ship with Neovim.
--]]

local LANGUAGES = {
  "typescript", "tsx", "javascript", "jsdoc",
  "json", "html", "css",
  "bash", "yaml", "toml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    config = function()
      require("nvim-treesitter").setup()

      -- Filtered against get_available so one bad name cannot abort the whole
      -- config and leave the editor without highlighting.
      local nt = require("nvim-treesitter")
      local available = nt.get_available()
      local installed = require("nvim-treesitter.config").get_installed("parsers")
      local missing = vim.tbl_filter(function(lang)
        return vim.tbl_contains(available, lang) and not vim.tbl_contains(installed, lang)
      end, LANGUAGES)
      if #missing > 0 then
        nt.install(missing)
      end

      -- main/ does not enable anything itself; highlighting is opt-in per buffer.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(ev)
          if not pcall(vim.treesitter.start, ev.buf) then
            return
          end
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
