set export
alias b := build
alias v := validate
alias w := watch
alias bu := bump

@ensure_dir:
  [ -d target/build ] || mkdir -p target/build

build: ensure_dir
  @bashly g -u

validate:
  @bashly v

test: validate ensure_dir
  @bashly g -u -q
  @./scripts/test.sh

watch:
  @bashly g -w

install:
  @cp target/build/lct /usr/local/bin/lct

docs:
  @bashly r :markdown_github docs

pages:
  @bashly r templates pages
  @cp scripts/install.sh pages/install.sh

[arg('type', pattern='major|minor|patch')]
bump type:
  #!/usr/bin/env bash
  set -euo pipefail
  current_version=$(yq '.version' ./src/bashly.yml)
  new_version=$(semver bump ${type} $current_version)
  echo "Bumping ${current_version} -> ${new_version}"
  yq -i ".version=\"${new_version}\"" ./src/bashly.yml
