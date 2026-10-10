--[[-------------------------------------------------------------------------------------------------------------
    GAR Datapad - Waffe: nur ueber Job-Waffen (jobs.lua -> weapons = { "gar_datapad" })
    Vorherige Waffe merken, nicht fallen lassen, Inhalte (Modelle, Schriften) verteilen.
-------------------------------------------------------------------------------------------------------------]]

local CFG = GAR_DP.Config
local CLASS = GAR_DP.WEAPON

if CFG.WorkshopContent then
    resource.AddWorkshop("2526015939") -- Easzy's Tablet F4: Modelle
end
for _, id in ipairs(CFG.FontWorkshop or {}) do
    if tostring(id) ~= "" then resource.AddWorkshop(tostring(id)) end
end

hook.Add("PlayerSpawn", "gar_datapad_spawn", function(ply)
    ply.gdp_spawnTime = CurTime()
end)

hook.Add("PlayerSwitchWeapon", "gar_datapad_prev", function(ply, oldWep, newWep)
    if IsValid(newWep) and newWep:GetClass() == CLASS and IsValid(oldWep) and oldWep:GetClass() ~= CLASS then
        ply.gdp_prevWeapon = oldWep:GetClass()
    end
end)

hook.Add("canDropWeapon", "gar_datapad_nodrop", function(ply, wep)
    if IsValid(wep) and wep:GetClass() == CLASS then return false end
end)

hook.Add("PlayerEnteredVehicle", "gar_datapad_vehicle", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and wep:GetClass() == CLASS and wep.CloseScreen then wep:CloseScreen(false) end
end)
