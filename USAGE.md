# How to use 'configure'

The `help` option should be self-explanatory:

    ./configure -h

An example with uses custom paths for Lua, Net-SNMP, and also a custom install path for `luasnmp` itself:

Custom Lua (in `PATH`):

    which lua
    /home/johan/fossil/nest/lua/lua/bin/lua


Custom Net-SNMP (not in `PATH`):

    which net-snmp-config
    (no output)

As Lua is in `PATH`, there is no need to add it to the `configure` options.  
The path to `net-snmp-config` has to be specified.  
The `--prefix` install path `../kk` is the root path for the install `luasnmp` tree.  
As this path is writeable by the current user, no root access is required for `make install`.  
All relative paths are converted to absolute paths by `configure`.

    ./configure --with-net-snmp-config=../../../net-snmp/bin/net-snmp-config --prefix=../kk
    make
    make install

The `LDFLAGS` variable in `configure` automatically adds the `-rpath` directive to the linker, so `snmp/core.so` may find `libnetsnmp.so` without setting `LD_LIBRARY_PATH`: 

    ldd ../kk/lib/lua/5.4.8/snmp/core.so 
        linux-vdso.so.1 (0x00007cc155a6d000)
        libnetsnmp.so.50 => /home/johan/fossil/nest/lua/snmp/net-snmp/lib/libnetsnmp.so.50 (0x00007cc155989000) <---- THANKS TO -rpath
        libm.so.6 => /lib/x86_64-linux-gnu/libm.so.6 (0x00007cc15587a000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007cc155600000)
        libcrypto.so.3 => /lib/x86_64-linux-gnu/libcrypto.so.3 (0x00007cc155000000)
        /lib64/ld-linux-x86-64.so.2 (0x00007cc155a6f000)
        libz.so.1 => /lib/x86_64-linux-gnu/libz.so.1 (0x00007cc15585c000)
        libzstd.so.1 => /lib/x86_64-linux-gnu/libzstd.so.1 (0x00007cc154f42000)
