-- Two-layer cache:
--   1. In-process table (instant, lost on restart)
--   2. Disk JSON in .cache/neo-symfony/ (survives restarts, invalidated by var/cache/dev mtime)
local M = {}

local mem = {}

-- ── Disk layer ────────────────────────────────────────────────────────────────

local function disk_path(root, key)
  return root .. '/.cache/neo-symfony/' .. key .. '.json'
end

local function disk_read(root, key)
  local file = io.open(disk_path(root, key), 'r')
  if not file then return nil end
  local raw = file:read('*a')
  file:close()
  local ok, data = pcall(vim.json.decode, raw)
  return ok and data or nil
end

local function disk_write(root, key, data)
  vim.fn.mkdir(root .. '/.cache/neo-symfony', 'p')
  local file = io.open(disk_path(root, key), 'w')
  if not file then return end
  file:write(vim.json.encode(data))
  file:close()
end

-- Returns true when var/cache/dev is newer than our disk cache file.
local function disk_stale(root, key)
  local cache_mtime = vim.fn.getftime(disk_path(root, key))
  if cache_mtime == -1 then return true end
  local source_mtime = vim.fn.getftime(root .. '/var/cache/dev')
  return source_mtime > cache_mtime
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- root is required for disk-backed keys; omit for TTL-only in-memory entries.
function M.get(key, root)
  if mem[key] then return mem[key] end
  if root then
    if not disk_stale(root, key) then
      local data = disk_read(root, key)
      if data then
        mem[key] = data
        return data
      end
    end
  end
  return nil
end

function M.set(key, data, root)
  mem[key] = data
  if root then disk_write(root, key, data) end
end

function M.invalidate(key, root)
  mem[key] = nil
  if root then vim.fn.delete(disk_path(root, key)) end
end

function M.clear(root)
  mem = {}
  if root then
    for _, key in ipairs({ 'container', 'routes', 'commands', 'events', 'services', 'templates', 'translations' }) do
      vim.fn.delete(disk_path(root, key))
    end
  end
end

return M
