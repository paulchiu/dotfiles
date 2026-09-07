--- Copies the item selected in Superfile onto the macOS pasteboard as a native
--- file object, so Command+V attaches the file in Slack, Mail or Finder instead
--- of pasting its path as text.
---
--- Flow: send Superfile's `copy_path` chord to the frontmost terminal, wait for
--- the pasteboard change count to advance, then replace the copied text path
--- with file URL objects.
---
--- Superfile v1.6.0 limitation: `copy_path` serialises only the focused item
--- (src/internal/handle_file_operations.go copyPath), and `copy_items` writes to
--- Superfile's internal clipboard rather than the system pasteboard, so there is
--- no supported route to the full multi-selection. The pipeline handles a list
--- of paths throughout so a future Superfile version needs only a new parser.
local M = {}

M.config = {
  hotkey = { mods = { "ctrl", "alt" }, key = "c" },

  --- Must match `copy_path` in Superfile's hotkeys.toml.
  copyPathChord = { mods = { "ctrl" }, key = "p" },

  --- Only these applications receive the synthetic copy_path chord.
  terminalBundleIDs = {
    ["com.mitchellh.ghostty"] = true,
    ["com.benfriebe.nex"] = true,
    ["com.apple.Terminal"] = true,
    ["com.googlecode.iterm2"] = true,
  },

  --- Second guard, so the chord is not sent to a terminal running something else.
  requireSuperfileProcess = true,
  superfileProcessName = "spf",

  timeoutSeconds = 1.0,
  pollIntervalSeconds = 0.03,
  keyStrokeDelayMicros = 20000,

  --- Filenames can be sensitive, so paths stay out of the log unless opted in.
  logPaths = false,
}

local log = hs.logger.new("superfileCopy", "info")

--- Generation token: a second hotkey press supersedes the first, and the older
--- timer callback discards itself rather than overwriting a newer selection.
local generation = 0
local pollTimer = nil

local function describe(paths)
  if M.config.logPaths then return table.concat(paths, ", ") end
  return string.format("%d path(s)", #paths)
end

local function isSuperfileContext(app)
  if not app then
    return false, "No frontmost application"
  end
  local bundleID = app:bundleID()
  if not bundleID or not M.config.terminalBundleIDs[bundleID] then
    return false, "Not a Superfile terminal"
  end
  if M.config.requireSuperfileProcess then
    local _, ok = hs.execute("/usr/bin/pgrep -x " .. M.config.superfileProcessName)
    if not ok then
      return false, "Superfile is not running"
    end
  end
  return true
end

local function waitForPasteboardChange(previousChangeCount, timeoutSeconds, callback)
  local deadline = hs.timer.secondsSinceEpoch() + timeoutSeconds
  local timer
  timer = hs.timer.doEvery(M.config.pollIntervalSeconds, function()
    if hs.pasteboard.changeCount() ~= previousChangeCount then
      timer:stop()
      callback(true)
    elseif hs.timer.secondsSinceEpoch() >= deadline then
      timer:stop()
      callback(false)
    end
  end)
  return timer
end

--- Superfile v1.6.0 writes the focused item's absolute path through pbcopy with
--- no delimiter or trailing newline, so the payload is the path verbatim.
--- Nothing is trimmed: whitespace and newlines here would be filename bytes.
local function parseCopiedPaths(text)
  if type(text) ~= "string" or text == "" then
    return nil, "Clipboard held no text"
  end
  return { text }
end

local function validatePaths(paths)
  if #paths == 0 then
    return nil, "Nothing to copy"
  end
  local seen, validated = {}, {}
  for _, path in ipairs(paths) do
    if path:sub(1, 1) ~= "/" then
      return nil, "Not an absolute path"
    end
    -- stat, not lstat: a broken symlink fails, a live one keeps its own path.
    if not hs.fs.attributes(path) then
      return nil, "Path no longer exists"
    end
    if not seen[path] then
      seen[path] = true
      validated[#validated + 1] = path
    end
  end
  return validated
end

--- Characters NSCharacterSet.urlPathAllowed leaves unencoded, verified
--- byte-for-byte against hs.fs.urlFromPath over every printable ASCII byte.
local URL_PATH_DISALLOWED = "[^A-Za-z0-9%-%._~!%$&'%(%)%*%+,=:@/]"

--- Percent-encodes a POSIX path into a file URL, preserving `/` as the
--- separator. hs.fs.urlFromPath is URL-aware but runs
--- stringByResolvingSymlinksInPath, which would rewrite a selected symlink to
--- its target and rename the resulting attachment.
local function fileURLFromPath(path)
  local encoded = path:gsub(URL_PATH_DISALLOWED, function(byte)
    return string.format("%%%02X", byte:byte())
  end)
  return "file://" .. encoded
end

--- Builds every file URL before touching the pasteboard, so a bad path cannot
--- leave a partial selection behind.
local function writeFileObjects(paths)
  local objects = {}
  for _, path in ipairs(paths) do
    objects[#objects + 1] = { url = fileURLFromPath(path) }
  end
  if not hs.pasteboard.writeObjects(objects) then
    return false, "Pasteboard write was rejected"
  end
  return true
end

local function fail(message)
  log.i("copy failed: " .. message)
  hs.alert.show(message)
end

function M.copySelection()
  local app = hs.application.frontmostApplication()
  local contextOK, contextErr = isSuperfileContext(app)
  if not contextOK then
    return fail(contextErr)
  end
  if hs.eventtap.isSecureInputEnabled() then
    return fail("Secure input is on; keystroke blocked")
  end

  generation = generation + 1
  local token = generation
  if pollTimer then
    pollTimer:stop()
    pollTimer = nil
  end

  local previousChangeCount = hs.pasteboard.changeCount()
  hs.eventtap.keyStroke(
    M.config.copyPathChord.mods,
    M.config.copyPathChord.key,
    M.config.keyStrokeDelayMicros
  )

  pollTimer = waitForPasteboardChange(previousChangeCount, M.config.timeoutSeconds, function(changed)
    if token ~= generation then
      return
    end
    pollTimer = nil

    if not changed then
      return fail("Superfile did not copy a selection")
    end

    local paths, parseErr = parseCopiedPaths(hs.pasteboard.readString())
    if not paths then
      return fail(parseErr)
    end

    local validated, validateErr = validatePaths(paths)
    if not validated then
      return fail(validateErr)
    end

    local written, writeErr = writeFileObjects(validated)
    if not written then
      return fail(writeErr)
    end

    log.i("copied " .. describe(validated))
    hs.alert.show(#validated == 1 and "Copied 1 file" or ("Copied " .. #validated .. " files"))
  end)
end

function M.bind()
  if M.hotkey then
    M.hotkey:delete()
  end
  M.hotkey = hs.hotkey.bind(M.config.hotkey.mods, M.config.hotkey.key, M.copySelection)
  return M.hotkey
end

--- Exposed for driving the pieces from the Hammerspoon console during testing.
M.internal = {
  isSuperfileContext = isSuperfileContext,
  parseCopiedPaths = parseCopiedPaths,
  fileURLFromPath = fileURLFromPath,
  validatePaths = validatePaths,
  writeFileObjects = writeFileObjects,
}

return M
