local M = {}

function M.register(keymaps)
  if keymaps == false then return end

  local pickers = require("neo-symfony.telescope")

  local maps = {
    { keymaps.routes,   pickers.routes,   "Symfony Routes" },
    { keymaps.services, pickers.services, "Symfony Services" },
    { keymaps.commands, pickers.commands, "Symfony Commands" },
    { keymaps.events,   pickers.events,   "Symfony Events" },
    { keymaps.doctrine, pickers.doctrine, "Symfony Entities" },
    { keymaps.twig,     pickers.templates, "Symfony Templates" },
  }

  for _, map in ipairs(maps) do
    local key, fn, desc = map[1], map[2], map[3]
    if key then
      vim.keymap.set("n", key, fn, { desc = desc, silent = true })
    end
  end
end

return M
