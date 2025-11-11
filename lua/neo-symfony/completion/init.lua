local M = {}

function M.setup(config, project_root)
  if not config.completion then
    return
  end

  -- Register blink.cmp sources using the modern blink.cmp API if available.
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok then
    vim.notify('blink.cmp not found, completion disabled', vim.log.levels.WARN)
    return
  end

  -- Add provider configuration compatible with blink.cmp's sources.providers
  local provider_config = {
    name = 'Symfony',
    module = 'neo-symfony.completion.blink_source',
    opts = {}, -- reserved for future options
  }

  -- Use the runtime API to add the provider and enable it for filetypes.
  local added = false
  if type(blink.add_source_provider) == 'function' then
    local status, err = pcall(blink.add_source_provider, 'symfony', provider_config)
    if not status then
      vim.notify('neo-symfony: failed to add blink.cmp provider: ' .. tostring(err), vim.log.levels.WARN)
    else
      added = true
    end
  end

  if added then
    -- Enable provider for typical filetypes used by the plugin
    if type(blink.add_filetype_source) == 'function' then
      pcall(blink.add_filetype_source, 'php', 'symfony')
      pcall(blink.add_filetype_source, 'twig', 'symfony')
      pcall(blink.add_filetype_source, 'yaml', 'symfony')
    end

    vim.notify('neo-symfony completion provider registered with blink.cmp', vim.log.levels.DEBUG)
  else
    vim.notify(
      'Could not register neo-symfony provider automatically. Please add it manually to blink.cmp sources.providers (see README).',
      vim.log.levels.WARN
    )
  end
end

return M
