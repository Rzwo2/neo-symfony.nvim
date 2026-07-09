-- Console command discovery via bin/console list --format=json (async + cached).
local M = {}
local cache = require("neo-symfony.cache")

-- Fetches commands asynchronously and calls cb(commands) when done.
-- commands: list of { name, description, class }
function M.get_commands(root, cb)
  if not cache.is_stale(root, "commands") then
    local cached = cache.read(root, "commands")
    if cached then
      cb(cached)
      return
    end
  end

  vim.system(
    { root .. "/bin/console", "list", "--format=json" },
    { cwd = root, text = true },
    function(result)
      if result.code ~= 0 then
        cb({})
        return
      end
      local ok, data = pcall(vim.json.decode, result.stdout)
      if not ok or not data then
        cb({})
        return
      end
      local commands = {}
      for _, cmd in ipairs(data.commands or {}) do
        table.insert(commands, {
          name = cmd.name,
          description = cmd.description,
        })
      end
      cache.write(root, "commands", commands)
      vim.schedule(function() cb(commands) end)
    end
  )
end

return M
