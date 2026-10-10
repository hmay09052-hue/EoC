--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - bKeypads: Einheiten und Ränge als Zugangsregeln
    (Untereinheiten zählen bei "Einheit" mit)
-------------------------------------------------------------------------------------------------------------]]

local function Sync()
    if not bKeypads or not bKeypads.CustomAccess or not bKeypads.CustomAccess.Addons then return end
    if not symchars or not symchars.factions or not symchars.factions.All then return end

    local keyTable = bKeypads.CustomAccess.Addons.KeyTable or {}
    for key in pairs(keyTable) do
        if isstring(key) and (string.sub(key, 1, 17) == "symchars-factions" or string.sub(key, 1, 14) == "symchars-ranks") then
            keyTable[key] = nil
        end
    end
    if bKeypads.CustomAccess.Addons.Registry then
        bKeypads.CustomAccess.Addons.Registry["symchars-factions"] = nil
        bKeypads.CustomAccess.Addons.Registry["symchars-ranks"] = nil
    end

    local units = bKeypads.CustomAccess:AddAddon("icon16/group.png", "[SymChars] Einheiten", "symchars_factions")
    local ranks = bKeypads.CustomAccess:AddAddon("icon16/award_star_gold_1.png", "[SymChars] Ränge", "symchars_ranks")

    for _, item in ipairs(symchars.factions.GetHierarchyList()) do
        local faction = item.data
        local id = faction.uniqueID
        units:AddMember("icon16/group.png", string.rep("  ", item.depth) .. faction.name, function(ent, ply)
            local target = IsValid(ply) and ply:IsPlayer() and ply or ent
            local char = IsValid(target) and target.GetCharacter and target:GetCharacter()
            return char ~= nil and char.faction ~= nil and symchars.factions.IsInTree(char.faction, id)
        end, id)

        local category = ranks:AddCategory("icon16/group.png", faction.name, id)
        for index, rank in ipairs(faction.ranks or {}) do
            category:AddMember("icon16/award_star_bronze_1.png", index .. ". " .. rank.name, function(ent, ply)
                local target = IsValid(ply) and ply:IsPlayer() and ply or ent
                local char = IsValid(target) and target.GetCharacter and target:GetCharacter()
                return char ~= nil and char.faction == id and char:GetRank() >= index
            end, id .. "_" .. index)
        end
    end
end

hook.Add("symchars_factions_synced", "symchars_bkeypads", Sync)
timer.Simple(2, Sync)
