local C = EOCDroids.Config

-- ============================================================
-- CONTENT-PRUEFUNG (verhindert Error-Models und Sound-Spam)
-- ============================================================
local modelCache = {}
local missingReported = {}

local function ReportMissing(kind, path)
    if missingReported[path] then return end
    missingReported[path] = true
    MsgC(Color(255, 170, 0), "[EoC Droids] ", color_white, kind .. " fehlt (Workshop-Content?): " .. path .. "\n")
end

-- Liefert das erste gueltige Model aus einer Liste (oder einem String), sonst den Fallback
function EOCDroids.PickModel(models, fallback)
    if isstring(models) then models = { models } end

    for _, mdl in ipairs(models or {}) do
        local ok = modelCache[mdl]
        if ok == nil then
            ok = util.IsValidModel(mdl)
            modelCache[mdl] = ok
            if not ok then ReportMissing("Model", mdl) end
        end
        if ok then return mdl end
    end

    return fallback or "models/combine_soldier.mdl"
end

function EOCDroids.IsValidModel(mdl)
    if not isstring(mdl) or mdl == "" then return false end
    local ok = modelCache[mdl]
    if ok == nil then
        ok = util.IsValidModel(mdl)
        modelCache[mdl] = ok
    end
    return ok
end

local soundCache = {}

-- Prueft ob ein Sound existiert (Ergebnis wird gecacht). Gibt den Pfad oder nil zurueck.
function EOCDroids.ValidSound(path, fallback)
    if not isstring(path) or path == "" then return fallback end

    local ok = soundCache[path]
    if ok == nil then
        local clean = string.gsub(path, "^[%^%)%(%#%*%@%<%>%!%?%$%&]+", "")
        ok = file.Exists("sound/" .. clean, "GAME")
        soundCache[path] = ok
        if not ok then ReportMissing("Sound", path) end
    end

    if ok then return path end
    return fallback
end

-- ============================================================
-- ZIELE
-- ============================================================
function EOCDroids.TargetPos(ent)
    if not IsValid(ent) then return vector_origin end
    if ent:IsPlayer() then
        if ent:Crouching() then
            return ent:GetPos() + Vector(0, 0, 30)
        end
        return ent:GetPos() + Vector(0, 0, 48)
    end
    return ent:WorldSpaceCenter()
end

function EOCDroids.PlayersInSphere(pos, radius)
    local result = {}
    local radiusSqr = radius * radius
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetPos():DistToSqr(pos) <= radiusSqr then
            result[#result + 1] = ply
        end
    end
    return result
end

-- ============================================================
-- PACKEN (B2 greift Spieler) - geteilt, damit es fluessig vorhergesagt wird
-- ============================================================
function EOCDroids.GetGrabHoldPos(grabber)
    local scale = grabber:GetModelScale()
    return grabber:GetPos() + grabber:GetForward() * (34 * scale) + Vector(0, 0, 26 * scale)
end

hook.Add("Move", "EOCDroids.Grab", function(ply, mv)
    local grabber = ply:GetNW2Entity("EOCGrabber")
    if not IsValid(grabber) then return end
    if grabber:GetPos():DistToSqr(ply:GetPos()) > 400 * 400 then return end

    mv:SetOrigin(EOCDroids.GetGrabHoldPos(grabber))
    mv:SetVelocity(vector_origin)
    return true
end)

-- ============================================================
-- SPAWNMENUE (NPC-Tab)
-- ============================================================
for _, entry in ipairs(C.Spawnlist) do
    list.Set("NPC", entry.class, {
        Name = entry.name,
        Class = entry.class,
        Category = C.Category,
        AdminOnly = C.AdminOnlySpawn,
    })
end

function EOCDroids.GetSpawnEntry(key)
    for index, entry in ipairs(C.Spawnlist) do
        if entry.key == key then return entry, index end
    end
end
