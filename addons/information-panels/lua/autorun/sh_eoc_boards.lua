--[[-------------------------------------------------------------------------------------------------------------
    Echoes of Clones - Info-Tafeln (gemeinsame Basis)
    Alle Tafeln (Willkommen, Allgemein, DEFCON, Formationen, Gesichter) teilen sich Layout, Blättern und Design.
    Gezeichnet wird komplett im Code im SymChars-Stil - es werden keine Bilder mehr benötigt.
-------------------------------------------------------------------------------------------------------------]]

EOC_BOARD = EOC_BOARD or {}
local B = EOC_BOARD

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("eoc_boards/cl_board.lua")
end

B.Scale = 0.1      -- 3D2D-Maßstab: 10 Tafel-Pixel = 1 Einheit
B.Head  = 140      -- Höhe der Kopfzeile
B.Foot  = 110      -- Höhe der Fußzeile
B.BtnW, B.BtnH = 190, 70

-- Weltposition -> Tafel-Koordinaten (Ursprung in der Mitte, x nach rechts, y nach unten)
function B.ToBoard(ent, worldPos)
    local l = ent:WorldToLocal(worldPos)
    return l.y / B.Scale, l.x / B.Scale
end

-- Rechtecke der beiden Blätter-Knöpfe
function B.Buttons(ent)
    local w, h = ent.BoardW, ent.BoardH
    local y = h / 2 - B.Foot / 2 - B.BtnH / 2
    return { x = -w / 2 + 40, y = y, w = B.BtnW, h = B.BtnH },
           { x = w / 2 - 40 - B.BtnW, y = y, w = B.BtnW, h = B.BtnH }
end

local function Inside(r, x, y)
    return x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h
end

-- -1 = zurück, 1 = weiter, 0 = irgendwo sonst auf der Tafel, nil = daneben
function B.HitTest(ent, x, y)
    local w, h = ent.BoardW, ent.BoardH
    if math.abs(x) > w / 2 or math.abs(y) > h / 2 then return nil end
    local prev, nxt = B.Buttons(ent)
    if Inside(prev, x, y) then return -1 end
    if Inside(nxt, x, y) then return 1 end
    return 0
end

function B.PageCount(ent)
    return math.max(1, math.floor(ent:GetMax()))
end

if SERVER then
    -- Gemeinsames ENT:Use für alle Tafeln
    function B.Use(ent, ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        local tr = ply:GetEyeTrace()
        if tr.Entity ~= ent then return end

        local dir = B.HitTest(ent, B.ToBoard(ent, tr.HitPos))
        if dir == nil then return end

        local max, page = B.PageCount(ent), math.floor(ent:GetPage())
        if max <= 1 then return end

        local new
        if dir == 0 then
            new = page >= max and 1 or page + 1 -- Klick auf die Tafel: weiter, am Ende wieder Seite 1
        else
            new = math.Clamp(page + dir, 1, max)
        end
        if new == page then return end

        ent:SetPage(new)
        ent:EmitSound("buttons/lightswitch2.wav", 60, 115, 0.5)
    end
else
    include("eoc_boards/cl_board.lua")
end
