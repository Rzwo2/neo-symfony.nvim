local M = {}

function M.find_symfony_root(config)
  local current_file = vim.fn.expand '%:p:h'

  for _, pattern in ipairs(config.symfony_root_patterns) do
    local root = vim.fn.finddir(pattern, current_file .. ';')
    if root ~= '' then
      return vim.fn.fnamemodify(root, ':h')
    end

    local file = vim.fn.findfile(pattern, current_file .. ';')
    if file ~= '' then
      return vim.fn.fnamemodify(file, ':h')
    end
  end

  return nil
end

function M.file_exists(path)
  return vim.fn.filereadable(path) == 1
end

function M.get_cursor_context()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before_cursor = line:sub(1, col)
  local after_cursor = line:sub(col + 1)

  return {
    line = line,
    col = col,
    before = before_cursor,
    after = after_cursor,
  }
end

-- Detect if cursor is inside a function call
function M.is_inside_function_call(func_name)
  local context = M.get_cursor_context()
  local pattern = func_name .. '%s*%('
  return context.before:match(pattern) ~= nil
end

-- Extract string argument at cursor position
function M.get_string_at_cursor()
  local context = M.get_cursor_context()
  local before = context.before:match '[\'"](.-)[\'"]?$'
  return before or ''
end

return M
