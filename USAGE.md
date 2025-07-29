# Usage

## Description

This document describes how to install Lua, Net-SNMP and LuaSNMP "locally", that is, in custom paths which don't need root access. 

## Quick Start - TL;DR

"tl;dr" is an internet acronym that stands for "too long; didn't read". :-)

Quick install from scratch:

    mkdir -p $HOME/somedir
    cp scripts/* $HOME/somedir/
    cp examples/walk-v*.lua $HOME/somedir/
    cd $HOME/somedir
    ./setup.sh
    ./mylua walk-v2.lua 127.0.0.1 public system.sysDescr
    ./mylua walk-v3.lua 127.0.0.1 noAuthNoPriv SHA AES myuser myauthpassphrase myprivpassphrase system.sysDescr
    # 'get-v3.lua' does not need 'mylua', as the custom 'package.path' and 'package.cpath' directives are included in the script itself:
    ./get-v3.lua -v3 -l authPriv -u myuser-SHA-512-AES128 -a SHA-512 -A myauth-SHA-512 -x AES128 -X mypriv-AES128 172.17.0.10 system.sysDescr.0

See [scripts/README.md](scripts/README.md) for details.

## How to use 'configure'

The `setup.sh` script calls another script, `install-luasnmp.sh`, which in turn calls `configure`.  
Installation paths can be customized; the `help` option should be self-explanatory:

    ./configure -h

An example with uses custom paths for Lua, Net-SNMP, and for `luasnmp` itself:

- Lua: Installed in `$HOME/some/custom/path/bin/lua`
- Net-SNMP: Installed in `$HOME/some/other/custom/path/net-snmp/bin/net-snmp-config`
- LuaSNMP: To be installed in `$HOME/yet/another/custom/path/luasnmp`

Custom Lua (in our example, let's say that Lua is already in `PATH`):

    which lua
    $HOME/some/custom/path/bin/lua

Custom Net-SNMP (in our example, let's say that NetSNMP is *not* in `PATH`):

    which net-snmp-config
    (no output)

As Lua is in `PATH`, there is no need to add it to the `configure` options.  
The path to `net-snmp-config` has to be specified, though.  
`luasnmp` will be installed in the `--prefix` install path `$HOME/yet/another/custom/path/luasnmp`.  
All paths may be given as either relative or absolute paths, as they are converted to absolute paths by `configure`.

    ./configure \
        --with-net-snmp-config=$HOME/some/other/custom/path/net-snmp/bin/net-snmp-config \
        --prefix=$HOME/yet/another/custom/path/luasnmp
    make
    make install

The `LDFLAGS` variable in `configure` automatically adds the `-rpath` directive to the linker, so `snmp/core.so` may find `libnetsnmp.so` without setting `LD_LIBRARY_PATH`: 

    ldd $HOME/yet/another/custom/path/luasnmp/lib/lua/5.4.8/snmp/core.so 
        linux-vdso.so.1 (0x00007cc155a6d000)
        libnetsnmp.so.50 => $HOME/some/other/custom/path/net-snmp/lib/libnetsnmp.so.50 (0x00007cc155989000) <---- THANKS TO -rpath
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007cc15587a000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007cc155600000)
        libcrypto.so.3 => /lib/x86_64-linux-gnu/libcrypto.so.3 (0x00007cc155000000)
        /lib64/ld-linux-x86-64.so.2 (0x00007cc155a6f000)
        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007cc15585c000)
        libzstd.so.1 => /lib/x86_64-linux-gnu/libzstd.so.1 (0x00007cc154f42000)

### How to use 'configure' with Nmap

`luasnmp` may be used as an NSE library for `snmp-*` NSE scripts, as a replacement for the standard NSE `snmp` library.  
The advantage with using `luasnmp` over the standard NSE `snmp` is the SNMPv3 support.  
At the time of writing this (2025), the standard NSE `snmp` library lacks SNMPv3 support.

If Nmap was built from source, `luasnmp` may be built using the Nmap executable to extract the Lua version, and the source code for headers and libraries (in the same subdirectory `liblua/` by default).  
In this case, no "stand-alone" Lua interpreter is required to build LuaSNMP.

Example, with Nmap sources built in `/tmp/nmap-7.97/`, and installed as `/tmp/bin/nmap`:

    ./configure \
        --prefix=/usr \
        --use-nmap \
        --with-lua=/tmp/bin/nmap \
        --with-luaincdir=/tmp/nmap-7.97/liblua/ \
        --with-lualibdir=/tmp/nmap-7.97/liblua/
    make
    make install

If Nmap was built from a package instead, the Lua header files and lib will not be available, and have to be installed separately (by a Lua package or source code).  
In such a case, do *not* use the `--use-nmap` option.  
The separately installed Lua version must match the Lua version included with Nmap.

As with any Lua script, adjust `package.path` and `package.cpath` as needed in the calling NSE script to find the `luasnmp` module.

### A word of warning about changing the module name with 'configure'

The `configure` option `--libname=NAME` defaults to `luasnmp`.  
The original module name was `snmp`, but this may clash with the Nmap NSE lib with the same name.   
It is possible to change the module name to something else, but currently the name is hardcoded in `src/nm_snmp.c`, so for now, this file must be patched manually if the module name is changed.  
Check comments in `src/nm_snmp.c` for details.

## Handling custom paths with LuaSNMP

If `Net-SNMP` has been installed in a custom path (by setting `--prefix` to a non-standard path), `-rpath` is added to the linker as described above, so `luasnmp` has can find the `Net-SNMP` library.  
If `luasnmp` also has been installed in a custom path, the second step is to make Lua aware of that custom path.  
There are basically two ways to solve this:

1. Use the environment variable `LUA_CPATH`.
2. Use Lua's `package.cpath`.

We will use the second option here.  
Assume that `luasnmp` has been installed in `'$HOME/somedir/luasnmp`.  
A "Lua loader" module would then look like this:

    cat > set_paths.lua << __EOF__
    package.cpath = '$HOME/somedir/luasnmp/lib/lua/5.4.8/?.so;' .. package.cpath
    __EOF__

A basic `lua` wrapper, using the module:

    cat > mylua << __EOF__
    #!/usr/bin/env bash

    lua -l "set_paths" "\$@"
    __EOF__

    chmod 755 mylua

### Step 1 : Test the wrapper 

Without wrapper (should fail; error message):

    lua -e 'local snmp = require "snmp.core"'

With wrapper (should succeed; no output):

    ./mylua -e 'local snmp = require "snmp.core"'


### Step 2 : Run a SNMPv2 query

Use a device which is known to run a `snmpd` daemon with SNMPv2 enabled.  
How to setup such a device is out of this scope.  
Any Docker container with Net-SNMP installed should be fine:

- <https://hub.docker.com/search?q=net-snmp>

Assume that the device has the following credentials:

- IP: `172.17.0.2`
- Community: `mycommunity161`

Run the test script included in `luasnmp`, `examples/walk.lua`:

    ./mylua examples/walk.lua 172.17.0.2 mycommunity161 system.sysDescr

The output should be similar to:

    Open session to "172.17.0.2" with community "mycommunity161"
    SNMPv2-MIB::sysDescr.0 = STRING: Linux 6affb27d2a79 6.11.0-28-generic #28-Ubuntu SMP PREEMPT_DYNAMIC Mon May 19 14:45:34 UTC 2025 x86_64
    Closing session ...

### Step 3 : Run a SNMPv3 query

This is almost identical to the previous test.  
Assume that the SNMPv3-enabled device has the following credentials:

- IP                                 : `172.17.0.4`
- Security Level                     : `noAuthNoPriv`
- Authentication Protocol            : `SHA`
- Privacy Protocol                   : `AES`
- User                               : `myuser161`
- Authentication Protocol Passphrase : `foobarfoo`
- Privacy Protocol Passphrase        : `barfoobar`

The output should be similar to the output from `snmpwalk`:

    snmpwalk -v3 -l authPriv -u myuser161 -a SHA -A foobarfoo -x AES -X barfoobar 172.17.0.4 system.sysDescr
        SNMPv2-MIB::sysDescr.0 = STRING: Linux faa916c96ceb 6.11.0-28-generic #28-Ubuntu SMP PREEMPT_DYNAMIC Mon May 19 14:45:34 UTC 2025 x86_64

Run the SNMPv3-adapted test script and check the output:

    ./mylua examples/walk-v3.lua 172.17.0.4 noAuthNoPriv SHA AES myuser161 foobarfoo barfoobar system.sysDescr
        Open session to "172.17.0.4" with user|pass myuser161|foobarfoo
        SNMPv2-MIB::sysDescr.0 = STRING: Linux faa916c96ceb 6.11.0-28-generic #28-Ubuntu SMP PREEMPT_DYNAMIC Mon May 19 14:45:34 UTC 2025 x86_64
        Closing session ...

### Step 4 (optional): Run a SNMPv3 query using different authetication and privacy protocols

At the time of writing this, Net-SNMP *may* support the following authentication and privacy protocols (`snmpget --help` to check):

- Authentication protocols:  `MD5 | SHA | SHA-224 | SHA-256 | SHA-384 | SHA-512`
- Privacy protocols: `DES | AES | AES-192 | AES-256`

The authentication protocols `MD5` and `SHA` are always enabled.  
If Net-SNMP has been linked with a recent enough version of OpenSSL, `HAVE_EVP_SHA224` also enables `SHA-224 | SHA-256`, and `HAVE_EVP_SHA384` enables `SHA-384 | SHA-512`.

The privacy protocols `DES` and `AES` are always enabled.  
If Net-SNMP has been compiled with either the flag `NETSNMP_DRAFT_BLUMENTHAL_AES_04` or, in newer versions of Net-SNMP, the `configure` option `--enable-blumenthal-aes`, then `AES-192` and `AES-256` are also enabled.

The LuaSNMP Makefile should automatically detect if these protocols are enabled.

An example to check if the protocols are working as expected:

Let's assume that the device `172.17.0.4` is a device running `snmpd`.  
If not already configured, add two users, one using `SHA-384` and another using `SHA-512`: 

1. `net-snmp-config --create-snmpv3-user -ro -a SHA-384 -A pass384 -x AES -X privAES user1`
2. `net-snmp-config --create-snmpv3-user -ro -a SHA-512 -A pass512 -x AES -X privAES user2`

Test the two users:

    ./mylua examples/walk-v3.lua 172.17.0.4 authPriv SHA-384 AES user1 pass384 privAES system.sysDescr
        Open session to "172.17.0.4" with user|pass user1|pass384

    ./mylua examples/walk-v3.lua 172.17.0.4 authPriv SHA-512 AES user2 pass512 privAES system.sysDescr
        Open session to "172.17.0.4" with user|pass user2|pass512

As with the tests above, the output should be the same as using `snmpwalk`:

    SNMPv2-MIB::sysDescr.0 = STRING: Linux faa916c96ceb 6.11.0-28-generic #28-Ubuntu SMP PREEMPT_DYNAMIC Mon May 19 14:45:34 UTC 2025 x86_64
        Closing session ...
