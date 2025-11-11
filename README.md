# neo-symfony.nvim

A comprehensive Symfony plugin for Neovim that provides intelligent autocompletion,
navigation, and tooling for Symfony projects.

## Features

### Autocompletion
- ✅ Service container IDs and parameters
- ✅ Route names with path preview
- ✅ Template paths
- ✅ Translation keys
- ✅ Form types
- ✅ Doctrine entities and repositories

### Requirements
- Neovim >= 0.9.0
- [blink.cmp](https://github.com/saghen/blink.cmp)
- [phpactor.nvim](https://github.com/gbprod/phpactor.nvim) (optional)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional)
- Symfony project with `bin/console` available

## Installation

### Using lazy.nvim

```lua
{
  'rzwo/neo-symfony.nvim',
  dependencies = {
    'saghen/blink.cmp',
    'gbprod/phpactor.nvim',
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('symfony').setup({
      -- Configuration options
      phpactor_enabled = true,
      telescope_enabled = true,
      cache_ttl = 300, -- Cache duration in seconds
      console_env = 'dev',
      completion = {
        services = true,
        routes = true,
        templates = true,
        translations = true,
        forms = true,
        doctrine = true,
      },
    })
  end,
  ft = { 'php', 'twig', 'yaml' },
}
```

### blink.cmp Configuration

After installing neo-symfony.nvim, configure blink.cmp to use the symfony source:

```lua
require('blink.cmp').setup({
  sources = {
    providers = {
      symfony = {
        name = 'symfony',
        module = 'symfony.completion.source',
        enabled = true,
      },
      -- your other sources...
    },
  },
})
```

## Usage

### Autocompletion Examples

#### Service Container
```php
// Type inside the quotes for service completion
$container->get('|') // Shows all public services

// Parameter completion
$container->getParameter('|') // Shows all parameters
```

#### Routes
```php
// Route name completion
$this->generateUrl('|') // Shows all routes with paths

// In Twig
{{ path('|') }}
{{ url('|') }}
```

#### Templates
```php
// Template path completion
return $this->render('|') // Shows all .twig templates
```

#### Translations
```php
// Translation key completion
$translator->trans('|') // Shows all translation keys

// In Twig
{{ '|'|trans }}
```

#### Forms
```php
// Form type completion
$builder->add('field', |Type::class) // Shows all form types
```

#### Doctrine
```php
// Entity completion
$em->getRepository(|::class) // Shows all entities
```

### Commands

- `:SymfonyReload` - Clear cache and reload Symfony data
- `:SymfonyServices` - List all services
- `:SymfonyRoutes` - List all routes

### Telescope Integration (Optional)

If telescope is enabled, you can use:
- `<leader>ss` - Search services
- `<leader>sr` - Search routes
- `<leader>st` - Search templates

## How It Works

symfony.nvim integrates with your Symfony project by:

1. **Auto-detection**: Finds your Symfony project root using `composer.json`, `symfony.lock`, or `bin/console`
2. **Console Integration**: Executes `bin/console` commands to fetch services, routes, and configuration
3. **Smart Caching**: Caches results for configurable duration to avoid performance issues
4. **Context-Aware**: Only shows relevant completions based on cursor position and function calls

## Configuration

### Default Configuration

```lua
{
  phpactor_enabled = true,      -- Enable phpactor integration
  telescope_enabled = true,     -- Enable telescope pickers
  symfony_root_patterns = {     -- Patterns to detect Symfony projects
    'composer.json',
    'symfony.lock',
    'bin/console'
  },
  cache_ttl = 300,              -- Cache time-to-live in seconds
  console_env = 'dev',          -- Symfony environment for console commands
  completion = {
    services = true,            -- Enable service completion
    routes = true,              -- Enable route completion
    templates = true,           -- Enable template completion
    translations = true,        -- Enable translation completion
    forms = true,               -- Enable form type completion
    doctrine = true,            -- Enable doctrine completion
  },
}
```

## Performance

- **Lazy Loading**: Plugin only loads when Symfony project is detected
- **Smart Caching**: Console commands are cached to prevent repeated execution
- **Async Operations**: Where possible, operations are non-blocking
- **Minimal Overhead**: Only active in PHP, Twig, and YAML files

## Troubleshooting

### Completion not working
1. Check if Symfony project is detected: Look for "Symfony project detected" message on startup
2. Verify `bin/console` is executable: `php bin/console --version`
3. Check cache: Run `:SymfonyReload` to clear cache
4. Ensure blink.cmp is properly configured with symfony source

### Performance issues
1. Increase `cache_ttl` for less frequent updates
2. Disable unused completion features in config
3. Check if console commands are slow: `time php bin/console debug:container --format=json`

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License
