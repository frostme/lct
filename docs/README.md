# lct

Local configuration tool

| Attributes       | &nbsp;
|------------------|-------------
| Version:         | 0.6.1

## Usage

```bash
lct COMMAND
```

## Configuration schema

The user config file at `~/.config/lct/config.yaml` should conform to the LCT config schema:

- [`docs/schema/lct-config.schema.yaml`](schema/lct-config.schema.yaml)
- [Configuration guide](config-schema.md)

### Minimal valid config

```yaml
remote: null
configs: []
dotfiles: []
other: {}
plugins: []
modules: []
```

### Full config

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

## Dependencies

#### *gum*



#### *yq*



## Commands

- [init](lct%20init.md) - Initialize lct configuration
- [bootstrap](lct%20bootstrap.md) - Bootstrap your local configuration
- [gather](lct%20gather.md) - Gather local configuration files
- [install](lct%20install.md) - Install bash script releases from GitHub or LCTFile
- [alias](lct%20alias.md) - Manage lct aliases
- [dotfiles](lct%20dotfiles.md) - Manage dotfiles list
- [configs](lct%20configs.md) - Manage configs list
- [env](lct%20env.md) - Manage local environment variables
- [plugin](lct%20plugin.md) - Develop and manage lct plugins
- [lib](lct%20lib.md) - Manage lct libraries
- [completions](lct%20completions.md) - Generate bash completions
- [config](lct%20config.md) - Open your config files in your ${EDITOR:-editor}
- [setup](lct%20setup.md) - Setup lct in your shell
- [prune](lct%20prune.md) - Prune config and plugins files


