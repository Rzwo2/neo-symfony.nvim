local M = {}

function M.get_completions(ctx)
  local utils = require 'symfony.utils'
  local items = {}

  -- Check if we're inside trans() or similar
  local is_trans = utils.is_inside_function_call 'trans'
  local is_trans_choice = utils.is_inside_function_call 'transChoice'

  -- Also check for Twig trans filter
  local filetype = vim.bo.filetype
  local context = utils.get_cursor_context()
  local is_twig_trans = filetype == 'twig' and context.before:match '%|%s*trans'

  if is_trans or is_trans_choice or is_twig_trans then
    local translations = require('neo-symfony.providers.translations').fetch_translations()

    for _, trans in ipairs(translations) do
      table.insert(items, {
        label = trans.key,
        kind = 'Text',
        detail = trans.domain,
        documentation = string.format('Translation: %s\nDomain: %s\nFile: %s', trans.key, trans.domain, trans.file),
        insertText = trans.key,
      })
    end
  end

  return items
end

return M
