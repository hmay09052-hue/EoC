-- Armor-System: Verwaltet Rüstungswerte und Schadensabsorption
ARMOR_REPAIR = 30
ARMOR_BASE_ABSORB = 0.7
ARMOR_CRIT_THRESHOLD = 0.2
ARMOR_CRIT_BONUS = 1.3

ARMOR_PARTS = {
    Chest = { name = "Brustplatte", max_durability = 100 },
    Helmet = { name = "Helm", max_durability = 100 },
    Arms = { name = "Armschützer", max_durability = 100 },
    Legs = { name = "Beinschützer", max_durability = 100 }
}

-- Waffenmodifikatoren
local WEAPON_ARMOR_MODIFIERS = {
    -- Flammenwerfer
    ["flamethrower_variant"] = 1.4,
    ["flamethrower_basic"] = 1.4,
    
    -- Blaster-Gewehre (1.0)
    ["rw_sw_e5"] = 1.0,
    ["rw_sw_e5bx"] = 1.0,
    ["rw_sw_dual_e5"] = 1.0,
    ["rw_sw_dual_e5bx"] = 1.0,
    ["rw_sw_b2rp_blaster"] = 1.0,
    ["rw_sw_droideka"] = 1.0,
    ["rw_sw_dc15a"] = 1.0,
    ["rw_sw_dc15a_o"] = 1.0,
    ["rw_sw_dc15le"] = 1.0,
    ["rw_sw_dc15le_o"] = 1.0,
    ["rw_sw_dc15s"] = 1.0,
    ["rw_sw_dc15se"] = 1.0,
    ["rw_sw_dc17s"] = 1.0,
    ["rw_sw_dc19"] = 1.0,
    ["rw_sw_dc19le"] = 1.0,
    ["rw_sw_dual_dc15s"] = 1.0,
    ["rw_sw_dual_dc17s"] = 1.0,
    ["rw_sw_stun_dc15s"] = 1.0,
    ["rw_sw_trd_dc15a"] = 1.0,
    ["rw_sw_trd_dc15s"] = 1.0,
    ["rw_sw_westarm5"] = 1.0,
    ["rw_sw_dp24"] = 1.0,
    ["at_sw_dc15a_all"] = 1.0,
    ["at_sw_dc15s_all"] = 1.0,
    ["rw_sw_valkenx38a"] = 1.0,
    ["rw_sw_valken38x"] = 1.0,
    
    -- Blaster-Pistolen (0.8)
    ["rw_sw_dc17"] = 0.8,
    ["rw_sw_dc17ext"] = 0.8,
    ["rw_sw_dc17c"] = 0.8,
    ["rw_sw_dual_dc17"] = 0.8,
    ["rw_sw_dual_dc17ext"] = 0.8,
    ["rw_sw_stun_dc17"] = 0.8,
    ["rw_sw_trd_dc17"] = 0.8,
    ["rw_sw_westar35"] = 0.8,
    ["rw_sw_westar34"] = 0.8,
    ["rw_sw_westar11"] = 0.8,
    ["rw_sw_dual_westar35"] = 0.8,
    ["rw_sw_dual_westar34"] = 0.8,
    ["rw_sw_dual_rg4d"] = 0.8,
    ["rw_sw_dual_se14"] = 0.8,
    ["rw_sw_rg4d"] = 0.8,
    ["rw_sw_se14"] = 0.8,
    ["rw_sw_se14c"] = 0.8,
    
    -- Blaster-Sniper (1.6)
    ["rw_sw_e5s"] = 1.6,
    ["rw_sw_e5s_auto"] = 1.6,
    ["rw_sw_tusken_cycler"] = 1.6,
    ["rw_sw_iqa11"] = 1.6,
    ["rw_sw_nt242"] = 1.6,
    ["rw_sw_iqa11c"] = 1.6,
    ["rw_sw_nt242c"] = 1.6,
    ["rw_sw_dc15x"] = 1.6,
    
    -- Raketenwerfer
    ["rw_sw_e60r"] = 2.0,
    ["rw_sw_hh12"] = 1.9,
    ["rw_sw_hh15"] = 1.9,
    ["rw_sw_minimagplt"] = 2.0,
    ["rw_sw_pinglauncher"] = 2.0,
    ["rw_sw_plx1"] = 2.0,
    ["rw_sw_rps4"] = 2.0,
    ["rw_sw_rps6"] = 2.0,
    ["rw_sw_smartlauncher"] = 2.0,
    
    -- Blaster-Miniguns
    ["rw_sw_z4"] = 1.2,
    ["rw_sw_z2"] = 1.2,
    ["rw_sw_z6"] = 1.3,
    
    -- Granaten und Minen
    ["rw_sw_nade_impact"] = 1.5,
    ["rw_sw_nade_incendiary"] = 1.6,
    ["rw_sw_nade_thermal"] = 1.4,
    ["rw_sw_nade_bacta"] = 0.0,
    ["rw_sw_nade_dioxis"] = 1.0,
    ["rw_sw_nade_flash"] = 0.0,
    ["rw_sw_nade_stun"] = 0.0,
    ["rw_sw_nade_smoke"] = 0.0,
    ["rw_sw_nade_training"] = 0.0,
    ["seal6-c4"] = 1.5,
    ["zeus_flashbang"] = 0.0,
    ["zeus_smokegranade"] = 0.0,
    ["zeus_thermaldet"] = 1.5
}

-- Rüstungsreparatur
function RepairArmor(healer, target, amount)
    local newArmor = math.min(target:GetMaxArmor(), target:Armor() + amount)
    target:SetArmor(newArmor)
    
    -- Rüstungsteile reparieren
    for part, data in pairs(ARMOR_PARTS) do
        local current = target:GetNWInt("CW_ArmorDura_"..part, data.max_durability)
        local newDura = math.min(data.max_durability, current + (amount * 0.25))
        target:SetNWInt("CW_ArmorDura_"..part, newDura)
    end
    
    target:EmitSound("items/suitchargeok1.wav")
    healer:ChatPrint("Rüstung repariert: "..target:Nick())
    
    local effect = EffectData()
    effect:SetEntity(target)
    util.Effect("cball_explode", effect)
    
    return true
end

hook.Add("PlayerSwitchWeapon", "FusionCutterRepair", function(ply, oldWep, newWep)
    if newWep:GetClass() == "alydus_fusioncutter" then
        local trace = ply:GetEyeTrace()
        if IsValid(trace.Entity) and trace.Entity:IsPlayer() then
            RepairArmor(ply, trace.Entity, ARMOR_REPAIR)
        end
    end
end)

hook.Add("PlayerSpawn", "InitArmorSystem", function(ply)
    ply:SetMaxArmor(100)
    ply:SetArmor(ply:GetMaxArmor())
    
    for part, data in pairs(ARMOR_PARTS) do
        ply:SetNWInt("CW_ArmorDura_"..part, data.max_durability)
    end
end)

hook.Add("EntityTakeDamage", "ArmorDamageSystem", function(target, dmg)
    if not target:IsPlayer() then return end
    local armor = target:Armor()
    if armor <= 0 then return end
    
    local weapon = dmg:GetInflictor()
    local modifier = 1.0
    if IsValid(weapon) and WEAPON_ARMOR_MODIFIERS[weapon:GetClass()] then
        modifier = WEAPON_ARMOR_MODIFIERS[weapon:GetClass()]
    end
    
    local absorption = ARMOR_BASE_ABSORB / modifier
    local armorDamage = math.min(armor, dmg:GetDamage() * absorption)
    local healthDamage = dmg:GetDamage() - armorDamage
    
    if armor < (target:GetMaxArmor() * ARMOR_CRIT_THRESHOLD) then
        healthDamage = healthDamage * ARMOR_CRIT_BONUS
    end
    
    target:SetArmor(armor - armorDamage)
    dmg:SetDamage(healthDamage)
    
    -- Rüstungsteil beschädigen
    if armorDamage > 0 then
        local partNames = {"Chest", "Helmet", "Arms", "Legs"}
        local randomPart = partNames[math.random(#partNames)]
        local current = target:GetNWInt("CW_ArmorDura_"..randomPart, ARMOR_PARTS[randomPart].max_durability)
        target:SetNWInt("CW_ArmorDura_"..randomPart, math.max(0, current - armorDamage))
        
        target:EmitSound("physics/metal/metal_sheet_impact_bullet"..math.random(1,2)..".wav")
        
        local effect = EffectData()
        effect:SetOrigin(target:GetPos() + Vector(0,0,50))
        util.Effect("sparks", effect)
    end
end)