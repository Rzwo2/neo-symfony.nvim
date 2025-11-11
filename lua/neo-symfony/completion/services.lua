local M = {}

function M.get_completions(ctx)
  local utils = require 'neo-symfony.utils'
  local context = utils.get_cursor_context()
  local items = {}

  -- Check if we're inside $container->get() or similar
  local is_get_call = utils.is_inside_function_call 'get'
  local is_param_call = utils.is_inside_function_call 'getParameter'

  if is_get_call then
    -- Service ID completion
    local services = require('neo-symfony.providers.services').fetch_services()

    for _, service in ipairs(services) do
      if service.public then
        table.insert(items, {
          label = service.id,
          kind = 'Class',
          detail = service.class,
          documentation = string.format(
            'Service: %s\nClass: %s\nPublic: %s\nLazy: %s',
            service.id,
            service.class,
            service.public and 'yes' or 'no',
            service.lazy and 'yes' or 'no'
          ),
          insertText = service.id,
        })
      end
    end
  elseif is_param_call then
    -- Parameter completion
    local parameters = require('neo-symfony.providers.services').fetch_parameters()

    for _, param in ipairs(parameters) do
      table.insert(items, {
        label = param.name,
        kind = 'Variable',
        detail = param.value,
        documentation = string.format('Parameter: %s\nValue: %s', param.name, param.value),
        insertText = param.name,
      })
    end
  end

  -- YAML service configuration
  if vim.bo.filetype == 'yaml' then
    local services = require('neo-symfony.providers.services').fetch_services()

    for _, service in ipairs(services) do
      table.insert(items, {
        label = service.id,
        kind = 'Class',
        detail = service.class,
        insertText = service.id,
      })
    end
  end

  return items
end

return M
