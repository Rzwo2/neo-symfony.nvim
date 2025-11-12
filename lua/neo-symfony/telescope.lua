-- Telescope pickers for Symfony resources

local M = {}

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local entry_display = require 'telescope.pickers.entry_display'

local cache = require 'symfony.cache'
local console = require 'symfony.console'

---Create a Symfony services picker
---@param opts? table Telescope options
function M.services(opts)
  local symfony = require 'symfony'

  if not symfony.project_root then
    vim.notify('No Symfony project detected', vim.log.levels.WARN)
    return
  end

  opts = opts or {}

  -- Try to get cached services first
  local cached = cache.get 'services'

  if cached then
    M._show_services_picker(cached, opts)
  else
    -- Fetch services asynchronously
    vim.notify('Fetching Symfony services...', vim.log.levels.INFO)
    console.fetch_services(symfony.project_root, symfony.config, function(services)
      if services then
        cache.set('services', services)
        vim.schedule(function()
          M._show_services_picker(services, opts)
        end)
      else
        vim.notify('Failed to fetch services', vim.log.levels.ERROR)
      end
    end)
  end
end

---Show services picker
---@param services table Services data
---@param opts table Telescope options
function M._show_services_picker(services, opts)
  -- Convert services to array
  local items = {}
  for id, service in pairs(services) do
    table.insert(items, {
      id = id,
      class = service.class or 'N/A',
      public = service.public,
      aliases = service.aliases or {},
    })
  end

  -- Sort by id
  table.sort(items, function(a, b)
    return a.id < b.id
  end)

  -- Create displayer for formatted output
  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = 50 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    return displayer {
      { entry.id, 'TelescopeResultsIdentifier' },
      { entry.class, 'TelescopeResultsComment' },
    }
  end

  pickers
    .new(opts, {
      prompt_title = 'Symfony Services',
      finder = finders.new_table {
        results = items,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display,
            ordinal = entry.id .. ' ' .. entry.class,
            id = entry.id,
            class = entry.class,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection then
            -- Insert service ID at cursor
            vim.api.nvim_put({ selection.id }, 'c', true, true)
          end
        end)
        return true
      end,
      previewer = conf.grep_previewer(opts),
    })
    :find()
end

---Create a Symfony routes picker
---@param opts? table Telescope options
function M.routes(opts)
  local symfony = require 'symfony'

  if not symfony.project_root then
    vim.notify('No Symfony project detected', vim.log.levels.WARN)
    return
  end

  opts = opts or {}

  local cached = cache.get 'routes'

  if cached then
    M._show_routes_picker(cached, opts)
  else
    vim.notify('Fetching Symfony routes...', vim.log.levels.INFO)
    console.fetch_routes(symfony.project_root, symfony.config, function(routes)
      if routes then
        cache.set('routes', routes)
        vim.schedule(function()
          M._show_routes_picker(routes, opts)
        end)
      else
        vim.notify('Failed to fetch routes', vim.log.levels.ERROR)
      end
    end)
  end
end

---Show routes picker
---@param routes table Routes data
---@param opts table Telescope options
function M._show_routes_picker(routes, opts)
  local items = {}
  for name, route in pairs(routes) do
    table.insert(items, {
      name = name,
      path = route.path or 'N/A',
      methods = route.methods or {},
      controller = route.controller or 'N/A',
    })
  end

  table.sort(items, function(a, b)
    return a.name < b.name
  end)

  local displayer = entry_display.create {
    separator = ' │ ',
    items = {
      { width = 30 },
      { width = 40 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    local methods = table.concat(entry.methods, ', ')
    if methods == '' then
      methods = 'ANY'
    end

    return displayer {
      { entry.name, 'TelescopeResultsIdentifier' },
      { entry.path, 'TelescopeResultsFunction' },
      { methods, 'TelescopeResultsComment' },
    }
  end

  pickers
    .new(opts, {
      prompt_title = 'Symfony Routes',
      finder = finders.new_table {
        results = items,
        entry_maker = function(entry)
          return {
            value = entry,
            display = make_display,
            ordinal = entry.name .. ' ' .. entry.path,
            name = entry.name,
            path = entry.path,
          }
        end,
      },
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()

          if selection then
            vim.api.nvim_put({ selection.name }, 'c', true, true)
          end
        end)
        return true
      end,
    })
    :find()
end

---Create a Symfony templates picker
---@param opts? table Telescope options
function M.templates(opts)
  local symfony = require 'symfony'

  if not symfony.project_root then
    vim.notify('No Symfony project detected', vim.log.levels.WARN)
    return
  end

  opts = opts or {}

  local cached = cache.get 'templates'

  if cached then
    M._show_templates_picker(cached, opts)
  else
    vim.notify('Fetching Symfony templates...', vim.log.levels.INFO)
    console.fetch_templates(symfony.project_root, function(templates)
      if templates then
        cache.set('templates', templates)
        vim.schedule(function()
          M._show_templates_picker(templates, opts)
        end)
      else
        vim.notify('Failed to fetch templates', vim.log.levels.ERROR)
      end
    end)
  end
end

---Show templates picker
---@param templates table Templates data
---@param opts table Telescope options
function M._show_templates_picker(templates, opts)
  pickers
    .new(opts, {
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
      attach_mappings = function(prompt_bufnr, map)
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
    })
    :find()
end

return M
