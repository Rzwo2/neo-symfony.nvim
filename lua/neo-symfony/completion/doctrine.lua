local M = {}

function M.get_completions(ctx)
  local utils = require 'neo-symfony.utils'
  local items = {}

  -- Check if we're inside getRepository()
  local is_get_repository = utils.is_inside_function_call 'getRepository'

  if is_get_repository then
    -- Use phpactor to find entities
    local ok, phpactor = pcall(require, 'phpactor')
    if ok then
      -- This would integrate with phpactor to find entities
      -- For now, we'll provide a basic implementation
      local symfony = require 'neo-symfony'
      local project_root = symfony.get_project_root()

      if project_root then
        local entity_dir = project_root .. '/src/Entity'
        local handle = vim.uv.fs_scandir(entity_dir)

        if handle then
          while true do
            local name, type = vim.uv.fs_scandir_next(handle)
            if not name then
              break
            end

            if type == 'file' and name:match '%.php.project_root%' then
              break
            end
          end
        end
      end
    end
  end
end

function M.reload()
  require('neo-symfony.cache').clear()
  vim.notify('neo-symfony cache cleared', vim.log.levels.INFO)
end

return M
