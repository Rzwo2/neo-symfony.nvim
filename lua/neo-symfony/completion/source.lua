local Source = {}
Source.__index = Source

local utils = require 'neo-symfony.utils'
local cache = require 'neo-symfony.cache'

--- Create a new source instance
---@return table Source instance
function Source:new()
  local o = setmetatable({}, self)
  return o
end

--- Get trigger characters for this source
--- These characters will trigger completion
---@return string[] List of trigger characters
function Source:get_trigger_characters()
  return { "'", '"', '(', ',' }
end

--- Check if we're in a context where we should provide completions
---@param context table Completion context from blink.cmp
---@return boolean True if in render context
function Source:is_in_render_context(context)
  local line = context.line
  local col = context.cursor[2]
  local before_cursor = line:sub(1, col)

  -- Try Tree-sitter based detection first (more accurate)
  local ts_result = self:check_context_with_treesitter(context)
  if ts_result ~= nil then
    return ts_result
  end

  -- Fallback to pattern matching
  local patterns = {
    'render%s*%(', -- render(
    'renderView%s*%(', -- renderView(
    '->render%s*%(', -- ->render(
    '->renderView%s*%(', -- ->renderView(
    'return%s+.*render%s*%(', -- return $this->render(
  }

  for _, pattern in ipairs(patterns) do
    if before_cursor:match(pattern) then
      -- Check if we're inside quotes after the opening parenthesis
      local after_pattern = before_cursor:match(pattern .. '%s*(.*)$')
      if after_pattern then
        -- Count quotes to see if we're inside a string
        local single_quotes = select(2, after_pattern:gsub("'", ''))
        local double_quotes = select(2, after_pattern:gsub('"', ''))

        -- If odd number of quotes, we're inside a string
        if (single_quotes % 2 == 1) or (double_quotes % 2 == 1) then
          return true
        end
      end
    end
  end

  return false
end

--- Use Tree-sitter to check context (more accurate)
---@param context table Completion context from blink.cmp
---@return boolean|nil True if in render context, nil if Tree-sitter unavailable
function Source:check_context_with_treesitter(context)
  local bufnr = context.bufnr
  local row = context.cursor[1] - 1 -- Tree-sitter uses 0-indexed rows
  local col = context.cursor[2]

  -- Check if Tree-sitter parser is available
  local has_parser, parser = pcall(vim.treesitter.get_parser, bufnr, 'php')
  if not has_parser then
    return nil -- Fallback to pattern matching
  end

  local tree = parser:parse()[1]
  if not tree then
    return nil
  end

  local root = tree:root()

  -- Get node at cursor position
  local node = root:descendant_for_range(row, col, row, col)

  -- Walk up the tree to find function call
  while node do
    local node_type = node:type()

    -- Check if we're in a string node
    if node_type == 'string' or node_type == 'string_value' or node_type == 'encapsed_string' then
      -- Check parent to see if it's a function call argument
      local parent = node:parent()
      while parent do
        if parent:type() == 'function_call_expression' or parent:type() == 'member_call_expression' then
          -- Get function name
          local name_node = parent:field('function')[1] or parent:field('name')[1]
          if name_node then
            local func_name = vim.treesitter.get_node_text(name_node, bufnr)
            -- Check if it's render or renderView
            if func_name:match 'render' or func_name:match 'renderView' then
              return true
            end
          end
        end
        parent = parent:parent()
      end
    end

    node = node:parent()
  end

  return false
end

--- Check if we're in a Twig template context
---@param context table Completion context from blink.cmp
---@return boolean True if in Twig template context
function Source:is_in_twig_context(context)
  local line = context.line
  local col = context.cursor[2]
  local before_cursor = line:sub(1, col)

  -- Twig patterns for templates
  local patterns = {
    '{%%s*include%s+', -- {% include '
    '{%%s*extends%s+', -- {% extends '
    '{%%s*embed%s+', -- {% embed '
    '{{%s*include%s*%(', -- {{ include('
  }

  for _, pattern in ipairs(patterns) do
    if before_cursor:match(pattern) then
      local after_pattern = before_cursor:match(pattern .. '%s*(.*)$')
      if after_pattern then
        local single_quotes = select(2, after_pattern:gsub("'", ''))
        local double_quotes = select(2, after_pattern:gsub('"', ''))
        if (single_quotes % 2 == 1) or (double_quotes % 2 == 1) then
          return true
        end
      end
    end
  end

  return false
end

--- Check if we should provide completions based on filetype and context
---@param context table Completion context from blink.cmp
---@return boolean True if completions should be provided
function Source:should_provide_completions(context)
  local bufnr = context.bufnr
  local filetype = vim.bo[bufnr].filetype

  -- Check filetype
  if filetype == 'php' then
    return self:is_in_render_context(context)
  elseif filetype == 'twig' or filetype == 'html.twig' then
    return self:is_in_twig_context(context)
  end

  return false
end

--- Extract the partial input that user has typed
---@param context table Completion context from blink.cmp
---@return string Partial filter text typed by user
function Source:get_filter_text(context)
  local line = context.line
  local col = context.cursor[2]
  local before_cursor = line:sub(1, col)

  -- Find the last quote and extract text after it
  local quote_pos = before_cursor:match '.*[\'"]()' or 0
  if quote_pos > 0 then
    return before_cursor:sub(quote_pos)
  end

  return ''
end

--- Main function: Get completions
---@param context table Completion context from blink.cmp
---@param callback function Callback to invoke with completion items
function Source:get_completions(context, callback)
  -- Check if we should provide completions
  if not self:should_provide_completions(context) then
    callback { items = {} }
    return
  end

  -- Get filter text (what user has typed so far)
  local filter_text = self:get_filter_text(context)

  -- Async operation to get templates
  vim.schedule(function()
    local templates = cache.get_templates()

    if not templates or #templates == 0 then
      -- Fetch templates if cache is empty
      utils.fetch_templates(function(fetched_templates)
        if fetched_templates then
          cache.set_templates(fetched_templates)
          local items = self:format_completion_items(fetched_templates, filter_text)
          callback { items = items }
        else
          callback { items = {} }
        end
      end)
    else
      local items = self:format_completion_items(templates, filter_text)
      callback { items = items }
    end
  end)
end

--- Format templates into blink.cmp completion items
---@param templates string[] List of template paths
---@param filter_text string Current filter text for matching
---@return table[] List of completion items
function Source:format_completion_items(templates, filter_text)
  local items = {}

  for _, template in ipairs(templates) do
    -- Simple prefix matching
    if filter_text == '' or template:lower():find(filter_text:lower(), 1, true) then
      table.insert(items, {
        label = template,
        kind = vim.lsp.protocol.CompletionItemKind.File,
        insertText = template,
        filterText = template,
        documentation = {
          kind = 'markdown',
          value = '**Symfony Template**\n\n`' .. template .. '`',
        },
        -- Optional: Add sorting priority
        sortText = template,
      })
    end
  end

  return items
end

--- Optional: Resolve additional details for a completion item
---@param item table Completion item to resolve
---@param callback function Callback to invoke with resolved item
function Source:resolve(item, callback)
  -- Can add more details here if needed
  callback(item)
end

--- Optional: Execute action after completion is accepted
---@param item table Completion item that was accepted
---@param callback function Callback to invoke after execution
function Source:execute(item, callback)
  -- Can perform actions after item is selected
  callback()
end

return Source
