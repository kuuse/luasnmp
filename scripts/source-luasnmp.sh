#!/usr/bin/env bash

# Fixed paths and files
SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "${SCRIPT_NAME}")

LUASNMP_INSTALL_DIR="${SCRIPT_PATH}/luasnmp"
LUASNMP_BIN_DIR="${LUASNMP_INSTALL_DIR}/bin"
LUASNMP_INCLUDE_DIR="${LUASNMP_INSTALL_DIR}/include"
LUASNMP_LIB_DIR="${LUASNMP_INSTALL_DIR}/lib"

NET_SNMP_INSTALL_DIR="${SCRIPT_PATH}/net-snmp"

if [ ! -d "$LUASNMP_INSTALL_DIR" ];then
    printf "ERROR: Local LuaSNMP directory '%s' doesn't exist.\n" "$LUASNMP_INSTALL_DIR"
    printf "Run '%s' and try again.\n" "${SCRIPT_PATH}/install-luasnmp.sh"
elif [ ! -d "$NET_SNMP_INSTALL_DIR" ];then
    printf "ERROR: Local Net-SNMP directory '%s' doesn't exist.\n" "$NET_SNMP_INSTALL_DIR"
    printf "Run '%s' and try again.\n" "${SCRIPT_PATH}/install-net-snmp.sh"
else
    LUASNMP_INSTALLED_VERSION=$(grep ^VERSION "${SCRIPT_PATH}/git/luasnmp/config" | cut -d= -f2)
    printf "%s\n" "--------------------------------------------------------------------------------"
    printf "LuaSNMP version     : %s\n" "$LUASNMP_INSTALLED_VERSION"
    printf "LuaSNMP bin dir     : %s\n" "$LUASNMP_BIN_DIR"
    printf "LuaSNMP include dir : %s\n" "$LUASNMP_INCLUDE_DIR"
    printf "LuaSNMP lib dir     : %s\n" "$LUASNMP_LIB_DIR"
    printf "%s\n" "--------------------------------------------------------------------------------"
    printf "%s\n" "Post-configure check:"
    printf "%s\n" "Check that 'ldd snmp/core.so' from LuaSNMP is linked correctly to the Net-SNMP library:"
    printf "%s\n" "$(find "$LUASNMP_INSTALL_DIR" -name core.so -print0 | xargs -0 ldd | grep libnetsnmp)"
    printf "%s\n" "--------------------------------------------------------------------------------"
fi
