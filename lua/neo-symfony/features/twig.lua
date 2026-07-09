-- Twig template navigation and {# @var #} type-hint driven completion.
local M = {}

-- Returns all *.html.twig paths under root, relative to root/templates/.
function M.get_templates(root)
  local files = vim.fn.glob(root .. "/templates/**/*.html.twig", false, true)
  local result = {}
  for _, f in ipairs(files) do
    table.insert(result, {
      path = f,
      rel = f:sub(#root + 2), -- strip leading root/
    })
  end
  return result
end

-- Parses {# @var varName \Full\Class\Name #} annotations from the given buffer.
-- Returns a map of varName -> FQCN.
function M.parse_var_hints(bufnr)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local hints = {}
  for _, line in ipairs(lines) do
    local var, class = line:match("{#%s*@var%s+(%S+)%s+(%S+)%s*#}")
    if var and class then
      hints[var] = class
    end
  end
  return hints
end

-- Resolves the template path from a render() call string argument.
-- Returns the absolute path or nil.
function M.resolve_template(root, rel_path)
  local abs = root .. "/templates/" .. rel_path
  if vim.fn.filereadable(abs) == 1 then return abs end
  return nil
end

return M
