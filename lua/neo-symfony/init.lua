local M = {}

local cache = require 'neo-symfony.cache'
local utils = require 'neo-symfony.utils'

-- Default configuration
local default_config = {
  -- Cache TTL in seconds (default: 5 minutes)
  cache_ttl = 300,

  -- Symfony console environment
  console_env = 'dev',

  -- Symfony project detection patterns
  symfony_root_patterns = {
    'composer.json',
    'symfony.lock',
    'bin/console',
  },

  -- Enable/disable specific completions
  completion = {
    services = true,
    routes = true,
    templates = true,
    translations = true,
    forms = true,
    doctrine = true,
  },

  -- Blink.cmp integration
  blink_cmp = {
    enabled = true,
    name = 'symfony',
    score_offset = 10, -- Priority boost for symfony completions
    opts = {},
  },

  -- Telescope integration
  telescope_enabled = true,

  -- Phpactor integration
  phpactor_enabled = true,
}

-- Plugin configuration
local config = vim.deepcopy(default_config)

--- Setup function to initialize the plugin
---@param opts table|nil User configuration options
function M.setup(opts)
  -- Merge user config with defaults
  config = vim.tbl_deep_extend('force', default_config, opts or {})

  -- Setup cache
  cache.setup { ttl = config.cache_ttl }

  -- Auto-configure blink.cmp if enabled
  if config.blink_cmp.enabled then
    M.setup_blink_cmp()
  end

  -- Setup commands
  M.setup_commands()

  -- Setup telescope if enabled
  if config.telescope_enabled then
    local has_telescope = pcall(require, 'telescope')
    if has_telescope then
      M.setup_telescope()
    end
  end

  -- Warm up cache on startup (optional)
  vim.defer_fn(function()
    M.reload_cache()
  end, 100)
end

--- Setup blink.cmp integration by registering the symfony source
function M.setup_blink_cmp()
  local has_blink, blink = pcall(require, 'blink.cmp')
  if not has_blink then
    return
  end

  -- Get current config
  local blink_config = blink.config or {}

  -- Ensure sources table exists
  blink_config.sources = blink_config.sources or {}
  blink_config.sources.providers = blink_config.sources.providers or {}
  blink_config.sources.default = blink_config.sources.default or { 'lsp', 'path', 'snippets', 'buffer' }

  -- Add symfony provider
  blink_config.sources.providers.symfony = vim.tbl_extend('force', {
    name = config.blink_cmp.name,
    module = 'neo-symfony.completion.source',
    enabled = true,
    score_offset = config.blink_cmp.score_offset,
  }, config.blink_cmp.opts)

  -- Add to default sources if not already present
  if not vim.tbl_contains(blink_config.sources.default, 'symfony') then
    table.insert(blink_config.sources.default, 'symfony')
  end

  -- Update blink.cmp config
  -- Note: This assumes blink.cmp v1.7+
  -- For newer versions, you may need to call blink.setup() again
end

--- Setup user commands for plugin interaction
function M.setup_commands()
  -- Reload cache
  vim.api.nvim_create_user_command('SymfonyReload', function()
    M.reload_cache()
    vim.notify('Symfony cache reloaded', vim.log.levels.INFO)
  end, { desc = 'Reload Symfony cache' })

  -- Show services
  vim.api.nvim_create_user_command('SymfonyServices', function()
    M.show_services()
  end, { desc = 'List Symfony services' })

  -- Show routes
  vim.api.nvim_create_user_command('SymfonyRoutes', function()
    M.show_routes()
  end, { desc = 'List Symfony routes' })

  -- Show templates
  vim.api.nvim_create_user_command('SymfonyTemplates', function()
    M.show_templates()
  end, { desc = 'List Symfony templates' })

  -- Show plugin info
  vim.api.nvim_create_user_command('SymfonyInfo', function()
    M.show_info()
  end, { desc = 'Show Symfony plugin info' })
end

--- Reload all caches by fetching fresh data from Symfony
function M.reload_cache()
  cache.clear()

  if config.completion.templates then
    utils.fetch_templates(function(templates)
      cache.set_templates(templates)
    end)
  end

  if config.completion.routes then
    utils.fetch_routes(function(routes)
      cache.set_routes(routes)
    end)
  end

  if config.completion.services then
    utils.fetch_services(function(services)
      cache.set_services(services)
    end)
  end
end

--- Show services in a new buffer
function M.show_services()
  local services = cache.get_services()
  if not services then
    utils.fetch_services(function(fetched)
      cache.set_services(fetched)
      M.display_in_buffer('Symfony Services', fetched)
    end)
  else
    M.display_in_buffer('Symfony Services', services)
  end
end

--- Show routes in a new buffer
function M.show_routes()
  local routes = cache.get_routes()
  if not routes then
    utils.fetch_routes(function(fetched)
      cache.set_routes(fetched)
      M.display_in_buffer('Symfony Routes', fetched)
    end)
  else
    M.display_in_buffer('Symfony Routes', routes)
  end
end

--- Show templates in a new buffer
function M.show_templates()
  local templates = cache.get_templates()
  if not templates then
    utils.fetch_templates(function(fetched)
      cache.set_templates(fetched)
      M.display_in_buffer('Symfony Templates', fetched)
    end)
  else
    M.display_in_buffer('Symfony Templates', templates)
  end
end

--- Display items in a new scratch buffer
---@param title string Buffer title to display
---@param items string[] List of items to display
function M.display_in_buffer(title, items)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false

  local lines = { title, string.rep('=', #title), '' }
  vim.list_extend(lines, items)

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(buf)
end

--- Show plugin information and configuration
function M.show_info()
  local root = utils.find_symfony_root()

  local info = {
    'Neo-Symfony Plugin Information',
    '================================',
    '',
    'Symfony Root: ' .. (root or 'Not found'),
    'Cache TTL: ' .. config.cache_ttl .. ' seconds',
    'Console Env: ' .. config.console_env,
    '',
    'Enabled Features:',
    '  - Services: ' .. tostring(config.completion.services),
    '  - Routes: ' .. tostring(config.completion.routes),
    '  - Templates: ' .. tostring(config.completion.templates),
    '  - Translations: ' .. tostring(config.completion.translations),
    '  - Forms: ' .. tostring(config.completion.forms),
    '  - Doctrine: ' .. tostring(config.completion.doctrine),
    '',
    'Integrations:',
    '  - Blink.cmp: ' .. tostring(config.blink_cmp.enabled),
    '  - Telescope: ' .. tostring(config.telescope_enabled),
    '  - Phpactor: ' .. tostring(config.phpactor_enabled),
  }

  M.display_in_buffer('Symfony Info', info)
end

--- Setup telescope integration (placeholder for future implementation)
function M.setup_telescope()
  -- This would be implemented separately
  -- See telescope.lua for full implementation
end

--- Get current plugin configuration
---@return table Current configuration table
function M.get_config()
  return config
end

return M
