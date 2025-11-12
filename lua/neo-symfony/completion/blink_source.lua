-- Compatibility provider module for blink.cmp
-- blink.cmp expects a module that exposes `new(opts, config)` and returns an object
-- implementing the provider interface (get_completions, enabled, ...).
--
-- This module adapts the existing neo-symfony.completion.source (which is a simple
-- source table used previously) into the blink.cmp provider constructor format.

local M = {}

-- create a minimal wrapper that adapts the existing source implementation
function M.new(opts, config)
  local base = require 'neo-symfony.completion.source'
  local self = setmetatable({}, { __index = M })

  -- store references if needed in future
  self._base = base
  self._opts = opts or {}
  self._config = config or {}

  return self
end

-- blink.cmp will call provider:enabled(context) to decide if provider is active
function M:enabled(ctx)
  -- the existing source implements M:enabled() with no args, reuse it
  if type(self._base.enabled) == 'function' then
    return self._base:enabled()
  end
  return true
end

-- blink.cmp will call provider:get_completions(context, on_items)
-- where on_items(items, is_cached) is the callback.
function M:get_completions(context, on_items)
  -- The existing source exposes get_completions(ctx, callback) which calls:
  --   callback { items = items, is_incomplete = false }
  -- We adapt that shape into blink.cmp's expected on_items signature.
  if type(self._base.get_completions) == 'function' then
    local ok, err = pcall(function()
      self._base:get_completions(context, function(res)
        if type(on_items) == 'function' then
          -- res is expected to be { items = items_table, is_incomplete = bool }
          local items = (res and res.items) or {}
          local is_cached = res and (res.is_incomplete == true) or false
          -- blink.cmp convention: on_items(items_table, is_cached_boolean)
          on_items(items, is_cached)
        end
      end)
    end)
    if not ok then
      vim.notify('neo-symfony: error while fetching completions: ' .. tostring(err), vim.log.levels.ERROR)
      if type(on_items) == 'function' then
        on_items({}, false)
      end
    end
    return
  end

  -- fallback: no completions
  if type(on_items) == 'function' then
    on_items({}, false)
  end
end

-- optional: provide signature help trigger chars if base provides it
function M:get_signature_help_trigger_characters()
  if type(self._base.get_signature_help_trigger_characters) == 'function' then
    return self._base:get_signature_help_trigger_characters()
  end
  return {}
end

-- optional reload hook
function M:reload()
  if type(self._base.reload) == 'function' then
    return self._base:reload()
  end
end

return M
