SWRPShield = SWRPShield or {}
SWRPShield.ents = {}
SWRPShield.Version = "3.0.1"

if SERVER then
    if JoeBase then
        JoeBase:RegisterProduct("Shield Generator", SWRPShield.Version)
    else
        hook.Add("JoeBase:FinishedLoading", "SWRPShield:Register", function()
            JoeBase:RegisterProduct("Shield Generator", SWRPShield.Version)
        end)
    end
end

local mainfolder = "shieldsystem/"
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