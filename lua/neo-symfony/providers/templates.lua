local M = {}

function M.fetch_templates()
  local cache = require 'symfony.cache'
  local cached = cache.get 'templates'
  if cached then
    return cached
  end

  local symfony = require 'symfony'
  local project_root = symfony.get_project_root()

  if not project_root then
    return {}
  end

  local templates_dir = project_root .. '/templates'
  local templates = {}

  local function scan_dir(dir, prefix)
    prefix = prefix or ''
    local handle = vim.uv.fs_scandir(dir)

    if not handle then
      return
    end

    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end

      local full_path = dir .. '/' .. name
      local relative_path = prefix .. name

      if type == 'directory' then
        scan_dir(full_path, relative_path .. '/')
      elseif name:match '%.twig$' then
        table.insert(templates, {
          path = relative_path,
          full_path = full_path,
        })
      end
    end
  end

  scan_dir(templates_dir)

  cache.set('templates', templates)
  return templates
end

return M
