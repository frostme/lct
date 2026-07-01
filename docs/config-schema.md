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
