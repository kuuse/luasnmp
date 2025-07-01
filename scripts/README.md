# Quick install scripts

Copy all files in this directory to any empty directory, `cd` to that directory and run `./setup.sh`.

The `setup.sh` scripts calls `install-net-snmp.sh` and `install-luasnmp.sh`, which both clone the GitHub repositories from scratch.

Example:

    mkdir -p $HOME/somedir
    cp * $HOME/somedir/
    cd $HOME/somedir/
    ./setup.sh

The libraries are then installed here by default:

    $HOME/somedir/net-snmp
    $HOME/somedir/luasnmp

To change the installation directories, change `NET_SNMP_INSTALL_DIR` and/or `LUASNMP_INSTALL_DIR` in the scripts.

The `source-net-snmp.sh` script adds the `Net-SNMP` binaries path to `PATH`.  
This is needed whenever `net-snmp-config` is installed in a custom path, as it is used for linking the `luasnmp` C library `snmp/core.so`.  
The `source-luasnmp.sh` script basically checks that `luasnmp` has been installed and that `snmp/core.so` has been linked correctly to the `Net-SNMP` library.

For a "classic" `./configure && make && make install`, check the `configure` script in the parent directory.
