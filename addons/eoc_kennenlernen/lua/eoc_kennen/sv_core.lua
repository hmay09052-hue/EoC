local K = EOC_KENNEN

util.AddNetworkString("eoc_kennen_sync")
util.AddNetworkString("eoc_kennen_add")

local TABLE = "eoc_kennen"

sql.Query("CREATE TABLE IF NOT EXISTS " .. TABLE .. " (char_id INTEGER NOT NULL, known_id INTEGER NOT NULL, PRIMARY KEY (char_id, known_id))")

local function notify(ply, text, kind)
    if symchars and symchars.Notify then
        symchars.Notify(ply, text, kind or "info")
    else
        ply:ChatPrint(text)
    end
end

function K.LoadKnown(charID)
    local known = {}
    charID = tonumber(charID) or 0
    if charID == 0 then return known end

    local rows = sql.Query("SELECT known_id FROM " .. TABLE .. " WHERE char_id = " .. charID)
    if istable(rows) then
        for _, row in ipairs(rows) do
            known[#known + 1] = tonumber(row.known_id)
        end
    end
    return known
end

function K.IsKnown(charID, otherID)
    charID, otherID = tonumber(charID) or 0, tonumber(otherID) or 0
    if charID == 0 or otherID == 0 then return false end
    return sql.QueryValue("SELECT 1 FROM " .. TABLE .. " WHERE char_id = " .. charID .. " AND known_id = " .. otherID) ~= nil
end

-- Schickt dem Spieler alle Charaktere, die sein aktiver Charakter kennt
function K.SyncPlayer(ply)
    if not IsValid(ply) then return end
    local charID = K.GetCharID(ply)
    local known = K.LoadKnown(charID)

    net.Start("eoc_kennen_sync")
        net.WriteUInt(charID, 32)
        net.WriteUInt(#known, 16)
        for _, id in ipairs(known) do
            net.WriteUInt(id, 32)
        end
    net.Send(ply)
end

local function sendAdd(ply, otherID)
    net.Start("eoc_kennen_add")
        net.WriteUInt(K.GetCharID(ply), 32)
        net.WriteUInt(otherID, 32)
    net.Send(ply)
end

function K.Learn(ply, target)
    local myID, otherID = K.GetCharID(ply), K.GetCharID(target)
    if myID == 0 or otherID == 0 or myID == otherID then return false end
    if K.IsKnown(myID, otherID) then return false end

    sql.Query("INSERT OR IGNORE INTO " .. TABLE .. " (char_id, known_id) VALUES (" .. myID .. ", " .. otherID .. ")")
    sendAdd(ply, otherID)
    return true
end

-- Spieler finden, den man gerade anschaut
local function getLookTarget(ply)
    local maxDist = K.Cfg().MaxDistance or 150
    local start = ply:EyePos()
    local tr = util.TraceHull({
        start = start,
        endpos = start + ply:GetAimVector() * maxDist,
        filter = ply,
        mins = Vector(-4, -4, -4),
        maxs = Vector(4, 4, 4),
        mask = MASK_SHOT,
    })

    local ent = tr.Entity
    if IsValid(ent) and ent:IsPlayer() and ent:Alive() then return ent end
    return nil
end

local function isCommand(text)
    text = string.lower(string.Trim(text or ""))
    for _, cmd in ipairs(K.Cfg().Commands or {}) do
        if text == string.lower(cmd) then return true end
    end
    return false
end

hook.Add("PlayerSay", "EOC_Kennen_Command", function(ply, text)
    if not isCommand(text) then return end

    if K.GetCharID(ply) == 0 then
        notify(ply, "Du hast keinen Charakter ausgewählt.", "error")
        return ""
    end

    local target = getLookTarget(ply)
    if not target then
        notify(ply, "Schau den Spieler an, den du kennenlernen willst (und geh näher ran).", "error")
        return ""
    end

    if K.GetCharID(target) == 0 then
        notify(ply, "Dieser Spieler hat keinen Charakter ausgewählt.", "error")
        return ""
    end

    local learned = K.Learn(ply, target)
    local learnedBack = K.Cfg().Mutual and K.Learn(target, ply) or false

    if learned then
        notify(ply, "Du kennst jetzt " .. target:Nick() .. ".", "succ")
    else
        notify(ply, "Du kennst " .. target:Nick() .. " bereits.", "info")
    end

    if learnedBack then
        notify(target, ply:Nick() .. " hat sich dir vorgestellt.", "succ")
    end

    return ""
end)

-- Charakterwechsel: neue Bekanntschaftsliste schicken
hook.Add("symchars_selectedcharacter", "EOC_Kennen_Sync", function(ply)
    -- NW2-Var wird im selben Tick gesetzt, kurz warten bis sie sicher steht
    timer.Simple(0, function() K.SyncPlayer(ply) end)
end)

hook.Add("PlayerInitialSpawn", "EOC_Kennen_Sync", function(ply)
    timer.Simple(3, function() K.SyncPlayer(ply) end)
end)

-- Gelöschte Charaktere aus der Datenbank entfernen
hook.Add("symchars_deleted", "EOC_Kennen_Cleanup", function(_, _, charID)
    charID = tonumber(charID) or 0
    if charID == 0 then return end
    sql.Query("DELETE FROM " .. TABLE .. " WHERE char_id = " .. charID .. " OR known_id = " .. charID)
end)

-- Admin: Bekanntschaften eines Charakters zurücksetzen (eoc_kennen_reset <charID>)
concommand.Add("eoc_kennen_reset", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local charID = tonumber(args[1]) or 0
    if charID == 0 then return end
    sql.Query("DELETE FROM " .. TABLE .. " WHERE char_id = " .. charID)

    for _, p in ipairs(player.GetAll()) do
        if K.GetCharID(p) == charID then K.SyncPlayer(p) end
    end
    print("[EoC Kennenlernen] Bekanntschaften von Charakter " .. charID .. " zurückgesetzt.")
end)
