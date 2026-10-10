-- Medic-System: Verwaltet Heilung und medizinische Interaktionen
MEDKIT_HEAL = 30
BACTA_HEAL = 60
MEDIC_BONUS = 1.5
TREATMENT_TIME = 5

util.AddNetworkString("StartTreatment")
util.AddNetworkString("CancelTreatment")
util.AddNetworkString("CompleteTreatment")

local activeTreatments = {}

function StartTreatment(healer, target)
    if activeTreatments[healer] then return end
    
    activeTreatments[healer] = {
        target = target,
        startTime = CurTime(),
        progress = 0
    }
    
    net.Start("StartTreatment")
        net.WriteEntity(target)
    net.Send(healer)
    
    healer:Freeze(true)
    healer:SetNWBool("IsTreating", true)
end

function CancelTreatment(healer)
    if not activeTreatments[healer] then return end
    
    net.Start("CancelTreatment")
    net.Send(healer)
    
    activeTreatments[healer] = nil
    healer:Freeze(false)
    healer:SetNWBool("IsTreating", false)
end

function CompleteTreatment(healer)
    if not activeTreatments[healer] then return end
    local treatment = activeTreatments[healer]
    
    local healAmount = MEDKIT_HEAL
    if healer:isMedic() then
        healAmount = healAmount * MEDIC_BONUS
    end
    
    local newHealth = math.min(treatment.target:GetMaxHealth(), treatment.target:Health() + healAmount)
    treatment.target:SetHealth(newHealth)
    
    -- Körperteile heilen
    local healPerPart = healAmount * 0.25
    local parts = {"Head", "Torso", "Arms", "Legs"}
    for _, part in ipairs(parts) do
        local current = treatment.target:GetNWInt("CW_"..part.."Health", 100)
        treatment.target:SetNWInt("CW_"..part.."Health", math.min(100, current + healPerPart))
    end
    
    -- Verletzung reduzieren
    if treatment.target.InjuryLevel and treatment.target.InjuryLevel > 1 then
        treatment.target.InjuryLevel = treatment.target.InjuryLevel - 1
        ApplyInjury(treatment.target, treatment.target:Health() / treatment.target:GetMaxHealth())
    end
    
    net.Start("CompleteTreatment")
    net.Send(healer)
    
    activeTreatments[healer] = nil
    healer:Freeze(false)
    healer:SetNWBool("IsTreating", false)
end

timer.Create("TreatmentProgress", 0.1, 0, function()
    for healer, treatment in pairs(activeTreatments) do
        if not IsValid(healer) or not IsValid(treatment.target) then
            if IsValid(healer) then
                healer:Freeze(false)
                healer:SetNWBool("IsTreating", false)
            end
            activeTreatments[healer] = nil
        else
            treatment.progress = (CurTime() - treatment.startTime) / TREATMENT_TIME

            -- Performance: DistToSqr statt Distance (keine Wurzel); abgebrochene Behandlung nicht noch abschließen
            if healer:GetPos():DistToSqr(treatment.target:GetPos()) > 10000 then
                CancelTreatment(healer)
            elseif treatment.progress >= 1 then
                CompleteTreatment(healer)
            end
        end
    end
end)

hook.Add("KeyPress", "MedicInteraction", function(ply, key)
    if key ~= IN_USE or ply:GetNWBool("IsTreating") then return end
    
    local trace = ply:GetEyeTrace()
    if IsValid(trace.Entity) and trace.Entity:IsPlayer() and ply:GetPos():Distance(trace.Entity:GetPos()) < 100 then
        StartTreatment(ply, trace.Entity)
    end
end)

hook.Add("KeyRelease", "CancelMedicInteraction", function(ply, key)
    if key == IN_USE and ply:GetNWBool("IsTreating") then
        CancelTreatment(ply)
    end
end)

hook.Add("PlayerSwitchWeapon", "BactaHealing", function(ply, oldWep, newWep)
    if newWep:GetClass() == "weapon_bactainjector" then
        local trace = ply:GetEyeTrace()
        local target = IsValid(trace.Entity) and trace.Entity:IsPlayer() and trace.Entity or ply
        
        local healAmount = BACTA_HEAL
        if ply:isMedic() then
            healAmount = healAmount * MEDIC_BONUS
        end
        
        local newHealth = math.min(target:GetMaxHealth(), target:Health() + healAmount)
        target:SetHealth(newHealth)
        
        -- Körperteile vollständig heilen
        local parts = {"Head", "Torso", "Arms", "Legs"}
        for _, part in ipairs(parts) do
            target:SetNWInt("CW_"..part.."Health", 100)
        end
        
        if target.InjuryLevel then
            target.InjuryLevel = nil
            ApplyInjury(target, target:Health() / target:GetMaxHealth())
        end
        
        ply:EmitSound("items/medshot4.wav")
    end
end)

local medicTeams = {
    [TEAM_501MDCUBM] = true,
    [TEAM_501MDCOFF] = true,
    [TEAM_501KIX] = true
}

local meta = FindMetaTable("Player")
function meta:isMedic()
    return medicTeams[self:Team()] or false
end