--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Holo-System (Welt-Darstellung)
-------------------------------------------------------------------------------------------------------------]]

local H = symchars.holo
local UI = symchars.ui
local U = symchars.util
local F = symchars.factions
local D = symchars.docs

local WIRE = Material("models/wireframe")
local WHITE = Material("models/debug/debugwhite")
local GLOW = Material("sprites/light_glow02_add")
local RING = Material("effects/select_ring")
local BEAM = Material("vgui/gradient-u")
local UP, DOWN = Vector(0, 0, 1), Vector(0, 0, -1)

H.docCache = H.docCache or {}

symchars.net.Receive("doc_holo", function(data)
    if not istable(data) then return end
    H.docCache[tonumber(data.id)] = { title = data.title, blocks = data.blocks or {}, time = CurTime() }
end)

local function RequestDoc(id)
    local entry = H.docCache[id]
    if entry and (entry.pending or CurTime() - entry.time < 60) then return entry end
    H.docCache[id] = entry or { title = "Lädt…", blocks = {}, time = CurTime() }
    H.docCache[id].pending = true
    timer.Simple(5, function() if H.docCache[id] then H.docCache[id].pending = nil end end)
    symchars.net.SendToServer("doc_holo", { id = id })
    return H.docCache[id]
end

local function Fade(ent, range)
    local dist = EyePos():Distance(ent:GetPos())
    if dist > range then return 0 end
    return math.Clamp(1 - (dist - range * 0.7) / (range * 0.3), 0, 1)
end

---------------------------------------------------------------------------------------------------------------
-- Inhalte der Holo-Anzeige (Zeilen-Spezifikation)
---------------------------------------------------------------------------------------------------------------
local function Spec(cfg)
    local spec = { title = cfg.title, sub = nil, rows = {}, text = nil, faction = nil, footer = nil }
    local unit = F.Get(cfg.unit)

    if cfg.mode == "unit" then
        spec.faction = unit
        spec.title = spec.title ~= "" and spec.title or (unit and unit.name or "Einheit wählen")
        if unit then
            local members = symchars.chars.GetMembers(unit, true)
            local online = 0
            for _, c in ipairs(members) do if c:IsOnline() then online = online + 1 end end
            spec.sub = F.GetDisplayName(unit)
            spec.text = unit:GetDescription()
            spec.stats = { { "Mitglieder", #members }, { "Online", online }, { "Ränge", #unit:GetRanks() } }
        end
        spec.footer = "[E]  Einheit ansehen"
    elseif cfg.mode == "roster" then
        spec.faction = unit
        spec.title = spec.title ~= "" and spec.title or (unit and (unit.name .. " – Im Dienst") or "Einheit wählen")
        if unit then
            for _, ply in ipairs(player.GetAll()) do
                local c = ply:GetCharacter()
                if c and c.faction and F.IsInTree(c.faction, unit) then
                    local rank = c:GetRankData()
                    spec.rows[#spec.rows + 1] = { text = symchars.utils.BuildDisplayName(c), value = rank and rank.name or "", col = UI.Readable(UI.UnitColor(c)), sort = c:GetRank() }
                end
            end
            table.sort(spec.rows, function(a, b) return a.sort > b.sort end)
            spec.sub = #spec.rows .. " im Dienst"
            if #spec.rows == 0 then spec.text = "Niemand im Dienst." end
        end
    elseif cfg.mode == "trainings" then
        spec.faction = unit
        spec.title = spec.title ~= "" and spec.title or "Fortbildungen"
        spec.sub = unit and unit.name or "Alle Einheiten"
        for _, t in ipairs(symchars.trainings.List()) do
            if not unit or symchars.trainings.AppliesToUnit(t, unit.uniqueID) then
                local holders = 0
                for _, c in pairs(symchars.chars.All()) do if c:HasTraining(t.id) then holders = holders + 1 end end
                spec.rows[#spec.rows + 1] = { text = t.name, value = holders .. " Absolventen", col = t.color }
            end
        end
        if #spec.rows == 0 then spec.text = "Keine Fortbildungen eingerichtet." end
        spec.footer = "[E]  Verwaltung öffnen"
    elseif cfg.mode == "document" then
        local doc = cfg.doc > 0 and RequestDoc(cfg.doc)
        spec.title = spec.title ~= "" and spec.title or (doc and doc.title or "Kein Dokument")
        spec.sub = "Dokument"
        if doc then
            local lines = {}
            for _, b in ipairs(doc.blocks) do
                if b.text and b.text ~= "" then
                    local prefix = (b.t == "ul" and "•  ") or (b.t == "todo" and (b.checked and "[x]  " or "[ ]  ")) or ""
                    lines[#lines + 1] = { text = prefix .. D.PlainText(b.text), head = b.t == "h1" or b.t == "h2" or b.t == "h3" }
                end
            end
            spec.docLines = lines
        end
        spec.footer = "[E]  Dokument öffnen"
    else
        spec.title = spec.title ~= "" and spec.title or "Hinweis"
    end

    if cfg.text ~= "" and cfg.mode ~= "text" then spec.extra = cfg.text end
    if cfg.mode == "text" then spec.text = cfg.text end
    return spec
end

local PX_W = 1000

local function DrawPanel(ent, cfg, alpha)
    local spec = Spec(cfg)
    local col = cfg.color
    local flick = 1
    if cfg.flicker then
        local t = CurTime() * 3 + ent:EntIndex()
        flick = (math.sin(t * 7.3) > 0.97 or math.random() < 0.004) and 0.55 or (0.92 + math.sin(t) * 0.08)
    end
    local a = alpha * flick
    local w = PX_W
    local pad = 40

    -- Höhe berechnen
    local h = 190
    local textLines = spec.text and spec.text ~= "" and UI.Wrap(spec.text, "symchars.world.body", w - pad * 2) or {}
    if #textLines > 10 then textLines = { unpack(textLines, 1, 10) } textLines[10] = textLines[10] .. " …" end
    h = h + #textLines * 36
    if spec.stats then h = h + 120 end
    local rows = spec.rows
    if #rows > 14 then rows = { unpack(rows, 1, 14) } end
    h = h + #rows * 46
    local docLines = {}
    if spec.docLines then
        for _, l in ipairs(spec.docLines) do
            for _, wrapped in ipairs(UI.Wrap(l.text, l.head and "symchars.world.h" or "symchars.world.body", w - pad * 2)) do
                docLines[#docLines + 1] = { text = wrapped, head = l.head }
                if #docLines >= 18 then break end
            end
            if #docLines >= 18 then break end
        end
        for _, l in ipairs(docLines) do h = h + (l.head and 50 or 36) end
    end
    local extraLines = spec.extra and UI.Wrap(spec.extra, "symchars.world.small", w - pad * 2) or {}
    h = h + #extraLines * 30
    if spec.footer then h = h + 60 end

    local scale = cfg.width / PX_W
    local ang = ent:GetAngles()
    local pos = ent:GetPos() + ang:Up() * 8
    local drawAng = Angle(ang.p, ang.y, ang.r)
    drawAng:RotateAroundAxis(drawAng:Up(), 90)
    drawAng:RotateAroundAxis(drawAng:Forward(), 90)
    -- x-Achse der Tafel zeigt nach links (aus Sicht der Entity), daher beginnt die Tafel rechts
    local origin = pos + ang:Up() * (h * scale) + ang:Right() * (w * scale / 2)

    -- Lichtkegel von der Platte zur Tafel
    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
    render.SetMaterial(BEAM)
    local right = ang:Right()
    local up = ang:Up()
    local base = ent:GetPos() + up * 1
    local top = pos + up * 2
    local halfW = w * scale / 2
    render.DrawQuad(top - right * halfW, top + right * halfW, base + right * 4, base - right * 4, Color(col.r, col.g, col.b, 40 * a))
    render.DrawQuad(base - right * 4, base + right * 4, top + right * halfW, top - right * halfW, Color(col.r, col.g, col.b, 40 * a))
    render.SetMaterial(GLOW)
    render.DrawSprite(base + up * 2, 24, 8, Color(col.r, col.g, col.b, 200 * a))
    render.OverrideBlend(false)

    local jitter = (flick < 0.7) and math.random(-3, 3) or 0

    cam.Start3D2D(origin, drawAng, scale)
        surface.SetAlphaMultiplier(a)
        local x0 = jitter
        UI.Box(x0, 0, w, h, Color(col.r * 0.12, col.g * 0.18, col.b * 0.25, 170))
        surface.SetDrawColor(col.r, col.g, col.b, 255)
        surface.SetMaterial(BEAM)
        surface.DrawTexturedRect(x0, 0, w, h)
        UI.Box(x0, 0, w, h, Color(4, 8, 14, 150))
        UI.Outline(x0, 0, w, h, Color(col.r, col.g, col.b, 230), 3)
        UI.Box(x0, 0, w, 6, Color(col.r, col.g, col.b, 255))
        for yy = 0, h, 6 do UI.Box(x0, yy, w, 2, Color(0, 0, 0, 55)) end
        local scanY = (CurTime() * 120 + ent:EntIndex() * 40) % (h + 80) - 40
        UI.Box(x0, scanY, w, 10, Color(col.r, col.g, col.b, 40))

        local tx = x0 + pad
        local y = 26
        if spec.faction then
            UI.DrawUnitLogo(spec.faction, tx, y, 110)
            tx = tx + 130
        end
        UI.TextFit(string.upper(spec.title or ""), "symchars.world.title", tx, y - 6, Color(255, 255, 255), x0 + w - tx - pad)
        UI.Aurebesh(spec.title or "", "symchars.world.aure", tx + 2, y + 60, Color(col.r, col.g, col.b, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, x0 + w - tx - pad)
        if spec.sub then UI.TextFit(spec.sub, "symchars.world.small", tx, y + 92, Color(200, 220, 235), x0 + w - tx - pad) end
        y = 170

        if spec.stats then
            local cw = (w - pad * 2 - 20) / #spec.stats
            for i, st in ipairs(spec.stats) do
                local sx = x0 + pad + (i - 1) * (cw + 10)
                UI.Box(sx, y, cw, 100, Color(col.r, col.g, col.b, 40))
                UI.Box(sx, y, 4, 100, Color(col.r, col.g, col.b, 255))
                UI.Text(tostring(st[2]), "symchars.world.title", sx + 20, y + 4, color_white)
                UI.Text(string.upper(st[1]), "symchars.world.small", sx + 20, y + 68, Color(190, 210, 225))
            end
            y = y + 120
        end

        for _, line in ipairs(textLines) do
            UI.Text(line, "symchars.world.body", x0 + pad, y, Color(215, 228, 238))
            y = y + 36
        end

        for i, row in ipairs(rows) do
            UI.Box(x0 + pad, y, w - pad * 2, 40, i % 2 == 0 and Color(255, 255, 255, 10) or Color(0, 0, 0, 0))
            if row.col then UI.Box(x0 + pad, y + 6, 4, 28, row.col) end
            UI.TextFit(row.text, "symchars.world.name", x0 + pad + 16, y + 20, color_white, w * 0.6, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            UI.TextFit(row.value or "", "symchars.world.small", x0 + w - pad - 8, y + 20, row.col or Color(200, 220, 235), w * 0.3, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            y = y + 46
        end

        for _, l in ipairs(docLines) do
            UI.Text(l.text, l.head and "symchars.world.h" or "symchars.world.body", x0 + pad, y, l.head and color_white or Color(215, 228, 238))
            y = y + (l.head and 50 or 36)
        end

        for _, line in ipairs(extraLines) do
            UI.Text(line, "symchars.world.small", x0 + pad, y, Color(190, 210, 225))
            y = y + 30
        end

        if spec.footer then
            UI.Box(x0 + pad, h - 58, w - pad * 2, 2, Color(col.r, col.g, col.b, 120))
            UI.Text(spec.footer, "symchars.world.small", x0 + w / 2, h - 30, Color(col.r, col.g, col.b, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        surface.SetAlphaMultiplier(1)
    cam.End3D2D()
end

---------------------------------------------------------------------------------------------------------------
-- Projektor
---------------------------------------------------------------------------------------------------------------
local projectorModels = {}

local function ProjectorModel(ent, path)
    local cm = projectorModels[ent]
    if IsValid(cm) and cm.path == path then return cm end
    if IsValid(cm) then cm:Remove() end
    cm = ClientsideModel(path, RENDERGROUP_TRANSLUCENT)
    if not IsValid(cm) then return nil end
    cm:SetNoDraw(true)
    cm.path = path
    for _, name in ipairs({ "idle_all_01", "idle_passive", "idle_subtle", "pose_standing_02" }) do
        local seq = cm:LookupSequence(name)
        if seq and seq > 0 then cm:ResetSequence(seq) break end
    end
    cm.born = CurTime()
    projectorModels[ent] = cm
    return cm
end

hook.Add("EntityRemoved", "symchars_holo_cleanup", function(ent)
    local cm = projectorModels[ent]
    if IsValid(cm) then cm:Remove() end
    projectorModels[ent] = nil
end)

local function DrawProjector(ent, cfg, alpha)
    local unit = F.Get(cfg.unit)
    local path = cfg.model ~= "" and cfg.model or (unit and unit:GetModel()) or "models/player/kleiner.mdl"
    local cm = ProjectorModel(ent, path)
    if not IsValid(cm) then return end

    local col = cfg.color
    local base = ent:GetPos() + ent:GetUp() * 4
    local yaw = (cfg.spin > 0) and (CurTime() * cfg.spin) % 360 or ent:GetAngles().y
    cm:SetModelScale(cfg.size, 0)
    cm:SetPos(base + ent:GetUp() * 2)
    cm:SetAngles(Angle(0, yaw, 0))
    cm:FrameAdvance(FrameTime())
    cm:SetupBones()

    local mins, maxs = cm:GetRenderBounds()
    local bottom = base.z + 2 + mins.z * cfg.size
    local top = base.z + 2 + maxs.z * cfg.size
    local age = (CurTime() - (cm.born or 0)) / 1.6
    local cut = Lerp(math.Clamp(age, 0, 1), bottom, top + 4)

    local flicker = math.random() < 0.02 and 0.45 or 1
    local a = alpha * flicker

    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
    render.SetMaterial(RING)
    render.DrawQuadEasy(base + UP * 0.5, UP, 44 * cfg.size, 44 * cfg.size, Color(col.r, col.g, col.b, 200 * alpha), CurTime() * 25)
    render.SetMaterial(GLOW)
    render.DrawQuadEasy(base + UP * 0.6, UP, 70 * cfg.size, 70 * cfg.size, Color(col.r, col.g, col.b, 120 * alpha), 0)
    -- Lichtkegel, zur Kamera gedreht
    local toEye = (EyePos() - base)
    toEye.z = 0
    toEye:Normalize()
    local side = toEye:Cross(UP)
    local hgt = (top - bottom) * 1.05
    render.SetMaterial(BEAM)
    render.DrawQuad(base + UP * hgt - side * 22 * cfg.size, base + UP * hgt + side * 22 * cfg.size, base + side * 6 * cfg.size, base - side * 6 * cfg.size, Color(col.r, col.g, col.b, 35 * alpha))
    render.OverrideBlend(false)

    local clipping = render.EnableClipping(true)
    render.PushCustomClipPlane(DOWN, -cut)
    render.MaterialOverride(WHITE)
    render.SetColorModulation(col.r / 255, col.g / 255, col.b / 255)
    render.SetBlend(0.45 * a)
    cm:DrawModel()
    render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
    render.MaterialOverride(WIRE)
    render.SetBlend(0.3 * a)
    cm:DrawModel()
    render.OverrideBlend(false)
    render.PopCustomClipPlane()

    local bandZ = bottom - 4 + ((CurTime() * 16) % (top - bottom + 8))
    if bandZ < cut then
        render.PushCustomClipPlane(DOWN, -(bandZ + 1.2))
        render.PushCustomClipPlane(UP, bandZ - 1.2)
        render.OverrideBlend(true, BLEND_SRC_ALPHA, BLEND_ONE, BLENDFUNC_ADD)
        render.MaterialOverride(WHITE)
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(0.5 * a)
        cm:DrawModel()
        render.OverrideBlend(false)
        render.PopCustomClipPlane()
        render.PopCustomClipPlane()
    end
    render.MaterialOverride()
    render.SetColorModulation(1, 1, 1)
    render.SetBlend(1)
    render.EnableClipping(clipping)

    if cfg.label and unit then
        local labelPos = Vector(base.x, base.y, top + 10)
        local ang = Angle(0, EyeAngles().y - 90, 90)
        cam.Start3D2D(labelPos, ang, 0.08)
            surface.SetAlphaMultiplier(alpha)
            UI.Text(string.upper(unit.name), "symchars.world.title", 0, 0, Color(col.r, col.g, col.b), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            UI.Aurebesh(unit.name, "symchars.world.aure", 0, 6, Color(col.r, col.g, col.b, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            surface.SetAlphaMultiplier(1)
        cam.End3D2D()
    end
end

---------------------------------------------------------------------------------------------------------------
-- Terminal
---------------------------------------------------------------------------------------------------------------
local TAB_NAMES = {}
for _, t in ipairs(H.TERMINAL_TABS) do TAB_NAMES[t.id] = t.name end

local function DrawTerminal(ent, cfg, alpha)
    local pos = ent:GetPos() + ent:GetUp() * (ent:OBBMaxs().z + 10)
    local ang = Angle(0, EyeAngles().y - 90, 90)
    local col = UI.Holo()
    local title = cfg.title ~= "" and cfg.title or ("Terminal: " .. (TAB_NAMES[cfg.tab] or ""))
    cam.Start3D2D(pos, ang, 0.06)
        surface.SetAlphaMultiplier(alpha)
        local w = math.max(420, UI.TextSize(string.upper(title), "symchars.world.h") + 80)
        UI.Box(-w / 2, -70, w, 110, Color(4, 8, 14, 190))
        UI.Outline(-w / 2, -70, w, 110, Color(col.r, col.g, col.b, 220), 2)
        UI.Box(-w / 2, -70, w, 5, Color(col.r, col.g, col.b, 255))
        UI.Text(string.upper(title), "symchars.world.h", 0, -58, color_white, TEXT_ALIGN_CENTER)
        UI.Text("[E]  Öffnen", "symchars.world.small", 0, 0, Color(col.r, col.g, col.b), TEXT_ALIGN_CENTER)
        surface.SetAlphaMultiplier(1)
    cam.End3D2D()
end

---------------------------------------------------------------------------------------------------------------
-- Einstieg aus der Entity
---------------------------------------------------------------------------------------------------------------
function H.DrawEntity(ent, translucent)
    local class = ent:GetClass()
    local cfg = H.GetConfig(ent)
    if not translucent then
        if class == "symchars_holo_display" then
            -- Platte nur zeigen, wenn man sie bearbeitet (Physgun/Toolgun) oder sie nicht gespeichert ist
            local wep = LocalPlayer():GetActiveWeapon()
            local editing = IsValid(wep) and (wep:GetClass() == "weapon_physgun" or wep:GetClass() == "gmod_tool")
            if editing or not ent:GetSymSaved() then ent:DrawModel() end
        else
            ent:DrawModel()
        end
        return
    end

    if class == "symchars_holo_display" then
        local alpha = Fade(ent, cfg.range or 900)
        if alpha > 0 then DrawPanel(ent, cfg, alpha) end
    elseif class == "symchars_holo_projector" then
        local alpha = Fade(ent, cfg.range or 1500)
        if alpha > 0 then DrawProjector(ent, cfg, alpha) end
    elseif class == "symchars_terminal" then
        local alpha = Fade(ent, 400)
        if alpha > 0 then DrawTerminal(ent, cfg, alpha) end
    end
end
