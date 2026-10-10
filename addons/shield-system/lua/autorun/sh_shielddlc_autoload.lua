SWRPShieldDLC = SWRPShieldDLC or {}
SWRPShieldDLC.Version = "1.2"

if SERVER then
    if JoeBase then
        JoeBase:RegisterProduct("Shield DLC", SWRPShieldDLC.Version)
    else
        hook.Add("JoeBase:FinishedLoading", "SWRPShieldDLC:Register", function()
            JoeBase:RegisterProduct("Shield DLC", SWRPShieldDLC.Version)
        end)
    end
end

local mainfolder = "shielddlc/"
-- sh files
for k,v in pairs(file.Find(mainfolder .. "sh_*", "LUA")) do
    include(mainfolder .. tostring(v))
    if SERVER then AddCSLuaFile(mainfolder .. tostring(v)) end
end

-- sv files
if SERVER then
    for k,v in pairs(file.Find(mainfolder .. "sv_*", "LUA")) do
        include(mainfolder .. tostring(v))
    end
end
-- cl files
for k,v in pairs(file.Find(mainfolder .. "cl_*", "LUA")) do
    if SERVER then AddCSLuaFile(mainfolder ..  tostring(v))
    else include(mainfolder .. tostring(v))
    end
end