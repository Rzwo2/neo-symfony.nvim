# neo-symfony.nvim

A comprehensive Symfony plugin for Neovim that provides intelligent autocompletion, navigation, and tooling for Symfony projects.

## ✨ Features

- ✅ Service container IDs and parameters
- ✅ Route names with path preview
- ✅ Template paths
- ✅ Translation keys
- ✅ Form types
- ✅ Doctrine entities and repositories
- ✅ **Auto-configures blink.cmp** - no manual setup required!
- ✅ Async operations for smooth performance
- ✅ Smart caching system
- ✅ Telescope integration (optional)

## 📋 Requirements

- Neovim >= 0.11.0
- [blink.cmp](https://github.com/saghen/blink.cmp) >= 1.0
- [phpactor.nvim](https://github.com/gbprod/phpactor.nvim) (optional)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional)
- Symfony project with `bin/console` available

## 📦 Installation

### Minimal Setup (Zero Configuration)

The absolute minimum - works with all defaults:

```lua
{ 'rzwo2/neo-symfony.nvim' }
```

### Recommended Setup (With Dependencies)

```lua
{
  'rzwo2/neo-symfony.nvim',
  dependencies = {
    'saghen/blink.cmp',  -- Required for completion
    'gbprod/phpactor.nvim',  -- Optional: PHP intellisense
    'nvim-telescope/telescope.nvim',  -- Optional: Fuzzy finder
  },
}
```

### With Custom Configuration

```lua
{
  'rzwo2/neo-symfony.nvim',
  dependencies = {
    'saghen/blink.cmp',
    'gbprod/phpactor.nvim',
    'nvim-telescope/telescope.nvim',
  },
  opts = {
    -- Override any defaults you want
    console_env = 'dev',
    cache_ttl = 600,
  },
}
```

### With Lazy Loading (Performance Optimized)

```lua
{
  'rzwo2/neo-symfony.nvim',
  dependencies = { 'saghen/blink.cmp' },
  ft = { 'php', 'twig', 'yaml' },  -- Load only for these file types
  opts = {},
}
```

That's it! The plugin will automatically:
- Detect your Symfony project
- Configure blink.cmp with the symfony source
- Set up all completion features
- Register telescope pickers (if available)
- Work with sensible defaults

### Advanced Configuration

```lua
{
  'rzwo/neo-symfony.nvim',
  dependencies = {
    'saghen/blink.cmp',
    'gbprod/phpactor.nvim',
    'nvim-telescope/telescope.nvim',
  },
  ft = { 'php', 'twig', 'yaml' },
  opts = {
    -- Phpactor integration
    phpactor_enabled = true,
    
    -- Telescope integration
    telescope_enabled = true,
    
    -- Symfony project detection
    symfony_root_patterns = {
      'composer.json',
      'symfony.lock',
      'bin/console'
    },
    
    -- Cache configuration
    cache_ttl = 300,  -- 5 minutes
    console_env = 'dev',
    
    -- Enable/disable completion features
    completion = {
      services = true,
      routes = true,
      templates = true,
      translations = true,
      forms = true,
      doctrine = true,
    },
    
    -- Blink.cmp auto-configuration
    blink_cmp = {
      enabled = true,  -- Set to false to disable auto-config
      name = 'symfony',
      score_offset = 10,  -- Priority boost
      opts = {},  -- Additional blink source options
    },
  },
}
```

## 🔧 Manual blink.cmp Configuration

If you prefer to configure blink.cmp manually or want more control:

```lua
-- 1. Disable auto-configuration in neo-symfony.nvim
{
  'rzwo/neo-symfony.nvim',
  opts = {
    blink_cmp = {
      enabled = false,  -- Disable auto-config
    },
  },
}

-- 2. Configure blink.cmp yourself
{
  'saghen/blink.cmp',
  opts = {
    sources = {
      providers = {
        symfony = {
          name = 'symfony',
          module = 'neo-symfony.completion.blink_source',
          enabled = true,
          score_offset = 10,
        },
        lsp = { name = 'LSP' },
        path = { name = 'Path' },
        buffer = { name = 'Buffer' },
      },
    },
  },
}
```

## 🚀 Usage

### Completion Examples

```php
// Service completion
$container->get('|')  // Press Ctrl+Space or type to see services

// Parameter completion
$container->getParameter('|')

// Route completion
$this->generateUrl('|')
$this->redirectToRoute('|')

// Template completion
return $this->render('|')
```

```twig
{# Route completion #}
{{ path('|') }}
{{ url('|') }}

{# Translation completion #}
{{ '|'|trans }}

{# Template inclusion #}
{% include '|' %}
```

```php
// Form type completion
$builder->add('field', |Type::class)

// Entity completion
$em->getRepository(|::class)
```

### Commands

| Command | Description |
|---------|-------------|
| `:SymfonyReload` | Clear cache and reload Symfony data |
| `:SymfonyServices` | List all services in a buffer |
| `:SymfonyRoutes` | List all routes in a buffer |
| `:SymfonyInfo` | Show plugin configuration and status |

### Telescope Pickers

If telescope is enabled, you get these default keymaps in PHP/Twig/YAML files:

| Keymap | Command | Description |
|--------|---------|-------------|
| `<leader>sS` | Services | Search and insert service IDs |
| `<leader>sR` | Routes | Search and insert route names |
| `<leader>sT` | Templates | Search and insert template paths |

## ⚙️ Configuration Options

### Main Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `phpactor_enabled` | boolean | `true` | Enable phpactor integration |
| `telescope_enabled` | boolean | `true` | Enable telescope pickers |
| `cache_ttl` | number | `300` | Cache time-to-live in seconds |
| `console_env` | string | `'dev'` | Symfony environment |
| `symfony_root_patterns` | table | `{'composer.json', 'symfony.lock', 'bin/console'}` | Project detection patterns |

### Completion Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `completion.services` | boolean | `true` | Service container completion |
| `completion.routes` | boolean | `true` | Route name completion |
| `completion.templates` | boolean | `true` | Template path completion |
| `completion.translations` | boolean | `true` | Translation key completion |
| `completion.forms` | boolean | `true` | Form type completion |
| `completion.doctrine` | boolean | `true` | Doctrine entity completion |

### Blink.cmp Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `blink_cmp.enabled` | boolean | `true` | Auto-configure blink.cmp |
| `blink_cmp.name` | string | `'symfony'` | Source name |
| `blink_cmp.score_offset` | number | `10` | Priority boost for symfony completions |
| `blink_cmp.opts` | table | `{}` | Additional source options |

## 🎯 How it Works

The plugin integrates seamlessly with your Symfony project:

1. **Auto-detection**: Finds your Symfony project root using `composer.json`, `symfony.lock`, or `bin/console`
2. **Console Integration**: Executes `bin/console` commands to fetch services, routes, and configuration
3. **Smart Caching**: Caches results for configurable duration (default 5 minutes) to avoid performance issues
4. **Context-Aware**: Only shows relevant completions based on cursor position and function calls
5. **Async Operations**: All console commands run asynchronously to keep the editor responsive
6. **Auto-Configuration**: Automatically registers with blink.cmp on startup

## ⚡ Performance

- **First completion**: ~100-500ms (fetches from console)
- **Cached completion**: <1ms (memory lookup)
- **Cache warmup**: ~1-2s on startup (optional)
- **Memory usage**: ~5-20MB depending on project size

### Performance Tuning

```lua
-- Faster startup with longer cache
opts = {
  cache_ttl = 600,  -- 10 minutes
}

-- More frequent updates
opts = {
  cache_ttl = 60,  -- 1 minute
}

-- Disable unused features
opts = {
  completion = {
    translations = false,  -- If not using translations
    forms = false,  -- If not using forms
  },
}
```

## 🐛 Troubleshooting

### Plugin not working

1. Check if Symfony project is detected:
   ```vim
   :SymfonyInfo
   ```

2. Verify `bin/console` is executable:
   ```bash
   php bin/console --version
   ```

3. Reload cache:
   ```vim
   :SymfonyReload
   ```

### Completions not showing

1. Check blink.cmp configuration:
   ```vim
   :lua print(vim.inspect(require('blink.cmp').config.sources.providers))
   ```

2. Ensure you're in a PHP/Twig/YAML file in a Symfony project

3. Try manual completion: `Ctrl+Space`

### Console commands slow

1. Check console performance:
   ```bash
   time php bin/console debug:container --format=json
   ```

2. Increase cache TTL:
   ```lua
   opts = { cache_ttl = 600 }
   ```

### Disable auto-configuration

If you prefer manual setup:

```lua
opts = {
  blink_cmp = {
    enabled = false,
  },
}
```

## 🔄 Migration from v1.x

If you're upgrading from an older version:

1. Update Neovim to 0.11+
2. Update blink.cmp to 1.0+
3. Remove manual blink.cmp configuration (now automatic)
4. Update plugin configuration if needed
5. Run `:SymfonyReload`

## 🤝 Contributing

Contributions are welcome! Areas for improvement:

- Additional Symfony features
- Better context detection
- Performance optimizations
- Documentation improvements

## 📄 License

MIT License

## 🙏 Acknowledgments

- Neovim core team for 0.11 features
- blink.cmp for the excellent completion framework
- Symfony community for the amazing framework
