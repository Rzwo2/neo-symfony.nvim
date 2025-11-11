if vim.g.loaded_neo_symfony then
  return
end
vim.g.loaded_neo_symfony = 1

-- Auto-setup if in Symfony project
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    local utils = require 'symfony.utils'
    local config = require('neo-symfony.config').setup {}
    local root = utils.find_symfony_root(config)

    if root then
      vim.notify('Symfony project detected', vim.log.levels.INFO)
    end
  end,
})

-- Commands
vim.api.nvim_create_user_command('SymfonyReload', function()
  require('neo-symfony').reload()
end, { desc = 'Reload Symfony cache' })

vim.api.nvim_create_user_command('SymfonyServices', function()
  local services = require('neo-symfony.providers.services').fetch_services()
  vim.notify(string.format('Found %d services', #services), vim.log.levels.INFO)
end, { desc = 'List Symfony services' })

vim.api.nvim_create_user_command('SymfonyRoutes', function()
  local routes = require('neo-symfony.providers.routes').fetch_routes()
  vim.notify(string.format('Found %d routes', #routes), vim.log.levels.INFO)
end, { desc = 'List Symfony routes' })
