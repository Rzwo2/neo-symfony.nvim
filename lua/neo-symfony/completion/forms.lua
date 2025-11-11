local M = {}

-- Common Symfony form types
local form_types = {
  'TextType',
  'TextareaType',
  'EmailType',
  'IntegerType',
  'MoneyType',
  'NumberType',
  'PasswordType',
  'PercentType',
  'SearchType',
  'UrlType',
  'RangeType',
  'TelType',
  'ColorType',
  'DateType',
  'DateIntervalType',
  'DateTimeType',
  'TimeType',
  'BirthdayType',
  'WeekType',
  'ChoiceType',
  'EnumType',
  'EntityType',
  'CountryType',
  'LanguageType',
  'LocaleType',
  'TimezoneType',
  'CurrencyType',
  'CheckboxType',
  'FileType',
  'RadioType',
  'UuidType',
  'UlidType',
  'CollectionType',
  'RepeatedType',
  'HiddenType',
  'ButtonType',
  'ResetType',
  'SubmitType',
  'FormType',
}

function M.get_completions(ctx)
  local utils = require 'symfony.utils'
  local items = {}

  -- Check if we're inside FormBuilder->add()
  local is_add = utils.is_inside_function_call 'add'

  if is_add then
    for _, form_type in ipairs(form_types) do
      table.insert(items, {
        label = form_type,
        kind = 'Class',
        detail = 'Form Type',
        documentation = 'Symfony Form Type: ' .. form_type,
        insertText = form_type .. '::class',
      })
    end
  end

  return items
end

return M
