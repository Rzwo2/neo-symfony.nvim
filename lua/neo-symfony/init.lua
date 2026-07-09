-- neoSymfony — Symfony 7/8 plugin for NeoVim
--
-- Recommended lazy.nvim spec (add to your plugin list):
--
--   { 'rzwo2/neo-symfony.nvim', opts = {} }
--
-- To wire the blink.cmp completion source, extend your blink.cmp opts:
--
--   {
--     'saghen/blink.cmp',
--     opts = {
--       sources = {
--         default = { 'lsp', 'path', 'snippets', 'lazydev', 'symfony' },
--         providers = {
--           symfony = {
--             name = 'symfony',
--             module = 'neo-symfony.completion.blink_source',
--             score_offset = 10,
--           },
--         },
--       },
--     },
--   }

local M = {}

-- Exposed to all submodules via require('neo-symfony').project_root
M.project_root = nil
M.config = {}

local default_config = {
  keymaps = {
    routes      = '<leader>sR',
    services    = '<leader>sS',
    commands    = '<leader>sC',
    events      = '<leader>sE',
    doctrine    = '<leader>sD',
    twig        = '<leader>sT',
  },
  completion = {
    services     = true,
    routes       = true,
    templates    = true,
    translations = true,
    forms        = true,
    doctrine     = true,
  },
  auto_install  = true,
  console_env   = 'dev',
}

local install_done = false

local function activate(root)
  if M.project_root == root then return end
  M.project_root = root

  if M.config.auto_install and not install_done then
    install_done = true
    require('neo-symfony.install').ensure_installed(true)
  end

  require('neo-symfony.keymaps').register(M.config.keymaps)
end

local function detect_and_activate()
  local detection = require 'neo-symfony.detection'
  local root = detection.find_root()
  if root and detection.is_symfony_project(root) then
    activate(root)
  end
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', default_config, opts or {})

  local group = vim.api.nvim_create_augroup('NeoSymfony', { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
    group = group,
    callback = detect_and_activate,
  })

  -- BufEnter already fired for the initial buffer when setup() is deferred
  vim.schedule(detect_and_activate)

  vim.api.nvim_create_user_command('NeoSymfonyInstall', function()
    require('neo-symfony.install').ensure_installed(false)
  end, { desc = 'Install neoSymfony Treesitter parsers' })

  vim.api.nvim_create_user_command('NeoSymfonyClearCache', function()
    if not M.project_root then
      vim.notify('[neoSymfony] No active Symfony project', vim.log.levels.WARN)
      return
    end
    require('neo-symfony.cache').clear(M.project_root)
    vim.notify('[neoSymfony] Cache cleared', vim.log.levels.INFO)
  end, { desc = 'Clear neoSymfony data cache' })

  vim.api.nvim_create_user_command('SymfonyInfo', function()
    local lines = {
      'neoSymfony',
      '===========',
      '',
      'Project root: ' .. (M.project_root or 'not detected'),
      'Console env:  ' .. M.config.console_env,
      '',
      'Keymaps:',
    }
    for action, key in pairs(M.config.keymaps) do
      table.insert(lines, '  ' .. key .. '  →  ' .. action)
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].bufhidden = 'wipe'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.cmd 'split'
    vim.api.nvim_win_set_buf(0, buf)
  end, { desc = 'Show neoSymfony info' })
end

function M.is_feature_enabled(feature)
  return M.config.completion and M.config.completion[feature] ~= false
end

function M.get_project_root()
  return M.project_root
end

return M
