local M = {}

local cache = {}
local cache_times = {}

function M.init(project_root)
  M.project_root = project_root
  cache = {}
  cache_times = {}
end

function M.get(key)
  local config = require('neo-symfony').config
  if cache_times[key] then
    local age = os.time() - cache_times[key]
    if age < config.cache_ttl then
      return cache[key]
    end
  end
  return nil
end

function M.set(key, value)
  cache[key] = value
  cache_times[key] = os.time()
end

function M.clear()
  cache = {}
  cache_times = {}
end

return M
