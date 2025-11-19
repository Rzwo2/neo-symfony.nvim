local M = {}

--- Find Symfony project root by searching for common Symfony markers
---@return string|nil Absolute path to Symfony root, or nil if not found
function M.find_symfony_root()
  local patterns = { 'composer.json', 'symfony.lock', 'bin/console' }

  -- Get current working directory
  local cwd = vim.uv.cwd()

  --- Search ancestor directories for Symfony markers
  ---@param path string Directory path to search from
  ---@return string|nil Symfony root path or nil
  local function search_ancestor(path)
    for _, pattern in ipairs(patterns) do
      local filepath = path .. '/' .. pattern
      local stat = vim.uv.fs_stat(filepath)
      if stat then
        return path
      end
    end

    -- Get parent directory
    local parent = vim.fs.dirname(path)
    if parent == path then
      return nil -- Reached root
    end

    return search_ancestor(parent)
  end

  return search_ancestor(cwd)
end

--- Execute Symfony console command asynchronously
---@param args string Console command arguments (e.g., "debug:router --format=json")
---@param callback function Callback function that receives the output or nil on error
function M.execute_console_command(args, callback)
  local root = M.find_symfony_root()
  if not root then
    vim.notify('Symfony project not found', vim.log.levels.ERROR)
    callback(nil)
    return
  end

  local console = root .. '/bin/console'

  -- Check if console exists
  local stat = vim.uv.fs_stat(console)
  if not stat then
    vim.notify('bin/console not found', vim.log.levels.ERROR)
    callback(nil)
    return
  end

  -- Build command
  local cmd = { 'php', console }
  -- Split args string into table
  for arg in args:gmatch '%S+' do
    table.insert(cmd, arg)
  end

  -- Execute async with vim.system (Neovim 0.10+)
  vim.system(cmd, {
    cwd = root,
    text = true,
  }, function(result)
    if result.code == 0 then
      callback(result.stdout)
    else
      if result.stderr and result.stderr ~= '' then
        vim.schedule(function()
          vim.notify('Console error: ' .. result.stderr, vim.log.levels.WARN)
        end)
      end
      callback(nil)
    end
  end)
end

--- Fetch templates from Symfony project
---@param callback function Callback that receives array of template paths
function M.fetch_templates(callback)
  -- Try multiple approaches to find templates

  -- Approach 1: Use debug:container to find Twig paths
  M.execute_console_command('debug:config twig --format=json', function(output)
    if output then
      local success, config = pcall(vim.json.decode, output)
      if success and config and config.paths then
        local templates = M.scan_template_directories(config.paths)
        callback(templates)
        return
      end
    end

    -- Approach 2: Scan common template directories
    local root = M.find_symfony_root()
    if root then
      local default_paths = {
        root .. '/templates',
        root .. '/app/Resources/views',
      }
      local templates = M.scan_template_directories(default_paths)
      callback(templates)
    else
      callback {}
    end
  end)
end

--- Scan directories for template files recursively
---@param paths string[] Array of directory paths to scan
---@return string[] Array of relative template paths
function M.scan_template_directories(paths)
  local templates = {}

  for _, path in ipairs(paths) do
    local stat = vim.uv.fs_stat(path)
    if stat and stat.type == 'directory' then
      -- Use vim.fs.find to recursively find template files (Neovim 0.11+)
      local files = vim.fs.find(function(name)
        return name:match '%.twig$' or name:match '%.html%.twig$'
      end, {
        path = path,
        type = 'file',
        limit = math.huge,
      })

      for _, file in ipairs(files) do
        -- Convert absolute path to relative template name
        local template_name = file:gsub(path .. '/', '')
        table.insert(templates, template_name)
      end
    end
  end

  return templates
end

--- Fetch routes from Symfony project
---@param callback function Callback that receives array of route names
function M.fetch_routes(callback)
  M.execute_console_command('debug:router --format=json', function(output)
    if output then
      local success, routes = pcall(vim.json.decode, output)
      if success and routes then
        local route_list = {}
        for name, _ in pairs(routes) do
          table.insert(route_list, name)
        end
        callback(route_list)
        return
      end
    end
    callback {}
  end)
end

--- Fetch services from Symfony container
---@param callback function Callback that receives array of service IDs
function M.fetch_services(callback)
  M.execute_console_command('debug:container --format=json', function(output)
    if output then
      local success, data = pcall(vim.json.decode, output)
      if success and data then
        local services = {}
        -- Extract service IDs from container dump
        if type(data) == 'table' then
          for key, _ in pairs(data) do
            if type(key) == 'string' then
              table.insert(services, key)
            end
          end
        end
        callback(services)
        return
      end
    end
    callback {}
  end)
end

return M
