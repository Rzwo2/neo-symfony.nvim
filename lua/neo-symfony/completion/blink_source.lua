local cache = require 'neo-symfony.cache'
local console = require 'neo-symfony.console'
local context = require 'neo-symfony.completion.context'

local M = {}

function M.new(opts, config)
  return setmetatable({}, { __index = M })
end

---@return string[]
function M.get_trigger_characters()
  return { "'", '"', '(', '>', ':', '/' }
end

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

---@param ctx table Completion context from blink.cmp
---@param callback function Callback to return items
function M.get_completions(ctx, callback)
  local symfony = require 'neo-symfony'

  if not symfony.project_root then
    callback { items = {} }
    return
  end

  local comp_type = context.detect_completion_type(ctx)

  if not comp_type or not symfony.is_feature_enabled(comp_type) then
    callback { items = {} }
    return
  end

  if comp_type == 'services' then
    local services = require('neo-symfony.features.container').get_services(symfony.project_root)
    callback { items = format_items(services, 'services'), is_incomplete = false }
    return
  end

  local cached = cache.get(comp_type)
  if cached then
    callback { items = format_items(cached, comp_type), is_incomplete = false }
    return
  end

  vim.schedule(function()
    console.fetch_async(symfony.project_root, comp_type, symfony.config, function(data)
      if data then
        cache.set(comp_type, data)
        callback { items = format_items(data, comp_type), is_incomplete = false }
      else
        callback { items = {}, is_incomplete = false }
      end
    end)
  end)
end

---@param item table Completion item
---@param callback function Callback with resolved item
function M.resolve(item, callback)
  callback(item)
end

---@param data table
---@param comp_type string
---@return table[]
function format_items(data, comp_type)
  local items = {}

  local types_ok, types = pcall(require, 'blink.cmp.types')
  local Kind = types_ok and types.CompletionItemKind or {}

  if comp_type == 'services' then
    for _, svc in ipairs(data) do
      table.insert(items, {
        label = svc.id,
        kind = Kind.Interface or 8,
        detail = svc.class ~= '' and svc.class or 'Symfony Service',
        documentation = {
          kind = 'markdown',
          value = string.format(
            '**Service**: `%s`\n\n**Class**: `%s`\n\n**Public**: %s',
            svc.id,
            svc.class ~= '' and svc.class or 'N/A',
            svc.public and 'yes' or 'no'
          ),
        },
        insertText = svc.id,
        filterText = svc.id,
        sortText = svc.id,
      })
    end
  elseif comp_type == 'routes' then
    for route_name, route_info in pairs(data) do
      table.insert(items, {
        label = route_name,
        kind = Kind.Function or 3,
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
        kind = Kind.File or 17,
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
        kind = Kind.Text or 1,
        detail = translation.value or 'Translation Key',
        documentation = {
          kind = 'markdown',
          value = string.format(
            '**Key**: `%s`\n\n**Domain**: `%s`\n\n**Value**: %s',
            key,
            translation.domain or 'messages',
            translation.value or 'N/A'
          ),
        },
        insertText = key,
        filterText = key,
      })
    end
  elseif comp_type == 'forms' then
    for _, form_type in ipairs(data) do
      table.insert(items, {
        label = form_type.name or form_type,
        kind = Kind.Class or 7,
        detail = form_type.fqcn or 'Form Type',
        documentation = {
          kind = 'markdown',
          value = string.format(
            '**Form Type**: `%s`\n\n**FQCN**: `%s`',
            form_type.name or form_type,
            form_type.fqcn or 'N/A'
          ),
        },
        insertText = form_type.name or form_type,
        filterText = (form_type.name or form_type) .. ' ' .. (form_type.fqcn or ''),
      })
    end
  elseif comp_type == 'doctrine' then
    for _, entity in ipairs(data) do
      table.insert(items, {
        label = entity.short_name or entity.class,
        kind = Kind.Class or 7,
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

return M
