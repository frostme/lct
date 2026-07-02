# lct plugin

Develop and manage lct plugins

| Attributes       | &nbsp;
|------------------|-------------
| Alias:           | p

## Usage

```bash
lct plugin COMMAND
```

## Examples

```bash
lct plugin install
```

```bash
lct p i owner/plugin
```

```bash
lct plugin validate ./plugins/example
```

## Commands

- [init](lct%20plugin%20init.md) - Initiate plugin for the current directory
- [install](lct%20plugin%20install.md) - Install an lct plugin from the registry (cached and refreshed automatically)
- [remove](lct%20plugin%20remove.md) - Remove an installed lct plugin
- [list](lct%20plugin%20list.md) - List all installed lct plugins
- [load](lct%20plugin%20load.md) - Load insalled lct plugins
- [validate](lct%20plugin%20validate.md) - Validate that a local plugin can run repeatedly

## Plugin idempotency contract

A plugin is repeat-safe when its **main.sh** can run more than once against the
same machine state without failing or requiring manual cleanup. Plugin authors
should:

- create directories with **mkdir -p** or check valid existing state first;
- clone repositories only when the destination is absent, and verify an
  existing destination before reusing it;
- check whether tools are already installed before installing them; and
- preserve valid user files instead of deleting them to make a rerun succeed.

**lct plugin validate \<path\>** syntax-checks the local plugin's **main.sh**, then
runs it twice with the same temporary **HOME** and isolated LCT/XDG directories.
The environment includes **LCT_PLUGIN_VALIDATION=1** and
**LCT_PLUGIN_VALIDATION_RUN=1** or **2** so external operations can be replaced by
deterministic test doubles in CI.

The validator removes the temporary state when it finishes and never modifies
the plugin source directory. It is not an operating-system sandbox: plugin
commands can still use the network or absolute paths outside the temporary
**HOME**. Review untrusted plugins first and use an isolated CI runner or
container when host-level commands are possible.
