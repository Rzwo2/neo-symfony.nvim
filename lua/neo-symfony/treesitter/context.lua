-- Determines what Symfony-relevant context the cursor is in.
-- Used to gate completions so they don't pollute unrelated positions.
local M = {}

-- Possible context values returned by M.get():
--   "constructor_param"  inside a PHP constructor parameter list
--   "render_call"        inside the first string argument of ->render()
--   "trans_call"         inside the first string argument of ->trans() / t()
--   "builder_add"        inside the second argument of $builder->add()
--   "twig_var"           inside {{ varName. }} in a Twig file
--   nil                  no recognized context

local function node_type_path(node)
  local path = {}
  local n = node
  while n do
    table.insert(path, 1, n:type())
    n = n:parent()
  end
  return path
end

-- Returns the nearest ancestor node matching any of the given types.
local function find_ancestor(node, types)
  local type_set = {}
  for _, t in ipairs(types) do type_set[t] = true end
  local n = node
  while n do
    if type_set[n:type()] then return n end
    n = n:parent()
  end
  return nil
end

function M.get()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok or not parsers.has_parser() then return nil end

  local node = vim.treesitter.get_node()
  if not node then return nil end

  local ft = vim.bo.filetype

  if ft == "php" then
    -- Constructor parameter: inside a method named __construct
    local method = find_ancestor(node, { "method_declaration" })
    if method then
      local name_node = method:field("name")[1]
      if name_node and vim.treesitter.get_node_text(name_node, 0) == "__construct" then
        if find_ancestor(node, { "formal_parameters" }) then
          return "constructor_param"
        end
      end
    end

    -- render() / renderView() call string argument
    local call = find_ancestor(node, { "member_call_expression", "function_call_expression" })
    if call then
      local name_node = call:field("name")[1]
      local fn_name = name_node and vim.treesitter.get_node_text(name_node, 0) or ""
      if fn_name == "render" or fn_name == "renderView" then
        if node:type() == "string" or node:type() == "encapsed_string" then
          return "render_call"
        end
      end
      if fn_name == "trans" or fn_name == "t" then
        if node:type() == "string" or node:type() == "encapsed_string" then
          return "trans_call"
        end
      end
    end

    -- $builder->add() second argument
    if call then
      local name_node = call:field("name")[1]
      if name_node and vim.treesitter.get_node_text(name_node, 0) == "add" then
        -- TODO: verify call is on a FormBuilderInterface and cursor is on arg 2
        local args = call:field("arguments")[1]
        if args then return "builder_add" end
      end
    end
  end

  if ft == "twig" then
    -- TODO: detect {{ varName. }} context using Twig treesitter grammar
    return nil
  end

  return nil
end

return M
