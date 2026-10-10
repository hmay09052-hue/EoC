-- Injury-System: Verwaltet Verletzungen und Gesundheitszustände
INJURY_THRESHOLD = 0.3
INJURY_LEVELS = {
    [1] = { speed = 0.8, jump = 0.9, name = "Leichte Verletzung", bleed = 0.1 },
    [2] = { speed = 0.6, jump = 0.7, name = "Mittelschwere Verletzung", bleed = 0.3 },
    [3] = { speed = 0.4, jump = 0.5, name = "Schwere Verletzung", bleed = 0.5 }
}

HITGROUP_TO_PART = {
    [HITGROUP_HEAD] = "Head",
    [HITGROUP_CHEST] = "Torso",
    [HITGROUP_STOMACH] = "Torso",
    [HITGROUP_LEFTARM] = "Arms",
    [HITGROUP_RIGHTARM] = "Arms",
    [HITGROUP_LEFTLEG] = "Legs",
    [HITGROUP_RIGHTLEG] = "Legs"
}

util.AddNetworkString("UpdateInjuryStatus")

local function ApplyInjury(ply, healthPercent)
    if healthPercent > INJURY_THRESHOLD then
        if ply.InjuryLevel then
            ply:SetRunSpeed(250)
            ply:SetJumpPower(200)
            ply.InjuryLevel = nil
            ply:SetNWBool("IsInjured", false)
            ply:SetNWInt("InjurySeverity", 0)
            ply:SetNWString("CW_CurrentInjury", "")
            ply:StopSound("ambient/voices/cough"..math.random(1,4)..".wav")
        end
        return
    end
    
    local newLevel = (healthPercent < 0.1) and 3 or (healthPercent < 0.2) and 2 or 1
    if ply.InjuryLevel == newLevel then return end
    
    ply.InjuryLevel = newLevel
    local injury = INJURY_LEVELS[newLevel]
    
    ply:SetRunSpeed(250 * injury.speed)
    ply:SetJumpPower(200 * injury.jump)
    ply:SetNWBool("IsInjured", true)
    ply:SetNWInt("InjurySeverity", newLevel)
    ply:SetNWString("CW_CurrentInjury", injury.name)
    
    if injury.bleed > 0 then
        ply:SetNWFloat("BleedRate", injury.bleed)
        timer.Create("BleedEffect_"..ply:SteamID(), 5, 0, function()
            if not IsValid(ply) then timer.Remove("BleedEffect_"..ply:SteamID()) return end
            if ply:Health() / ply:GetMaxHealth() > INJURY_THRESHOLD then return end
            
            local dmg = DamageInfo()
            dmg:SetDamage(ply:GetMaxHealth() * injury.bleed * 0.05)
            dmg:SetDamageType(DMG_SLASH)
            dmg:SetAttacker(game.GetWorld())
            ply:TakeDamageInfo(dmg)
            
            if math.random() < injury.bleed then
                ply:EmitSound("ambient/voices/cough"..math.random(1,4)..".wav")
            end
        end)
    end
    
    if not ply.InjuryAnim then
        ply:AnimRestartGesture(GESTURE_SLOT_CUSTOM, ACT_GMOD_GESTURE_TAUNT_ZOMBIE, true)
        ply.InjuryAnim = true
    end
end

hook.Add("EntityTakeDamage", "AdvancedInjurySystem", function(target, dmg)
    if not target:IsPlayer() then return end
    
    -- Körperteil-Schaden
    local hitgroup = target:LastHitGroup()
    local partName = HITGROUP_TO_PART[hitgroup] or "Torso"
    local currentHealth = target:GetNWInt("CW_"..partName.."Health", 100)
    local newPartHealth = math.max(0, currentHealth - dmg:GetDamage())
    target:SetNWInt("CW_"..partName.."Health", newPartHealth)
    
    -- Gesamtschaden
    local newHealth = target:Health() - dmg:GetDamage()
    if newHealth < (target:GetMaxHealth() * INJURY_THRESHOLD) then
        ApplyInjury(target, newHealth / target:GetMaxHealth())
    end
end)

hook.Add("PostEntityTakeDamage", "ResetInjuryState", function(target)
    if not target:IsPlayer() then return end
    ApplyInjury(target, target:Health() / target:GetMaxHealth())
end)

hook.Add("PlayerDeath", "ClearInjuryOnDeath", function(ply)
    ply.InjuryLevel = nil
    ply:SetNWBool("IsInjured", false)
    ply:SetNWInt("InjurySeverity", 0)
    ply:SetNWString("CW_CurrentInjury", "")
    timer.Remove("BleedEffect_"..ply:SteamID())
end)

hook.Add("PlayerSpawn", "ResetInjuryOnRespawn", function(ply)
    ply.InjuryLevel = nil
    ply:SetNWBool("IsInjured", false)
    ply:SetNWInt("InjurySeverity", 0)
    ply:SetNWString("CW_CurrentInjury", "")
    ply:SetRunSpeed(250)
    ply:SetJumpPower(200)
    timer.Remove("BleedEffect_"..ply:SteamID())
    
    -- Körperteil-Initialisierung
    ply:SetNWInt("CW_HeadHealth", 100)
    ply:SetNWInt("CW_TorsoHealth", 100)
    ply:SetNWInt("CW_ArmsHealth", 100)
    ply:SetNWInt("CW_LegsHealth", 100)
end)