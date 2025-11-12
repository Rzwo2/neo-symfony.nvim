-- Context detection for intelligent Symfony completion

local M = {}

---Pattern matching for different Symfony contexts
local patterns = {
  services = {
    -- PHP patterns
    { pattern = 'get%s*%(%s*[\'"]([^\'"]*)', filetype = 'php' },
    { pattern = 'getParameter%s*%(%s*[\'"]([^\'"]*)', filetype = 'php', type = 'parameters' },
    { pattern = '@([%w_%.]+)', filetype = 'yaml' },
  },
  routes = {
    -- PHP patterns
    { pattern = 'generateUrl%s*%(%s*[\'"]([^\'"]*)', filetype = 'php' },
    { pattern = 'redirectToRoute%s*%(%s*[\'"]([^\'"]*)', filetype = 'php' },
    -- Twig patterns
    { pattern = 'path%s*%(%s*[\'"]([^\'"]*)', filetype = 'twig' },
    { pattern = 'url%s*%(%s*[\'"]([^\'"]*)', filetype = 'twig' },
  },
  templates = {
    -- PHP patterns
    { pattern = 'render%s*%(%s*[\'"]([^\'"]*)', filetype = 'php' },
    { pattern = 'renderView%s*%(%s*[\'"]([^\'"]*)', filetype = 'php' },
    -- Twig patterns
    { pattern = 'include%s*%(%s*[\'"]([^\'"]*)', filetype = 'twig' },
    { pattern = 'extends%s+[\'"]([^\'"]*)', filetype = 'twig' },
  },
  translations = {
    -- PHP patterns
    { pattern = 'trans%s*%(%s*[\'"]([^\'"]*)', filetype = 'php' },
    -- Twig patterns
    { pattern = '[\'"]([^\'"]*)[\'"]+%s*|%s*trans', filetype = 'twig' },
  },
  forms = {
    -- PHP patterns
    { pattern = 'add%s*%([^,]+,%s*([%w\\]+)::class', filetype = 'php' },
    { pattern = 'createForm%s*%(([%w\\]+)::class', filetype = 'php' },
  },
  doctrine = {
    -- PHP patterns
    { pattern = 'getRepository%s*%(([%w\\]+)::class', filetype = 'php' },
    { pattern = 'find%s*%(([%w\\]+)::class', filetype = 'php' },
  },
}

---Get the text around cursor
---@param bufnr number Buffer number
---@param line number Line number (1-indexed)
---@param col number Column number (0-indexed)
---@return string Text around cursor
local function get_context_text(bufnr, line, col)
  local lines = vim.api.nvim_buf_get_lines(bufnr, math.max(0, line - 2), line + 1, false)
  local text = table.concat(lines, '\n')
  return text
end

---Check if cursor is inside quotes
---@param line_text string Current line text
---@param col number Column position (0-indexed)
---@return boolean, string|nil Whether inside quotes and the quote character
local function is_inside_quotes(line_text, col)
  local before = line_text:sub(1, col)
  local single_quotes = 0
  local double_quotes = 0
  local last_quote = nil

  -- Count unescaped quotes
  local i = 1
  while i <= #before do
    local char = before:sub(i, i)
    if char == "'" and (i == 1 or before:sub(i - 1, i - 1) ~= '\\') then
      single_quotes = single_quotes + 1
      last_quote = "'"
    elseif char == '"' and (i == 1 or before:sub(i - 1, i - 1) ~= '\\') then
      double_quotes = double_quotes + 1
      last_quote = '"'
    end
    i = i + 1
  end

  -- Inside quotes if odd number of quotes
  if single_quotes % 2 == 1 then
    return true, "'"
  elseif double_quotes % 2 == 1 then
    return true, '"'
  end

  return false, nil
end

---Detect completion type based on context
---@param ctx table Completion context from blink.cmp
---@return string|nil Completion type or nil
function M.detect_completion_type(ctx)
  local bufnr = ctx.bufnr
  local filetype = vim.bo[bufnr].filetype

  -- Get cursor position (blink.cmp provides 1-indexed line, 0-indexed col)
  local line = ctx.cursor[1]
  local col = ctx.cursor[2]

  -- Get current line and context
  local line_text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
  local context_text = get_context_text(bufnr, line, col)

  -- Check if we're inside quotes (common for string completions)
  local inside_quotes, quote_char = is_inside_quotes(line_text, col)

  -- Try to match patterns for each completion type
  for comp_type, type_patterns in pairs(patterns) do
    for _, pattern_info in ipairs(type_patterns) do
      -- Check if pattern applies to current filetype
      if pattern_info.filetype == filetype or pattern_info.filetype == 'any' then
        -- Try to find pattern match
        local match = context_text:match(pattern_info.pattern)
        if match then
          -- Special handling for parameters
          if pattern_info.type == 'parameters' then
            return 'services' -- Parameters are fetched with services
          end
          return comp_type
        end
      end
    end
  end

  -- Fallback: if inside quotes in PHP/Twig, try service completion
  if inside_quotes and (filetype == 'php' or filetype == 'twig') then
    -- Check if previous word might be a Symfony method
    local before_quotes = line_text:sub(1, col):match '(%w+)%s*%([^%(]*$'
    if before_quotes then
      local symfony_methods = {
        'get',
        'has',
        'generateUrl',
        'redirectToRoute',
        'render',
        'renderView',
        'trans',
        'path',
        'url',
      }
      for _, method in ipairs(symfony_methods) do
        if before_quotes:match(method) then
          return 'services' -- Default to services
        end
      end
    end
  end

  return nil
end

---Get partial text for filtering
---@param ctx table Completion context
---@return string Partial text before cursor
function M.get_partial_text(ctx)
  local bufnr = ctx.bufnr
  local line = ctx.cursor[1]
  local col = ctx.cursor[2]

  local line_text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''

  -- Find the start of the current word (after quotes/parens)
  local before = line_text:sub(1, col)
  local partial = before:match '[\'"]([^\'"]*)$' or before:match '%(([^%(]*)$' or ''

  return partial
end

---Check if cursor is in a valid completion position
---@param ctx table Completion context
---@return boolean Whether completion should trigger
function M.should_complete(ctx)
  local filetype = vim.bo[ctx.bufnr].filetype

  -- Only complete in relevant file types
  if not vim.tbl_contains({ 'php', 'twig', 'yaml', 'yml' }, filetype) then
    return false
  end

  -- Get trigger character if any
  local trigger_char = ctx.trigger_character

  -- Always allow manual completion
  if not trigger_char then
    return true
  end

  -- Check if trigger character is valid
  local valid_triggers = { "'", '"', '(', '>', ':', '/' }
  return vim.tbl_contains(valid_triggers, trigger_char)
end

return M
