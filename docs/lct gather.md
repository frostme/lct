# lct gather

Gather local configuration files. The command scans gathered files for common secret patterns before committing and will prompt to continue, scrub, or abort. Set `LCT_GATHER_SECRET_ACTION` to `continue`, `scrub`, or `abort` to preselect an action in non-interactive runs.

| Attributes       | &nbsp;
|------------------|-------------
| Alias:           | g

## Usage

```bash
lct gather [OPTIONS]
```

## Examples

```bash
lct gather
```

## Options

#### *--force, -f*

overwrite existing files in remote repository

