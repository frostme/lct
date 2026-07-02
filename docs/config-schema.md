# LCT config schema

The LCT CLI reads `~/.config/lct/config.yaml`. This file should conform to:

- [`schema/lct-config.schema.yaml`](schema/lct-config.schema.yaml)

## Minimal valid config

```yaml
remote: null
configs: []
dotfiles: []
other: []
encryptAliasFile: false
encryptEnvFile: false
plugins: []
modules: []
projects: []
bootstrap_order:
  - packages
  - configs
  - projects
  - plugins
  - modules
  - secrets
```

## Full config

```yaml
remote: git@github.com:example/dotfiles.git
configs:
  - alacritty
  - nvim
dotfiles:
  - ~/.zshrc
  - ~/.gitconfig
other:
  - ~/work/custom.conf
  - ~/.local/bin/dev-tool
encryptAliasFile: true
encryptEnvFile: true
plugins:
  - gh/owner/example-plugin
  - gh/owner/another-plugin
modules:
  - github.com/example/lct-module
  - github.com/example/lct-theme
projects:
  - frostme/lct
  - frostme/hmgmt-vibe
packageManager: mise
bootstrap_order:
  - plugins
  - packages
  - configs
  - projects
  - modules
  - secrets
```

## Bootstrap order

`bootstrap_order` controls the sequence used by `lct bootstrap`. The default is:

1. `packages` — install the gathered package-manager bundle.
2. `configs` — restore configured application directories.
3. `projects` — clone configured code projects.
4. `plugins` — install and load LCT plugins.
5. `modules` — install configured LCT modules.
6. `secrets` — decrypt and restore configured secrets.

A custom order must include every supported phase exactly once. LCT validates the
list and prints the resolved order before running any phase.

## Package-manager model

`packageManager` selects the preferred manager for package gather and bootstrap
flows. Internally, LCT models managers in a registry with three categories:

- `system` — top-level operating-system package managers such as `brew` and `apt`.
- `runtime` — runtime/toolchain managers such as `mise`.
- `language` — language ecosystem managers such as `pnpm`, `cargo`, `pip`, and `uv`.

Dependencies use typed identifiers such as `runtime:node`, `runtime:rust`, and
`runtime:python`. Unsupported bundle export or restore operations are recorded
explicitly instead of being inferred from a missing implementation.

| Manager | Category | Dependencies | Install/remove | Bundle export/restore |
| --- | --- | --- | --- | --- |
| `brew` | system | none | supported | supported |
| `apt` | system | none | supported | supported |
| `mise` | runtime | none | supported | supported |
| `pnpm` | language | `runtime:node` | supported | unsupported |
| `cargo` | language | `runtime:rust` | supported | unsupported |
| `pip` | language | `runtime:python` | supported | supported |
| `uv` | language | none | supported | unsupported |

To add a manager, add a record to `src/lib/package_manager_registry.sh`, add the
corresponding operation handlers to `src/lib/package_manager.sh`, and extend the
registry tests and this table. Operation handler identifiers are dispatched by
LCT and are never evaluated as shell input.

## Curated package lists

The `packages` map is the explicit source of truth for packages tracked by each
registered manager. Manage it through the CLI:

```bash
lct package list brew
lct package add brew wget
lct package remove brew wget
lct package add pnpm '@dotenvx/dotenvx'
```

Duplicate additions are idempotent. Removing an untracked package leaves the
list unchanged. Both cases print a concise status message and return success.
