local M = {}

-- Cache storage
local cache = {
  templates = {},
  routes = {},
  services = {},
  last_updated = {
    templates = 0,
    routes = 0,
    services = 0,
  },
}

-- Default TTL: 5 minutes (300 seconds)
local DEFAULT_TTL = 300

-- Configuration
local config = {
  ttl = DEFAULT_TTL,
}

--- Setup cache with configuration
---@param opts table|nil Configuration options with optional 'ttl' field
function M.setup(opts)
  config = vim.tbl_extend('force', config, opts or {})
end

--- Check if cache is valid based on TTL
---@param cache_type string Type of cache ('templates', 'routes', 'services')
---@return boolean True if cache is still valid
local function is_cache_valid(cache_type)
  local now = os.time()
  local last_update = cache.last_updated[cache_type] or 0
  return (now - last_update) < config.ttl
end

--- Get templates from cache
---@return string[]|nil Array of template paths, or nil if cache invalid
function M.get_templates()
  if is_cache_valid 'templates' and #cache.templates > 0 then
    return cache.templates
  end
  return nil
end

--- Set templates in cache
---@param templates string[] Array of template paths to cache
function M.set_templates(templates)
  cache.templates = templates or {}
  cache.last_updated.templates = os.time()
end

--- Get routes from cache
---@return string[]|nil Array of route names, or nil if cache invalid
function M.get_routes()
  if is_cache_valid 'routes' and #cache.routes > 0 then
    return cache.routes
  end
  return nil
end

--- Set routes in cache
---@param routes string[] Array of route names to cache
function M.set_routes(routes)
  cache.routes = routes or {}
  cache.last_updated.routes = os.time()
end

--- Get services from cache
---@return string[]|nil Array of service IDs, or nil if cache invalid
function M.get_services()
  if is_cache_valid 'services' and #cache.services > 0 then
    return cache.services
  end
  return nil
end

--- Set services in cache
---@param services string[] Array of service IDs to cache
function M.set_services(services)
  cache.services = services or {}
  cache.last_updated.services = os.time()
end

--- Clear all cache entries
function M.clear()
  cache.templates = {}
  cache.routes = {}
  cache.services = {}
  cache.last_updated = {
    templates = 0,
    routes = 0,
    services = 0,
  }
end

--- Clear specific cache type
---@param cache_type string Type of cache to clear ('templates', 'routes', 'services')
function M.clear_type(cache_type)
  if cache[cache_type] then
    cache[cache_type] = {}
    cache.last_updated[cache_type] = 0
  end
end

return M
