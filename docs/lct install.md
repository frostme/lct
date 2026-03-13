# lct install

Install modules from an LCTFile or globally (bin links are created only for high-confidence scripts)

| Attributes       | &nbsp;
|------------------|-------------
| Alias:           | add

## Usage

```bash
lct install [MODULE] [OPTIONS]
```

## Examples

```bash
lct install DannyBen/approvals.bash
```

```bash
lct install -g DannyBen/approvals.bash
```

```bash
lct install
```

## Arguments

#### *MODULE*

GitHub owner/repo or repository path of the module to install

## Options

#### *--force, -f*

Force reinstall and bypass the module cache

#### *--global, -g*

Use global module installation from config.yaml


