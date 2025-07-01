#!/usr/bin/env bash

printf "package.path = '%s%s\n" "$(dirname "$(readlink -f "$(find luasnmp/ -name snmp.lua)")")" "/?.lua;' .. package.path" > set_paths.lua
printf "package.cpath = '%s%s\n" "$(dirname "$(dirname "$(readlink -f "$(find luasnmp/ -name core.so)")")")" "/?.so;' .. package.cpath" >> set_paths.lua
