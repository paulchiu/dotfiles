--[[
Copies a code reference to the clipboard as markdown, optionally carrying a
commit-pinned permalink. A port of the Saucer VS Code extension.

Lives in the config rather than its own repo, so require("saucer") resolves
without a plugin spec: ~/.config/nvim is already on the runtimepath.
--]]

local M = {}

local config = {
  --- Attach a git permalink to the copied reference. Off by default because
  --- resolving one costs three git calls; <leader>sl and the ! bang force it.
  link = false,
  --- Format <leader>ss copies without prompting; nil shows the picker.
  default = "Reference",
  --- Remote to build permalinks from.
  remote = "origin",
}

--- Runs git in `root`, returning trimmed stdout or nil on any failure.
local function git(root, ...)
  local res = vim.system({ "git", "-C", root, ... }, { text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  return vim.trim(res.stdout or "")
end

--- Splits a remote URL into host and "owner/repo", handling ssh and https forms.
local function parse_remote(url)
  url = url:gsub("%.git$", ""):gsub("/$", "")

  local host, path = url:match("^git@([^:]+):(.+)$")
  if host then
    return host, path
  end

  -- Strip the scheme, then any user@ prefix, before splitting host from path.
  local rest = url:match("^ssh://(.+)$") or url:match("^https?://(.+)$")
  if not rest then
    return nil
  end
  local host, path = rest:gsub("^[^/@]*@", ""):match("^([^/]+)/(.+)$")
  -- An ssh port has no meaning in the web URL these routers build.
  return host and host:gsub(":%d+$", ""), path
end

--- Per-forge line-anchor URL builders, keyed off the remote's own host so
--- self-hosted instances work. `name` is the link text in rendered references.
local ROUTERS = {
  github = {
    name = "GitHub",
    url = function(host, repo, sha, file, s, e)
      local anchor = s == e and ("#L%d"):format(s) or ("#L%d-L%d"):format(s, e)
      return ("https://%s/%s/blob/%s/%s%s"):format(host, repo, sha, file, anchor)
    end,
  },
  gitlab = {
    name = "GitLab",
    url = function(host, repo, sha, file, s, e)
      local anchor = s == e and ("#L%d"):format(s) or ("#L%d-%d"):format(s, e)
      return ("https://%s/%s/-/blob/%s/%s%s"):format(host, repo, sha, file, anchor)
    end,
  },
  bitbucket = {
    name = "Bitbucket",
    url = function(host, repo, sha, file, s, e)
      local anchor = s == e and ("#lines-%d"):format(s) or ("#lines-%d:%d"):format(s, e)
      return ("https://%s/%s/src/%s/%s%s"):format(host, repo, sha, file, anchor)
    end,
  },
  azure = {
    name = "Azure DevOps",
    url = function(host, repo, sha, file, s, e)
      return ("https://%s/%s?path=/%s&version=GC%s&line=%d&lineEnd=%d&lineStartColumn=1&lineEndColumn=1")
        :format(host, repo, file, sha, s, e)
    end,
  },
}

--- Substring matched, so gitlab.acme.com routes like gitlab. Anything unknown
--- gets the GitHub layout, which Gitea, Forgejo and GHE also serve.
local function router_for(host)
  if host:find("gitlab", 1, true) then
    return ROUTERS.gitlab
  end
  if host:find("bitbucket", 1, true) then
    return ROUTERS.bitbucket
  end
  if host:find("dev.azure.com", 1, true) then
    return ROUTERS.azure
  end
  return ROUTERS.github
end

--- Permalink for `file` (repo-relative) at lines s..e plus the forge name,
--- or nil outside a repo.
local function permalink(root, file, s, e)
  local url = git(root, "remote", "get-url", config.remote)
  local sha = git(root, "rev-parse", "HEAD")
  if not url or not sha or url == "" then
    return nil
  end

  local host, repo = parse_remote(url)
  if not host or not repo then
    return nil
  end

  local router = router_for(host)
  return router.url(host, repo, sha, file, s, e), router.name
end

--- True when an LSP range covers every line of `span` (0-based, inclusive).
local function covers(range, span)
  return range.start.line <= span.first and range["end"].line >= span.last
end

--- Walks the symbol tree, collecting the names of every symbol covering `span`.
local function descend(symbols, span, acc)
  for _, sym in ipairs(symbols or {}) do
    local range = sym.range or (sym.location and sym.location.range)
    if range and covers(range, span) then
      acc[#acc + 1] = sym.name
      return descend(sym.children, span, acc)
    end
  end
  return acc
end

--- Dotted path of the innermost symbol covering the whole span, e.g.
--- "Greeter.greet", so a selection across two methods names their class.
--- Nil when no server answers or the span sits outside every symbol.
local function symbol_path(bufnr, span)
  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  local ok, responses = pcall(vim.lsp.buf_request_sync, bufnr, "textDocument/documentSymbol", params, 2000)
  if not ok or not responses then
    return nil
  end

  for _, response in pairs(responses) do
    local path = descend(response.result, span, {})
    if #path > 0 then
      return table.concat(path, ".")
    end
  end
  return nil
end

--- Everything the formats below are built from. `link` decides whether the
--- permalink is resolved at all, since that costs three git calls.
local function gather(line1, line2, link)
  local bufnr = vim.api.nvim_get_current_buf()
  local absolute = vim.api.nvim_buf_get_name(bufnr)
  local root = git(vim.fs.dirname(absolute), "rev-parse", "--show-toplevel")
  local relative = root and absolute:sub(#root + 2) or vim.fn.fnamemodify(absolute, ":t")
  local url, forge
  if link and root then
    url, forge = permalink(root, relative, line1, line2)
  end

  return {
    filename = vim.fn.fnamemodify(absolute, ":t"),
    relative = relative,
    first = line1,
    last = line2,
    symbol = symbol_path(bufnr, { first = line1 - 1, last = line2 - 1 }),
    url = url,
    forge = forge,
  }
end

--- Renders "10" or "10-14" for the reference suffix.
local function lines(ctx)
  return ctx.first == ctx.last and tostring(ctx.first) or ("%d-%d"):format(ctx.first, ctx.last)
end

--- A nil `text` means the format is unavailable here; `bare` emits the raw URL.
local FORMATS = {
  {
    name = "Reference",
    text = function(ctx)
      local ref = ("%s:%s"):format(ctx.relative, lines(ctx))
      return ctx.symbol and ("%s (%s)"):format(ref, ctx.symbol) or ref
    end,
  },
  { name = "Symbol", text = function(ctx) return ctx.symbol and ("`%s`"):format(ctx.symbol) end },
  { name = "File and line", text = function(ctx) return ("`%s:%s`"):format(ctx.filename, lines(ctx)) end },
  { name = "Path and line", text = function(ctx) return ("`%s:%s`"):format(ctx.relative, lines(ctx)) end },
  { name = "Link only", bare = true },
}

--- Renders a format, followed by a "(GitHub)" style link when a permalink resolved.
local function render(format, ctx)
  if format.bare then
    return ctx.url
  end

  local text = format.text(ctx)
  if not text or not ctx.url then
    return text
  end
  return ("%s ([%s](%s))"):format(text, ctx.forge, ctx.url)
end

local function put(text)
  if not text or text == "" then
    vim.notify("saucer: nothing to copy", vim.log.levels.WARN)
    return
  end
  vim.fn.setreg("+", text)
  vim.notify(text)
end

--- Offerable formats, dropping any that render to nothing (no LSP symbol, no
--- permalink) or that duplicate an earlier one (a file at the repo root).
local function choices_for(ctx)
  local seen, choices = {}, {}
  for _, format in ipairs(FORMATS) do
    local text = render(format, ctx)
    if text and not seen[text] then
      seen[text] = true
      choices[#choices + 1] = { name = format.name, text = text }
    end
  end
  return choices
end

--- Copies a reference for lines line1..line2 (defaulting to the cursor line).
--- `link` overrides config.link for this one call; `pick` prompts even when
--- config.default is set.
function M.copy(line1, line2, link, pick)
  if link == nil then
    link = config.link
  end
  local ctx = gather(line1 or vim.fn.line("."), line2 or vim.fn.line("."), link)
  local choices = choices_for(ctx)

  if config.default and not pick then
    for _, choice in ipairs(choices) do
      if choice.name == config.default then
        return put(choice.text)
      end
    end
  end

  vim.ui.select(choices, {
    prompt = "Copy reference as",
    format_item = function(choice)
      return ("%-14s %s"):format(choice.name, choice.text)
    end,
  }, function(choice)
    if choice then
      put(choice.text)
    end
  end)
end

function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})

  -- The bang forces a permalink on, whatever config.link says.
  vim.api.nvim_create_user_command("SaucerCopy", function(args)
    M.copy(args.line1, args.line2, args.bang or nil)
  end, { range = true, bang = true, desc = "Copy a code reference" })
  vim.api.nvim_create_user_command("SaucerPick", function(args)
    M.copy(args.line1, args.line2, args.bang or nil, true)
  end, { range = true, bang = true, desc = "Choose a code reference format to copy" })

  local keymap = { silent = true }
  vim.keymap.set({ "n", "x" }, "<leader>ss", ":SaucerCopy<CR>",
    vim.tbl_extend("force", keymap, { desc = "Copy code reference" }))
  vim.keymap.set({ "n", "x" }, "<leader>sl", ":SaucerPick!<CR>",
    vim.tbl_extend("force", keymap, { desc = "Choose code reference format, with permalink" }))
  vim.keymap.set({ "n", "x" }, "<leader>sp", ":SaucerPick<CR>",
    vim.tbl_extend("force", keymap, { desc = "Choose code reference format" }))
end

return M
