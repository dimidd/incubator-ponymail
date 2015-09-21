--[[
 Licensed to the Apache Software Foundation (ASF) under one or more
 contributor license agreements.  See the NOTICE file distributed with
 this work for additional information regarding copyright ownership.
 The ASF licenses this file to You under the Apache License, Version 2.0
 (the "License"); you may not use this file except in compliance with
 the License.  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
]]--

-- This is aaa.lua - AAA filter for ASF.

function getPMCs(r, uid)
    local groups = {}
    local ldapdata = io.popen( ([[ldapsearch -x -LLL "(|(memberUid=%s)(member=uid=%s,ou=people,dc=apache,dc=org))" cn]]):format(uid,uid) )
    local data = ldapdata:read("*a")
    for match in data:gmatch("dn: cn=([-a-zA-Z0-9]+),ou=pmc,ou=committees,ou=groups,dc=apache,dc=org") do
        table.insert(groups, match)
    end
    return groups
end
    
function isMember(r, uid)
    local nowish = math.floor(os.time() / 1800)
    local t = r:ivm_get("isMember_" .. nowish .. "_" .. uid)
    if t then
        return tonumber(t) == 1
    else
        local ldapdata = io.popen([[ldapsearch -x -LLL -b cn=member,ou=groups,dc=apache,dc=org]])
        local data = ldapdata:read("*a")
        for match in data:gmatch("memberUid: ([-a-z0-9_.]+)") do
            if match == uid then
                r:ivm_set("isMember_" .. nowish .. "_" .. uid, "1")
                return true
            end
        end
    end
    r:ivm_set("isMember_" .. nowish .. "_" .. uid, "0")
    return false
end

function getRights(r, xuid)
    uid = xuid:match("([-a-zA-Z0-9._]+)") -- whitelist
    local rights = {}
    if not uid or xuid ~= uid then
        return rights
    end
    if isMember(r, uid) then
        table.insert(rights, "*")
    else
        local list = getPMCs(r, uid)
        for k, v in pairs(list) do
            table.insert(rights, v .. ".apache.org")
        end
    end
    return rights
end

return {
    rights = getRights
}
