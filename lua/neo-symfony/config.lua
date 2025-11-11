local M = {}

local defaults = {
  phpactor_enabled = true,
  telescope_enabled = true,
  symfony_root_patterns = {
    'composer.json',
    'symfony.lock',
    'bin/console',
  },
  cache_ttl = 300, -- 5 minutes
  console_env = 'dev',
  completion = {
    services = true,
    routes = true,
    templates = true,
    translations = true,
    forms = true,
    doctrine = true,
  },
}

function M.setup(opts)
  return vim.tbl_deep_extend('force', defaults, opts or {})
end

return M
