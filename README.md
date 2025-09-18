# LuaSNMP fork

## Description

The original repository [hleuwer/luasnmp](https://github.com/hleuwer/luasnmp) implements a module with Lua bindings to [Net-SNMP](https://www.net-snmp.org/).  
This repository is a fork of with additional features.  

The main purpose of this fork is to be able to use SNMPv3 queries in Nmap NSE scripts.

## Additional features

- A new `configure` script.  
  The original repository use a `config` file with hardcoded values to be used during installation.  
  The `configure` script is probably easier to use, as it auto-detects certain paths, and may override settings in `config` automatically.  
  (Using `configure` is still optional, if one prefers to edit `config` manually instead.)
- Support for authentication protocols `MD5`,`SHA-224|256|384|512` and privacy protocols `DES`,`AES-192|256`, if the installed version of [Net-SNMP](https://www.net-snmp.org/) supports the mentioned protocols.  
- Nmap NSE support:
   - The installed library has been renamed from `snmp` to `luasnmp` to not clash with the existing Nmap NSE library `snmp`.
   - Minor modifications to make `luasnmp` work in `strict mode` with Nmap NSE scripts.
- Parsing the `host:port` argument (a.k.a. "peername") accepts custom SNMP port numbers, and only the `host` part is validated as an IP/hostname.  
  (Without this fix, using a custom SNMP port caused the IP validation to fail.)
- The `timeout` argument may be a decimal value, to support low timeout values (fractions of a second).
- The `secLevel` argument is case-insensitive (accepts any of `Authpriv`, `AUTHPRIV` etc.), to be more aligned with Net-SNMP and other SNMP implementations.

## Install

See [USAGE.md](USAGE.md) for details.
