local M = {}

---@class SymfonyConfig
---@field phpactor_enabled boolean Enable phpactor integration
---@field telescope_enabled boolean Enable telescope pickers
---@field symfony_root_patterns table Patterns to detect Symfony projects
---@field cache_ttl number Cache time-to-live in seconds
---@field console_env string Symfony environment for console commands
---@field completion table Completion feature flags
---@field blink_cmp table Blink.cmp configuration

---@type SymfonyConfig
local default_config = {
  phpactor_enabled = true,
  telescope_enabled = true,
  symfony_root_patterns = {
    'composer.json',
    'symfony.lock',
    'bin/console',
  },
  cache_ttl = 300,
  console_env = 'dev',
  completion = {
    services = true,
    routes = true,
    templates = true,
    translations = true,
    forms = true,
    doctrine = true,
  },
  -- Blink.cmp auto-configuration
  blink_cmp = {
    enabled = true, -- Auto-configure blink.cmp
    name = 'symfony',
    score_offset = 10, -- Priority boost for symfony completions
    opts = {}, -- Additional blink source options
  },
}

---@type SymfonyConfig
M.config = {}

---@type string|nil
M.project_root = nil

---@type boolean
M.initialized = false

-- Cache system using vim.uv (libuv) for better performance in 0.11+
local cache = require 'neo-symfony.cache'
local console = require 'neo-symfony.console'
local utils = require 'neo-symfony.utils'

---Find Symfony project root using vim.fs (Neovim 0.11+ optimized)
---@param start_path string Starting path for search
---@return string|nil root Root path or nil
local function find_symfony_root(start_path)
  -- Use vim.fs.root for efficient root detection (Neovim 0.11+)
  local root = vim.fs.root(start_path or 0, M.config.symfony_root_patterns)

  if root then
    -- Verify bin/console exists and is executable
    local console_path = vim.fs.joinpath(root, 'bin', 'console')
    local stat = vim.uv.fs_stat(console_path)

    if stat and stat.type == 'file' then
      -- Check if executable (more robust than vim.fn.executable)
      local mode = stat.mode
      if mode and (mode % 2 == 1 or (mode / 8) % 2 == 1 or (mode / 64) % 2 == 1) then
        return root
      end
    end
  end

  return nil
end

---Auto-configure blink.cmp with symfony source
local function setup_blink_cmp()
  if not M.config.blink_cmp.enabled then
    return
  end

  -- Check if blink.cmp is available
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok then
    vim.notify('blink.cmp not found. Symfony completion will not be available.', vim.log.levels.WARN)
    return
  end

  -- Get current blink config
  local blink_config = blink.config or {}

  -- Ensure sources table exists
  if not blink_config.sources then
    blink_config.sources = {}
  end
  if not blink_config.sources.providers then
    blink_config.sources.providers = {}
  end

  -- Add symfony source if not already configured
  if not blink_config.sources.providers.symfony then
    blink_config.sources.providers.symfony = vim.tbl_deep_extend('force', {
      name = M.config.blink_cmp.name,
      module = 'neo-symfony.completion.source',
      enabled = true,
      score_offset = M.config.blink_cmp.score_offset,
    }, M.config.blink_cmp.opts)

    -- Update blink.cmp configuration
    local update_ok, err = pcall(function()
      -- Try to update config if blink provides an update method
      if blink.update_config then
        blink.update_config(blink_config)
      elseif blink.setup then
        -- Fallback: call setup again (this works with most plugins)
        blink.setup(blink_config)
      else
        -- Direct config update
        blink.config = blink_config
      end
    end)

    if update_ok then
      vim.notify('Symfony source registered with blink.cmp', vim.log.levels.INFO)
    else
      vim.notify(string.format('Failed to auto-configure blink.cmp: %s', err), vim.log.levels.WARN)
      vim.notify('Please manually configure blink.cmp with symfony source', vim.log.levels.INFO)
    end
  end
end

---Setup the plugin
---@param opts? SymfonyConfig User configuration
function M.setup(opts)
  if M.initialized then
    vim.notify('neo-symfony.nvim is already initialized', vim.log.levels.WARN)
    return
  end

  -- Merge user config with defaults using vim.tbl_deep_extend
  M.config = vim.tbl_deep_extend('force', default_config, opts or {})

  -- Initialize cache system
  cache.init(M.config.cache_ttl)

  -- Auto-configure blink.cmp
  -- Delay slightly to ensure blink.cmp is loaded
  vim.defer_fn(function()
    setup_blink_cmp()
  end, 100)

  -- Auto-detect Symfony project on startup
  vim.schedule(function()
    local cwd = vim.fn.getcwd()
    M.project_root = find_symfony_root(cwd)

    if M.project_root then
      vim.notify(string.format('Symfony project detected at: %s', M.project_root), vim.log.levels.INFO)

      -- Pre-warm cache asynchronously
      console.warmup_cache(M.project_root, M.config)
    end
  end)

  -- Setup autocommands for file type detection
  local augroup = vim.api.nvim_create_augroup('SymfonyNvim', { clear = true })

  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = { 'php', 'twig', 'yaml', 'yml' },
    callback = function(ev)
      if not M.project_root then
        local bufname = vim.api.nvim_buf_get_name(ev.buf)
        M.project_root = find_symfony_root(vim.fs.dirname(bufname))
      end

      if M.project_root then
        -- Setup buffer-local keymaps and commands
        M.setup_buffer(ev.buf)
      end
    end,
  })

  -- Watch for composer.json changes to invalidate cache
  vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    group = augroup,
    pattern = { 'composer.json', 'config/**/*.yaml', 'config/**/*.yml' },
    callback = function()
      if M.project_root then
        cache.invalidate_all()
        vim.notify('Symfony cache invalidated', vim.log.levels.INFO)
      end
    end,
  })

  -- Setup user commands
  M.setup_commands()

  M.initialized = true
end

---Setup buffer-local functionality
---@param bufnr number Buffer number
function M.setup_buffer(bufnr)
  -- Setup telescope integration if enabled
  if M.config.telescope_enabled then
    local ok, telescope = pcall(require, 'telescope')
    if ok then
      local pickers = require 'neo-symfony.telescope'

      vim.keymap.set('n', '<leader>sS', pickers.services, {
        buffer = bufnr,
        desc = 'Search Symfony Services',
      })

      vim.keymap.set('n', '<leader>sR', pickers.routes, {
        buffer = bufnr,
        desc = 'Search Symfony Routes',
      })

      vim.keymap.set('n', '<leader>sT', pickers.templates, {
        buffer = bufnr,
        desc = 'Search Symfony Templates',
      })
    end
  end
end

---Setup user commands
function M.setup_commands()
  vim.api.nvim_create_user_command('SymfonyReload', function()
    if not M.project_root then
      vim.notify('No Symfony project detected', vim.log.levels.WARN)
      return
    end

    cache.invalidate_all()
    console.warmup_cache(M.project_root, M.config)
    vim.notify('Symfony cache reloaded', vim.log.levels.INFO)
  end, {
    desc = 'Reload Symfony cache',
  })

  vim.api.nvim_create_user_command('SymfonyServices', function()
    if not M.project_root then
      vim.notify('No Symfony project detected', vim.log.levels.WARN)
      return
    end

    console.list_services(M.project_root, M.config)
  end, {
    desc = 'List all Symfony services',
  })

  vim.api.nvim_create_user_command('SymfonyRoutes', function()
    if not M.project_root then
      vim.notify('No Symfony project detected', vim.log.levels.WARN)
      return
    end

    console.list_routes(M.project_root, M.config)
  end, {
    desc = 'List all Symfony routes',
  })

  vim.api.nvim_create_user_command('SymfonyInfo', function()
    local blink_status = 'not found'
    local ok, blink = pcall(require, 'blink.cmp')
    if ok then
      if blink.config and blink.config.sources and blink.config.sources.providers and blink.config.sources.providers.symfony then
        blink_status = 'configured'
      else
        blink_status = 'found but not configured'
      end
    end

    local info = {
      'neo-symfony.nvim Information',
      '===========================',
      '',
      string.format('Project Root: %s', M.project_root or 'Not detected'),
      string.format('Console Env: %s', M.config.console_env),
      string.format('Cache TTL: %d seconds', M.config.cache_ttl),
      string.format('Phpactor: %s', M.config.phpactor_enabled and 'enabled' or 'disabled'),
      string.format('Telescope: %s', M.config.telescope_enabled and 'enabled' or 'disabled'),
      string.format('Blink.cmp: %s', blink_status),
      '',
      'Completion Features:',
      string.format('  Services: %s', M.config.completion.services and '✓' or '✗'),
      string.format('  Routes: %s', M.config.completion.routes and '✓' or '✗'),
      string.format('  Templates: %s', M.config.completion.templates and '✓' or '✗'),
      string.format('  Translations: %s', M.config.completion.translations and '✓' or '✗'),
      string.format('  Forms: %s', M.config.completion.forms and '✓' or '✗'),
      string.format('  Doctrine: %s', M.config.completion.doctrine and '✓' or '✗'),
    }

    vim.api.nvim_echo({ { table.concat(info, '\n'), 'Normal' } }, true, {})
  end, {
    desc = 'Show Symfony plugin information',
  })
end

---Get current Symfony project root
---@return string|nil
function M.get_project_root()
  return M.project_root
end

---Check if a feature is enabled
---@param feature string Feature name
---@return boolean
function M.is_feature_enabled(feature)
  return M.config.completion[feature] == true
end

return M
