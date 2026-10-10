--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Holo-System (Server): Einstellungen, dauerhaftes Speichern pro Karte, Benutzen
-------------------------------------------------------------------------------------------------------------]]

local H = symchars.holo
local U = symchars.util
local DB = symchars.db
local Json, Unjson = symchars.net.Json, symchars.net.Unjson

local function Entry(ent)
    return { ent = ent:EntIndex(), class = ent:GetClass(), cfg = H.ToSave(H.GetConfig(ent)) }
end

function H.SyncEntity(ent, ply)
    if not IsValid(ent) then return end
    symchars.net.Send("holo_configs", { Entry(ent) }, ply)
end

function H.SyncAll(ply)
    local list = {}
    for class in pairs(H.CLASSES) do
        for _, ent in ipairs(ents.FindByClass(class)) do list[#list + 1] = Entry(ent) end
    end
    if #list > 0 then symchars.net.Send("holo_configs", list, ply) end
end

function H.OnSpawned(ent)
    H.configs[ent:EntIndex()] = H.Normalize(ent:GetClass(), ent.symchars_pendingcfg or {})
    ent.symchars_pendingcfg = nil
    timer.Simple(0.2, function() if IsValid(ent) then H.SyncEntity(ent) end end)
end

function H.OnRemoved(ent)
    local idx = ent:EntIndex()
    H.configs[idx] = nil
    symchars.net.Send("holo_configs", { { ent = idx, removed = true } })
end

function H.OnUse(ent, ply)
    if not IsValid(ply) then return end
    if (ply.symchars_holouse or 0) > CurTime() then return end
    ply.symchars_holouse = CurTime() + 1
    local cfg = H.GetConfig(ent)
    local class = ent:GetClass()

    if class == "symchars_terminal" then
        symchars.net.Send("menu_open", { tab = cfg.tab, unit = cfg.unit }, ply)
    elseif class == "symchars_holo_projector" then
        symchars.net.Send("menu_open", { tab = "units", unit = cfg.unit }, ply)
    elseif class == "symchars_holo_display" then
        if cfg.mode == "document" and cfg.doc > 0 then
            symchars.net.Send("menu_open", { tab = "docs", doc = cfg.doc }, ply)
        elseif cfg.mode == "trainings" then
            symchars.net.Send("menu_open", { tab = "manager", unit = cfg.unit }, ply)
        elseif cfg.mode == "unit" or cfg.mode == "roster" then
            symchars.net.Send("menu_open", { tab = "units", unit = cfg.unit }, ply)
        end
    end
end

---------------------------------------------------------------------------------------------------------------
-- Speichern pro Karte
---------------------------------------------------------------------------------------------------------------
local function VecText(v) return string.format("%.2f %.2f %.2f", v.x, v.y, v.z) end
local function AngText(a) return string.format("%.2f %.2f %.2f", a.p, a.y, a.r) end
local function ParseVec(s)
    local x, y, z = string.match(tostring(s or ""), "^(%S+) (%S+) (%S+)$")
    return Vector(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0)
end
local function ParseAng(s)
    local p, y, r = string.match(tostring(s or ""), "^(%S+) (%S+) (%S+)$")
    return Angle(tonumber(p) or 0, tonumber(y) or 0, tonumber(r) or 0)
end

function H.Persist(ent, done)
    local cfg = Json(H.ToSave(H.GetConfig(ent)))
    local id = ent:GetHoloID()
    if id > 0 then
        DB.Query("UPDATE sc_holos SET pos = " .. DB.Str(VecText(ent:GetPos())) .. ", ang = " .. DB.Str(AngText(ent:GetAngles()))
            .. ", data = " .. DB.Str(cfg) .. " WHERE id = " .. DB.Num(id), done)
        return
    end
    DB.Query("INSERT INTO sc_holos (map, class, pos, ang, data) VALUES (" .. DB.Str(game.GetMap()) .. ", " .. DB.Str(ent:GetClass()) .. ", "
        .. DB.Str(VecText(ent:GetPos())) .. ", " .. DB.Str(AngText(ent:GetAngles())) .. ", " .. DB.Str(cfg) .. ")", function(_, lastId)
        if IsValid(ent) and lastId and lastId > 0 then
            ent:SetHoloID(lastId)
            ent:SetSymSaved(true)
        end
        if done then done() end
    end)
end

function H.Unpersist(ent)
    local id = ent:GetHoloID()
    if id <= 0 then return end
    DB.Query("DELETE FROM sc_holos WHERE id = " .. DB.Num(id))
    ent:SetHoloID(0)
    ent:SetSymSaved(false)
end

function H.SpawnSaved()
    if H.spawned then return end
    H.spawned = true
    DB.Query("SELECT * FROM sc_holos WHERE map = " .. DB.Str(game.GetMap()), function(rows)
        for _, row in ipairs(rows) do
            if H.CLASSES[row.class] then
                local ent = ents.Create(row.class)
                if IsValid(ent) then
                    ent.symchars_pendingcfg = Unjson(row.data or "") or {}
                    ent:SetPos(ParseVec(row.pos))
                    ent:SetAngles(ParseAng(row.ang))
                    ent:Spawn()
                    ent:Activate()
                    ent:SetHoloID(tonumber(row.id) or 0)
                    ent:SetSymSaved(true)
                    local phys = ent:GetPhysicsObject()
                    if IsValid(phys) then phys:EnableMotion(false) end
                end
            end
        end
        if #rows > 0 then symchars.print(#rows .. " Holo-Objekte aufgestellt.") end
    end)
end

hook.Add("PostCleanupMap", "symchars_holo", function()
    H.spawned = false
    timer.Simple(1, H.SpawnSaved)
end)

-- Gespeicherte Holos nicht mit Physgun/Toolgun bewegen (außer Admins mit Holo-Recht)
hook.Add("PhysgunPickup", "symchars_holo", function(ply, ent)
    if IsValid(ent) and H.CLASSES[ent:GetClass()] and ent:GetSymSaved() and not symchars.HasPriv(ply, "symchars_holo") then return false end
end)

hook.Add("CanTool", "symchars_holo", function(ply, tr)
    local ent = tr.Entity
    if IsValid(ent) and H.CLASSES[ent:GetClass()] and ent:GetSymSaved() and not symchars.HasPriv(ply, "symchars_holo") then return false end
end)

---------------------------------------------------------------------------------------------------------------
-- Netzwerk
---------------------------------------------------------------------------------------------------------------
symchars.net.Receive("holo_config", function(ply, data)
    if not symchars.IsSuperAdmin(ply) or not istable(data) then return end
    local ent = Entity(U.Int(data.ent, 0))
    if not IsValid(ent) or not H.CLASSES[ent:GetClass()] then return end

    H.configs[ent:EntIndex()] = H.Normalize(ent:GetClass(), data.cfg)
    H.SyncEntity(ent)

    if data.persist == true then
        H.Persist(ent, function() symchars.Notify(ply, "Holo dauerhaft gespeichert.", "succ") end)
    elseif data.persist == false then
        H.Unpersist(ent)
        symchars.Notify(ply, "Holo wird nicht mehr gespeichert.", "info")
    else
        if ent:GetHoloID() > 0 then H.Persist(ent) end
        symchars.Notify(ply, "Holo eingestellt.", "succ")
    end
end, 0.3)

symchars.net.Receive("holo_list", function(ply)
    if not symchars.IsSuperAdmin(ply) then return end
    local list = {}
    for class, name in pairs(H.CLASSES) do
        for _, ent in ipairs(ents.FindByClass(class)) do
            local cfg = H.GetConfig(ent)
            list[#list + 1] = {
                ent = ent:EntIndex(), class = class, name = name, persistent = ent:GetHoloID() > 0,
                pos = VecText(ent:GetPos()), mode = cfg.mode or cfg.tab or "", unit = cfg.unit or "",
            }
        end
    end
    symchars.net.Send("holo_list", list, ply)
end, 0.5)

symchars.net.Receive("holo_action", function(ply, data)
    if not symchars.IsSuperAdmin(ply) or not istable(data) then return end
    local ent = Entity(U.Int(data.ent, 0))
    if not IsValid(ent) or not H.CLASSES[ent:GetClass()] then return end
    if data.action == "goto" then
        ply:SetPos(ent:GetPos() + ent:GetForward() * 60 + Vector(0, 0, 10))
    elseif data.action == "remove" then
        H.Unpersist(ent)
        ent:Remove()
        symchars.Notify(ply, "Holo entfernt.", "succ")
    end
end, 0.3)
