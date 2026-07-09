-- Event/listener navigation via debug:event-dispatcher --format=json (async + cached).
local M = {}
local cache = require("neo-symfony.cache")

-- Fetches events asynchronously and calls cb(events) when done.
-- events: list of { event, listeners: [{ class, method, priority }] }
function M.get_events(root, cb)
  if not cache.is_stale(root, "events") then
    local cached = cache.read(root, "events")
    if cached then
      cb(cached)
      return
    end
  end

  vim.system(
    { root .. "/bin/console", "debug:event-dispatcher", "--format=json" },
    { cwd = root, text = true },
    function(result)
      if result.code ~= 0 then
        cb({})
        return
      end
      local ok, data = pcall(vim.json.decode, result.stdout)
      if not ok or not data then
        cb({})
        return
      end
      local events = {}
      for event_name, listeners in pairs(data) do
        local ls = {}
        for _, l in ipairs(listeners) do
          table.insert(ls, {
            class = l.class or l[1],
            method = l.method or l[2],
            priority = l.priority or 0,
          })
        end
        table.insert(events, { event = event_name, listeners = ls })
      end
      cache.write(root, "events", events)
      vim.schedule(function() cb(events) end)
    end
  )
end

return M
