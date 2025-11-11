local M = {}

function M.fetch_services()
  local cache = require 'neo-symfony.cache'
  local cached = cache.get 'services'
  if cached then
    return cached
  end

  local console = require 'neo-symfony.console'
  local output = console.execute_sync 'debug:container --format=json'

  if not output then
    return {}
  end

  local ok, data = pcall(vim.json.decode, output)
  if not ok then
    return {}
  end

  local services = {}

  -- Parse services from JSON
  if data and data.definitions then
    for service_id, service_data in pairs(data.definitions) do
      table.insert(services, {
        id = service_id,
        class = service_data.class or '',
        public = service_data.public or false,
        synthetic = service_data.synthetic or false,
        lazy = service_data.lazy or false,
        tags = service_data.tags or {},
      })
    end
  end

  cache.set('services', services)
  return services
end

function M.fetch_parameters()
  local cache = require 'neo-symfony.cache'
  local cached = cache.get 'parameters'
  if cached then
    return cached
  end

  local console = require 'neo-symfony.console'
  local output = console.execute_sync 'debug:container --parameters --format=json'

  if not output then
    return {}
  end

  local ok, data = pcall(vim.json.decode, output)
  if not ok then
    return {}
  end

  local parameters = {}

  if data and data.parameters then
    for param_name, param_value in pairs(data.parameters) do
      table.insert(parameters, {
        name = param_name,
        value = tostring(param_value),
      })
    end
  end

  cache.set('parameters', parameters)
  return parameters
end

return M
