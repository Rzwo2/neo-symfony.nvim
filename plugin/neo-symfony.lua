if vim.g.loaded_neo_symfony then
  return
end
vim.g.loaded_neo_symfony = 1

if vim.fn.has 'nvim-0.11' ~= 1 then
  vim.notify('neo-symfony.nvim requires Neovim >= 0.11.0', vim.log.levels.ERROR)
  return
end

-- Auto-setup with defaults if user hasn't called setup() yet
-- This runs after all plugins are loaded
vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('SymfonyAutoSetup', { clear = true }),
  once = true,
  callback = function()
    -- Check if symfony module is available
    local ok, symfony = pcall(require, 'neo-symfony')
    if not ok then
      return
    end

    -- Auto-setup only if not already initialized
    if not symfony.initialized then
      -- Small delay to ensure all plugins (especially blink.cmp) are loaded
      vim.defer_fn(function()
        symfony.setup() -- Use all defaults
      end, 150)
    end
  end,
})
