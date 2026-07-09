-- Translation key completion and gd-to-key navigation.
-- Parses translations/*.yaml directly — no console command needed.
local M = {}

local function parse_yaml_keys(path, prefix)
  prefix = prefix or ""
  local keys = {}
  local f = io.open(path, "r")
  if not f then return keys end

  local line_num = 0
  for line in f:lines() do
    line_num = line_num + 1
    local indent, key = line:match("^(%s*)([%w%.%-_]+):")
    if key then
      local full_key = prefix ~= "" and (prefix .. "." .. key) or key
      -- Only leaf keys (lines not followed by deeper indent) are translation strings.
      -- We collect all for now; filtering happens at completion time.
      table.insert(keys, { key = full_key, file = path, line = line_num })
    end
  end
  f:close()
  return keys
end

-- Returns all translation keys across all locales.
-- Result: list of { key, file, line, locale }
function M.get_keys(root)
  local result = {}
  local files = vim.fn.glob(root .. "/translations/*.yaml", false, true)
  for _, f in ipairs(files) do
    local locale = vim.fn.fnamemodify(f, ":t:r"):match("%.(.+)$") or "en"
    local keys = parse_yaml_keys(f)
    for _, entry in ipairs(keys) do
      entry.locale = locale
      table.insert(result, entry)
    end
  end
  return result
end

return M
