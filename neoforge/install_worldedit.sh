#!/usr/bin/env bash
# 把官方 WorldEdit 模组下载到 mods/。
# 已准备 26.2 且没有 26.3 时安装 7.4.5，否则安装 26.3 对应的 7.4.6。
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$ROOT"
mkdir -p mods

if [[ -f libraries/net/neoforged/neoforge/26.2.0.93/unix_args.txt && ! -f libraries/net/neoforged/neoforge/26.3.0.101/unix_args.txt ]]; then
  MC_VERSION="26.2"
  WE_VERSION="7.4.5"
  FILE="worldedit-mod-7.4.5.jar"
  URL="https://cdn.modrinth.com/data/1u6JkXh5/versions/6YnCYPwc/worldedit-mod-7.4.5.jar"
  SHA1="7d909b53f5fb76756bca1db08113151304cc173a"
else
  MC_VERSION="26.3"
  WE_VERSION="7.4.6"
  FILE="worldedit-mod-7.4.6.jar"
  URL="https://cdn.modrinth.com/data/1u6JkXh5/versions/ByRNkO83/worldedit-mod-7.4.6.jar"
  SHA1="8f7962199ec8b3fef214b7f81c07fcf2d1eac28f"
fi

dest="mods/${FILE}"
trap 'rm -f "${dest}.partial"' EXIT
curl -fL --retry 3 --retry-delay 2 -o "${dest}.partial" "$URL"
echo "${SHA1}  ${dest}.partial" | sha1sum -c -
mv "${dest}.partial" "$dest"
trap - EXIT

shopt -s nullglob
for old in mods/worldedit-mod-*.jar; do
  [[ "$old" == "$dest" ]] && continue
  rm -f "$old"
done
shopt -u nullglob

echo "已安装 WorldEdit ${WE_VERSION}（Minecraft ${MC_VERSION} / NeoForge）: ${dest}"
echo "重启服务器后生效。"
