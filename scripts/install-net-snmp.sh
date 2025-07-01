#!/usr/bin/env bash

set -e

SCRIPT_NAME=$(readlink -f "$0")
SCRIPT_PATH=$(dirname "${SCRIPT_NAME}")

NET_SNMP_GIT_URL=https://github.com/net-snmp/net-snmp.git
NET_SNMP_GIT_LOCAL_ROOT_DIR="${SCRIPT_PATH}/git"
NET_SNMP_GIT_LOCAL_SRC_DIR="${NET_SNMP_GIT_LOCAL_ROOT_DIR}/net-snmp"
NET_SNMP_INSTALL_DIR="${SCRIPT_PATH}/net-snmp"
printf "\nNet-SNMP will be installed in:\n"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "NET_SNMP_INSTALL_DIR=%s\n" "$NET_SNMP_INSTALL_DIR"
printf "%s\n" "--------------------------------------------------------------------------------"

rm -rf "$NET_SNMP_GIT_LOCAL_SRC_DIR" && mkdir -p "$NET_SNMP_GIT_LOCAL_ROOT_DIR" && cd "$NET_SNMP_GIT_LOCAL_ROOT_DIR" && git clone --depth 1 $NET_SNMP_GIT_URL && cd -
cd "$NET_SNMP_GIT_LOCAL_SRC_DIR" && \
    ./configure \
    --with-openssl \
    --enable-shared \
    --enable-mini-agent \
    --enable-ipv6 \
    --without-rpm \
    --enable-blumenthal-aes \
    --disable-embedded-perl \
    --without-perl-modules \
    --without-python-modules \
    --with-default-snmp-version="3" \
    --with-security-modules="usm" \
    --with-sys-location="Unknown location" \
    --with-gnu-ld \
    --prefix="$NET_SNMP_INSTALL_DIR" \
    --with-sys-contact="I am your contact" \
    --with-logfile=/var/log/snmpd.log \
    --with-persistent-directory=/var/net-snmp && \
    make clean && \
    make && \
    make install

printf "\nTo use the locally installed Net-SNMP:\n"
printf "%s\n" "--------------------------------------------------------------------------------"
printf "sudo ldconfig\n"
printf "source %s\n" "$SCRIPT_PATH/source-net-snmp.sh"
printf "%s\n" "--------------------------------------------------------------------------------"
