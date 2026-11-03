--!nonstrict

local home = "https://directory.cisco.com/"
local results = home .. "find-people/results?query="

function onQuery(query)
  local text = noctalia.string.trim(query)
  if text == "" then
    launcher.setResults(query, {
      { id = "home", title = "Open Cisco Directory", subtitle = "Type a name to search", glyph = "address-book" },
    })
    return
  end

  launcher.setResults(query, {
    { id = "search:" .. text, title = "Search Cisco Directory", subtitle = text, glyph = "address-book" },
  })
end

function onActivate(id)
  local url = home
  if id ~= "home" then
    local query = id:match("^search:(.+)$")
    if not query then return end
    url = results .. noctalia.string.urlEncode(query)
  end
  -- The running shell may still have an outdated BROWSER environment value.
  noctalia.runAsync({ "env", "-u", "BROWSER", "xdg-open", url })
end
