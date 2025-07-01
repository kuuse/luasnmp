#!/usr/bin/env bash

# Fixed paths and files
SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "${SCRIPT_NAME}")


NET_SNMP_INSTALL_DIR="${SCRIPT_PATH}/net-snmp"
NET_SNMP_BIN_DIR="${NET_SNMP_INSTALL_DIR}/bin"
NET_SNMP_INCLUDE_DIR="${NET_SNMP_INSTALL_DIR}/include"
NET_SNMP_LIB_DIR="${NET_SNMP_INSTALL_DIR}/lib"
NET_SNMP_CONFIG="${NET_SNMP_INSTALL_DIR}/bin/net-snmp-config"
if [ ! -d "$NET_SNMP_INSTALL_DIR" ];then
    printf "ERROR: Local Net-SNMP directory '%s' doesn't exist.\n" "$NET_SNMP_INSTALL_DIR"
    printf "Run '%s' and try again.\n" "${SCRIPT_PATH}/install-net-snmp.sh"
elif [ ! -f "$NET_SNMP_CONFIG" ];then
    printf "ERROR: Could not find '%s' in local Net-SNMP directory '%s'.\n" "net-snmp-config" "$NET_SNMP_INSTALL_DIR"
    printf "Run '%s' and try again.\n" "${SCRIPT_PATH}/install-net-snmp.sh"
else
    # Check that all paths are as expected, evaluating using different commands.
    NET_SNMP_INSTALL_DIR_EVAL=$("$NET_SNMP_CONFIG" --prefix)
    NET_SNMP_BIN_DIR_EVAL="$(dirname "$(which "$NET_SNMP_BIN_DIR/snmpget")")"
    NET_SNMP_INCLUDE_DIR_EVAL=$(dirname $(dirname "$(find "$NET_SNMP_INSTALL_DIR" -name net-snmp-config.h)"))
    NET_SNMP_LIB_DIR_EVAL="$("$NET_SNMP_CONFIG" --libdir | sed 's/-L//')"
    ERROR=0
    if [ "$NET_SNMP_INSTALL_DIR" != "$NET_SNMP_INSTALL_DIR_EVAL" ];then
        ERROR=1
    fi
    if [ "$NET_SNMP_BIN_DIR" != "$NET_SNMP_BIN_DIR_EVAL" ];then
        ERROR=1
    fi
    if [ "$NET_SNMP_INCLUDE_DIR" != "$NET_SNMP_INCLUDE_DIR_EVAL" ];then
        ERROR=1
    fi
    if [ "$NET_SNMP_LIB_DIR" != "$NET_SNMP_LIB_DIR_EVAL" ];then
        ERROR=1
    fi
    if [ $ERROR -ne 0 ];then
        ERROR=1
        printf "ERROR: One or more path are not as expected:\n"
        printf "%s\n" "--------------------------------------------------------------------------------"
        printf "Net-SNMP path        : %s \tExpected: %s \n" "$NET_SNMP_INSTALL_DIR" "$NET_SNMP_INSTALL_DIR_EVAL"
        printf "Net-SNMP bin dir     : %s \tExpected: %s \n" "$NET_SNMP_BIN_DIR" "$NET_SNMP_BIN_DIR_EVAL"
        printf "Net-SNMP include dir : %s \tExpected: %s \n" "$NET_SNMP_INCLUDE_DIR" "$NET_SNMP_INCLUDE_DIR_EVAL"
        printf "Net-SNMP lib dir     : %s \tExpected: %s \n" "$NET_SNMP_LIB_DIR" "$NET_SNMP_LIB_DIR_EVAL"
        printf "%s\n" "--------------------------------------------------------------------------------"
        printf "Run '%s' and try again.\n" "${SCRIPT_PATH}/install-net-snmp.sh"

    else

        export PATH="$NET_SNMP_BIN_DIR":"$PATH"
        NET_SNMP_VERSION=$(net-snmp-config --version)
        printf "%s\n" "--------------------------------------------------------------------------------"
        printf "Net-SNMP version     : %s\n" "$NET_SNMP_VERSION"
        printf "Net-SNMP bin dir     : %s\n" "$NET_SNMP_BIN_DIR"
        printf "Net-SNMP include dir : %s\n" "$NET_SNMP_INCLUDE_DIR"
        printf "Net-SNMP lib dir     : %s\n" "$NET_SNMP_LIB_DIR"
        printf "%s\n" "--------------------------------------------------------------------------------"
        printf "Next step - install LuaSNMP:\n"
        printf "%s\n" "--------------------------------------------------------------------------------"
        printf "To install LuaSNMP from source (recommended):\n"
        printf "./install-luasnmp.sh\n"
        printf "%s\n" "--------------------------------------------------------------------------------"
        printf "To install LuaSNMP via LuaRocks, using NETSNMP_DIR:\n"
        printf "./myluarocks install luasnmp LV=5.4 NETSNMP_DIR=%s\n" "$NET_SNMP_INSTALL_DIR"
        printf "%s\n" "--------------------------------------------------------------------------------"

    fi
fi
