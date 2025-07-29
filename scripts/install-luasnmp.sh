#!/usr/bin/env bash

set -e

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "${SCRIPT_NAME}")

LUASNMP_GIT_URL=https://github.com/kuuse/luasnmp.git
LUASNMP_GIT_LOCAL_ROOT_DIR="${SCRIPT_PATH}/git"
LUASNMP_GIT_LOCAL_SRC_DIR="${LUASNMP_GIT_LOCAL_ROOT_DIR}/luasnmp"
LUASNMP_INSTALL_DIR="${SCRIPT_PATH}/luasnmp"

NET_SNMP_PATH="${SCRIPT_PATH}/net-snmp"

if [ ! -d "$NET_SNMP_PATH" ];then
    printf "ERROR: Missing directory '%s'. This LuaSNMP install script depends on local Net-SNMP installation, which doesn't exist.\n" "$NET_SNMP_PATH"
    printf "Run '%s' and try again.\n" "${SCRIPT_PATH}/install-net-snmp.sh"
fi

printf "\nLuaSNMP will be installed in:\n"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "LUASNMP_INSTALL_DIR=%s\n" "$LUASNMP_INSTALL_DIR"
printf "%s\n" "--------------------------------------------------------------------------------"

rm -rf "$LUASNMP_GIT_LOCAL_SRC_DIR" && mkdir -p "$LUASNMP_GIT_LOCAL_ROOT_DIR" && cd "$LUASNMP_GIT_LOCAL_ROOT_DIR" && git clone --depth 1 $LUASNMP_GIT_URL && cd -
cd "$LUASNMP_GIT_LOCAL_SRC_DIR" && \
    ./configure \
    --with-net-snmp-config=../../net-snmp/bin/net-snmp-config \
    --prefix="$LUASNMP_INSTALL_DIR" && \
    make clean && \
    make LV=5.4 && \
    make LV=5.4 install
printf "\nTo use the locally installed LuaSNMP:\n"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "source %s\n" "$SCRIPT_PATH/source-luasnmp.sh"
printf "%s\n" "--------------------------------------------------------------------------------"
