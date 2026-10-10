Tarnnetz = Tarnnetz or {}

local C = Tarnnetz.Config

-- Networked Werte am Spieler
--   Tarnnetz.Active   (bool)  Tarnung an
--   Tarnnetz.Paused   (bool)  Droide in der Nähe (nur ProximityMode 'pause')
--   Tarnnetz.Camo     (int)   Index in Config.Camos
--   Tarnnetz.Cooldown (float) CurTime(), ab der wieder aktiviert werden darf

function Tarnnetz.IsActive(ply)
    return IsValid(ply) and ply:GetNWBool('Tarnnetz.Active', false)
end

function Tarnnetz.GetCamo(ply)
    return C.Camos[ply:GetNWInt('Tarnnetz.Camo', 0)]
end

function Tarnnetz.CooldownLeft(ply)
    return math.max(0, ply:GetNWFloat('Tarnnetz.Cooldown', 0) - CurTime())
end

function Tarnnetz.Meters(units)
    return math.Round(units / 52.49)
end

local droidClassCache = {}

local function IsDroidClass(class)
    local cached = droidClassCache[class]
    if cached ~= nil then return cached end

    local result = false
    for _, prefix in ipairs(C.DroidPrefixes or {}) do
        if string.StartWith(class, prefix) then result = true break end
    end
    if not result then
        for _, b in ipairs(C.DroidBases or {}) do
            if class == b or scripted_ents.IsBasedOn(class, b) then result = true break end
        end
    end

    droidClassCache[class] = result
    return result
end

function Tarnnetz.IsDroid(ent)
    if not IsValid(ent) or ent:IsPlayer() then return false end
    if ent:Health() <= 0 and (ent:IsNPC() or ent:IsNextBot()) then return false end
    if C.AllNPCs and (ent:IsNPC() or ent:IsNextBot()) then return true end
    return IsDroidClass(ent:GetClass())
end

-- Nächster Droide im Radius um den Spieler: Entity, Entfernung
function Tarnnetz.NearestDroid(ply, radius)
    local pos = ply:WorldSpaceCenter()
    local best, bestDist
    for _, ent in ipairs(ents.FindInSphere(pos, radius)) do
        if Tarnnetz.IsDroid(ent) then
            local d = pos:Distance(ent:WorldSpaceCenter())
            if not bestDist or d < bestDist then best, bestDist = ent, d end
        end
    end
    return best, bestDist
end
