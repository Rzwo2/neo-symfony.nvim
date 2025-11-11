local M = {}

M.name = 'neo-symfony'

-- Check if this source should be active for current context
function M:enabled()
  local filetype = vim.bo.filetype
  return filetype == 'php' or filetype == 'twig' or filetype == 'yaml'
end

-- Get completion items
function M:get_completions(ctx, callback)
  local filetype = vim.bo.filetype
  local items = {}

  if filetype == 'php' then
    -- Try all PHP completions
    vim.list_extend(items, require('neo-symfony.completion.services').get_completions(ctx))
    vim.list_extend(items, require('neo-symfony.completion.routes').get_completions(ctx))
    vim.list_extend(items, require('neo-symfony.completion.templates').get_completions(ctx))
    vim.list_extend(items, require('neo-symfony.completion.translations').get_completions(ctx))
    vim.list_extend(items, require('neo-symfony.completion.forms').get_completions(ctx))
    vim.list_extend(items, require('neo-symfony.completion.doctrine').get_completions(ctx))
  elseif filetype == 'twig' then
    vim.list_extend(items, require('neo-symfony.completion.routes').get_completions(ctx))
    vim.list_extend(items, require('neo-symfony.completion.translations').get_completions(ctx))
  elseif filetype == 'yaml' then
    vim.list_extend(items, require('neo-symfony.completion.services').get_completions(ctx))
  end

  callback { items = items, is_incomplete = false }
end

return M
