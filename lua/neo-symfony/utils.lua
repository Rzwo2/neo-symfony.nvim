local M = {}

---Check if a file exists
---@param path string File path
---@return boolean
function M.file_exists(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == 'file'
end

---Check if a directory exists
---@param path string Directory path
---@return boolean
function M.dir_exists(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

---Read file contents
---@param path string File path
---@return string|nil Content or nil on error
function M.read_file(path)
  local fd = vim.uv.fs_open(path, 'r', 438) -- 438 = 0666
  if not fd then
    return nil
  end

  local stat = vim.uv.fs_fstat(fd)
  if not stat then
    vim.uv.fs_close(fd)
    return nil
  end

  local data = vim.uv.fs_read(fd, stat.size, 0)
  vim.uv.fs_close(fd)

  return data
end

---Debounce function calls
---@param fn function Function to debounce
---@param ms number Delay in milliseconds
---@return function Debounced function
function M.debounce(fn, ms)
  local timer = vim.uv.new_timer()
  local wrapped_fn

  wrapped_fn = function(...)
    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(unpack(argv))
    end)
  end

  return wrapped_fn, timer
end

---Throttle function calls
---@param fn function Function to throttle
---@param ms number Minimum interval in milliseconds
---@return function Throttled function
function M.throttle(fn, ms)
  local timer = vim.uv.new_timer()
  local running = false

  return function(...)
    if not running then
      running = true
      timer:start(ms, 0, function()
        running = false
      end)
      return fn(...)
    end
  end
end

---Deep merge two tables
---@param t1 table First table
---@param t2 table Second table
---@return table Merged table
function M.deep_merge(t1, t2)
  return vim.tbl_deep_extend('force', t1, t2)
end

---Check if table is empty
---@param t table Table to check
---@return boolean
function M.is_empty(t)
  return next(t) == nil
end

---Get table keys
---@param t table Input table
---@return table Array of keys
function M.keys(t)
  local keys = {}
  for k, _ in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

---Get table values
---@param t table Input table
---@return table Array of values
function M.values(t)
  local values = {}
  for _, v in pairs(t) do
    table.insert(values, v)
  end
  return values
end

---Filter table by predicate
---@param t table Input table
---@param predicate function Filter function
---@return table Filtered table
function M.filter(t, predicate)
  local result = {}
  for k, v in pairs(t) do
    if predicate(v, k) then
      result[k] = v
    end
  end
  return result
end

---Map table values
---@param t table Input table
---@param mapper function Map function
---@return table Mapped table
function M.map(t, mapper)
  local result = {}
  for k, v in pairs(t) do
    result[k] = mapper(v, k)
  end
  return result
end

---Find value in table
---@param t table Input table
---@param predicate function Predicate function
---@return any|nil Found value or nil
function M.find(t, predicate)
  for k, v in pairs(t) do
    if predicate(v, k) then
      return v
    end
  end
  return nil
end

---Check if string starts with prefix
---@param str string Input string
---@param prefix string Prefix to check
---@return boolean
function M.starts_with(str, prefix)
  return str:sub(1, #prefix) == prefix
end

---Check if string ends with suffix
---@param str string Input string
---@param suffix string Suffix to check
---@return boolean
function M.ends_with(str, suffix)
  return str:sub(-#suffix) == suffix
end

---Split string by delimiter
---@param str string Input string
---@param delimiter string Delimiter
---@return table Array of parts
function M.split(str, delimiter)
  local result = {}
  local pattern = string.format('([^%s]+)', delimiter)

  for match in str:gmatch(pattern) do
    table.insert(result, match)
  end

  return result
end

---Trim whitespace from string
---@param str string Input string
---@return string Trimmed string
function M.trim(str)
  return str:match '^%s*(.-)%s*$'
end

---Create a weak table (for caching)
---@param mode? string Weakness mode ('k', 'v', or 'kv')
---@return table Weak table
function M.weak_table(mode)
  return setmetatable({}, { __mode = mode or 'v' })
end

---Safely call a function and return result or error
---@param fn function Function to call
---@param ... any Function arguments
---@return boolean, any Success status and result/error
function M.safe_call(fn, ...)
  return pcall(fn, ...)
end

---Execute function with timeout
---@param fn function Function to execute
---@param timeout number Timeout in milliseconds
---@param callback function Callback(success, result)
function M.with_timeout(fn, timeout, callback)
  local timer = vim.uv.new_timer()
  local completed = false

  -- Start timeout
  timer:start(
    timeout,
    0,
    vim.schedule_wrap(function()
      if not completed then
        completed = true
        timer:close()
        callback(false, 'Timeout exceeded')
      end
    end)
  )

  -- Execute function
  vim.schedule(function()
    local ok, result = pcall(fn)
    if not completed then
      completed = true
      timer:stop()
      timer:close()
      callback(ok, result)
    end
  end)
end

---Get relative path from base to target
---@param base string Base path
---@param target string Target path
---@return string Relative path
function M.relative_path(base, target)
  -- Normalize paths
  base = vim.fs.normalize(base)
  target = vim.fs.normalize(target)

  -- If target starts with base, return relative part
  if M.starts_with(target, base) then
    local rel = target:sub(#base + 2) -- +2 to skip trailing slash
    return rel
  end

  return target
end

---Format file size in human-readable format
---@param bytes number File size in bytes
---@return string Formatted size
function M.format_size(bytes)
  local units = { 'B', 'KB', 'MB', 'GB', 'TB' }
  local unit_index = 1
  local size = bytes

  while size >= 1024 and unit_index < #units do
    size = size / 1024
    unit_index = unit_index + 1
  end

  return string.format('%.2f %s', size, units[unit_index])
end

---Create a simple logger
---@param name string Logger name
---@return table Logger instance
function M.create_logger(name)
  return {
    debug = function(msg, ...)
      vim.notify(string.format('[%s] ' .. msg, name, ...), vim.log.levels.DEBUG)
    end,
    info = function(msg, ...)
      vim.notify(string.format('[%s] ' .. msg, name, ...), vim.log.levels.INFO)
    end,
    warn = function(msg, ...)
      vim.notify(string.format('[%s] ' .. msg, name, ...), vim.log.levels.WARN)
    end,
    error = function(msg, ...)
      vim.notify(string.format('[%s] ' .. msg, name, ...), vim.log.levels.ERROR)
    end,
  }
end

return M
