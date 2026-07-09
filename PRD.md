# PRD: neoSymfony — Symfony 7/8 Plugin for NeoVim

## Problem Statement

PHP developers working on Symfony projects who use NeoVim (with a LazyVim distribution) lose access to a large set of framework-aware IDE features they previously had in PhpStorm. Generic PHP LSP servers (phpactor, intelephense) provide class navigation and autocompletion, but have no knowledge of the Symfony container, routing system, Twig templates, Doctrine entities, translation keys, form types, or event listeners. This forces developers to either manually search for service definitions, remember route names by heart, or switch back to PhpStorm for Symfony-specific tasks — breaking their NeoVim-first workflow.

## Solution

A NeoVim plugin (`neoSymfony`) targeting LazyVim users that provides the full set of PhpStorm Symfony plugin features inside NeoVim. The plugin auto-installs its LSP and Treesitter dependencies via Mason on first launch, detects Symfony projects automatically, and exposes features through three surfaces: blink.cmp completion sources (triggered in-context), Telescope pickers (triggered by keymaps), and `gd` overrides (jump-to-definition on Symfony-typed strings). Data is sourced from Symfony's already-compiled cache files on disk rather than booting the kernel, keeping all operations near-instant.

## User Stories

### Project Detection & Setup

1. As a Symfony developer, I want the plugin to detect that I am inside a Symfony project automatically (via `bin/console` + `symfony.lock`), so that features activate without manual configuration.
2. As a Symfony developer, I want to be notified on first launch that phpactor, yamlls, and twig-language-server are being installed, so that I understand what is happening to my environment.
3. As a Symfony developer, I want to run `:NeoSymfonyInstall` to trigger dependency installation manually, so that I can recover from a skipped auto-install.
4. As a Symfony developer, I want the plugin to remain completely silent in non-Symfony PHP projects (Laravel, plain PHP), so that it does not pollute unrelated workflows.
5. As a Symfony developer, I want all default keymaps to be overridable via `opts.keymaps`, so that I can adapt the plugin to my existing keymap configuration.
6. As a Symfony developer, I want to disable all default keymaps with `opts.keymaps = false` and define my own, so that I have full control over my key bindings.
7. As a Symfony developer, I want to run `:NeoSymfonyClearCache` to force a data refresh, so that stale completions after a container rebuild do not persist.
8. As a Symfony developer, I want to run `:SymfonyInfo` to see the active project root, configured keymaps, and console environment at a glance, so that I can verify the plugin is correctly activated.

### DI Container / Service Awareness

9. As a Symfony developer, I want autocomplete for service IDs inside PHP constructor parameter lists, so that I can wire dependencies without leaving the editor or consulting `debug:container`.
10. As a Symfony developer, I want each completion item to show the service's FQCN as detail text, so that I can confirm I am injecting the correct class.
11. As a Symfony developer, I want to use `<leader>sS` to open a Telescope picker listing all registered services, so that I can fuzzy-search by service ID or class name.
12. As a Symfony developer, I want `gd` on a service ID string to jump to the service's class file, so that I can inspect the implementation without a manual file search.
13. As a Symfony developer, I want container data to be read from the compiled container XML on disk (not from running `debug:container`), so that completions appear instantly even in large projects.
14. As a Symfony developer, I want the container data cache to be automatically invalidated when `var/cache/dev/` is newer than the cache file, so that I always get current data after a `cache:clear`.

### Route Navigation

15. As a Symfony developer, I want to use `<leader>sR` to open a Telescope picker listing all application routes with their name, path, methods, and controller, so that I can find and jump to any controller action by fuzzy-searching.
16. As a Symfony developer, I want `gd` on a route name string (e.g. `'app_user_index'`) to jump to the corresponding controller action, so that I can navigate from any call site to the handler.
17. As a Symfony developer, I want route data to be parsed from the compiled route cache files on disk, so that the picker loads instantly without booting the Symfony kernel.
18. As a Symfony developer, I want autocomplete for route names inside `$this->generateUrl()` and `$this->redirectToRoute()` calls, so that I can reference routes without memorizing their names.

### Twig Template Navigation

19. As a Symfony developer, I want `gd` on a template path string inside a `render()` call to open the corresponding `.html.twig` file, so that I can navigate from controller to template in one keystroke.
20. As a Symfony developer, I want to use `<leader>sT` to open a Telescope picker fuzzy-searching all `*.html.twig` templates in the project, so that I can jump to any template directly.
21. As a Symfony developer writing a Twig template, I want to type `{# @var user \App\Entity\User #}` and have `{{ user.` trigger autocomplete with the entity's fields, so that I get type-driven completion without cross-file controller analysis.
22. As a Symfony developer, I want `gd` on a `@var`-hinted Twig variable to jump to the corresponding PHP entity class, so that I can inspect the entity from within the template.
23. As a Symfony developer, I want Twig files to have syntax checking and basic tag/filter completion provided by `twig-language-server`, so that I catch syntax errors early.

### Doctrine ORM

24. As a Symfony developer, I want to use `<leader>sD` to open a Telescope picker listing all Entity classes under `src/Entity/`, so that I can jump to any entity file by name.
25. As a Symfony developer, I want `gd` on a repository property (e.g. `$this->userRepository`) to resolve and jump to the `UserRepository` class file, so that I can inspect the repository without a manual search.
26. As a Symfony developer, I want repository resolution to use the compiled container XML, so that service-to-class mapping is always accurate.

### Translation Keys

27. As a Symfony developer, I want autocomplete for translation keys inside `trans()` and `t()` calls in PHP files, so that I can insert keys without leaving the editor or opening translation files.
28. As a Symfony developer, I want autocomplete for translation keys inside `{{ 'key'|trans }}` expressions in Twig templates, so that I have the same completion experience across both file types.
29. As a Symfony developer, I want each translation key completion item to show the locale as detail text, so that I can distinguish between keys from different locale files.
30. As a Symfony developer, I want `gd` on a translation key string to jump to the exact line in the corresponding translation YAML file, so that I can inspect or edit the translation immediately.
31. As a Symfony developer, I want translation data to be parsed directly from `translations/*.yaml` files without running any console command, so that key completion is instant.

### Console Commands

32. As a Symfony developer, I want to use `<leader>sC` to open a Telescope picker listing all registered Symfony console commands with their descriptions, so that I can find and jump to any `Command` class by fuzzy-searching.
33. As a Symfony developer, I want command data to be fetched asynchronously via `bin/console list --format=json` without blocking the editor, so that opening the picker never causes a freeze.
34. As a Symfony developer, I want command data to be cached and only refreshed when `var/cache/dev/` has changed, so that repeated picker openings are instant.

### Event & Listener Navigation

35. As a Symfony developer, I want to use `<leader>sE` to open a Telescope picker listing all events and their registered listeners (class + method + priority), so that I can navigate the event system without reading YAML or running console commands.
36. As a Symfony developer, I want selecting a listener entry in the picker to jump to the listener class file, so that I can inspect the handler directly.
37. As a Symfony developer, I want event/listener data to be fetched asynchronously via `debug:event-dispatcher --format=json` with caching, so that the picker is fast on repeated use.

### Form Types

38. As a Symfony developer, I want autocomplete for Symfony form type classes inside `$builder->add()` as the second argument, so that I can select field types without consulting the documentation.
39. As a Symfony developer, I want the completion list to include all built-in Symfony 7/8 form types as well as custom `AbstractType` subclasses found in `src/Form/`, so that project-specific types are also available.
40. As a Symfony developer, I want each form type completion item to show the FQCN as detail text and whether it is a built-in or project type, so that I can quickly distinguish them.

### YAML Config Validation

41. As a Symfony developer, I want `config/packages/*.yaml` files to be validated against their Symfony JSON schemas, so that misconfiguration is caught at edit time with inline diagnostics.
42. As a Symfony developer, I want `security.yaml` to be validated and to receive completion for firewall keys, access control roles, and voter names, so that I can write security config with confidence.

## Implementation Decisions

### Module Architecture

The plugin is structured into five layers with clear separation of concerns:

1. **Core infrastructure** (`detection`, `cache`, `install`, `config`) — project detection, disk-based JSON caching, Mason dependency installation, and user configuration. These have no dependency on Symfony features and no dependency on each other (except `cache` depending on nothing).

2. **Feature modules** (`features/container`, `features/routes`, `features/twig`, `features/doctrine`, `features/translations`, `features/commands`, `features/events`, `features/forms`) — one module per Symfony subsystem. Each module exposes a simple data-fetching interface (`get_*`) and is completely independent of the editor surface. Synchronous modules return data directly; modules backed by slow console commands accept a callback and use `vim.system()` for non-blocking execution.

3. **Context detection** (`treesitter/context`) — wraps the Treesitter API to answer a single question: what Symfony context is the cursor in right now? Returns a string constant (`"constructor_param"`, `"render_call"`, `"trans_call"`, `"builder_add"`, `nil`). Used by blink.cmp sources to gate completions.

4. **Editor surfaces** (`completion/blink_source`, `telescope`, `keymaps`) — translate feature module data into NeoVim UI: blink.cmp completion source, Telescope pickers, and keymap registrations. These are the only modules that import NeoVim plugin APIs (blink.cmp, telescope). They depend on feature modules but feature modules do not depend on them.

5. **Plugin entry** (`init`, `plugin/neo-symfony.lua`) — orchestrates activation per project root, registers autocommands and user commands, and calls into all other layers.

### Completion Engine: blink.cmp

The plugin targets **blink.cmp** as the completion engine, not nvim-cmp. Users wire the source via their blink.cmp `opts`:

```lua
sources = {
  default = { 'lsp', 'path', 'snippets', 'lazydev', 'symfony' },
  providers = {
    symfony = {
      name = 'symfony',
      module = 'neo-symfony.completion.blink_source',
      score_offset = 10,
    },
  },
},
```

The blink source calls `context.detect_completion_type(ctx)` to gate by cursor context, then delegates to the appropriate feature module.

### Data Source Strategy

Fast data (near-instant, synchronous):
- **Services**: parsed from `var/cache/dev/*Container.xml` on disk — no kernel boot.
- **Routes**: parsed from `var/cache/dev/url_generating_routes.php` on disk.
- **Translations**: parsed directly from `translations/*.yaml`.
- **Twig templates**: filesystem glob over `templates/**/*.html.twig`.
- **Doctrine entities**: filesystem glob over `src/Entity/**/*.php`.
- **Form types**: filesystem glob over `src/Form/**/*.php` for `AbstractType` subclasses.

Slow data (async via `vim.system()`, file-cached):
- **Console commands**: `bin/console list --format=json`
- **Events/listeners**: `bin/console debug:event-dispatcher --format=json`

Cache invalidation: compare `vim.fn.getftime(cache_file)` against `vim.fn.getftime("var/cache/dev")`. If the dev cache directory is newer, the plugin cache is stale and re-fetched on next access.

### Cache Module API

The cache module exposes a two-layer (in-process + disk) interface:

- `cache.get(key, root)` — returns cached data or nil; populates from disk if present and fresh
- `cache.set(key, data, root)` — writes to in-process table and, if `root` given, to disk as JSON
- `cache.invalidate(key, root)` — removes from in-process table and deletes disk file
- `cache.clear(root)` — clears all keys for a project root

Data is stored as JSON in `{project_root}/.cache/neo-symfony/{key}.json`. All feature modules go through this interface — no module holds in-process state beyond what it receives from `cache.get`. Note: feature stubs written against a legacy `cache.read/write/is_stale` API must be updated to use `cache.get/set`.

### Context Detection

Treesitter is a hard dependency. The context module walks the Treesitter AST upward from the cursor node to identify Symfony-specific call sites. Pattern-matching fallback (line regex) is used only for YAML files where the Treesitter grammar is thinner. Context detection is called at completion trigger time, not at buffer open time, to avoid unnecessary work.

### Container XML Parsing (Critical Gap)

`features/container.lua` currently contains only a stub. The implementation must parse `var/cache/dev/*Container.xml` using Lua's pattern matching (NeoVim has no XML library). Key attributes to extract per `<service>` node: `id`, `class`, `public`. Tags (e.g. `kernel.event_listener`) can be extracted for later filtering. The file is large (10k+ nodes in real projects) so the parser should scan line-by-line rather than loading the full file into memory.

### Route PHP Cache Parsing (Critical Gap)

`features/routes.lua` currently contains only a stub. The implementation must parse `var/cache/dev/url_generating_routes.php` using Lua pattern matching. The file exports a PHP array of route definitions. Key fields: route name (array key), `path`, `defaults` (`_controller`), `methods`. The file format is stable across Symfony 7 and 8.

### Dependency Auto-Install

On first activation in a Symfony project, Mason installs `phpactor`, `yamlls`, and `twig-language-server` via `mason-lspconfig.setup({ ensure_installed = ... })`. Treesitter parsers (`php`, `twig`, `yaml`) are installed via `nvim-treesitter.install.ensure_installed`. The user is notified before installation begins. A `:NeoSymfonyInstall` command allows manual re-triggering. For LazyVim users, all plugin-level dependencies (telescope, blink.cmp, mason, nvim-treesitter) are already present — only the LSP servers and Treesitter parsers are net-new downloads.

### Project Detection

The plugin root is resolved by `vim.fs.root(0, { "symfony.lock" })` and confirmed by verifying that `bin/console` exists at that root. Both files must be present. Detection runs on `BufEnter` and `DirChanged` autocmds. Once a root is activated it is stored in `require("neo-symfony").project_root` for all modules to read.

### Keymaps

Default keymaps follow the LazyVim `<leader>s` (search) convention:

| Key | Action |
|---|---|
| `<leader>sR` | Routes picker |
| `<leader>sS` | Services picker |
| `<leader>sC` | Console commands picker |
| `<leader>sE` | Events/listeners picker |
| `<leader>sD` | Doctrine entities picker |
| `<leader>sT` | Twig templates picker |

All keymaps are fully overridable via `opts.keymaps = { routes = "...", ... }` or disabled entirely with `opts.keymaps = false`.

### Symfony Version Support

Symfony 7 and 8 only. Both versions share the same compiled container XML schema, console command formats, and file layout. PHP 8.2+ is assumed (Symfony 8 requirement).

### Twig @var Type Hints

The `{# @var varName \Full\Class\Name #}` PhpStorm convention is parsed locally in the current buffer using a line-by-line regex over Twig comment nodes. The resulting `varName → FQCN` map is used to feed entity field completions from the Doctrine feature module and to enable `gd` from the Twig variable to the PHP class. No cross-file controller analysis is required.

### Doctrine Depth (v1)

Level 2 only: entity class navigation (filesystem glob over `src/Entity/`) and repository service resolution via container XML. DQL completion (Level 3) and full ORM introspection (Level 4) are post-v1.

## Testing Decisions

### What makes a good test

Tests should verify observable behavior at module boundaries, not internal implementation details. A good test calls a module's public function with known inputs (real or fixture files) and asserts on the returned data structure. Tests should not mock internal helpers — they should use real fixture files that mirror actual Symfony project output (e.g. a real `*Container.xml`, a real `url_generating_routes.php`, real `translations/messages.en.yaml`).

### Modules to test

| Module | What to test | Test approach |
|---|---|---|
| `detection` | Returns root when both marker files exist; returns nil when either is missing | Temp dir with/without files |
| `cache` | Write+read round-trip; stale detection based on mtime; invalidate deletes file | Temp dir, controlled mtimes |
| `features/translations` | Parses flat and nested YAML keys; correctly records file path and line number | Fixture YAML files |
| `features/forms` | Built-in types are present; `AbstractType` subclasses in src/Form/ are discovered; non-form classes are excluded | Fixture PHP files |
| `features/twig` | Template glob returns correct relative paths; `parse_var_hints` extracts all `@var` annotations; `resolve_template` returns correct path or nil | Fixture directory tree |
| `features/doctrine` | Entity scan returns correct name+path pairs; `resolve_repository` maps FQCN to file path | Fixture `src/Entity/` directory |
| `treesitter/context` | Returns correct context constant for each recognized cursor position; returns nil for unrecognized positions | Requires NeoVim headless test runner with Treesitter |
| `features/container` | Parses service id, class, and public flag from fixture XML; handles 10k+ service files without OOM | Fixture XML from a real Symfony 7 project |
| `features/routes` | Parses route name, path, methods, and controller from fixture PHP cache file | Fixture PHP file from a real Symfony 7 project |

### Modules intentionally not unit-tested

- `completion/blink_source` and `telescope` — thin wiring layers over blink.cmp and telescope APIs; correctness verified by integration/manual testing.
- `install` — Mason integration; no meaningful unit test possible without a live NeoVim + Mason environment.
- `features/commands` and `features/events` — async `vim.system()` callers; tested via integration test with a real Symfony project or a mock `bin/console` script.

## Out of Scope

- **Generic NeoVim support** (packer, mini.deps, etc.) — LazyVim/lazy.nvim only for v1.
- **nvim-cmp support** — the plugin targets blink.cmp exclusively; nvim-cmp users are out of scope for v1.
- **Symfony 6 and below** — container XML schema and command output differ; not supported.
- **Monorepo layouts** — projects with multiple `bin/console` roots (multiple Symfony apps in one repo) are a known v1 limitation.
- **Environment switching** — container data always comes from `var/cache/dev/`. Production container inspection is not supported in v1.
- **Doctrine Level 3** — DQL completion inside `createQuery()` strings.
- **Doctrine Level 4** — field completion on entity instances, relation traversal.
- **Twig Level 3** — cross-file variable awareness derived from controller `render()` calls (without `@var` hints).
- **Form type option completion** — completing the options array (third `$builder->add()` argument) for each specific form type.
- **LazyVim extra submission** — `lang.symfony` LazyVim extra is a post-v1 distribution milestone.
- **Security config deep awareness** — `security.yaml` gets YAML schema validation via `yaml-language-server` only; no custom role/firewall picker.

## Further Notes

- The `.cache/neo-symfony/` directory should be added to `.gitignore` in consumer projects.
- The `twig-language-server` is still maturing as of Symfony 8 — users should expect gaps in Twig diagnostics and completions that are outside neoSymfony's control.
- The existing `NeverI/symfony.nvim` plugin (denite/ncm2-based) and `dyatlovk/symfony-nvim` (no blink.cmp/telescope/treesitter integration) were evaluated and found to cover fewer than 4 of the 9 required features using incompatible tooling. neoSymfony is built standalone for this reason.
- The `{# @var #}` convention for Twig type hints is a de facto standard originating from PhpStorm's Symfony plugin. Documenting it prominently in the README will help users discover this feature.
- The two most critical unimplemented pieces are the container XML parser (`features/container.lua`) and the route PHP cache parser (`features/routes.lua`) — all other data layers (translations, twig, doctrine, forms) are either implemented or backed by simple filesystem globs.
- Feature stubs (`features/container.lua`, `features/routes.lua`) call a legacy `cache.read/write/is_stale` API that no longer exists. These must be migrated to `cache.get/set` before they can be wired up.
