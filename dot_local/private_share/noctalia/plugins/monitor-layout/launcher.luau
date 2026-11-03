--!nonstrict

local script = noctalia.expandPath("~/.local/bin/kanshi-save-layout")

function onQuery(query)
  local text = noctalia.string.trim(query)
  local replacement = text:match("^%-%-replace%s+(.+)$")
  local name = replacement and noctalia.string.trim(replacement) or text
  if text == "" or text == "--replace" then
    launcher.setResults(query, {
      { id = "", title = "Save monitor layout", subtitle = "Type a name; use --replace name to update", glyph = "device-desktop" },
    })
  elseif #name > 64 or not name:match("^[A-Za-z0-9][A-Za-z0-9_%-]*$") then
    launcher.setResults(query, {
      { id = "", title = "Invalid layout name", subtitle = "Use letters, numbers, underscores, or hyphens", glyph = "alert-triangle" },
    })
  else
    launcher.setResults(query, {
      { id = (replacement and "replace:" or "save:") .. name,
        title = (replacement and "Replace layout: " or "Save layout: ") .. name,
        subtitle = "Capture connected outputs in Kanshi", glyph = "device-desktop" },
    })
  end
end

function onActivate(id)
  local action, name = id:match("^(%a+):(.+)$")
  if not name or (action ~= "save" and action ~= "replace") then return end
  local args = { script, "--notify" }
  if action == "replace" then table.insert(args, "--replace") end
  table.insert(args, name)
  if not noctalia.runAsync(args) then
    noctalia.notifyError("Monitor layout", "Could not start the layout saver")
  end
end
