local M = {}

function M.execute(command, callback)
  local symfony = require 'neo-symfony'
  local project_root = symfony.get_project_root()

  if not project_root then
    vim.notify('Symfony project root not found', vim.log.levels.ERROR)
    return
  end

  local console_path = project_root .. '/bin/console'
  if vim.fn.filereadable(console_path) ~= 1 then
    vim.notify('Symfony console not found', vim.log.levels.ERROR)
    return
  end

  local env = symfony.config.console_env
  local full_command = string.format('cd %s && APP_ENV=%s php %s %s', project_root, env, console_path, command)

  local output = {}
  vim.fn.jobstart(full_command, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line ~= '' then
            table.insert(output, line)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        if callback then
          callback(output)
        end
      else
        vim.notify('Console command failed: ' .. command, vim.log.levels.ERROR)
      end
    end,
  })
end

function M.execute_sync(command)
  local symfony = require 'neo-symfony'
  local project_root = symfony.get_project_root()

  if not project_root then
    return nil
  end

  local console_path = project_root .. '/bin/console'
  if vim.fn.filereadable(console_path) ~= 1 then
    return nil
  end

  local env = symfony.config.console_env
  local full_command = string.format('cd %s && APP_ENV=%s php %s %s 2>/dev/null', project_root, env, console_path, command)

  local handle = io.popen(full_command)
  if not handle then
    return nil
  end

  local result = handle:read '*a'
  handle:close()

  return result
end

return M
