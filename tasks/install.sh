#!/usr/bin/env bash
mkdir -p target/build
mkdir -p target/release
latest_version=$(yq '.version' ./src/bashly.yml)
package_url="https://github.com/frostme/lct"

curl -L "${package_url}/releases/download/v${latest_version}/lct-v${latest_version}.tar.xz" >"target/release/lct-v${latest_version}.tar.xz"
tar -xJf "target/release/lct-v${latest_version}.tar.xz" -C "target/build"
cp target/build/lct /usr/local/bin/lct
#
