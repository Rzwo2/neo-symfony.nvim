local M = {}

function M.fetch_routes()
  local cache = require 'neo-symfony.cache'
  local cached = cache.get 'routes'
  if cached then
    return cached
  end

  local console = require 'neo-symfony.console'
  local output = console.execute_sync 'debug:router --format=json'

  if not output then
    return {}
  end

  local ok, data = pcall(vim.json.decode, output)
  if not ok then
    return {}
  end

  local routes = {}

  for route_name, route_data in pairs(data or {}) do
    local params = {}
    if route_data.path then
      for param in route_data.path:gmatch '{([^}]+)}' do
        table.insert(params, param)
      end
    end

    table.insert(routes, {
      name = route_name,
      path = route_data.path or '',
      controller = route_data.controller or '',
      methods = route_data.methods or {},
      params = params,
    })
  end

  cache.set('routes', routes)
  return routes
end

return M
