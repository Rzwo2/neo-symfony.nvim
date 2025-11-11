local M = {}

function M.get_completions(ctx)
  local utils = require 'symfony.utils'
  local items = {}

  -- Check if we're inside render() or similar
  local is_render = utils.is_inside_function_call 'render'
  local is_render_view = utils.is_inside_function_call 'renderView'

  if is_render or is_render_view then
    local templates = require('neo-symfony.providers.templates').fetch_templates()

    for _, template in ipairs(templates) do
      table.insert(items, {
        label = template.path,
        kind = 'File',
        detail = 'Template',
        documentation = 'Template: ' .. template.path,
        insertText = template.path,
      })
    end
  end

  return items
end

return M
