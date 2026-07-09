# neoSymfony — Design Document

## Overview

A NeoVim plugin for Symfony 7/8 development targeting LazyVim users, providing the full palette of PhpStorm Symfony features inside NeoVim. Built standalone — no existing plugin covers enough ground to be a viable base.

## Scope & Target

- **NeoVim**: 0.12+
- **Distribution**: LazyVim / lazy.nvim first. Generic NeoVim support is a v2 concern.
- **Symfony versions**: 7 and 8 only (both share the same container/console architecture)
- **PHP**: 8.2+ (Symfony 8 requirement)

## Existing Plugins — Why We Build Standalone

| Plugin | Covers | Verdict |
|---|---|---|
| `NeverI/symfony.nvim` | Container, routes, config syntax | Built for denite + ncm2 — incompatible with LazyVim. Abandoned. |
| `pierreboissinot/cmp-symfony` | Service + route nvim-cmp completion | Route part WIP, no navigation, no Twig/Doctrine/translations/forms |
| `fbuchlak/cmp-symfony-router` | Route completion only | Too narrow |
| `ccaglak/phptools.nvim` | Generic PHP `gd` navigation | Not Symfony-specific |
| `dyatlovk/symfony-nvim` | Services, routes, console commands | No nvim-cmp/Telescope/Treesitter, covers 3 of 9 features |

None cover half the required features. Building standalone avoids inheriting technical debt.

---

## Features

### Priority Order (highest to lowest daily friction)

1. DI / Service container awareness
2. Route navigation
3. Twig template navigation
4. Doctrine ORM
5. Translation key completion
6. Console command discovery
7. Event / listener navigation
8. Form type introspection
9. YAML config validation + security config

### Feature Surface (how each feature appears in NeoVim)

| Feature | UI Mechanism | Keymap |
|---|---|---|
| Service completion | nvim-cmp source | triggered on typing |
| Route navigation | Telescope picker + `gd` override | `<leader>sR` |
| Twig template navigation | `gd` override on string in `render()` | `gd` |
| Doctrine entity navigation | Telescope picker + nvim-cmp source | `<leader>sD` |
| Translation key completion | nvim-cmp source + `gd` to key | triggered on typing |
| Console commands | Telescope picker | `<leader>sC` |
| Event / listener navigation | Telescope picker | `<leader>sE` |
| Form type completion | nvim-cmp source | triggered on typing |
| YAML config validation | LSP diagnostics via `yaml-language-server` | automatic |

### Keymaps

Default prefix follows LazyVim's `<leader>s` (search) convention:

| Keymap | Action |
|---|---|
| `<leader>sR` | Symfony routes picker |
| `<leader>sS` | Symfony services picker |
| `<leader>sC` | Symfony console commands picker |
| `<leader>sE` | Symfony events / listeners picker |
| `<leader>sD` | Symfony Doctrine entities picker |
| `<leader>sT` | Symfony Twig templates picker |

All keymaps are fully overridable via `opts.keymaps`. Disable all defaults with `opts.keymaps = false`.

---

## Feature Depth (v1)

### DI / Service Container
- Parse `var/cache/dev/App_KernelDevDebugContainer.xml` directly — no kernel boot
- nvim-cmp source triggered inside PHP constructor parameter lists (Treesitter context)
- `gd` on a service id string resolves to the service class

### Route Navigation
- Parse `var/cache/dev/url_generating_routes.php` and `url_matching_routes.php`
- Telescope picker with fuzzy search over route names, paths, and controller
- `gd` on a route name string jumps to the controller action

### Twig Template Navigation
- `gd` on a string inside `render('...')` opens the template file
- Telescope picker for fuzzy-finding `*.html.twig` files
- **`{# @var varName \Full\Class\Name #}` support**: parse these comments in Twig files via Treesitter, map variable names to PHP classes, enable `{{ varName.` completion from Doctrine entity metadata and `gd` to the entity class — no cross-file controller analysis needed
- Twig LSP (`twig-language-server`) installed via Mason for syntax checking and basic completion
- **Gotcha**: `twig-language-server` is still young with known gaps — documented in README

### Doctrine ORM (Level 2)
- Telescope picker to fuzzy-find and jump to Entity classes (`src/Entity/`)
- `gd` on `$this->userRepository` resolves to the correct `UserRepository` via container XML
- Level 3 (DQL completion) and Level 4 (full ORM introspection) are post-v1

### Translation Keys (Level 2)
- Parse `translations/` YAML files directly — fast, no console needed
- nvim-cmp source triggered inside `trans('...')` and `t('...')` calls in PHP and Twig
- `gd` on a translation key string jumps to the correct line in the translation file

### Console Commands
- Data source: `bin/console list --format=json` (async, cached)
- Telescope picker: fuzzy-search command names, jump to the `Command` class

### Event / Listener Navigation
- Data source: `bin/console debug:event-dispatcher --format=json` (async, cached)
- Telescope picker: browse events, see all registered listeners, jump to listener class

### Form Types (Level 2)
- Telescope picker for `*Form` / `*Type` classes in `src/Form/`
- nvim-cmp source inside `$builder->add(...)` second argument: completes with Symfony built-in types (`TextType`, `EmailType`, etc.) + custom types found by scanning for classes extending `AbstractType`

### YAML Config Validation
- `yaml-language-server` installed via Mason
- Symfony JSON schemas wired up for `config/packages/*.yaml` and `security.yaml`

---

## Data Sources & Caching

| Feature | Data Source | Speed |
|---|---|---|
| Services / DI | Parse `var/cache/dev/*Container.xml` | ~instant |
| Routes | Parse `var/cache/dev/url_*_routes.php` | ~instant |
| Events / listeners | `debug:event-dispatcher --format=json` + file cache | async |
| Translation keys | Parse `translations/` directory | ~instant |
| Console commands | `bin/console list --format=json` + file cache | async |
| Twig templates | Filesystem scan for `*.html.twig` | ~instant |
| Doctrine entities | Filesystem scan of `src/Entity/` + container XML | ~instant |
| Form types | Filesystem scan of `src/Form/` | ~instant |

**Async strategy**: use `vim.system()` (non-blocking) for console commands. Cache JSON output to `.cache/neo-symfony/` in project root. Invalidate cache by watching `var/cache/dev/` mtime.

**Gotcha**: `debug:container` and similar commands boot the full Symfony kernel — can take 2–5s on large projects. Always prefer parsing the compiled cache files on disk. Console commands are a fallback only.

---

## Context Detection (Treesitter)

Treesitter is used to detect cursor context before activating completions:

- Inside a PHP constructor parameter list → trigger service completion
- Inside `render('...')` string argument → trigger template completion + `gd` override
- Inside `trans('...')` / `t('...')` string → trigger translation completion
- Inside `$builder->add(...)` second argument → trigger form type completion
- Inside a `{# @var ... #}` Twig comment → parse variable type mapping
- On a route name string → enable `gd` override to controller

Pattern matching (regex on current line) used as fallback for YAML files where Treesitter coverage is thinner.

---

## Dependencies

All dependencies are available in LazyVim by default except phpactor and yamlls (installed via Mason):

| Dependency | Purpose | Already in LazyVim |
|---|---|---|
| `nvim-treesitter` + `php`, `twig`, `yaml` grammars | Context detection | Yes |
| `nvim-cmp` | Completion sources | Yes |
| `telescope.nvim` | Navigation pickers | Yes |
| `mason.nvim` | LSP / tool installer | Yes |
| `mason-lspconfig.nvim` | LSP auto-install bridge | Yes |
| `nvim-lspconfig` | LSP configuration | Yes |
| `phpactor` (via Mason) | PHP LSP | No — auto-installed |
| `yaml-language-server` (via Mason) | YAML validation | No — auto-installed |
| `twig-language-server` (via Mason) | Twig LSP | No — auto-installed |

### Auto-Install Behaviour

On first launch in a Symfony project, the plugin shows a one-time notification:

```
[neoSymfony] Installing dependencies: phpactor, yamlls, twig-language-server...
Run :NeoSymfonyInstall to install manually if skipped.
```

Then installs in the background via Mason. `:NeoSymfonyInstall` is also exposed as a manual command.

---

## Project Detection

The plugin activates only when both of the following exist in the project root (resolved via `vim.fs.root()`):

1. `bin/console`
2. `symfony.lock`

This avoids false positives on plain PHP, Laravel, or other frameworks.

---

## Known Limitations (v1)

- **Single Symfony app per repo only.** Monorepo layouts (multiple `bin/console` roots) are not supported. Each app must be opened as its own NeoVim root.
- **Multiple environments not switchable.** Container data always comes from `var/cache/dev/`. Production container inspection is not supported.
- **`twig-language-server` gaps.** The Twig LSP is still maturing — some completions and diagnostics may be missing or incorrect.
- **Doctrine Level 3/4 not in v1.** DQL completion and full ORM introspection are post-v1.
- **Symfony 6 and below not supported.** The plugin targets Symfony 7 and 8 only.

---

## Future Work (v2+)

- Monorepo / multi-app support
- Environment switching (`dev` / `prod` container)
- Doctrine Level 3: DQL completion inside `createQuery()` strings
- Doctrine Level 4: field completion on entity instances, relation traversal
- Twig Level 3: cross-file variable awareness from controller `render()` calls
- Form type Level 3: option completion per type (configureOptions introspection)
- Submit as a LazyVim extra (`lang.symfony`) for maximum discoverability
- Generic NeoVim support (packer, mini.deps)
