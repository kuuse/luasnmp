#!/usr/bin/env lua

-- To test against a Docker container running 'snmpd':
--
-- docker exec -it v3_MD5_DES snmpget -v3 -l authPriv -u myuser-MD5-DES -a MD5 -A myauth-MD5 -x DES -X mypriv-DES 172.17.0.3 system.sysDescr.0
-- SNMPv2-MIB::sysDescr.0 = STRING: Linux 61e5cecf05d2 6.11.0-29-generic #29-Ubuntu SMP PREEMPT_DYNAMIC Fri Jun 13 20:29:41 UTC 2025 x86_64

-- http://lua-users.org/lists/lua-l/2020-01/msg00345.html
-- --------------------------------------------------------------------------------
local fullpath = debug.getinfo(1,"S").source:sub(2)
-- The following two lines work with Lua 5.1
local handle = io.popen("realpath '"..fullpath.."'")
fullpath = handle:read("*a")
-- The following line fails with Lua 5.1
-- fullpath = io.popen("realpath '"..fullpath.."'", 'r'):read('a')
fullpath = fullpath:gsub('[\n\r]*$','')
local dirname, filename = fullpath:match('^(.*/)([^/]-)$')
dirname = dirname or ''
filename = filename or fullpath
-- --------------------------------------------------------------------------------
package.path = dirname .. 'luasnmp/share/lua/5.4/?.lua;' .. package.path
package.cpath = dirname .. 'luasnmp/lib/lua/5.4/?.so;' .. package.cpath

local pprint = require "pprint"

local snmp = require "luasnmp"

local function usage(prg)
  -- Usage
  -- Use the same syntax as Net-SNMP's 'snmpget'
  -- snmpget -v3 -l authPriv -u myuser-MD5-AES128 -a MD5 -A myauth-MD5 -x AES128 -X mypriv-AES128 172.17.0.4 system.sysDescr.0

  -- ./mylua walk-v3.lua 172.17.0.4 authPriv SHA AES myuser161 foobarfoo barfoobar system.sysDescr
  -- - IP                                 : `172.17.0.4`
  -- - Security Level                     : `authPriv`
  -- - Authentication Protocol            : `SHA`
  -- - Privacy Protocol                   : `AES`
  -- - User                               : `myuser161`
  -- - Authentication Protocol Passphrase : `foobarfoo`
  -- - Privacy Protocol Passphrase        : `barfoobar`
  print(string.format("Usage: (same syntax as Net-SNMP's 'snmpget'):"))
  print(string.format("SNMPv2  : %s %s -c %s %s %s", prg, "-v2c", "COMMUNITY", "HOST[:PORT]", "OID"))
  print(string.format("SNMPv3  : %s %s -l %s -u %s -a %s -A %s -x %s -X %s %s %s", prg, "-v3", "SEC_LEVEL", "USER", "AUTH_PROTO", "AUTH_PASS", "PRIV_PROTO",  "PRIV_PASS", "HOST[:PORT]", "OID"))
  print(string.format("Example : %s %s -c %s %s %s", prg, "-v2c", "community12", "172.17.0.2", "system.sysDescr.0"))
  print(string.format("Example : %s %s -l %s -u %s -a %s -A %s -x %s -X %s %s %s", prg, "-v3", "authPriv", "md5-user0910", "MD5", "myauth-MD5", "DES", "mypriv-DES", "172.17.0.10", "system.sysDescr.0"))
  print(string.format("Example : %s %s -l %s -u %s -a %s -A %s -x %s -X %s %s %s", prg, "-v3", "authPriv", "sha-512-user1516", "SHA-512", "myauth-SHA-512", "AES", "mypriv-AES", "172.17.0.17:16161", "system.sysDescr.0"))
  os.exit(1)
end

-- Split string
-- Used to split command-line HOST:PORT into a table of two variables.
-- (This function is generic, and can also split a string into multiple parts.)
function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from, true)
    while delim_from do
        if (delim_from ~= 1) then
            table.insert(result, string.sub(self, from, delim_from-1))
        end
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from, true)
    end
    if (from <= #self) then table.insert(result, string.sub(self, from)) end
    return result
end

local function snmpopen(host, port, cred)
  local hub1, err = nil,nil
  if cred.version == 'SNMPv2' then
    hub1, err = snmp.open{
    peer = host,
    port = port,
    version = snmp.SNMPv2,
    community = cred.community,
    }
  else
    hub1, err = snmp.open{
    peer = host,
    port = port,
    version = snmp.SNMPv3,
    user = cred.user,
    securityLevel = cred.securityLevel,
    authType = cred.authType,
    password = cred.password,
    privType = cred.privType,
    privPassphrase = cred.privPassphrase,
  }
  end
  return hub1, err
end

local function snmpget(host, port, cred, oid)

  -- pprint(cred)

  local hub1, err = snmpopen(host, port, cred)
  assert(hub1, err)

  -- vlist, err, index = snmp.get(hub1, {"sysName.0","sysContact.0"})
  local vlist, err, index = snmp.get(hub1, {oid})

  if not err then
    -- print(string.format("Contact for %s : %s",
    --                     vlist[1].value, vlist[2].value))
    print(string.format("%s", vlist[1].value))
  else
    if index then
      print(string.format("Error : %s in index %d", err, index))
    else
      print(string.format("Error : %s", err))
    end
  end

end

--------------------------------------------------------------------------------
-- MAIN
--------------------------------------------------------------------------------

-- Parse command-line args
local opt = {
  version        = '',
  community      = '',
  user           = '',
  securityLevel  = '',
  authType       = '',
  password       = '',
  privType       = '',
  privPassphrase = '',
  host           = '',
  port           = '161',
  oid            = '',
}
for k, v in ipairs(arg) do
  if (v == '-v3') then opt.version = 'SNMPv3'
  elseif (v == '-v2c') then opt.version = 'SNMPv2'
  elseif (v == '-v1') then opt.version = 'SNMPv1'
  elseif (v == '-c') and arg[k+1] ~= nil then opt.community = arg[k+1]
  elseif (v == '-l') and arg[k+1] ~= nil then opt.securityLevel = arg[k+1]
  elseif (v == '-u') and arg[k+1] ~= nil then opt.user = arg[k+1]
  elseif (v == '-a') and arg[k+1] ~= nil then opt.authType = arg[k+1]
  elseif (v == '-A') and arg[k+1] ~= nil then opt.password = arg[k+1]
  elseif (v == '-x') and arg[k+1] ~= nil then opt.privType = arg[k+1]
  elseif (v == '-X') and arg[k+1] ~= nil then opt.privPassphrase = arg[k+1]
  elseif (k == #arg - 1) then opt.host = v
  elseif (k == #arg) then opt.oid = v
  end
end
--pprint(opt)

-- Check minimum required args depending on SNMP version
if (opt.version == '') then
  usage(arg[0])
elseif opt.version == 'SNMPv2' and #arg < 3 then
  print(string.format("ERROR: Missing arguments for SNMPv2"))
  usage(arg[0])
elseif opt.version == 'SNMPv3' and #arg < 8 then
  print(string.format("ERROR: Missing arguments for SNMPv2"))
  usage(arg[0])
end
-- Parse host and optional port
if string.len(opt.host) == 0 then
  print(string.format("ERROR: Missing 'host' argument"))
  usage(arg[0])
end
local host_and_port = opt.host:split(':')
if #host_and_port == 2 then
  if tonumber(host_and_port[2], 10) == nil then
    print(string.format("ERROR: Host port '%s' is not numeric", host_and_port[2]))
    usage(arg[0])
  end
  opt.host = host_and_port[1]
  opt.port = host_and_port[2]
end

-- Tweak for AES-128
if opt.privType == "AES128" then opt.privType = "AES" end

local host = opt.host
local port = opt.port
local cred = {}
if opt.version == 'SNMPv2' then
  -- SNMPv2
  cred = {
    version                            = opt.version        ,
    community                          = opt.community      ,
  }
else
  -- SNMPv3
  cred = {
    version                            = opt.version        ,
    user                               = opt.user           ,
    securityLevel                      = opt.securityLevel  ,
    authType                           = opt.authType       ,
    password                           = opt.password       ,
    privType                           = opt.privType       ,
    privPassphrase                     = opt.privPassphrase ,
  }
end
local oid = opt.oid
snmpget(host, port, cred, oid)
