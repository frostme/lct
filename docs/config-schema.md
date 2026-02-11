# LCT config schema

The LCT CLI reads `~/.config/lct/config.yaml`. This file should conform to:

- [`schema/lct-config.schema.yaml`](schema/lct-config.schema.yaml)

## Minimal valid config

```yaml
remote: null
configs: []
dotfiles: []
other: {}
plugins: []
modules: []
```

## Full config

```yaml
remote: git@github.com:example/dotfiles.git
configs:
  - ~/.config/alacritty
  - ~/.config/nvim
dotfiles:
  - ~/.zshrc
  - ~/.gitconfig
other:
  ~/work/custom.conf: ~/.config/custom/custom.conf
  ~/.local/bin/dev-tool: ~/.local/bin/dev-tool
plugins:
  - gh/owner/example-plugin
  - gh/owner/another-plugin
modules:
  - github.com/example/lct-module
  - github.com/example/lct-theme
packageManager: mise
```
