set export
alias b := build
alias bu := bump
alias d := docs
alias i := install
alias p := pages
alias t := test
alias v := validate
alias w := watch

@ensure_dir:
  [ -d target/build ] || mkdir -p target/build

build: ensure_dir
  @gum spin --title "Building lct..." -- bashly g -u

validate:
  @bashly v

test: validate ensure_dir
  @bashly g -u -q
  @./test/approve

watch:
  @bashly g -w

install: build
  target/build/lct install

setup: build
  target/build/lct install -g fsaintjacques/semver-tool

dev:
  @gum spin --title "Installing lct..." -- bashly g -u
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
  new_version=$(./lct_modules/fsaintjacques-semver-tool/src/semver bump ${type} $current_version)
  echo "Bumping ${current_version} -> ${new_version}"
  yq -i ".version=\"${new_version}\"" ./src/bashly.yml
