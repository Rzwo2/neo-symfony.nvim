local M = {}

function M.get_completions(ctx)
  local utils = require 'neo-symfony.utils'
  local items = {}

  -- Check context for route name completion
  local is_generate_url = utils.is_inside_function_call 'generateUrl'
  local is_path = utils.is_inside_function_call 'path'
  local is_url = utils.is_inside_function_call 'url'

  if is_generate_url or is_path or is_url then
    local routes = require('neo-symfony.providers.routes').fetch_routes()

    for _, route in ipairs(routes) do
      local params_str = #route.params > 0 and '(' .. table.concat(route.params, ', ') .. ')' or ''

      table.insert(items, {
        label = route.name,
        kind = 'Function',
        detail = route.path .. ' ' .. params_str,
        documentation = string.format(
          'Route: %s\nPath: %s\nController: %s\nMethods: %s\nParameters: %s',
          route.name,
          route.path,
          route.controller,
          table.concat(route.methods, ', '),
          table.concat(route.params, ', ')
        ),
        insertText = route.name,
      })
    end
  end

  return items
end

return M
