local WS = GRNSerials
local C = WS.Config

function WS.InitStation(ent)
    local model = ent.WSModel
    if not model or not util.IsValidModel(model) then model = "models/props_lab/workspace003.mdl" end
    ent:SetModel(model)
    ent:SetMoveType(MOVETYPE_NONE)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetUseType(SIMPLE_USE)
    if not IsValid(ent:GetPhysicsObject()) then
        ent:SetSolid(SOLID_BBOX)
        local mins, maxs = ent:GetModelBounds()
        if mins and maxs then ent:SetCollisionBounds(mins, maxs) end
    end
    if ent.WSKind == "vitrine" then
        timer.Simple(0, function() if IsValid(ent) then WS.UpdateVitrine(ent) end end)
    end
end

function WS.UseStation(ent, ply)
    if not C.Enabled or not IsValid(ply) or not ply:IsPlayer() then return end
    if (ply.WSNextUse or 0) > CurTime() then return end
    ply.WSNextUse = CurTime() + 0.6
    WS.OpenStation(ply, ent, ent.WSKind)
end

-- Vitrine: zeigt eingelagerte Traditionswaffen ihres Regiments.
function WS.UpdateVitrine(ent)
    local regiment = ent:GetNW2String("ws_regiment", "")
    local list = {}
    if regiment ~= "" then
        for _, row in ipairs(WS.DB.Rows("SELECT serial, class, honor_name, status FROM ws_weapons WHERE regiment_id = ? AND is_tradition = 1 AND status != 'RETIRED' ORDER BY created_at ASC LIMIT 3", regiment)) do
            list[#list + 1] = { c = row.class, n = row.honor_name, s = row.serial, home = row.status == "STORED" }
        end
    end
    ent:SetNW2String("ws_display", util.TableToJSON(list, false) or "[]")
end

timer.Create("GRNSerials_Vitrines", 15, 0, function()
    for _, ent in ipairs(ents.FindByClass("grn_ws_vitrine")) do WS.UpdateVitrine(ent) end
end)

-- Neue Vitrine gehört dem Regiment des Admins, der sie aufstellt.
hook.Add("PlayerSpawnedSENT", "GRNSerials_VitrineOwner", function(ply, ent)
    if IsValid(ent) and ent:GetClass() == "grn_ws_vitrine" then
        ent:SetNW2String("ws_regiment", WS.GetRegiment(ply) or "T501")
        WS.UpdateVitrine(ent)
    end
end)

-- ws_vitrine_regiment <ID>  (Vitrine anschauen)
concommand.Add("ws_vitrine_regiment", function(ply, _, args)
    if not IsValid(ply) or not WS.IsAdmin(ply) then return end
    local ent = ply:GetEyeTrace().Entity
    if not IsValid(ent) or ent:GetClass() ~= "grn_ws_vitrine" then
        ply:ChatPrint("Schau eine Vitrine an.")
        return
    end
    local id = string.upper(tostring(args[1] or ""))
    if not (C.RegimentNames or {})[id] then
        ply:ChatPrint("Unbekanntes Regiment. Möglich: " .. table.concat(table.GetKeys(C.RegimentNames or {}), ", "))
        return
    end
    ent:SetNW2String("ws_regiment", id)
    WS.UpdateVitrine(ent)
    ply:ChatPrint("Vitrine gehört jetzt zu " .. WS.RegimentName(id) .. ".")
end)
