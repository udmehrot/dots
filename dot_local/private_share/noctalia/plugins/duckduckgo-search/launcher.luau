--!nonstrict

local home = "https://duckduckgo.com/"

function onQuery(query)
  local text = noctalia.string.trim(query)
  if text == "" then
    launcher.setResults(query, {
      { id = "home", title = "Open DuckDuckGo", subtitle = "Type a search query", glyph = "world-search" },
    })
    return
  end

  launcher.setResults(query, {
    { id = "search:" .. text, title = "Search DuckDuckGo", subtitle = text, glyph = "world-search" },
  })
end

function onActivate(id)
  local url = home
  if id ~= "home" then
    local query = id:match("^search:(.+)$")
    if not query then return end
    url = home .. "?q=" .. noctalia.string.urlEncode(query)
  end
  -- The running shell may still have an outdated BROWSER environment value.
  noctalia.runAsync({ "env", "-u", "BROWSER", "xdg-open", url })
end
