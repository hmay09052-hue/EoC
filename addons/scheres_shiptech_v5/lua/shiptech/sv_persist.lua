--[[
    ShipTech – Speichern der platzierten Konsolen pro Map
    shiptech_save   – speichert alle Konsolen (superadmin)
    shiptech_load   – lädt die gespeicherten Konsolen neu (superadmin)
    shiptech_clear  – entfernt alle Konsolen der Map (superadmin)
]]

-- Weitere Addons (z. B. ShipTech EVA) tragen hier Klassen ein, die mit shiptech_save gespeichert werden
ShipTech.ExtraPersist = ShipTech.ExtraPersist or {}

local function MapFile()
    return "shiptech/maps/" .. game.GetMap() .. ".json"
end

function ShipTech.SaveEntities()
    local list = {}
    for _, e in ipairs(ents.GetAll()) do
        if e.IsShipTech and ShipTech.ConsoleByClass[e:GetClass()] then
            list[#list + 1] = { c = e:GetClass(), p = e:GetPos(), a = e:GetAngles(), s = e:GetSector() }
        elseif ShipTech.ExtraPersist[e:GetClass()] then
            list[#list + 1] = { c = e:GetClass(), p = e:GetPos(), a = e:GetAngles(), x = e.STSaveData and e:STSaveData() or nil }
        end
    end
    file.Write(MapFile(), util.TableToJSON(list, true))
    return #list
end

function ShipTech.ClearEntities()
    for _, e in ipairs(ents.GetAll()) do
        if e.IsShipTech or ShipTech.ExtraPersist[e:GetClass()] then e:Remove() end
    end
end

function ShipTech.LoadEntities()
    local raw = file.Read(MapFile(), "DATA")
    if not raw then return 0 end
    local list = util.JSONToTable(raw)
    if not list then return 0 end

    -- gespeicherter Stand ersetzt alle vorhandenen Konsolen
    ShipTech.ClearEntities()

    local n = 0
    for _, d in ipairs(list) do
        if ShipTech.ConsoleByClass[d.c] or ShipTech.ExtraPersist[d.c] then
            local e = ents.Create(d.c)
            if IsValid(e) then
                e:SetPos(d.p)
                e:SetAngles(d.a)
                e:Spawn()
                e:Activate()
                if d.s and d.s ~= "" and e.SetSector then e:SetSector(d.s) end
                if d.x and e.STLoadData then e:STLoadData(d.x) end
                e.ST_Persist = true
                local phys = e:GetPhysicsObject()
                if IsValid(phys) then phys:EnableMotion(false) end
                n = n + 1
            end
        end
    end
    return n
end

hook.Add("InitPostEntity", "ShipTech_LoadEntities", function()
    timer.Simple(2, function()
        local n = ShipTech.LoadEntities()
        if n > 0 then MsgC(Color(80, 190, 255), "[ShipTech] ", color_white, n .. " Konsolen geladen.\n") end
    end)
end)

hook.Add("PostCleanupMap", "ShipTech_LoadEntities", function()
    timer.Simple(1, function() ShipTech.LoadEntities() end)
end)

local function AdminCmd(name, fn)
    concommand.Add(name, function(ply)
        if IsValid(ply) and not ply:IsSuperAdmin() then return end
        local msg = fn()
        if IsValid(ply) then ShipTech.Notify(ply, msg, 0) end
        print("[ShipTech] " .. msg)
    end)
end

AdminCmd("shiptech_save", function() return ShipTech.SaveEntities() .. " Konsolen gespeichert (" .. game.GetMap() .. ")." end)
AdminCmd("shiptech_load", function() return ShipTech.LoadEntities() .. " Konsolen geladen." end)
AdminCmd("shiptech_clear", function() ShipTech.ClearEntities() return "Alle Konsolen entfernt." end)
AdminCmd("shiptech_reset", function() ShipTech.ResetState() return "Schiffszustand zurückgesetzt." end)
