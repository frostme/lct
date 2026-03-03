# lct

Local configuration tool

| Attributes       | &nbsp;
|------------------|-------------
| Version:         | 0.4.1

## Usage

```bash
lct COMMAND
```

## Dependencies

#### *gum*

Checkout the [installation](https://github.com/charmbracelet/gum?tab=readme-ov-file#installation) section of gum's README.md

#### *yq*

Checkout the [install](https://github.com/mikefarah/yq?tab=readme-ov-file#install) section of yq's README.md

## Environment Variables

#### *SOFTWARE_DIR*

Base directory for downloaded libraries managed on this machine.

| Attributes      | &nbsp;
|-----------------|-------------
| Default Value:  | $HOME/software

#### *CONFIG_DIR*

Base directory for local configuration files.

| Attributes      | &nbsp;
|-----------------|-------------
| Default Value:  | $HOME/.config

#### *SHARE_DIR*

Base directory for local shared application data.

| Attributes      | &nbsp;
|-----------------|-------------
| Default Value:  | $HOME/.local/share

#### *STATE_DIR*

Base directory for persistent local state data.

| Attributes      | &nbsp;
|-----------------|-------------
| Default Value:  | $HOME/.local/state

#### *CACHE_DIR*

Base directory for local cache data.

| Attributes      | &nbsp;
|-----------------|-------------
| Default Value:  | $HOME/.cache

## Commands

- [init](lct%20init.md) - Initialize lct configuration
- [bootstrap](lct%20bootstrap.md) - Bootstrap your local configuration
- [gather](lct%20gather.md) - Gather local configuration files (flags possible secrets before committing)
- [install](lct%20install.md) - Install modules from an LCTFile or globally (bin links are created only for high-confidence scripts)
- [self-update](lct%20self-update.md) - Update lct to the latest release
- [remove](lct%20remove.md) - Remove modules from an LCTFile or globally
- [alias](lct%20alias.md) - Manage lct aliases
- [dotfiles](lct%20dotfiles.md) - Manage dotfiles list
- [configs](lct%20configs.md) - Manage configs list
- [env](lct%20env.md) - Manage local environment variables
- [reload](lct%20reload.md) - Reload lct environment variables and aliases into the current shell
- [plugin](lct%20plugin.md) - Develop and manage lct plugins
- [completions](lct%20completions.md) - Generate bash completions
- [config](lct%20config.md) - Open your config files in your ${EDITOR:-editor}
- [setup](lct%20setup.md) - Setup lct in your shell
- [prune](lct%20prune.md) - Prune config and plugins files

## Configuration schema

The user config file at ~/.config/lct/config.yaml should conform to the LCT config schema:

- [docs/schema/lct-config.schema.yaml](schema/lct-config.schema.yaml)
- [Configuration guide](config-schema.md)

### Minimal valid config

    remote: null
    configs: []
    dotfiles: []
    other: {}
    plugins: []
    modules: []

### Full config

    remote: git@github.com:example/dotfiles.git
    configs:
      - alacritty
      - nvim
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
