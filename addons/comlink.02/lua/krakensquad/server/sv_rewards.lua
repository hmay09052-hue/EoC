local XP_DISPATCH = {
    vrondakis    = function(ply, amt) if ply.addXP then ply:addXP(amt, false) return true end end,
    sublime      = function(ply, amt) if Sublime and ply.SL_AddExperience then ply:SL_AddExperience(amt, "", false) return true end end,
    bricks       = function(ply, amt)
        if BRICKS_SERVER and BRICKS_SERVER.Func
           and BRICKS_SERVER.Func.IsSubModuleEnabled("essentials", "inventory")
           and ply.AddExperience then
            ply:AddExperience(amt, "")
            return true
        end
    end,
    voidfactions = function(ply, amt) if ply.AddXP        then ply:AddXP(amt)             return true end end,
    glorified    = function(ply, amt) if GlorifiedLeveling then GlorifiedLeveling.AddPlayerXP(ply, amt) return true end end,
    RDV          = function(ply, amt) if ply.addXP        then ply:addXP(amt, false)      return true end end,
    elevels      = function(ply, amt) if ply.ELV_AddXP    then ply:ELV_AddXP(amt)         return true end end,
    darkrp       = function(ply, amt) if ply.addXP        then ply:addXP(amt, false)      return true end end,
}

local function DetectXPSystem()
    if StarWarsBF2UI and StarWarsBF2UI.Config then
        local s = StarWarsBF2UI.Config.levelSystem
        if s and s ~= "none" then return s end
    end
    if BF2HUD and BF2HUD.Config then
        local s = BF2HUD.Config.bf2hud_sv_level_system
        if s and s ~= "none" then return s end
    end
    if LevelSystemConfiguration then return "vrondakis" end
    if Sublime                  then return "sublime"   end
    if BRICKS_SERVER            then return "bricks"    end
    if VoidFactions             then return "voidfactions" end
    if GlorifiedLeveling        then return "glorified" end
end

function KrakenSquad.GiveXP(ply, amount)
    local fn = XP_DISPATCH[DetectXPSystem() or ""]
    return fn and fn(ply, amount) or false
end

function KrakenSquad.RestartXPTimer()
    timer.Remove("KS.XPReward")
    local cfg = KrakenSquad.GetConfig("xpRewards")
    if not cfg.enabled then return end

    timer.Create("KS.XPReward", (cfg.frequency or 25) * 60, 0, function()
        local c = KrakenSquad.GetConfig("xpRewards")
        if not c.enabled then return end
        for _, ply in ipairs(player.GetAll()) do
            local s = ply:GetKSSquad()
            if s and s:GetMemberCount() >= 2 and KrakenSquad.GiveXP(ply, c.amount or 100) and c.notify then
                KrakenSquad.Notify(ply, "success", KrakenSquad.L("xp_reward"))
            end
        end
    end)
end

hook.Add("InitPostEntity", "KrakenSquad.XPTimer", function()
    timer.Simple(5, KrakenSquad.RestartXPTimer)
end)

hook.Add("PlayerDeath", "KrakenSquad.MoneyShare", function(victim, _, attacker)
    local cfg = KrakenSquad.GetConfig("sharedMoney")
    if not cfg.enabled then return end
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end
    local squad = attacker:GetKSSquad()
    if not squad then return end
    if KF.Integrations.GetMoney(attacker) <= 0 then return end

    local share = victim:IsNPC() and math.floor((cfg.npcBounty or 50) * (cfg.percentage or 15) / 100) or 0
    if share <= 0 then return end

    for _, ply in ipairs(squad:GetMembers()) do
        if ply ~= attacker then
            KF.Integrations.AddMoney(ply, share)
            KrakenSquad.Notify(ply, "info", KrakenSquad.L("money_shared", KF.Integrations.FormatMoney(share)))
        end
    end
end)
