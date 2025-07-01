#!/usr/bin/env bash

# Install Net-SNMP and luasnmp from GitHub source code.
# Sets required paths to both libraries

set -e

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "${SCRIPT_NAME}")

"$SCRIPT_PATH/install-net-snmp.sh"
source "$SCRIPT_PATH/source-net-snmp.sh"
"$SCRIPT_PATH/install-luasnmp.sh"
source "$SCRIPT_PATH/source-luasnmp.sh"
"$SCRIPT_PATH/set_paths.sh"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "%s\n" "Lua 'package.cpath' test:"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "%s\n" "Loading 'luasnmp' without setting custom path (should fail):"
printf "%s\n" "lua -e 'local snmp = require \"snmp.core\"'"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "%s\n" "Loading 'luasnmp' with custom path set (should succeed):"
printf "%s\n" "./mylua -e 'local snmp = require \"snmp.core\"'"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "%s\n" "LuaSNMP test programs:"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "%s\n" "./mylua walk-v2.lua 127.0.0.1 public system.sysDescr"
printf "%s\n" "./mylua walk-v3.lua 127.0.0.1 noAuthNoPriv SHA AES myuser myauthpassphrase myprivpassphrase system.sysDescr"
printf "%s\n" "--------------------------------------------------------------------------------"
