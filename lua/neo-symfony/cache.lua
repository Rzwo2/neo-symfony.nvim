-- lua/symfony/cache.lua
-- Efficient caching system using vim.uv timers for Neovim 0.11+

local M = {}

---@class CacheEntry
---@field data any Cached data
---@field timestamp number Cache creation time
---@field timer uv.uv_timer_t|nil UV timer handle

---@type table<string, CacheEntry>
local cache_store = {}

---@type number Cache TTL in milliseconds
local cache_ttl = 300000 -- Default 5 minutes

---@type uv.uv_timer_t|nil Cleanup timer
local cleanup_timer = nil

---Initialize cache system
---@param ttl number Time-to-live in seconds
function M.init(ttl)
  cache_ttl = ttl * 1000 -- Convert to milliseconds

  -- Setup periodic cleanup (every minute)
  if cleanup_timer then
    cleanup_timer:stop()
    cleanup_timer:close()
  end

  cleanup_timer = vim.uv.new_timer()
  cleanup_timer:start(
    60000,
    60000,
    vim.schedule_wrap(function()
      M.cleanup_expired()
    end)
  )
end

---Get cached data
---@param key string Cache key
---@return any|nil Cached data or nil if expired/missing
function M.get(key)
  local entry = cache_store[key]

  if not entry then
    return nil
  end

  local now = vim.uv.now()
  local age = now - entry.timestamp

  if age > cache_ttl then
    -- Expired, clean up
    M.invalidate(key)
    return nil
  end

  return entry.data
end

---Set cache data with automatic expiration
---@param key string Cache key
---@param data any Data to cache
function M.set(key, data)
  -- Cancel existing timer if any
  if cache_store[key] and cache_store[key].timer then
    cache_store[key].timer:stop()
    cache_store[key].timer:close()
  end

  -- Create expiration timer
  local timer = vim.uv.new_timer()
  timer:start(
    cache_ttl,
    0,
    vim.schedule_wrap(function()
      M.invalidate(key)
    end)
  )

  cache_store[key] = {
    data = data,
    timestamp = vim.uv.now(),
    timer = timer,
  }
end

---Invalidate a specific cache entry
---@param key string Cache key
function M.invalidate(key)
  local entry = cache_store[key]
  if entry then
    if entry.timer then
      entry.timer:stop()
      entry.timer:close()
    end
    cache_store[key] = nil
  end
end

---Invalidate all cache entries
function M.invalidate_all()
  for key, entry in pairs(cache_store) do
    if entry.timer then
      entry.timer:stop()
      entry.timer:close()
    end
  end
  cache_store = {}
end

---Clean up expired entries
function M.cleanup_expired()
  local now = vim.uv.now()
  local expired_keys = {}

  for key, entry in pairs(cache_store) do
    local age = now - entry.timestamp
    if age > cache_ttl then
      table.insert(expired_keys, key)
    end
  end

  for _, key in ipairs(expired_keys) do
    M.invalidate(key)
  end

  if #expired_keys > 0 then
    vim.notify(string.format('Cleaned up %d expired cache entries', #expired_keys), vim.log.levels.DEBUG)
  end
end

---Get cache statistics
---@return table Statistics about cache usage
function M.stats()
  local count = 0
  local total_size = 0

  for _, entry in pairs(cache_store) do
    count = count + 1
    -- Approximate size calculation
    local ok, size = pcall(function()
      return #vim.json.encode(entry.data)
    end)
    if ok then
      total_size = total_size + size
    end
  end

  return {
    entries = count,
    size_bytes = total_size,
    ttl_ms = cache_ttl,
  }
end

---Check if a key exists in cache (regardless of expiration)
---@param key string Cache key
---@return boolean
function M.has(key)
  return cache_store[key] ~= nil
end

return M
