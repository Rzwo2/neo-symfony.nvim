local M = {}

function M.find_root()
  return vim.fs.root(0, { "symfony.lock" })
end

function M.is_symfony_project(root)
  root = root or M.find_root()
  if not root then return false end
  return vim.fn.filereadable(root .. "/bin/console") == 1
    and vim.fn.filereadable(root .. "/symfony.lock") == 1
end

return M
