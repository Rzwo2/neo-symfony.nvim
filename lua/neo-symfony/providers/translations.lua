local M = {}

function M.fetch_translations()
  local cache = require 'neo-symfony.cache'
  local cached = cache.get 'translations'
  if cached then
    return cached
  end

  local symfony = require 'neo-symfony'
  local project_root = symfony.get_project_root()

  if not project_root then
    return {}
  end

  local translations_dir = project_root .. '/translations'
  local translations = {}

  local function parse_yaml_file(filepath)
    local file = io.open(filepath, 'r')
    if not file then
      return {}
    end

    local content = file:read '*a'
    file:close()

    local keys = {}
    -- Simple YAML key extraction (for basic cases)
    for key in content:gmatch '([%w_.]+)%s*:' do
      table.insert(keys, key)
    end

    return keys
  end

  local handle = vim.uv.fs_scandir(translations_dir)
  if handle then
    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end

      if type == 'file' and (name:match '%.yaml$' or name:match '%.yml$') then
        local domain = name:match '(.+)%.%w+%.ya?ml$' or 'messages'
        local filepath = translations_dir .. '/' .. name
        local keys = parse_yaml_file(filepath)

        for _, key in ipairs(keys) do
          table.insert(translations, {
            key = key,
            domain = domain,
            file = name,
          })
        end
      end
    end
  end

  cache.set('translations', translations)
  return translations
end

function M.reload()
  require('neo-symfony.cache').clear()
  vim.notify('Symfony cache cleared', vim.log.levels.INFO)
end

return M
