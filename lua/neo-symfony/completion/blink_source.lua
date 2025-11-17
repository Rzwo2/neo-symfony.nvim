local cache = require 'neo-symfony.cache'
local console = require 'neo-symfony.console'
local context = require 'neo-symfony.completion.context'

local M = {}

---Get trigger characters for Symfony completion
---@return string[]
function M.get_trigger_characters()
  return { "'", '"', '(', '>', ':', '/' }
end

---Check if completion should be triggered
---@param ctx table Context from blink.cmp
---@return boolean
function M.enabled(ctx)
  local symfony = require 'neo-symfony'

  if not symfony.project_root then
    return false
  end

  local filetype = vim.bo[ctx.bufnr].filetype
  return vim.tbl_contains({ 'php', 'twig', 'yaml', 'yml' }, filetype)
end

---Get completions asynchronously
---@param ctx table Completion context from blink.cmp
---@param callback function Callback to return items
function M.get_completions(ctx, callback)
  local symfony = require 'neo-symfony'

  if not symfony.project_root then
    callback { items = {} }
    return
  end

  -- Determine completion type based on context
  local comp_type = context.detect_completion_type(ctx)

  if not comp_type or not symfony.is_feature_enabled(comp_type) then
    callback { items = {} }
    return
  end

  -- Try cache first for performance
  local cached = cache.get(comp_type)
  if cached then
    local items = M.format_items(cached, comp_type, ctx)
    callback { items = items, is_incomplete = false }
    return
  end

  -- Fetch from console asynchronously
  vim.schedule(function()
    console.fetch_async(symfony.project_root, comp_type, symfony.config, function(data)
      if data then
        cache.set(comp_type, data)
        local items = M.format_items(data, comp_type, ctx)
        callback { items = items, is_incomplete = false }
      else
        callback { items = {}, is_incomplete = false }
      end
    end)
  end)
end

---Format items for blink.cmp
---@param data table Raw data from console
---@param comp_type string Completion type
---@param ctx table Completion context
---@return table[] Formatted completion items
function M.format_items(data, comp_type, ctx)
  local items = {}

  -- Get CompletionItemKind from blink.cmp
  local kind_ok, types = pcall(require, 'blink.cmp.types')
  local CompletionItemKind = kind_ok and types.CompletionItemKind or {}

  if comp_type == 'services' then
    for service_id, service_info in pairs(data) do
      table.insert(items, {
        label = service_id,
        kind = CompletionItemKind.Interface or 8,
        detail = service_info.class or 'Symfony Service',
        documentation = {
          kind = 'markdown',
          value = string.format(
            '**Service**: `%s`\n\n**Class**: `%s`\n\n**Aliases**: %s',
            service_id,
            service_info.class or 'N/A',
            service_info.aliases and table.concat(service_info.aliases, ', ') or 'None'
          ),
        },
        insertText = service_id,
        filterText = service_id,
        sortText = string.format('%03d_%s', service_info.priority or 100, service_id),
      })
    end
  elseif comp_type == 'routes' then
    for route_name, route_info in pairs(data) do
      table.insert(items, {
        label = route_name,
        kind = CompletionItemKind.Function or 3,
        detail = route_info.path or 'Symfony Route',
        documentation = {
          kind = 'markdown',
          value = string.format(
            '**Route**: `%s`\n\n**Path**: `%s`\n\n**Methods**: %s\n\n**Controller**: `%s`',
            route_name,
            route_info.path or 'N/A',
            route_info.methods and table.concat(route_info.methods, ', ') or 'ANY',
            route_info.controller or 'N/A'
          ),
        },
        insertText = route_name,
        filterText = route_name .. ' ' .. (route_info.path or ''),
      })
    end
  elseif comp_type == 'templates' then
    for _, template in ipairs(data) do
      local label = template.path or template
      table.insert(items, {
        label = label,
        kind = CompletionItemKind.File or 17,
        detail = 'Twig Template',
        documentation = {
          kind = 'markdown',
          value = string.format('**Template**: `%s`', label),
        },
        insertText = label,
        filterText = label,
      })
    end
  elseif comp_type == 'translations' then
    for key, translation in pairs(data) do
      table.insert(items, {
        label = key,
        kind = CompletionItemKind.Text or 1,
        detail = translation.value or 'Translation Key',
        documentation = {
          kind = 'markdown',
          value = string.format('**Key**: `%s`\n\n**Domain**: `%s`\n\n**Value**: %s', key, translation.domain or 'messages', translation.value or 'N/A'),
        },
        insertText = key,
        filterText = key,
      })
    end
  elseif comp_type == 'forms' then
    for _, form_type in ipairs(data) do
      table.insert(items, {
        label = form_type.name or form_type,
        kind = CompletionItemKind.Class or 7,
        detail = form_type.fqcn or 'Form Type',
        documentation = {
          kind = 'markdown',
          value = string.format('**Form Type**: `%s`\n\n**FQCN**: `%s`', form_type.name or form_type, form_type.fqcn or 'N/A'),
        },
        insertText = form_type.name or form_type,
        filterText = (form_type.name or form_type) .. ' ' .. (form_type.fqcn or ''),
      })
    end
  elseif comp_type == 'doctrine' then
    for _, entity in ipairs(data) do
      table.insert(items, {
        label = entity.short_name or entity.class,
        kind = CompletionItemKind.Class or 7,
        detail = entity.class or 'Doctrine Entity',
        documentation = {
          kind = 'markdown',
          value = string.format(
            '**Entity**: `%s`\n\n**Table**: `%s`\n\n**Repository**: `%s`',
            entity.class or 'N/A',
            entity.table or 'N/A',
            entity.repository or 'Default'
          ),
        },
        insertText = entity.class,
        filterText = (entity.short_name or '') .. ' ' .. (entity.class or ''),
      })
    end
  end

  return items
end

---Resolve completion item (lazy loading additional info)
---@param item table Completion item
---@param callback function Callback with resolved item
function M.resolve(item, callback)
  -- For now, all info is provided during get_completions
  -- This could be used for lazy loading documentation or additional details
  callback(item)
end

return M
