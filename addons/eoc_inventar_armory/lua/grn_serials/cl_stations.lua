local WS = GRNSerials

local ACCENT = Color(255, 190, 50)
local TEXT = Color(236, 233, 224)

function WS.DrawStationLabel(ent)
    local eye = EyePos()
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local pos = ent:LocalToWorld(Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, maxs.z + 18))
    if eye:DistToSqr(pos) > 700 * 700 then return end
    local yaw = (eye - pos):Angle().y + 90
    local label = ent.WSLabel or "STATION"
    local sub = ent.WSSub or ""
    if ent.WSKind == "vitrine" then
        local reg = ent:GetNW2String("ws_regiment", "")
        if reg ~= "" then sub = string.upper(WS.RegimentName(reg)) end
    end
    cam.Start3D2D(pos, Angle(0, yaw, 90), 0.08)
        surface.SetFont("WS_3D")
        local w = surface.GetTextSize(label)
        draw.RoundedBox(0, -w / 2 - 24, -44, w + 48, 104, Color(10, 12, 16, 200))
        draw.RoundedBox(0, -w / 2 - 24, -44, 6, 104, ACCENT)
        draw.SimpleText(label, "WS_3D", 0, -8, TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(sub, "WS_3DSub", 0, 36, ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

-- Vitrine: Waffenmodelle der eingelagerten Traditionswaffen.
local models = {}

local function displayList(ent)
    local raw = ent:GetNW2String("ws_display", "[]")
    if ent.WSDisplayRaw ~= raw then
        ent.WSDisplayRaw = raw
        ent.WSDisplay = util.JSONToTable(raw) or {}
    end
    return ent.WSDisplay or {}
end

local function modelFor(class)
    if models[class] ~= nil then return models[class] end
    local stored = weapons.GetStored(class)
    local mdl = stored and (stored.WorldModel or stored.WM)
    if not isstring(mdl) or mdl == "" or not util.IsValidModel(mdl) then models[class] = false return false end
    local cm = ClientsideModel(mdl, RENDERGROUP_OPAQUE)
    if not IsValid(cm) then models[class] = false return false end
    cm:SetNoDraw(true)
    models[class] = cm
    return cm
end

function WS.DrawStationExtras(ent)
    if ent.WSKind ~= "vitrine" then return end
    if EyePos():DistToSqr(ent:GetPos()) > 900 * 900 then return end
    local list = displayList(ent)
    local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
    local cz = mins.z + (maxs.z - mins.z) * 0.62
    for i, w in ipairs(list) do
        if w.home then
            local cm = modelFor(w.c)
            if cm then
                local z = cz - (i - 1) * (maxs.z - mins.z) * 0.22
                local pos = ent:LocalToWorld(Vector((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, z))
                local ang = ent:LocalToWorldAngles(Angle(0, 90, 0))
                cm:SetPos(pos)
                cm:SetAngles(ang)
                cm:SetupBones()
                cm:DrawModel()
            end
        end
    end
end
