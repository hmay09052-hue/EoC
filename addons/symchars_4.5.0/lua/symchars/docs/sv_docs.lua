--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Dokumente (Server) mit Live-Bearbeitung

    Mehrere Spieler können ein Dokument gleichzeitig bearbeiten. Wer einen Block bearbeitet, sperrt ihn
    (andere sehen "✎ Name"). Änderungen werden sofort an alle Betrachter verteilt und alle 10s gespeichert.
-------------------------------------------------------------------------------------------------------------]]

local D = symchars.docs
local U = symchars.util
local UT = symchars.utils
local DB = symchars.db
local Json, Unjson = symchars.net.Json, symchars.net.Unjson

D.index = D.index or {}
D.sessions = D.sessions or {}

local LOCK_TIME = 25
local MAX_DOC_BYTES = 600000

local function MetaFromRow(row)
    local perms = D.SanitizePerms(Unjson(row.perms or ""))
    return {
        id = tonumber(row.id), folder = row.folder or "public", title = U.Clean(row.title, 120), perms = perms,
        createdBy = row.createdBy or "", createdBySteam = tostring(row.createdBySteam or ""),
        createdAt = tonumber(row.createdAt) or 0, updatedAt = tonumber(row.updatedAt) or 0, updatedBy = row.updatedBy or "",
    }
end

function D.Load(done)
    DB.Query("SELECT id, folder, title, perms, createdBy, createdBySteam, createdAt, updatedAt, updatedBy FROM sc_docs", function(rows)
        D.index = {}
        for _, row in ipairs(rows) do
            local meta = MetaFromRow(row)
            D.index[meta.id] = meta
        end
        symchars.print(table.Count(D.index) .. " Dokumente gefunden.")
        if done then done() end
    end, function() if done then done() end end)
end

local function PlayerColor(ply)
    local h = tonumber(util.CRC(ply:SteamID64() or "0")) or 0
    local col = HSVToColor(h % 360, 0.65, 1)
    return { r = col.r, g = col.g, b = col.b }
end

local function PlayerName(ply)
    local char = ply:GetCharacter()
    return char and UT.BuildDisplayName(char) or ply:Nick()
end

local function MetaFor(ply, meta)
    local char = ply:GetCharacter()
    return {
        id = meta.id, folder = meta.folder, title = meta.title, perms = meta.perms, createdBy = meta.createdBy,
        createdAt = meta.createdAt, updatedAt = meta.updatedAt, updatedBy = meta.updatedBy,
        canWrite = D.CanWrite(ply, char, meta), canManage = D.CanManage(ply, char, meta),
    }
end

---------------------------------------------------------------------------------------------------------------
-- Sitzungen
---------------------------------------------------------------------------------------------------------------
local function Viewers(session)
    local list = {}
    for ply in pairs(session.viewers) do
        if IsValid(ply) then list[#list + 1] = ply else session.viewers[ply] = nil end
    end
    return list
end

local function Presence(session)
    local now = CurTime()
    local list = {}
    for ply, info in pairs(session.viewers) do
        if IsValid(ply) then
            local block = nil
            for bid, lock in pairs(session.locks) do
                if lock.ply == ply and lock.untilTime > now then block = bid end
            end
            list[#list + 1] = { uid = ply:UserID(), name = info.name, color = info.color, block = block }
        end
    end
    local targets = Viewers(session)
    if #targets > 0 then symchars.net.Send("doc_presence", { id = session.id, users = list }, targets) end
end

local function Broadcast(session, action, data, except)
    local targets = {}
    for _, ply in ipairs(Viewers(session)) do
        if ply ~= except then targets[#targets + 1] = ply end
    end
    if #targets > 0 then symchars.net.Send(action, data, targets) end
end

local function SaveSession(session)
    if not session.dirty then return end
    session.dirty = false
    local meta = D.index[session.id]
    if not meta then return end
    meta.updatedAt = os.time()
    meta.updatedBy = session.lastEditor or meta.updatedBy
    DB.Query("UPDATE sc_docs SET data = " .. DB.Str(Json(session.blocks)) .. ", updatedAt = " .. DB.Num(meta.updatedAt)
        .. ", updatedBy = " .. DB.Str(meta.updatedBy) .. " WHERE id = " .. DB.Num(session.id))
end

local function OpenSession(id, callback)
    local session = D.sessions[id]
    if session then callback(session) return end
    DB.Query("SELECT data FROM sc_docs WHERE id = " .. DB.Num(id), function(rows)
        if not rows[1] then callback(nil) return end
        if D.sessions[id] then callback(D.sessions[id]) return end
        local raw = Unjson(rows[1].data or "") or {}
        local blocks = {}
        for _, b in ipairs(raw) do
            local clean = D.SanitizeBlock(b)
            if clean then blocks[#blocks + 1] = clean end
        end
        if #blocks == 0 then blocks = D.EmptyBlocks() end
        session = { id = id, blocks = blocks, viewers = {}, locks = {}, dirty = false, version = 0 }
        D.sessions[id] = session
        callback(session)
    end, function() callback(nil) end)
end

local function CloseViewer(session, ply)
    session.viewers[ply] = nil
    for bid, lock in pairs(session.locks) do
        if lock.ply == ply then session.locks[bid] = nil end
    end
    if #Viewers(session) == 0 then
        SaveSession(session)
        D.sessions[session.id] = nil
    else
        Presence(session)
    end
end

local function FindBlock(session, bid)
    for i, b in ipairs(session.blocks) do
        if b.id == bid then return i, b end
    end
end

local function LockedByOther(session, bid, ply)
    local lock = session.locks[bid]
    return lock ~= nil and lock.ply ~= ply and IsValid(lock.ply) and lock.untilTime > CurTime()
end

local function DocBytes(session)
    return #Json(session.blocks)
end

timer.Create("symchars_docs_save", 10, 0, function()
    for _, session in pairs(D.sessions) do SaveSession(session) end
end)

hook.Add("ShutDown", "symchars_docs_save", function()
    for _, session in pairs(D.sessions) do SaveSession(session) end
end)

hook.Add("PlayerDisconnected", "symchars_docs", function(ply)
    for _, session in pairs(D.sessions) do
        if session.viewers[ply] then CloseViewer(session, ply) end
    end
end)

-- Bei Charakterwechsel Rechte neu prüfen
hook.Add("symchars_selectedcharacter", "symchars_docs", function(ply)
    for _, session in pairs(D.sessions) do
        if session.viewers[ply] then
            local meta = D.index[session.id]
            if not meta or not D.CanRead(ply, ply:GetCharacter(), meta) then
                CloseViewer(session, ply)
                symchars.net.Send("doc_closed", { id = session.id }, ply)
            end
        end
    end
end)

---------------------------------------------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------------------------------------------
symchars.net.Receive("doc_list", function(ply)
    local char = ply:GetCharacter()
    local list = {}
    for _, meta in pairs(D.index) do
        if D.CanRead(ply, char, meta) then
            local m = MetaFor(ply, meta)
            m.perms = nil
            m.editing = D.sessions[meta.id] and #Viewers(D.sessions[meta.id]) or 0
            list[#list + 1] = m
        end
    end
    table.sort(list, function(a, b) return a.updatedAt > b.updatedAt end)

    local folders = {}
    if D.CanCreateIn(ply, char, "public") then folders[#folders + 1] = "public" end
    for id in pairs(symchars.factions.All()) do
        if D.CanCreateIn(ply, char, id) then folders[#folders + 1] = id end
    end

    symchars.net.Send("doc_list", { docs = list, create = folders }, ply)
end, 0.5)

symchars.net.Receive("doc_open", function(ply, data)
    local id = U.Int(istable(data) and data.id, 0)
    local meta = D.index[id]
    if not meta or not D.CanRead(ply, ply:GetCharacter(), meta) then
        symchars.Notify(ply, "Du darfst dieses Dokument nicht lesen.", "error")
        return
    end
    OpenSession(id, function(session)
        if not session or not IsValid(ply) then return end
        for _, other in pairs(D.sessions) do
            if other ~= session and other.viewers[ply] then CloseViewer(other, ply) end
        end
        session.viewers[ply] = { name = PlayerName(ply), color = PlayerColor(ply) }
        symchars.net.Send("doc_full", { meta = MetaFor(ply, meta), blocks = session.blocks }, ply)
        Presence(session)
    end)
end, 0.3)

symchars.net.Receive("doc_close", function(ply, data)
    local session = D.sessions[U.Int(istable(data) and data.id, 0)]
    if session and session.viewers[ply] then CloseViewer(session, ply) end
end)

symchars.net.Receive("doc_create", function(ply, data)
    if not istable(data) then return end
    local folder = U.ID(data.folder)
    if folder == "" then folder = "public" end
    if folder ~= "public" and not symchars.factions.Get(folder) then return end
    if not D.CanCreateIn(ply, ply:GetCharacter(), folder) then
        symchars.Notify(ply, "Du darfst hier keine Dokumente anlegen.", "error")
        return
    end
    local title = U.Clean(data.title, 120)
    if title == "" then title = "Neues Dokument" end
    local blocks = D.EmptyBlocks()
    blocks[1].text = title
    local perms = D.DefaultPerms(folder)
    local now = os.time()
    local name = PlayerName(ply)

    local q = "INSERT INTO sc_docs (folder, title, data, perms, createdBy, createdBySteam, createdAt, updatedAt, updatedBy) VALUES ("
        .. DB.Str(folder) .. ", " .. DB.Str(title) .. ", " .. DB.Str(Json(blocks)) .. ", " .. DB.Str(Json(perms)) .. ", " .. DB.Str(name) .. ", "
        .. DB.Str(ply:SteamID64()) .. ", " .. DB.Num(now) .. ", " .. DB.Num(now) .. ", " .. DB.Str(name) .. ")"
    DB.Query(q, function(_, lastId)
        local function Done(id)
            if not id or id <= 0 then return end
            D.index[id] = { id = id, folder = folder, title = title, perms = perms, createdBy = name, createdBySteam = ply:SteamID64(), createdAt = now, updatedAt = now, updatedBy = name }
            symchars.net.Send("doc_created", { id = id }, ply)
        end
        if lastId and lastId > 0 then
            Done(lastId)
        else
            DB.Query("SELECT id FROM sc_docs WHERE createdBySteam = " .. DB.Str(ply:SteamID64()) .. " ORDER BY id DESC LIMIT 1", function(rows)
                Done(tonumber(rows[1] and rows[1].id))
            end)
        end
    end)
end, 2)

symchars.net.Receive("doc_delete", function(ply, data)
    local id = U.Int(istable(data) and data.id, 0)
    local meta = D.index[id]
    if not meta or not D.CanManage(ply, ply:GetCharacter(), meta) then return end
    D.index[id] = nil
    local session = D.sessions[id]
    if session then
        Broadcast(session, "doc_closed", { id = id, deleted = true })
        D.sessions[id] = nil
    end
    DB.Query("DELETE FROM sc_docs WHERE id = " .. DB.Num(id))
    symchars.Notify(ply, "Dokument '" .. meta.title .. "' gelöscht.", "succ")
    symchars.net.Send("doc_deleted", { id = id }, ply)
end, 1)

symchars.net.Receive("doc_meta", function(ply, data)
    if not istable(data) then return end
    local id = U.Int(data.id, 0)
    local meta = D.index[id]
    if not meta then return end
    local char = ply:GetCharacter()
    if not D.CanManage(ply, char, meta) then symchars.Notify(ply, "Dir fehlt die Berechtigung.", "error") return end

    local title = U.Clean(data.title, 120)
    if title ~= "" then meta.title = title end
    if istable(data.perms) then meta.perms = D.SanitizePerms(data.perms) end
    if isstring(data.folder) and data.folder ~= meta.folder then
        local folder = U.ID(data.folder)
        if (folder == "public" or symchars.factions.Get(folder)) and D.CanCreateIn(ply, char, folder) then meta.folder = folder end
    end

    DB.Query("UPDATE sc_docs SET title = " .. DB.Str(meta.title) .. ", perms = " .. DB.Str(Json(meta.perms)) .. ", folder = " .. DB.Str(meta.folder)
        .. " WHERE id = " .. DB.Num(id))

    local session = D.sessions[id]
    if session then
        for _, viewer in ipairs(Viewers(session)) do
            if D.CanRead(viewer, viewer:GetCharacter(), meta) then
                symchars.net.Send("doc_meta", MetaFor(viewer, meta), viewer)
            else
                CloseViewer(session, viewer)
                symchars.net.Send("doc_closed", { id = id }, viewer)
            end
        end
    end
    symchars.Notify(ply, "Dokument gespeichert.", "succ")
end, 0.5)

symchars.net.Receive("doc_lock", function(ply, data)
    if not istable(data) then return end
    local session = D.sessions[U.Int(data.id, 0)]
    local meta = session and D.index[session.id]
    if not session or not session.viewers[ply] or not D.CanWrite(ply, ply:GetCharacter(), meta) then return end
    local bid = tostring(data.block or "")

    -- eigene alte Sperren lösen
    for other, lock in pairs(session.locks) do
        if lock.ply == ply and other ~= bid then session.locks[other] = nil end
    end

    if data.release == true or bid == "" then
        session.locks[bid] = (session.locks[bid] and session.locks[bid].ply ~= ply) and session.locks[bid] or nil
        Presence(session)
        return
    end

    if LockedByOther(session, bid, ply) then
        symchars.net.Send("doc_lock_denied", { id = session.id, block = bid }, ply)
        return
    end
    session.locks[bid] = { ply = ply, untilTime = CurTime() + LOCK_TIME }
    Presence(session)
end)

symchars.net.Receive("doc_op", function(ply, data)
    if not istable(data) or not istable(data.op) then return end
    local session = D.sessions[U.Int(data.id, 0)]
    local meta = session and D.index[session.id]
    if not session or not session.viewers[ply] or not D.CanWrite(ply, ply:GetCharacter(), meta) then return end

    local op = data.op
    local out
    local maxBlocks = symchars.Config("docsmaxblocks") or 400

    if op.k == "set" then
        local block = D.SanitizeBlock(op.block)
        if not block then return end
        if block.t == "img" and not symchars.Config("docsallowimages") then return end
        local index = FindBlock(session, block.id)
        if not index or LockedByOther(session, block.id, ply) then return end
        session.blocks[index] = block
        session.locks[block.id] = { ply = ply, untilTime = CurTime() + LOCK_TIME }
        out = { k = "set", block = block }
    elseif op.k == "insert" then
        if #session.blocks >= maxBlocks then symchars.Notify(ply, "Maximale Anzahl an Blöcken erreicht.", "error") return end
        local block = D.SanitizeBlock(op.block)
        if not block then return end
        if block.t == "img" and not symchars.Config("docsallowimages") then return end
        if FindBlock(session, block.id) then block.id = D.NewBlockID() end
        local after = tostring(op.after or "")
        local index = after == "" and 0 or (FindBlock(session, after) or #session.blocks)
        table.insert(session.blocks, index + 1, block)
        session.locks[block.id] = { ply = ply, untilTime = CurTime() + LOCK_TIME }
        out = { k = "insert", after = after, block = block }
    elseif op.k == "remove" then
        local bid = tostring(op.id or "")
        local index = FindBlock(session, bid)
        if not index or LockedByOther(session, bid, ply) or #session.blocks <= 1 then return end
        table.remove(session.blocks, index)
        session.locks[bid] = nil
        out = { k = "remove", id = bid }
    elseif op.k == "move" then
        local bid = tostring(op.id or "")
        local index = FindBlock(session, bid)
        local dir = op.dir == -1 and -1 or 1
        if not index then return end
        local target = index + dir
        if target < 1 or target > #session.blocks then return end
        session.blocks[index], session.blocks[target] = session.blocks[target], session.blocks[index]
        out = { k = "move", id = bid, dir = dir }
    else
        return
    end

    if DocBytes(session) > MAX_DOC_BYTES then
        symchars.Notify(ply, "Das Dokument ist zu groß.", "error")
        -- Änderung rückgängig machen: komplette Version neu senden
        D.sessions[session.id] = nil
        OpenSession(session.id, function(fresh)
            if not fresh then return end
            fresh.viewers = session.viewers
            for viewer in pairs(fresh.viewers) do
                if IsValid(viewer) then symchars.net.Send("doc_full", { meta = MetaFor(viewer, meta), blocks = fresh.blocks }, viewer) end
            end
        end)
        return
    end

    session.dirty = true
    session.version = session.version + 1
    session.lastEditor = PlayerName(ply)
    out.by = ply:UserID()
    Broadcast(session, "doc_ops", { id = session.id, ops = { out } }, ply)
    if op.k ~= "set" then Presence(session) end
end)

-- Inhalte für Holo-Anzeigen (nur Dokumente, die auf einer Holo-Anzeige eingestellt sind)
symchars.net.Receive("doc_holo", function(ply, data)
    local id = U.Int(istable(data) and data.id, 0)
    local allowed = false
    for _, ent in ipairs(ents.FindByClass("symchars_holo_display")) do
        local cfg = symchars.holo.GetConfig(ent)
        if cfg and cfg.mode == "document" and cfg.doc == id then allowed = true break end
    end
    if not allowed or not D.index[id] then return end
    OpenSession(id, function(session)
        if not session or not IsValid(ply) then return end
        local blocks = {}
        for i = 1, math.min(#session.blocks, 40) do blocks[i] = session.blocks[i] end
        symchars.net.Send("doc_holo", { id = id, title = D.index[id].title, blocks = blocks }, ply)
        if #Viewers(session) == 0 then D.sessions[id] = nil end
    end)
end, 1)
