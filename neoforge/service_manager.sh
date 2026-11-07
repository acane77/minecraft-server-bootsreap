#!/usr/bin/env bash
# 安装或卸载 Minecraft NeoForge 服务器的 systemd 服务。
# 适用于 Ubuntu 20.04 及更新版本（需要 systemd）。
# 用法: ./service_manager.sh install
#       ./service_manager.sh uninstall
set -euo pipefail

SERVICE_NAME="minecraft-neoforge"
ROOT="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

usage() {
  echo "用法: $0 install|uninstall" >&2
  exit 1
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    exec sudo --preserve-env=http_proxy,https_proxy,HTTP_PROXY,HTTPS_PROXY -- "$0" "$@"
  fi
}

require_systemd() {
  if ! command -v systemctl >/dev/null 2>&1 || [[ ! -d /run/systemd/system ]]; then
    cat <<'EOF' >&2
当前系统没有在运行 systemd，无法安装服务。
Ubuntu 20.04 服务器一般已经启用 systemd。若这是 WSL，请在 /etc/wsl.conf 写入：

[boot]
systemd=true

然后在 Windows 里执行 wsl --shutdown，再重新打开发行版。
EOF
    exit 1
  fi
}

write_unit() {
  local owner="$1" group="$2" root_escaped proxy_env="" name value
  root_escaped="${ROOT//%/%%}"
  for name in http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; do
    value="${!name:-}"
    if [[ -n "$value" ]]; then
      proxy_env+="Environment=\"${name}=${value}\""$'\n'
    fi
  done
  cat >"$UNIT_PATH" <<EOF
[Unit]
Description=Minecraft NeoForge 26.3 Server
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=${owner}
Group=${group}
WorkingDirectory="${root_escaped}"
ExecStart="${root_escaped}/start_server.sh"
Restart=on-failure
RestartSec=15
SuccessExitStatus=143 130
TimeoutStopSec=90
KillSignal=SIGTERM
LimitNOFILE=65536
Environment=LANG=C.UTF-8
${proxy_env}
[Install]
WantedBy=multi-user.target
EOF
}

install_service() {
  local owner group
  require_systemd
  if [[ ! -x "${ROOT}/start_server.sh" ]]; then
    echo "找不到可执行的 ${ROOT}/start_server.sh" >&2
    exit 1
  fi

  owner="$(stat -c '%U' "$ROOT")"
  group="$(stat -c '%G' "$ROOT")"
  if [[ "$owner" == "root" ]]; then
    cat <<EOF >&2
服务器目录属于 root。服务不能以 root 运行。
请先交给普通用户，例如：
  sudo chown -R minecraft:minecraft ${ROOT}
然后重新执行 ./service_manager.sh install
EOF
    exit 1
  fi

  write_unit "$owner" "$group"
  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}.service"
  cat <<EOF
已安装 systemd 服务 ${SERVICE_NAME}，并设置为开机自启。
服务用户: ${owner}:${group}
工作目录: ${ROOT}

启动: sudo systemctl start ${SERVICE_NAME}
停止: sudo systemctl stop ${SERVICE_NAME}
状态: systemctl status ${SERVICE_NAME}
日志: journalctl -u ${SERVICE_NAME} -f

若服务已在运行，执行 sudo systemctl restart ${SERVICE_NAME} 后新配置才会生效。
启动前请先执行 make 准备服务器，并装好 Java 25。游戏端口是 TCP 25566。
EOF
}

uninstall_service() {
  require_systemd
  systemctl disable --now "${SERVICE_NAME}.service" || true
  rm -f "$UNIT_PATH"
  systemctl daemon-reload
  systemctl reset-failed "${SERVICE_NAME}.service" || true
  echo "已停止并卸载 ${SERVICE_NAME}。服务器文件仍保留在 ${ROOT}。"
}

if [[ $# -ne 1 ]]; then
  usage
fi

case "$1" in
  install)
    require_root "$@"
    install_service
    ;;
  uninstall)
    require_root "$@"
    uninstall_service
    ;;
  *)
    usage
    ;;
esac
