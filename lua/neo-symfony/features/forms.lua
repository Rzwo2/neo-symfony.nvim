-- Form type completion: built-in Symfony types + project AbstractType subclasses.
local M = {}

-- Built-in Symfony form types (Symfony 7/8).
local BUILTIN_TYPES = {
  "TextType", "EmailType", "PasswordType", "TextareaType", "IntegerType",
  "NumberType", "MoneyType", "PercentType", "RangeType", "UrlType",
  "SearchType", "TelType", "ColorType", "CheckboxType", "RadioType",
  "ChoiceType", "EntityType", "EnumType", "FileType", "HiddenType",
  "DateType", "DateTimeType", "TimeType", "BirthdayType", "DateIntervalType",
  "CollectionType", "RepeatedType", "ButtonType", "ResetType", "SubmitType",
  "FormType",
}

local BUILTIN_NAMESPACE = "Symfony\\Component\\Form\\Extension\\Core\\Type\\"

-- Scans src/ for classes extending AbstractType.
local function find_custom_types(root)
  local files = vim.fn.glob(root .. "/src/Form/**/*.php", false, true)
  local types = {}
  for _, f in ipairs(files) do
    local content = table.concat(vim.fn.readfile(f), "\n")
    local class_name = content:match("class%s+(%w+)%s+extends%s+AbstractType")
    if class_name then
      -- Derive FQCN from namespace declaration
      local ns = content:match("namespace%s+([%w\\]+)%s*;")
      local fqcn = ns and (ns .. "\\" .. class_name) or class_name
      table.insert(types, { name = class_name, fqcn = fqcn, path = f, builtin = false })
    end
  end
  return types
end

-- Returns all form types: built-ins + project custom types.
-- Result: list of { name, fqcn, builtin }
function M.get_types(root)
  local types = {}
  for _, name in ipairs(BUILTIN_TYPES) do
    table.insert(types, { name = name, fqcn = BUILTIN_NAMESPACE .. name, builtin = true })
  end
  for _, t in ipairs(find_custom_types(root)) do
    table.insert(types, t)
  end
  return types
end

return M
