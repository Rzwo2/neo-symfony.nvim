local M = {}

M.config = {}
M.project_root = nil

function M.setup(opts)
  M.config = require('neo-symfony.config').setup(opts)
  M.project_root = require('neo-symfony.utils').find_symfony_root(M.config)

  if M.project_root then
    -- Initialize cache
    require('neo-symfony.cache').init(M.project_root)

    -- Initialize completion
    require('neo-symfony.completion').setup(M.config, M.project_root)

    -- Initialize telescope if enabled
    if M.config.telescope_enabled then
      require('neo-symfony.telescope').setup(M.config, M.project_root)
    end

    vim.notify('neo-neo-symfony.nvim initialized: ' .. M.project_root, vim.log.levels.INFO)
  else
    vim.notify('neo-symfony project root not found', vim.log.levels.WARN)
  end
end

function M.get_project_root()
  return M.project_root
end

function M.reload()
  require('neo-symfony.cache').clear()
  vim.notify('neo-symfony cache cleared', vim.log.levels.INFO)
end

return M
