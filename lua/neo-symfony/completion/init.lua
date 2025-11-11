local M = {}

function M.setup(config, project_root)
  if not config.completion then
    return
  end

  -- Register blink.cmp sources
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok then
    vim.notify('blink.cmp not found, completion disabled', vim.log.levels.WARN)
    return
  end

  -- Register our completion source
  local source = require 'neo-symfony.completion.source'
  blink.register_source('neo-symfony', source)

  vim.notify('Symfony completion registered', vim.log.levels.DEBUG)
end

return M
