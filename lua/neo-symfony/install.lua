-- Dependency installer. phpactor and twiggy_language_server are already
-- configured in the user's init.lua, so we only ensure Treesitter parsers.
local M = {}

local TS_PARSERS = { 'php', 'twig', 'yaml' }

function M.ensure_installed(silent)
  if not silent then
    vim.notify('[neoSymfony] Ensuring Treesitter parsers: ' .. table.concat(TS_PARSERS, ', '), vim.log.levels.INFO)
  end

  local ok = pcall(require, 'nvim-treesitter')
  if not ok then
    if not silent then
      vim.notify('[neoSymfony] nvim-treesitter not found — install parsers manually: ' .. table.concat(TS_PARSERS, ', '), vim.log.levels.WARN)
    end
    return
  end
  require('nvim-treesitter.install').ensure_installed(TS_PARSERS)
end

return M
