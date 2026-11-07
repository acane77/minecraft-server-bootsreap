#!/usr/bin/env bash
# WorldEdit 7.4 没有 Minecraft 26.2 / 26.3 的 Forge 构建。
set -euo pipefail

cat <<'EOF' >&2
WorldEdit 没有 Minecraft 26.2 或 26.3 的 Forge 版本。
官方 7.4.5（26.2）和 7.4.6（26.3）只发布 NeoForge 与 Fabric 构建。
把 NeoForge 的 worldedit-mod jar 放进 Forge 的 mods/ 会导致服务器无法加载这个模组。
请在 neoforge 目录执行 ./install_worldedit.sh。
EOF
exit 1
