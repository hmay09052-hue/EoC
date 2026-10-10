CW_Combat = CW_Combat or {}
CW_Combat.Config = CW_Combat.Config or {}

-- Team-Namen
CW_Combat.Config.MEDIC_TEAM_NAME = "Medic"
CW_Combat.Config.TECH_TEAM_NAME = "Techniker"

-- Verletzungskonfiguration
CW_Combat.Config.Injuries = {
    ["bullet"] = {
        bg_id = 1, 
        name = "Schusswunde", 
        cure_item = "cw_medkit_antibiotic", 
        heal_time = 8, 
        severity = 3
    },
    ["lightsaber"] = {
        bg_id = 2, 
        name = "Lichtschwerverbrennung", 
        cure_item = "cw_medkit_burngel", 
        heal_time = 12, 
        severity = 3
    },
    ["fire"] = {
        bg_id = 3, 
        name = "Brandwunde", 
        cure_item = "cw_medkit_burngel", 
        heal_time = 10, 
        severity = 2
    },
    ["poison"] = {
        bg_id = 4, 
        name = "Vergiftung", 
        cure_item = "cw_medkit_antidote", 
        heal_time = 15, 
        severity = 3
    }
}

-- Rüstungskonfiguration
CW_Combat.Config.ArmorParts = {
    ["helm"] = {
        name = "Helm", 
        max_durability = 100
    },
    ["chest"] = {
        name = "Brustpanzer", 
        max_durability = 150
    },
    ["arms"] = {
        name = "Armrüstung", 
        max_durability = 80
    },
    ["legs"] = {
        name = "Beinschienen", 
        max_durability = 120
    }
}

-- Player-Metatable erweitern
local function SetupPlayerMethods()
    local Player = FindMetaTable("Player")
    
    function Player:IsMedic()
        if not IsValid(self) then return false end
        local teamName = team.GetName(self:Team())
        return teamName == CW_Combat.Config.MEDIC_TEAM_NAME
    end
    
    function Player:IsTech()
        if not IsValid(self) then return false end
        local teamName = team.GetName(self:Team())
        return teamName == CW_Combat.Config.TECH_TEAM_NAME
    end
end

hook.Add("Initialize", "CW_SetupPlayerMethods", SetupPlayerMethods)