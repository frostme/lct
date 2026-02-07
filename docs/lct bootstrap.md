# lct bootstrap

Bootstrap your local configuration

| Attributes       | &nbsp;
|------------------|-------------
| Alias:           | b

## Usage

```bash
lct bootstrap [OPTIONS]
```

## Examples

```bash
lct bootstrap
```

```bash
lct bootstrap -c 26.01.20
```

If initialization has not been run yet, this command will trigger `lct init` with default answers before bootstrapping.

## Options

#### *--config, -c CONFIG*

Config version to bootstrap

