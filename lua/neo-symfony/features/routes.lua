-- Parses var/cache/dev/url_generating_routes.php to extract route definitions.
local M = {}
local cache = require("neo-symfony.cache")

-- Returns a list of { name, path, controller, methods } tables.
function M.get_routes(root)
  if not cache.is_stale(root, "routes") then
    local cached = cache.read(root, "routes")
    if cached then return cached end
  end

  -- TODO: parse url_generating_routes.php
  -- The file exports a PHP array — use regex to extract route name, path, defaults._controller
  local routes = {}

  cache.write(root, "routes", routes)
  return routes
end

return M
