# make：下载并准备服务器。默认 26.3，也可 make VERSION=26.2。make clean：删除下载结果。
SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := all

VERSION ?= 26.3
NEOFORGE_26.2 := 26.2.0.93
NEOFORGE_26.3 := 26.3.0.101
SHA1_26.2 := 97205829a020fc9389f504a77f590b54157c8dde
SHA1_26.3 := fdc7740d48063e9ea511d606d8bdb229e745c62d
NEOFORGE_VERSION := $(NEOFORGE_$(VERSION))
INSTALLER_SHA1 := $(SHA1_$(VERSION))
INSTALLER := neoforge-$(NEOFORGE_VERSION)-installer.jar
INSTALLER_URL := https://maven.neoforged.net/releases/net/neoforged/neoforge/$(NEOFORGE_VERSION)/$(INSTALLER)
ARGS_FILE := libraries/net/neoforged/neoforge/$(NEOFORGE_VERSION)/unix_args.txt

.PHONY: all clean

all: $(ARGS_FILE)

$(INSTALLER):
	curl -fL --retry 3 --retry-delay 2 -o "$@.partial" "$(INSTALLER_URL)"
	echo "$(INSTALLER_SHA1)  $@.partial" | sha1sum -c -
	mv "$@.partial" "$@"

$(ARGS_FILE): $(INSTALLER)
	echo "$(INSTALLER_SHA1)  $(INSTALLER)" | sha1sum -c -
	best=""
	best_major=999
	consider() {
	  local bin="$$1" line major
	  [[ -n "$$bin" && -f "$$bin" && -x "$$bin" && "$$bin" != *.exe ]] || return 0
	  if command -v file >/dev/null 2>&1 && file -b "$$bin" 2>/dev/null | grep -q PE32; then
	    return 0
	  fi
	  line="$$("$$bin" -version 2>&1 | head -n 1 || true)"
	  major="$$(printf '%s\n' "$$line" | sed -n 's/.* version "\([0-9][0-9]*\).*/\1/p')"
	  [[ -n "$$major" && "$$major" -ge 25 ]] || return 0
	  if [[ -z "$$best" || "$$major" -lt "$$best_major" ]]; then
	    best="$$bin"
	    best_major="$$major"
	  fi
	}
	if [[ -n "$${JAVA:-}" ]]; then
	  if [[ "$${JAVA}" == */* ]]; then
	    consider "$${JAVA}"
	  else
	    consider "$$(command -v "$${JAVA}" || true)"
	  fi
	  if [[ -z "$$best" ]]; then
	    echo "环境变量 JAVA 不是 Linux 上的 Java 25 或更高版本: $${JAVA}" >&2
	    exit 1
	  fi
	else
	  if [[ -n "$${JAVA_HOME:-}" ]]; then
	    consider "$${JAVA_HOME}/bin/java"
	  fi
	  shopt -s nullglob
	  for candidate in \
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
	    consider "$$candidate"
	  done
	  shopt -u nullglob
	  if command -v update-alternatives >/dev/null 2>&1; then
	    while IFS= read -r candidate; do
	      [[ -n "$$candidate" ]] || continue
	      consider "$$candidate"
	    done < <(update-alternatives --list java 2>/dev/null || true)
	  fi
	  if command -v java >/dev/null 2>&1; then
	    consider "$$(command -v java)"
	  fi
	fi
	if [[ -z "$$best" ]]; then
	  echo "未找到 Java 25 或更高版本，无法下载并准备服务器。" >&2
	  echo "Ubuntu 20.04 可安装 Eclipse Temurin 25；Ubuntu 24.04 及更新版本可执行: sudo apt-get install openjdk-25-jdk" >&2
	  exit 1
	fi
	echo "使用 Java $${best_major}: $${best}"
	proxy_url="$${https_proxy:-$${HTTPS_PROXY:-$${http_proxy:-$${HTTP_PROXY:-}}}}"
	proxy_args=()
	if [[ -n "$$proxy_url" ]]; then
	  proxy_authority="$${proxy_url#*://}"
	  proxy_authority="$${proxy_authority%%/*}"
	  proxy_authority="$${proxy_authority##*@}"
	  proxy_host="$${proxy_authority%%:*}"
	  if [[ "$$proxy_authority" == *:* ]]; then
	    proxy_port="$${proxy_authority##*:}"
	  else
	    proxy_port=80
	  fi
	  if [[ -z "$$proxy_host" || ! "$$proxy_port" =~ ^[0-9]+$$ ]]; then
	    echo "无法解析代理地址: $$proxy_url" >&2
	    exit 1
	  fi
	  proxy_args=(
	    "-Dhttp.proxyHost=$$proxy_host"
	    "-Dhttp.proxyPort=$$proxy_port"
	    "-Dhttps.proxyHost=$$proxy_host"
	    "-Dhttps.proxyPort=$$proxy_port"
	  )
	  echo "通过 HTTP 代理 $${proxy_host}:$${proxy_port} 下载"
	fi
	"$$best" "$${proxy_args[@]}" -jar "$(INSTALLER)" --installServer
	test -f "$(ARGS_FILE)"

clean:
	rm -rf libraries
	rm -f neoforge-26.2.0.93-installer.jar neoforge-26.2.0.93-installer.jar.log neoforge-26.2.0.93-installer.jar.partial
	rm -f neoforge-26.3.0.101-installer.jar neoforge-26.3.0.101-installer.jar.log neoforge-26.3.0.101-installer.jar.partial
	rm -f run.sh run.bat README.txt
