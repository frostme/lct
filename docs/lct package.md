# lct package

Manage tracked packages by package manager

## Usage

```bash
lct package COMMAND
```

## Examples

```bash
lct package list brew
```

```bash
lct package add brew wget
```

```bash
lct package remove brew wget
```

```bash
lct package add pnpm '@dotenvx/dotenvx'
```

## Commands

- [list](lct%20package%20list.md) - List packages tracked for a package manager
- [add](lct%20package%20add.md) - Add a package to a manager-specific tracked list
- [remove](lct%20package%20remove.md) - Remove a package from a manager-specific tracked list


