set export
alias b := build
alias v := validate
alias w := watch
alias bu := bump


build:
  [[ -d target/build ]] || mkdir -p target/build
  @bashly g -u

validate:
  @bashly v

test:
  @bashly v
  @[[ -d target/build ]] || mkdir -p target/build
  @bashly g -u -q
  @./tasks/test.sh

watch:
  @bashly g -w

install:
  cp target/build/lct /usr/local/bin/lct

docs:
  @bashly r :markdown_github docs

[arg('type', pattern='major|minor|patch')]
release type:
  @just bump {{type}}
  @just build
  @just validate
  @just docs
  @./tasks/release.sh

[arg('type', pattern='major|minor|patch')]
bump type:
  #!/usr/bin/env bash
  set -euo pipefail
  current_version=$(yq '.version' ./src/bashly.yml)
  new_version=$(semver -i "$type" $current_version)
  echo "Bumping ${current_version} -> ${new_version}"
  yq -i ".version=\"${new_version}\"" ./src/bashly.yml
