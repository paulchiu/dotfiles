--[[
LSP layer. vtsls is the actively maintained TypeScript server wrapper; it
resolves import specifiers through tsserver itself, so `gd` on an import
string follows relative paths and tsconfig `paths` aliases with no extra
path configuration on Neovim's side.

Servers are installed into ~/.local/share/nvim/mason/, not globally.
--]]

--- Buffer-local LSP mappings, applied once a server attaches.
--- Telescope is used for anything that can return more than one location.
local function on_attach(client, bufnr)
  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = "LSP: " .. desc })
  end

  local ok, builtin = pcall(require, "telescope.builtin")

  map("gd", ok and builtin.lsp_definitions or vim.lsp.buf.definition, "Go to definition")
  map("gy", ok and builtin.lsp_type_definitions or vim.lsp.buf.type_definition, "Go to type definition")
  map("gi", ok and builtin.lsp_implementations or vim.lsp.buf.implementation, "Go to implementation")
  map("gr", ok and builtin.lsp_references or vim.lsp.buf.references, "Find references")
  map("gD", vim.lsp.buf.declaration, "Go to declaration")

  -- Call hierarchy: who calls this, and what this calls.
  map("<leader>ci", ok and builtin.lsp_incoming_calls or vim.lsp.buf.incoming_calls, "Incoming calls (callers)")
  map("<leader>co", ok and builtin.lsp_outgoing_calls or vim.lsp.buf.outgoing_calls, "Outgoing calls (callees)")

  map("<leader>ds", ok and builtin.lsp_document_symbols or vim.lsp.buf.document_symbol, "Document symbols")
  map("<leader>ws", ok and builtin.lsp_dynamic_workspace_symbols or vim.lsp.buf.workspace_symbol, "Workspace symbols")

  map("K", vim.lsp.buf.hover, "Hover")
  map("<leader>rn", vim.lsp.buf.rename, "Rename")
  map("<leader>ca", vim.lsp.buf.code_action, "Code action")
  map("<leader>e", vim.diagnostic.open_float, "Line diagnostics")
  map("<leader>q", ok and builtin.diagnostics or vim.diagnostic.setloclist, "Diagnostic list")

  -- Completion without a completion plugin (Neovim 0.11+).
  if vim.lsp.completion and vim.lsp.completion.enable then
    pcall(vim.lsp.completion.enable, true, client.id, bufnr, { autotrigger = false })
  end
end

return {
  { "williamboman/mason.nvim", cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonLog" }, opts = {} },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      vim.lsp.config("vtsls", {
        settings = {
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            preferences = { importModuleSpecifier = "shortest" },
            inlayHints = {
              parameterNames = { enabled = "literals" },
              variableTypes = { enabled = false },
            },
          },
        },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      require("mason-lspconfig").setup({
        ensure_installed = { "vtsls", "lua_ls" },
      })

      vim.lsp.enable({ "vtsls", "lua_ls" })

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          on_attach(vim.lsp.get_client_by_id(args.data.client_id), args.buf)
        end,
      })

      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
      })
    end,
  },
}
