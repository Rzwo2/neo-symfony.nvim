-- Parses var/cache/dev/*Container.xml to extract service definitions.
-- No kernel boot required — reads the already-compiled container on disk.
local M = {}
local cache = require('neo-symfony.cache')

local function find_container_xml(root)
  local files = vim.fn.glob(root .. '/var/cache/dev/*Container.xml', false, true)
  return files[1]
end

local function parse_attributes(line)
  local attrs = {}
  for key, value in line:gmatch('(%w+)="([^"]*)"') do
    attrs[key] = value
  end
  return attrs
end

local function parse_xml(path)
  local services = {}
  local current = nil
  for line in io.lines(path) do
    if line:find('<service ', 1, true) then
      local id = line:match('id="([^"]*)"')
      if id then
        current = {
          id = id,
          class = line:match('class="([^"]*)"') or '',
          public = line:find('public="true"', 1, true) ~= nil,
          tags = {},
        }
      end
    elseif line:find('<tag ', 1, true) and current then
      table.insert(current.tags, parse_attributes(line))
    elseif line:find('</service>', 1, true) and current then
      table.insert(services, current)
      current = nil
    end
  end
  return services
end

-- Returns a list of { id, class, public, tags } tables.
function M.get_services(root)
  local cached = cache.get('container', root)
  if cached then return cached end

  local xml_path = find_container_xml(root)
  if not xml_path then return {} end

  local services = parse_xml(xml_path)
  cache.set('container', services, root)
  return services
end

return M
