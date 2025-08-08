#!/usr/bin/env lua

-- NOTE: For IPv4, 'peername' refers to 'IPv4', 'IPv4:port', 'hostname' or 'hostname:port'
-- That is, the port value is always included in the 'peername', and should NOT be treated separately.
-- NET-SNMP used 'remote_port' in the past, but this variable is obsolete since a long time ago, and should not be used any longer in new code.
-- For example, 'snmpget' syntax uses this 'peername', where the port value is extracted internally by NET-SNMP.

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
  --
  -- - Security Level                     : `authPriv`
  -- - Authentication Protocol            : `SHA`
  -- - Privacy Protocol                   : `AES`
  -- - User                               : `myuser161`
  -- - Authentication Protocol Passphrase : `foobarfoo`
  -- - Privacy Protocol Passphrase        : `barfoobar`
  -- - Host[:Port]                        : `172.17.0.4`
  -- - [Retries]                          : Defaults to `5`. Set to `0` for shortest timeout test.
  -- - [Timeout]                          : Defaults to `1` (second). Set to as small as possible, for example `0.1` for a reasonable timeout test. TODO: TEST THIS VALUE.
  print(string.format("Usage: (same syntax as Net-SNMP's 'snmpget'):"))
  print(string.format("SNMPv2  : %s %s -c %s %s %s", prg, "-v2c", "COMMUNITY", "HOST[:PORT]", "OID"))
  print(string.format("SNMPv3  : %s %s -l %s -u %s -a %s -A %s -x %s -X %s %s %s", prg, "-v3", "SEC_LEVEL", "USER", "AUTH_PROTO", "AUTH_PASS", "PRIV_PROTO",  "PRIV_PASS", "HOST[:PORT]", "OID"))
  print(string.format("Example : %s %s -c %s %s %s", prg, "-v2c", "community12", "172.17.0.2", "system.sysDescr.0"))
  print(string.format("Example : %s %s -l %s -u %s -a %s -A %s -x %s -X %s %s %s", prg, "-v3", "authPriv", "md5-user0910", "MD5", "myauth-MD5", "DES", "mypriv-DES", "172.17.0.10", "system.sysDescr.0"))
  print(string.format("Example : %s %s -l %s -u %s -a %s -A %s -x %s -X %s %s %s", prg, "-v3", "authPriv", "sha-512-user1516", "SHA-512", "myauth-SHA-512", "AES", "mypriv-AES", "172.17.0.17:16161", "system.sysDescr.0"))
  print(string.format("Example with short timeout : %s %s -r %s -t %s -l %s -u %s -a %s -A %s -x %s -X %s %s %s", prg, "-v3", "0", "0.1", "authPriv", "sha-512-user1516", "SHA-512", "myauth-SHA-512", "AES", "mypriv-AES2", "172.17.0.17:16161", "system.sysDescr.0"))
  os.exit(1)
end

-- Split string
-- (This function is generic, and can split a string into multiple parts.)
-- function string:split(delimiter)
--     local result = {}
--     local from = 1
--     local delim_from, delim_to = string.find(self, delimiter, from, true)
--     while delim_from do
--         if (delim_from ~= 1) then
--             table.insert(result, string.sub(self, from, delim_from-1))
--         end
--         from = delim_to + 1
--         delim_from, delim_to = string.find(self, delimiter, from, true)
--     end
--     if (from <= #self) then table.insert(result, string.sub(self, from)) end
--     return result
-- end

local function snmpopen(peername, params, cred)
  local hub1, err = nil,nil
  if cred.version == 'SNMPv2' then
    hub1, err = snmp.open{
    peer    = peername,
    retries = params.retries,
    timeout = params.timeout,
    version = snmp.SNMPv2,
    community = cred.community,
    }
  else
    hub1, err = snmp.open{
    peer = peername,
    retries = params.retries,
    timeout = params.timeout,
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

local function snmpget(peername, params, cred, oid)

  -- pprint(cred)

  local hub1, err = snmpopen(peername, params, cred)
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
  retries        = '5',
  timeout        = '1',
  version        = '',
  community      = '',
  user           = '',
  securityLevel  = '',
  authType       = '',
  password       = '',
  privType       = '',
  privPassphrase = '',
  peername       = '', -- host[:port]
  oid            = '',
}
for k, v in ipairs(arg) do
  if (v == '-v3') then opt.version = 'SNMPv3'
  elseif (v == '-v2c') then opt.version = 'SNMPv2'
  elseif (v == '-v1') then opt.version = 'SNMPv1'
  elseif (v == '-r') and arg[k+1] ~= nil then opt.retries = arg[k+1]
  elseif (v == '-t') and arg[k+1] ~= nil then opt.timeout = arg[k+1]
  elseif (v == '-c') and arg[k+1] ~= nil then opt.community = arg[k+1]
  elseif (v == '-l') and arg[k+1] ~= nil then opt.securityLevel = arg[k+1]
  elseif (v == '-u') and arg[k+1] ~= nil then opt.user = arg[k+1]
  elseif (v == '-a') and arg[k+1] ~= nil then opt.authType = arg[k+1]
  elseif (v == '-A') and arg[k+1] ~= nil then opt.password = arg[k+1]
  elseif (v == '-x') and arg[k+1] ~= nil then opt.privType = arg[k+1]
  elseif (v == '-X') and arg[k+1] ~= nil then opt.privPassphrase = arg[k+1]
  elseif (k == #arg - 1) then opt.peername = v
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
-- Verify peername presence
if string.len(opt.peername) == 0 then
  print(string.format("ERROR: Missing 'peername' (host[:port]) argument"))
  usage(arg[0])
end

-- Tweak for AES-128
if opt.privType == "AES128" then opt.privType = "AES" end

-- Params (optional)
local params = {
    retries                            = opt.retries        ,
    timeout                            = opt.timeout        ,
}
-- Credentials
local cred = {
    version                            = opt.version        ,
}
if opt.version == 'SNMPv2' then
  -- SNMPv2
  cred['community'] = opt.community
else
  -- SNMPv3
  cred['user']           = opt.user
  cred['securityLevel']  = opt.securityLevel
  cred['authType']       = opt.authType
  cred['password']       = opt.password
  cred['privType']       = opt.privType
  cred['privPassphrase'] = opt.privPassphrase
end
local peername = opt.peername
local oid = opt.oid
snmpget(peername, params, cred, oid)
