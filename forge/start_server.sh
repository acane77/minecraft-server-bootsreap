#!/usr/bin/env bash
# 启动 Minecraft Forge 26.3（推荐版 66.1.0）。
# 适用于 Ubuntu 20.04 及更新版本。需要 Linux 上的 Java 25 或更高版本。
set -euo pipefail

ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$ROOT"

FORGE_VERSION="26.3-66.1.0"
ARGS_FILE="libraries/net/minecraftforge/forge/${FORGE_VERSION}/unix_args.txt"

if [[ ! -f "$ARGS_FILE" ]]; then
  echo "服务器文件还没有下载。请先在本目录执行 make。" >&2
  exit 1
fi

print_java_help() {
  cat <<'EOF'
未找到可用的 Java 25 或更高版本。
Minecraft Forge 26.3 必须用 Linux 版 Java 25+。Windows 里的 java.exe 不能启动这个服务。

Ubuntu 20.04 官方源没有 Java 25。在 Ubuntu 20.04 上安装 Eclipse Temurin 25：

  sudo apt-get update
  sudo apt-get install -y wget ca-certificates gnupg
  sudo mkdir -p /etc/apt/keyrings
  wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor | sudo tee /etc/apt/keyrings/adoptium.gpg >/dev/null
  echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb focal main" | sudo tee /etc/apt/sources.list.d/adoptium.list
  sudo apt-get update
  sudo apt-get install -y temurin-25-jdk
  java -version

如果 java -version 仍显示 11，执行 sudo update-alternatives --config java 并选 25。
本脚本也会直接查找 /usr/lib/jvm/temurin-25-jdk-*，因此默认 java 仍是 11 时也可以启动。

Ubuntu 22.04 及更新版本也可以改用系统源（26.04 已确认有该包）：

  sudo apt-get update
  sudo apt-get install -y openjdk-25-jdk

不想用 apt 仓库时，可下载 Temurin 25 的 Linux x64 JDK 压缩包（不要下 Windows 版，也不要下 Alpine 版）：
  https://adoptium.net/temurin/releases/?os=linux&arch=x64&package=jdk&version=25
  或直接：
  https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse?project=jdk
当前最新为 25.0.5+8，文件 OpenJDK25U-jdk_x64_linux_hotspot_25.0.5_8.tar.gz
SHA256: 68982529869257d0ee6b824ec5aa270ff8b118bb438670da0b97ebdab178d7fb

  cd /tmp
  curl -fL -o temurin25.tar.gz "https://api.adoptium.net/v3/binary/latest/25/ga/linux/x64/jdk/hotspot/normal/eclipse?project=jdk"
  sudo mkdir -p /usr/lib/jvm
  sudo tar -xzf temurin25.tar.gz -C /usr/lib/jvm
  jdk_dir=$(echo /usr/lib/jvm/jdk-25*)
  sudo update-alternatives --install /usr/bin/java java "$jdk_dir/bin/java" 2500
  java -version

也可以把 java 的绝对路径赋给环境变量 JAVA 后再启动。
EOF
}

resolve_bin() {
  local bin="$1"
  if [[ "$bin" == */* ]]; then
    printf '%s\n' "$bin"
  else
    command -v "$bin" 2>/dev/null || true
  fi
}

java_major() {
  local bin="$1" line major
  line="$("$bin" -version 2>&1 | head -n 1 || true)"
  major="$(printf '%s\n' "$line" | sed -n 's/.* version "\([0-9][0-9]*\).*/\1/p')"
  [[ -n "$major" ]] || return 1
  printf '%s\n' "$major"
}

consider_java() {
  local raw="$1" bin major
  bin="$(resolve_bin "$raw")"
  [[ -n "$bin" && -f "$bin" && -x "$bin" ]] || return 0
  [[ "$bin" != *.exe ]] || return 0
  if command -v file >/dev/null 2>&1; then
    if file -b "$bin" 2>/dev/null | grep -q 'PE32'; then
      return 0
    fi
  fi
  major="$(java_major "$bin" || true)"
  [[ -n "$major" && "$major" -ge 25 ]] || return 0
  if [[ -z "$BEST_BIN" || "$major" -lt "$BEST_MAJOR" ]]; then
    BEST_BIN="$bin"
    BEST_MAJOR="$major"
  fi
}

find_java() {
  local pattern candidate
  BEST_BIN=""
  BEST_MAJOR=999

  if [[ -n "${JAVA_HOME:-}" ]]; then
    consider_java "${JAVA_HOME}/bin/java"
  fi

  shopt -s nullglob
  for pattern in \
    /usr/lib/jvm/temurin-25-jdk-*/bin/java \
    /usr/lib/jvm/java-25-openjdk-*/bin/java \
    /usr/lib/jvm/jdk-25*/bin/java \
    /opt/jdk-25*/bin/java \
    /opt/temurin-25*/bin/java \
    /usr/lib/jvm/java-2[6-9]-openjdk-*/bin/java \
    /usr/lib/jvm/java-[3-9][0-9]-openjdk-*/bin/java \
    /usr/lib/jvm/temurin-2[6-9]-jdk-*/bin/java \
    /usr/lib/jvm/temurin-[3-9][0-9]-jdk-*/bin/java
  do
    for candidate in $pattern; do
      consider_java "$candidate"
    done
  done
  shopt -u nullglob

  if command -v update-alternatives >/dev/null 2>&1; then
    while IFS= read -r candidate; do
      [[ -n "$candidate" ]] || continue
      consider_java "$candidate"
    done < <(update-alternatives --list java 2>/dev/null || true)
  fi

  if command -v java >/dev/null 2>&1; then
    consider_java "$(command -v java)"
  fi

  [[ -n "$BEST_BIN" ]]
}

if [[ -n "${JAVA:-}" ]]; then
  BEST_BIN=""
  BEST_MAJOR=999
  consider_java "$JAVA"
  if [[ -z "$BEST_BIN" ]]; then
    echo "环境变量 JAVA 不是 Linux 上的 Java 25 或更高版本: $JAVA" >&2
    print_java_help >&2
    exit 1
  fi
  JAVA_BIN="$BEST_BIN"
else
  if ! find_java; then
    print_java_help >&2
    exit 1
  fi
  JAVA_BIN="$BEST_BIN"
fi

echo "使用 Java ${BEST_MAJOR}: ${JAVA_BIN}" >&2

# curl 会使用 http_proxy/https_proxy，Java 默认忽略这两个变量。
PROXY_ARGS=()
PROXY_URL="${https_proxy:-${HTTPS_PROXY:-${http_proxy:-${HTTP_PROXY:-}}}}"
if [[ -n "$PROXY_URL" ]]; then
  proxy_authority="${PROXY_URL#*://}"
  proxy_authority="${proxy_authority%%/*}"
  proxy_authority="${proxy_authority##*@}"
  proxy_host="${proxy_authority%%:*}"
  if [[ "$proxy_authority" == *:* ]]; then
    proxy_port="${proxy_authority##*:}"
  else
    proxy_port="80"
  fi
  if [[ -z "$proxy_host" || ! "$proxy_port" =~ ^[0-9]+$ ]]; then
    echo "无法解析代理地址: ${PROXY_URL}" >&2
    exit 1
  fi
  PROXY_ARGS=(
    "-Dhttp.proxyHost=${proxy_host}"
    "-Dhttp.proxyPort=${proxy_port}"
    "-Dhttps.proxyHost=${proxy_host}"
    "-Dhttps.proxyPort=${proxy_port}"
  )
  echo "Java 使用 HTTP 代理 ${proxy_host}:${proxy_port}" >&2
fi

if [[ ! -f eula.txt ]] || ! grep -q '^eula=true' eula.txt; then
  echo "eula.txt 里没有 eula=true。同意 Minecraft EULA 后才能启动: https://aka.ms/MinecraftEULA" >&2
  exit 1
fi

mkdir -p mods
exec "$JAVA_BIN" "${PROXY_ARGS[@]}" @user_jvm_args.txt @"$ARGS_FILE" nogui "$@"
