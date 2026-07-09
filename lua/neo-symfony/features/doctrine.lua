-- Doctrine ORM support: entity discovery and repository resolution.
local M = {}
local cache = require("neo-symfony.cache")

-- Returns all Entity classes found under src/Entity/.
function M.get_entities(root)
  local files = vim.fn.glob(root .. "/src/Entity/**/*.php", false, true)
  local result = {}
  for _, f in ipairs(files) do
    local name = vim.fn.fnamemodify(f, ":t:r")
    table.insert(result, { name = name, path = f })
  end
  return result
end

-- Resolves a repository service id to its class file via container XML.
-- e.g. "App\Repository\UserRepository" -> "/path/to/src/Repository/UserRepository.php"
function M.resolve_repository(root, fqcn)
  -- TODO: look up FQCN in container services, map to file path
  local rel = fqcn:gsub("\\", "/"):gsub("^App/", "src/") .. ".php"
  local abs = root .. "/" .. rel
  if vim.fn.filereadable(abs) == 1 then return abs end
  return nil
end

return M
