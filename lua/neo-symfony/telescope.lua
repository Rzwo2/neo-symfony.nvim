-- Telescope pickers for Symfony resources

local M = {}

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local entry_display = require 'telescope.pickers.entry_display'

local cache = require 'neo-symfony.cache'
local console = require 'neo-symfony.console'

local function require_root(label)
  local symfony = require 'neo-symfony'
  if not symfony.project_root then
    vim.notify('No Symfony project detected', vim.log.levels.WARN)
    return nil
  end
  return symfony.project_root
end

---@param opts? table Telescope options
function M.services(opts)
  local root = require_root()
  if not root then return end

  opts = opts or {}
  local services = require('neo-symfony.features.container').get_services(root)

  local items = {}
  for _, service in ipairs(services) do
    table.insert(items, {
      id = service.id,
      class = service.class ~= '' and service.class or 'N/A',
    })
  end
  table.sort(items, function(a, b) return a.id < b.id end)

  local displayer = entry_display.create {
    separator = ' ',
    items = { { width = 50 }, { remaining = true } },
  }

  pickers.new(opts, {
    prompt_title = 'Symfony Services',
    finder = finders.new_table {
      results = items,
      entry_maker = function(entry)
        return {
          value = entry,
          display = function(e)
            return displayer {
              { e.id, 'TelescopeResultsIdentifier' },
              { e.class, 'TelescopeResultsComment' },
            }
          end,
          ordinal = entry.id .. ' ' .. entry.class,
          id = entry.id,
          class = entry.class,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.api.nvim_put({ selection.id }, 'c', true, true)
        end
      end)
      return true
    end,
  }):find()
end

---@param opts? table Telescope options
function M.routes(opts)
  local root = require_root()
  if not root then return end

  opts = opts or {}

  local cached = cache.get('routes', root)
  if cached then
    show_routes_picker(cached, opts)
    return
  end

  vim.notify('Fetching Symfony routes...', vim.log.levels.INFO)
  local symfony = require 'neo-symfony'
  console.fetch_routes(root, symfony.config, function(routes)
    if routes then
      cache.set('routes', routes, root)
      vim.schedule(function() show_routes_picker(routes, opts) end)
    else
      vim.notify('Failed to fetch routes', vim.log.levels.ERROR)
    end
  end)
end

---@param routes table
---@param opts table
function show_routes_picker(routes, opts)
  local items = {}
  for name, route in pairs(routes) do
    table.insert(items, {
      name = name,
      path = route.path or 'N/A',
      methods = route.methods or {},
      controller = route.controller or 'N/A',
    })
  end
  table.sort(items, function(a, b) return a.name < b.name end)

  local displayer = entry_display.create {
    separator = ' │ ',
    items = { { width = 30 }, { width = 40 }, { remaining = true } },
  }

  pickers.new(opts, {
    prompt_title = 'Symfony Routes',
    finder = finders.new_table {
      results = items,
      entry_maker = function(entry)
        return {
          value = entry,
          display = function(route)
            local methods = table.concat(route.methods, ', ')
            if methods == '' then methods = 'ANY' end
            return displayer {
              { route.name, 'TelescopeResultsIdentifier' },
              { route.path, 'TelescopeResultsFunction' },
              { methods, 'TelescopeResultsComment' },
            }
          end,
          ordinal = entry.name .. ' ' .. entry.path,
          name = entry.name,
          path = entry.path,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.api.nvim_put({ selection.name }, 'c', true, true)
        end
      end)
      return true
    end,
  }):find()
end

---@param opts? table Telescope options
function M.templates(opts)
  local root = require_root()
  if not root then return end

  opts = opts or {}

  local cached = cache.get('templates', root)
  if cached then
    show_templates_picker(cached, opts)
    return
  end

  vim.notify('Fetching Symfony templates...', vim.log.levels.INFO)
  console.fetch_templates(root, function(templates)
    if templates then
      cache.set('templates', templates, root)
      vim.schedule(function() show_templates_picker(templates, opts) end)
    else
      vim.notify('Failed to fetch templates', vim.log.levels.ERROR)
    end
  end)
end

---@param templates table
---@param opts table
function show_templates_picker(templates, opts)
  pickers.new(opts, {
    prompt_title = 'Symfony Templates',
    finder = finders.new_table {
      results = templates,
      entry_maker = function(entry)
        local path = entry.path or entry
        return {
          value = path,
          display = path,
          ordinal = path,
          path = path,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          vim.api.nvim_put({ selection.path }, 'c', true, true)
        end
      end)
      return true
    end,
    previewer = conf.file_previewer(opts),
  }):find()
end

---@param opts? table Telescope options
function M.commands(opts)
  local root = require_root()
  if not root then return end

  opts = opts or {}
  require('neo-symfony.features.commands').get_commands(root, function(cmds)
    vim.schedule(function()
      pickers.new(opts, {
        prompt_title = 'Symfony Commands',
        finder = finders.new_table {
          results = cmds,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.name .. '  ' .. (entry.description or ''),
              ordinal = entry.name,
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then vim.notify('Command: ' .. selection.value.name) end
          end)
          return true
        end,
      }):find()
    end)
  end)
end

---@param opts? table Telescope options
function M.events(opts)
  local root = require_root()
  if not root then return end

  opts = opts or {}
  require('neo-symfony.features.events').get_events(root, function(evts)
    vim.schedule(function()
      local flat = {}
      for _, event in ipairs(evts) do
        for _, listener in ipairs(event.listeners or {}) do
          table.insert(flat, { event = event.event, class = listener.class, method = listener.method })
        end
      end

      local displayer = entry_display.create {
        separator = '  →  ',
        items = { { width = 45 }, { remaining = true } },
      }

      pickers.new(opts, {
        prompt_title = 'Symfony Events',
        finder = finders.new_table {
          results = flat,
          entry_maker = function(entry)
            return {
              value = entry,
              display = function(evt)
                return displayer {
                  { evt.event, 'TelescopeResultsIdentifier' },
                  { evt.class or '', 'TelescopeResultsComment' },
                }
              end,
              ordinal = entry.event .. ' ' .. (entry.class or ''),
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _)
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            -- TODO: resolve class to file path and open
            local selection = action_state.get_selected_entry()
            if selection then vim.notify('Listener: ' .. (selection.value.class or '')) end
          end)
          return true
        end,
      }):find()
    end)
  end)
end

---@param opts? table Telescope options
function M.doctrine(opts)
  local root = require_root()
  if not root then return end

  opts = opts or {}
  local entities = require('neo-symfony.features.doctrine').get_entities(root)

  pickers.new(opts, {
    prompt_title = 'Symfony Entities',
    finder = finders.new_table {
      results = entities,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
          path = entry.path,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and selection.path then
          vim.cmd('edit ' .. vim.fn.fnameescape(selection.path))
        end
      end)
      return true
    end,
    previewer = conf.file_previewer(opts),
  }):find()
end

return M
