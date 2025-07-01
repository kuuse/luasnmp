#! /usr/bin/env lua
--
-- Function walk implements a MIB subtree traversal
--
-- It is functionally identical to:
--
--  snmpwalk -v3 -l authPriv -u myuser161 -a SHA -A foobarfoo -x AES -X barfoobar 172.17.0.4 system.sysDescr
--
--  parameters: 
--	1. the identification of an SNMP agent (a host name or IP address)
--	2. the SNMPv3 credentials
--	3. a MIB label identifying the subtree to be traversed (optional)
--
local snmp = require "snmp"
local mib=snmp.mib
-- local pprint = require "pprint"

--
-- We will use this frequently
--
local check = snmp.check

function walkV3(host, cred, subtree)


   -- Open an SNMP session with host using SNMPv3
  print(string.format("Open session to %q with user|pass %s|%s", host, cred.user, cred.authentication_protocol_passphrase))

  -- local sess, err = snmp.open{
  --   peer = "localhost",
  --   version = snmp.SNMPv3,
  --   user = "leuwer",
  --   password = "leuwer2006"
  -- }

  -- pprint(cred)

  local s, err = snmp.open{
    peer = host,
    version = snmp.SNMPv3,
    securityLevel = cred.security_level,
    authType = cred.authentication_protocol,
    privpType = cred.privacy_protocol,
    user = cred.user,
    password = cred.authentication_protocol_passphrase,
    privPassphrase = cred.private_protocol_passphrase
  }
  -- print(string.format("walk:   session=%s\n",s))

  -- pprint(s)
  -- print(string.format("walk: unable to open session: %s\n",err))
  -- check(sess, err)

  -- local s,err = snmp.open{peer = host, version = SNMPv3, cred=cred}
  if not s then
    print(string.format("walk: unable to open session with %s\n%",err))
    return
  end

  -- Convert MIB label to its OID. 
  local root
  if subtree then
    root = mib.oid(subtree)
    if not root then
      print(string.format("walk: invalid subtree %s\n",subtree))
      return
    end
  else -- if no label is defined, traverse the entire MIB
    root = "1"
  end
  
  -- Traverse the subtree
  local vb={oid=root}
  local mibEnd
  repeat
--    print("#11# vb=",vb.oid, vb.type)
    vb,err = s:getnext(vb)
--    print("#22#", vb, err, root, vb.type)
    if not err then
      -- Check if the returned OID contains the OID associated 
      --   with the root of the subtree
      if string.find(vb.oid,root) == nil or 
	vb.type == snmp.ENDOFMIBVIEW then
	mibEnd = 1
      else
	-- print the returned varbind and request next var
	-- use LuaSNMP's sprintvar:
	-- print(snmp.sprintvar(vb))
	-- or NETSNMP's sprint_var via session
	-- print(session:sprintvar(vb))
	-- or simply rely on Lua's __tostring metamethod
	print(vb)
      end
    end
  until err or mibEnd
  
  -- Close the SNMP session
  print(string.format("Closing session ..."))
  s:close(s)
  
end

if #arg < 8 then
  -- ./mylua walk-v3.lua 172.17.0.4 authPriv SHA AES myuser161 foobarfoo barfoobar system.sysDescr
  -- - IP                                 : `172.17.0.4`
  -- - Security Level                     : `authPriv`
  -- - Authentication Protocol            : `SHA`
  -- - Privacy Protocol                   : `AES`
  -- - User                               : `myuser161`
  -- - Authentication Protocol Passphrase : `foobarfoo`
  -- - Privacy Protocol Passphrase        : `barfoobar`
  print(string.format("Usage   : %s %s %s %s %s %s %s %s %s", arg[0], "HOST", "SECURITY_LEVEL", "AUTHENTICATION_PROTOCOL", "PRIVACY_PROTOCOL", "USER", "AUTHENTICATION_PROTOCOL_PASSPHRASE", "PRIVACY_PROTOCOL_PASSPHRASE", "OID"))
  print(string.format("Example : %s %s %s %s %s %s %s %s %s", arg[0], "172.17.0.4", "noAuthNoPriv", "SHA", "AES", "myuser161", "foobarfoo", "barfoobar", "system.sysDescr"))
  os.exit(1)
end

-- function walk(host, commStr, subtree)
local ip = arg[1]
local cred = {
  security_level = arg[2],
  authentication_protocol            = arg[3],
  privacy_protocol                   = arg[4],
  user                               = arg[5],
  authentication_protocol_passphrase = arg[6],
  privacy_protocol_passphrase        = arg[7],
}
local oid = arg[8]
walkV3(ip, cred, oid)
