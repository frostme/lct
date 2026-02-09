# lct install

Install bash script releases from GitHub or LCTFile

## Usage

```bash
lct install [MODULE]
```

## Examples

```bash
lct install DannyBen/approvals.bash
```

```bash
lct install
```

Running `lct install` without arguments from a directory containing an `LCTFile` installs each listed module (`owner/repo` or `owner/repo = 'v1.0.0'`) into `./lct_modules` with binaries in `./lct_modules/bin`.

## Arguments

#### *MODULE*

GitHub owner/repo of the module to install

