--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Benachrichtigungen, Einladungen, Einblendungen
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local S = UI.S

local notes = {}

local KINDS = {
    info = { col = function() return UI.Accent() end, icon = "info" },
    succ = { col = function() return UI.col.green end, icon = "check" },
    error = { col = function() return UI.col.red end, icon = "warn" },
}

function symchars.Notify(a, b, c, d)
    local text, typ, len
    if isstring(a) then
        text, typ, len = a, b, c
    else
        text, typ, len = b, c, d
    end
    if not text or text == "" then return end
    typ = KINDS[typ] and typ or "info"
    table.insert(notes, 1, { text = tostring(text), typ = typ, start = RealTime(), len = math.Clamp(tonumber(len) or 4.5, 1, 30), y = nil })
    while #notes > 6 do table.remove(notes) end
    UI.Sound(typ == "error" and "error" or "notify")
end

symchars.net.Receive("notify", function(data)
    if istable(data) then symchars.Notify(data.t, data.k, data.l) end
end)

hook.Add("DrawOverlay", "symchars_notify", function()
    if #notes == 0 then return end
    local w = S(440)
    local x = ScrW() - w - S(24)
    local baseY = ScrH() - S(120)
    local now = RealTime()

    for i = #notes, 1, -1 do
        local n = notes[i]
        if now - n.start > n.len + 0.4 then table.remove(notes, i) end
    end

    local y = baseY
    for _, n in ipairs(notes) do
        local lines = UI.Wrap(n.text, "symchars.body", w - S(70))
        local _, lh = UI.TextSize("Ag", "symchars.body")
        local h = math.max(S(56), #lines * lh + S(22))
        y = y - h - S(8)
        n.y = n.y and Lerp(math.min(FrameTime() * 12, 1), n.y, y) or y + S(30)

        local age = now - n.start
        local alpha = math.min(1, age * 5) * math.Clamp((n.len + 0.4 - age) / 0.4, 0, 1)
        local slide = (1 - math.min(1, age * 5)) * S(60)
        local col = KINDS[n.typ].col()
        local nx, ny = x + slide, n.y

        surface.SetAlphaMultiplier(alpha)
        UI.Cut(nx, ny, w, h, Color(9, 11, 14, 245), S(10), "tlbr")
        UI.CutOutline(nx, ny, w, h, UI.Alpha(col, 160), S(10), "tlbr")
        UI.Box(nx, ny + S(10), S(4), h - S(20), col)
        UI.Icon(KINDS[n.typ].icon, nx + S(16), ny + h / 2 - S(14), S(28), col)
        for li, line in ipairs(lines) do
            UI.Text(line, "symchars.body", nx + S(56), ny + S(11) + (li - 1) * lh, UI.col.text)
        end
        local frac = math.Clamp(1 - age / n.len, 0, 1)
        UI.Box(nx + S(10), ny + h - S(3), (w - S(20)) * frac, S(2), UI.Alpha(col, 140))
        surface.SetAlphaMultiplier(1)
    end
end)

---------------------------------------------------------------------------------------------------------------
-- Einladung in eine Einheit
---------------------------------------------------------------------------------------------------------------
symchars.net.Receive("invite", function(data)
    if not istable(data) then return end
    local faction = symchars.factions.Get(data.unit)
    local name = faction and symchars.factions.GetDisplayName(faction) or tostring(data.unit)
    if IsValid(UI.invitePanel) then UI.invitePanel:Remove() end

    local p = vgui.Create("DPanel")
    UI.invitePanel = p
    p:SetSize(S(520), S(220))
    p:SetPos(ScrW() / 2 - S(260), S(90))
    p:MakePopup()
    p:SetKeyboardInputEnabled(false)
    local start, duration = RealTime(), tonumber(data.time) or 60

    p.Paint = function(_, w, h)
        UI.Cut(0, 0, w, h, Color(9, 11, 14, 248), S(14), "tlbr")
        UI.CutOutline(0, 0, w, h, UI.Accent(170), S(14), "tlbr")
        UI.Glow(0, 0, w, h, UI.Accent(120), S(10), 0.6)
        UI.Text("EINLADUNG", "symchars.h2", S(22), S(14), UI.Accent())
        UI.Aurebesh("Einladung", "symchars.aure.small", S(24), S(46), UI.Alpha(UI.col.dim, 120))
        if faction then UI.DrawUnitLogo(faction, w - S(96), S(16), S(76)) end
        UI.TextFit(tostring(data.by) .. " lädt dich ein in:", "symchars.body", S(22), S(74), UI.col.dim, w - S(130))
        UI.TextFit(name, "symchars.name.small", S(22), S(100), UI.col.text, w - S(130))
        local frac = math.Clamp(1 - (RealTime() - start) / duration, 0, 1)
        UI.Box(S(22), h - S(10), (w - S(44)) * frac, S(3), UI.Accent())
        if frac <= 0 then p:Remove() end
    end

    local no = UI.Button(p, "Ablehnen", "danger", function()
        symchars.net.SendToServer("invite_answer", { accept = false })
        p:Remove()
    end)
    no:SetPos(S(22), S(146))
    no:SetSize(S(200), S(46))

    local yes = UI.Button(p, "Annehmen", "primary", function()
        symchars.net.SendToServer("invite_answer", { accept = true })
        p:Remove()
    end)
    yes:SetPos(S(520) - S(22) - S(240), S(146))
    yes:SetSize(S(240), S(46))
    UI.Sound("open")
end)

---------------------------------------------------------------------------------------------------------------
-- "Fortbildung bestanden" (Holo-Einblendung)
---------------------------------------------------------------------------------------------------------------
local banner

symchars.net.Receive("training_passed", function(data)
    local t = symchars.trainings.Get(istable(data) and data.id)
    if not t then return end
    banner = { t = t, start = RealTime() }
    surface.PlaySound("buttons/button3.wav")
end)

hook.Add("HUDPaint", "symchars_training_banner", function()
    if not banner then return end
    local age = RealTime() - banner.start
    if age > 6 then banner = nil return end
    local alpha = math.min(1, age * 3) * math.Clamp((6 - age) / 0.6, 0, 1)
    local holo = UI.Holo()
    local w, h = S(620), S(150)
    local x, y = ScrW() / 2 - w / 2, ScrH() * 0.18

    surface.SetAlphaMultiplier(alpha)
    local flick = (math.random() > 0.97) and 0.6 or 1
    UI.Gradient(x, y, w, h, UI.Alpha(holo, 70 * flick), "up")
    UI.Outline(x, y, w, h, UI.Alpha(holo, 200 * flick))
    UI.Scanlines(x, y, w, h, 60)
    local reveal = math.Clamp(age * 1.5, 0, 1)
    render.SetScissorRect(x, y, x + w * reveal, y + h, true)
    UI.Text("FORTBILDUNG BESTANDEN", "symchars.h2", x + w / 2, y + S(16), UI.Alpha(holo, 255), TEXT_ALIGN_CENTER)
    UI.Text(string.upper(banner.t.name), "symchars.title", x + w / 2, y + S(50), color_white, TEXT_ALIGN_CENTER)
    UI.Aurebesh(banner.t.name, "symchars.aure", x + w / 2, y + h - S(28), UI.Alpha(holo, 200), TEXT_ALIGN_CENTER)
    render.SetScissorRect(0, 0, 0, 0, false)
    UI.Box(x + w * reveal - S(2), y, S(3), h, UI.Alpha(color_white, 200 * (1 - math.min(1, age))))
    surface.SetAlphaMultiplier(1)
end)
