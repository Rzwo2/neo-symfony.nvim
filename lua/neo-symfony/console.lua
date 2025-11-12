-- lua/symfony/console.lua
-- Optimized console command execution using vim.uv (libuv) for Neovim 0.11+

local M = {}

---Execute Symfony console command asynchronously
---@param project_root string Project root path
---@param command string Console command
---@param args table Command arguments
---@param callback function Callback with result (stdout, stderr, code)
local function execute_console_async(project_root, command, args, callback)
  local console_path = vim.fs.joinpath(project_root, 'bin', 'console')

  -- Build full command arguments
  local cmd_args = vim.list_extend({ console_path, command }, args or {})

  local stdout = vim.uv.new_pipe(false)
  local stderr = vim.uv.new_pipe(false)

  local stdout_data = {}
  local stderr_data = {}

  local handle, pid
  handle, pid = vim.uv.spawn('php', {
    args = cmd_args,
    cwd = project_root,
    stdio = { nil, stdout, stderr },
    env = nil,
    uid = nil,
    gid = nil,
    verbatim = false,
    detached = false,
    hide = false,
  }, function(code, signal)
    stdout:close()
    stderr:close()
    handle:close()

    vim.schedule(function()
      local stdout_str = table.concat(stdout_data, '')
      local stderr_str = table.concat(stderr_data, '')
      callback(stdout_str, stderr_str, code)
    end)
  end)

  if not handle then
    vim.schedule(function()
      callback(nil, string.format('Failed to spawn process: %s', pid), 1)
    end)
    return
  end

  -- Read stdout
  stdout:read_start(function(err, data)
    if err then
      vim.schedule(function()
        vim.notify(string.format('Console stdout error: %s', err), vim.log.levels.ERROR)
      end)
    elseif data then
      table.insert(stdout_data, data)
    end
  end)

  -- Read stderr
  stderr:read_start(function(err, data)
    if err then
      vim.schedule(function()
        vim.notify(string.format('Console stderr error: %s', err), vim.log.levels.ERROR)
      end)
    elseif data then
      table.insert(stderr_data, data)
    end
  end)
end

---Parse JSON output from console command
---@param output string Raw output
---@return table|nil Parsed JSON or nil on error
local function parse_json_output(output)
  if not output or output == '' then
    return nil
  end

  local ok, result = pcall(vim.json.decode, output)
  if not ok then
    vim.notify(string.format('Failed to parse console JSON output: %s', result), vim.log.levels.ERROR)
    return nil
  end

  return result
end

---Fetch services from Symfony container
---@param project_root string Project root path
---@param config table Plugin configuration
---@param callback function Callback with services data
function M.fetch_services(project_root, config, callback)
  execute_console_async(project_root, 'debug:container', { '--format=json', '--env=' .. config.console_env }, function(stdout, stderr, code)
    if code ~= 0 then
      vim.notify(string.format('Failed to fetch services: %s', stderr), vim.log.levels.ERROR)
      callback(nil)
      return
    end

    local data = parse_json_output(stdout)
    if data then
      -- Transform services into a more usable format
      local services = {}
      if data.services then
        for id, service in pairs(data.services) do
          services[id] = {
            class = service.class,
            aliases = service.aliases,
            public = service.public,
            priority = service.public and 1 or 50,
          }
        end
      end
      callback(services)
    else
      callback(nil)
    end
  end)
end

---Fetch routes from Symfony router
---@param project_root string Project root path
---@param config table Plugin configuration
---@param callback function Callback with routes data
function M.fetch_routes(project_root, config, callback)
  execute_console_async(project_root, 'debug:router', { '--format=json', '--env=' .. config.console_env }, function(stdout, stderr, code)
    if code ~= 0 then
      vim.notify(string.format('Failed to fetch routes: %s', stderr), vim.log.levels.ERROR)
      callback(nil)
      return
    end

    local data = parse_json_output(stdout)
    if data then
      local routes = {}
      for name, route in pairs(data) do
        routes[name] = {
          path = route.path,
          methods = route.methods,
          controller = route.defaults and route.defaults._controller,
        }
      end
      callback(routes)
    else
      callback(nil)
    end
  end)
end

---Fetch templates from filesystem
---@param project_root string Project root path
---@param callback function Callback with templates data
function M.fetch_templates(project_root, callback)
  -- Use vim.fs.find for efficient file search (Neovim 0.11+)
  vim.schedule(function()
    local templates_dir = vim.fs.joinpath(project_root, 'templates')

    -- Check if templates directory exists
    local stat = vim.uv.fs_stat(templates_dir)
    if not stat or stat.type ~= 'directory' then
      callback {}
      return
    end

    -- Find all .twig files
    local twig_files = vim.fs.find(function(name, path)
      return name:match '%.twig$'
    end, {
      type = 'file',
      limit = math.huge,
      path = templates_dir,
    })

    -- Convert absolute paths to relative template paths
    local templates = {}
    for _, file in ipairs(twig_files) do
      local rel_path = file:sub(#templates_dir + 2) -- +2 for trailing slash
      table.insert(templates, { path = rel_path })
    end

    callback(templates)
  end)
end

---Fetch translations
---@param project_root string Project root path
---@param callback function Callback with translations data
function M.fetch_translations(project_root, callback)
  execute_console_async(project_root, 'debug:translation', { '--format=json' }, function(stdout, stderr, code)
    if code ~= 0 then
      -- Translation command might not be available, fail silently
      callback {}
      return
    end

    local data = parse_json_output(stdout)
    callback(data or {})
  end)
end

---Fetch form types
---@param project_root string Project root path
---@param callback function Callback with form types data
function M.fetch_form_types(project_root, callback)
  execute_console_async(project_root, 'debug:form', { '--format=json' }, function(stdout, stderr, code)
    if code ~= 0 then
      callback {}
      return
    end

    local data = parse_json_output(stdout)
    if data and data.types then
      callback(data.types)
    else
      callback {}
    end
  end)
end

---Fetch Doctrine entities
---@param project_root string Project root path
---@param callback function Callback with entities data
function M.fetch_entities(project_root, callback)
  execute_console_async(project_root, 'doctrine:mapping:info', { '--format=json' }, function(stdout, stderr, code)
    if code ~= 0 then
      callback {}
      return
    end

    local data = parse_json_output(stdout)
    callback(data or {})
  end)
end

---Fetch data based on completion type
---@param project_root string Project root path
---@param comp_type string Completion type
---@param config table Plugin configuration
---@param callback function Callback with fetched data
function M.fetch_async(project_root, comp_type, config, callback)
  if comp_type == 'services' then
    M.fetch_services(project_root, config, callback)
  elseif comp_type == 'routes' then
    M.fetch_routes(project_root, config, callback)
  elseif comp_type == 'templates' then
    M.fetch_templates(project_root, callback)
  elseif comp_type == 'translations' then
    M.fetch_translations(project_root, callback)
  elseif comp_type == 'forms' then
    M.fetch_form_types(project_root, callback)
  elseif comp_type == 'doctrine' then
    M.fetch_entities(project_root, callback)
  else
    callback(nil)
  end
end

---Pre-warm cache by fetching all enabled completion types
---@param project_root string Project root path
---@param config table Plugin configuration
function M.warmup_cache(project_root, config)
  vim.schedule(function()
    local cache = require 'symfony.cache'

    for feature, enabled in pairs(config.completion) do
      if enabled then
        M.fetch_async(project_root, feature, config, function(data)
          if data then
            cache.set(feature, data)
          end
        end)
      end
    end
  end)
end

---List services in a buffer
---@param project_root string Project root path
---@param config table Plugin configuration
function M.list_services(project_root, config)
  M.fetch_services(project_root, config, function(services)
    if not services then
      vim.notify('No services found', vim.log.levels.WARN)
      return
    end

    local lines = { 'Symfony Services', '================', '' }
    for id, service in pairs(services) do
      table.insert(lines, string.format('• %s', id))
      if service.class then
        table.insert(lines, string.format('  Class: %s', service.class))
      end
      table.insert(lines, '')
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].filetype = 'markdown'

    vim.cmd 'split'
    vim.api.nvim_win_set_buf(0, buf)
  end)
end

---List routes in a buffer
---@param project_root string Project root path
---@param config table Plugin configuration
function M.list_routes(project_root, config)
  M.fetch_routes(project_root, config, function(routes)
    if not routes then
      vim.notify('No routes found', vim.log.levels.WARN)
      return
    end

    local lines = { 'Symfony Routes', '==============', '' }
    for name, route in pairs(routes) do
      table.insert(lines, string.format('• %s', name))
      if route.path then
        table.insert(lines, string.format('  Path: %s', route.path))
      end
      if route.methods then
        table.insert(lines, string.format('  Methods: %s', table.concat(route.methods, ', ')))
      end
      table.insert(lines, '')
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].filetype = 'markdown'

    vim.cmd 'split'
    vim.api.nvim_win_set_buf(0, buf)
  end)
end

return M
