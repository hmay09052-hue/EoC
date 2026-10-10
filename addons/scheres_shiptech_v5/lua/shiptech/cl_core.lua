--[[
    ShipTech – Client: Synchronisation, Schriften, Chat, HUD (Alarme, Fortschritt, Stromausfall)
]]

local C = ShipTech.Config
ShipTech.Data = ShipTech.Data or {}

---------------------------------------------------------------------------
-- Schriften
---------------------------------------------------------------------------
-- Design wie das Charaktersystem (EOCUI): BigNoodleTitling für Überschriften, Roboto Condensed für Text
local HEAD, BODY = "BigNoodleTitling", "Roboto Condensed"
local function Head(name, size)
    surface.CreateFont(name, { font = HEAD, size = size, weight = 500, antialias = true, extended = true })
end
local function Body(name, size, weight)
    surface.CreateFont(name, { font = BODY, size = size, weight = weight or 500, antialias = true, extended = true })
end
Head("ShipTech_HoloTitle", 64)
Body("ShipTech_HoloText", 28, 600)
Body("ShipTech_HoloSmall", 22, 600)
Head("ShipTech_HoloBig", 120)
Head("ShipTech_HoloMed", 46)
Head("ShipTech_UITitle", 40)
Body("ShipTech_UI", 18, 500)
Body("ShipTech_UISmall", 15, 500)
Head("ShipTech_UIBold", 24)
Head("ShipTech_UIBig", 60)
Head("ShipTech_UIMed", 32)
Body("ShipTech_UISub", 13, 800)
Body("ShipTech_UISection", 14, 800)
Head("ShipTech_HUD", 32)
Body("ShipTech_HUDSmall", 15, 600)
Head("ShipTech_Tab", 34)
Head("ShipTech_TabS", 28)

-- Farbpalette (identisch zum Charaktersystem)
local E = EOCUI and EOCUI.col or {}
ShipTech.Colors = {
    yellow  = Color(252, 178, 73),
    yellowD = Color(252, 178, 73, 56),
    yellowF = Color(252, 178, 73, 22),
    white   = E.text or Color(236, 233, 224),
    text    = E.text or Color(236, 233, 224),
    soft    = E.dim or Color(168, 174, 180),
    muted   = E.muted or Color(112, 119, 127),
    bg      = Color(6, 8, 11, 245),
    panel   = E.panel or Color(11, 14, 18, 232),
    panel2  = E.panel2 or Color(18, 22, 28, 240),
    panel3  = E.panel3 or Color(27, 32, 40, 245),
    line    = E.line or Color(255, 255, 255, 22),
    lineS   = E.line2 or Color(255, 255, 255, 50),
    red     = Color(205, 62, 56),
    green   = Color(95, 200, 120),
    blue    = Color(80, 170, 230),
    cyan    = Color(64, 196, 255),
    orange  = Color(240, 140, 60),
    cream   = E.cream or Color(231, 225, 213),
    ink     = E.ink or Color(18, 21, 25),
}
local P = ShipTech.Colors
-- flaches Panel mit dünnem Rahmen
function ShipTech.Box(x, y, w, h, col, outline)
    surface.SetDrawColor(col or P.panel)
    surface.DrawRect(x, y, w, h)
    if outline ~= false then
        surface.SetDrawColor(P.line)
        surface.DrawOutlinedRect(x, y, w, h, 1)
    end
end

---------------------------------------------------------------------------
-- Zustand empfangen
---------------------------------------------------------------------------
net.Receive("ShipTech_State", function()
    local len = net.ReadUInt(32)
    local json = util.Decompress(net.ReadData(len))
    if not json then return end
    local t = util.JSONToTable(json)
    if not t then return end

    local old = ShipTech.State
    ShipTech.State = t
    if old then
        local before = 0
        for i = 1, 4 do before = before + ((old.shields and old.shields.sectors and old.shields.sectors[i]) or 0) end
        if ShipTech.GetShieldPercent() < before / 4 - 2 then ShipTech.ShieldFlash = RealTime() end
    end
    hook.Run("ShipTech_StateUpdated", t, old)
end)

-- Nur geänderte Teile ("sys.<id>" oder oberste Schlüssel) werden übertragen
net.Receive("ShipTech_Delta", function()
    local len = net.ReadUInt(32)
    local json = util.Decompress(net.ReadData(len))
    local S = ShipTech.State
    if not json or not S then return end
    local delta = util.JSONToTable(json)
    if not delta then return end
    local before = ShipTech.GetShieldPercent()
    for k, v in pairs(delta) do
        if string.sub(k, 1, 4) == "sys." then
            S.systems[string.sub(k, 5)] = v
        else
            S[k] = v
        end
    end
    if ShipTech.GetShieldPercent() < before - 2 then ShipTech.ShieldFlash = RealTime() end
    hook.Run("ShipTech_StateUpdated", S)
end)

-- Ingame-Konfiguration vom Server übernehmen
net.Receive("ShipTech_ConfigSync", function()
    local t = util.JSONToTable(net.ReadString()) or {}
    for k, def in pairs(ShipTech.ConfigDefaults) do
        if t[k] == nil then ShipTech.SetConfigValue(k, istable(def) and table.Copy(def) or def) end
    end
    for k, v in pairs(t) do ShipTech.SetConfigValue(k, v) end
    ShipTech.ConfigOverrides = t
    hook.Run("ShipTech_ConfigUpdated")
end)

net.Receive("ShipTech_Data", function()
    local kind = net.ReadString()
    local len = net.ReadUInt(32)
    local json = util.Decompress(net.ReadData(len))
    ShipTech.Data[kind] = (json and util.JSONToTable(json)) or {}
    hook.Run("ShipTech_DataUpdated", kind)
end)

function ShipTech.SendAction(action, ent, args)
    net.Start("ShipTech_Action")
    net.WriteString(action)
    net.WriteEntity(ent)
    net.WriteString(util.TableToJSON(args or {}))
    net.SendToServer()
end

function ShipTech.SendEvent(action, args)
    net.Start("ShipTech_EventAction")
    net.WriteString(action)
    net.WriteString(util.TableToJSON(args or {}))
    net.SendToServer()
end

function ShipTech.RequestData(kind)
    net.Start("ShipTech_RequestData")
    net.WriteString(kind)
    net.SendToServer()
end

---------------------------------------------------------------------------
-- Chat & Benachrichtigungen
---------------------------------------------------------------------------
local chatStyle = {
    reactor = { "REAKTOR",         P.cyan },
    info    = { "TECHNIK",         P.yellow },
    warn    = { "WARNUNG",         P.orange },
    crit    = { "ALARM",           P.red },
    order   = { "WARTUNGSAUFTRAG", P.blue },
    event   = { "EVENT",           P.yellow },
    navy    = { "NAVY",            P.blue },
}

net.Receive("ShipTech_Chat", function()
    local kind = net.ReadString()
    local text = net.ReadString()
    local st = chatStyle[kind] or chatStyle.info
    chat.AddText(st[2], "[" .. st[1] .. "] ", P.white, text)
    if kind == "crit" then
        surface.PlaySound("buttons/blip1.wav")
    elseif kind == "reactor" then
        surface.PlaySound("buttons/button17.wav")
    end
end)

net.Receive("ShipTech_Notify", function()
    local text = net.ReadString()
    local typ = net.ReadUInt(3)
    notification.AddLegacy(text, typ, 5)
    surface.PlaySound(typ == 1 and "buttons/button10.wav" or "buttons/button15.wav")
end)

net.Receive("ShipTech_FX", function()
    local kind = net.ReadString()
    if kind == "hit" then
        surface.PlaySound(C.Sounds.Hit)
        util.ScreenShake(LocalPlayer():GetPos(), 8, 6, 1.4, 1000)
    elseif kind == "shieldhit" then
        ShipTech.ShieldFlash = RealTime()
        surface.PlaySound(C.Sounds.ShieldHit)
        util.ScreenShake(LocalPlayer():GetPos(), 2, 4, 0.6, 1000)
    end
end)

---------------------------------------------------------------------------
-- Fortschrittsbalken
---------------------------------------------------------------------------
local prog
net.Receive("ShipTech_Progress", function()
    local label = net.ReadString()
    local dur = net.ReadFloat()
    if dur <= 0 then prog = nil else prog = { label = label, start = CurTime(), dur = dur } end
end)

hook.Add("HUDPaint", "ShipTech_Progress", function()
    if not prog then return end
    local f = math.Clamp((CurTime() - prog.start) / prog.dur, 0, 1)
    local w, h = 460, 58
    local x, y = ScrW() / 2 - w / 2, ScrH() * 0.72
    ShipTech.Box(x, y, w, h, P.bg)
    surface.SetDrawColor(P.yellow)
    surface.DrawRect(x, y, 2, h)
    draw.SimpleText(string.upper(prog.label), "ShipTech_UIBold", x + 14, y + 17, P.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    draw.SimpleText(math.floor(f * 100) .. " %", "ShipTech_UIBold", x + w - 12, y + 17, P.yellow, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    ShipTech.Box(x + 14, y + 36, w - 28, 10, P.panel2)
    surface.SetDrawColor(P.yellow)
    surface.DrawRect(x + 14, y + 36, (w - 28) * f, 10)
end)

---------------------------------------------------------------------------
-- Alarme: Banner, roter Rand, Sirene
---------------------------------------------------------------------------
local mute = CreateClientConVar("shiptech_alarm_mute", "0", true, false, "Alarmsirene stummschalten")
local nextSiren = 0

local function Vignette(alpha)
    local w, h = ScrW(), ScrH()
    for i = 0, 19 do
        local a = alpha * (1 - i / 20)
        surface.SetDrawColor(255, 0, 0, a)
        local d = i * 6
        surface.DrawRect(0, d, w, 6)
        surface.DrawRect(0, h - d - 6, w, 6)
        surface.DrawRect(d, 0, 6, h)
        surface.DrawRect(w - d - 6, 0, 6, h)
    end
end

hook.Add("HUDPaint", "ShipTech_Alarms", function()
    local S = ShipTech.State
    if not S then return end

    local list = {}
    for id, a in pairs(S.alarms or {}) do
        local def = ShipTech.AlarmTypes[id]
        if def then list[#list + 1] = { def = def, a = a } end
    end
    table.sort(list, function(x, y) return x.def.prio < y.def.prio end)

    local y = 12
    if S.combat then
        local p = math.abs(math.sin(RealTime() * 2.5))
        ShipTech.Box(ScrW() / 2 - 150, y, 300, 34, P.bg)
        surface.SetDrawColor(225, 88, 88, 120 + 135 * p)
        surface.DrawRect(ScrW() / 2 - 150, y + 32, 300, 2)
        draw.SimpleText("GEFECHTSALARM", "ShipTech_HUD", ScrW() / 2, y + 17, P.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 42
    end
    if #list == 0 then return end

    local pulse = math.abs(math.sin(RealTime() * 3))
    Vignette(22 * pulse)

    for i, e in ipairs(list) do
        if i > 3 then break end
        local title = e.def.name .. ((e.a.info and e.a.info ~= "") and (" – " .. e.a.info) or "")
        surface.SetFont("ShipTech_HUD")
        local tw = surface.GetTextSize(title)
        surface.SetFont("ShipTech_HUDSmall")
        local pw = surface.GetTextSize(e.def.protocol)
        local w = math.max(tw, pw) + 48
        local x = ScrW() / 2 - w / 2
        ShipTech.Box(x, y, w, 58, P.bg)
        surface.SetDrawColor(225, 88, 88, 120 + 135 * pulse)
        surface.DrawRect(x, y, 2, 58)
        surface.DrawRect(x, y + 56, w, 2)
        surface.DrawRect(x, y, 14, 2)
        surface.DrawRect(x + w - 2, y + 44, 2, 14)
        draw.SimpleText(title, "ShipTech_HUD", ScrW() / 2, y + 19, P.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(e.def.protocol, "ShipTech_HUDSmall", ScrW() / 2, y + 42, P.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        y = y + 64
    end

    if RealTime() > nextSiren and not mute:GetBool() then
        nextSiren = RealTime() + C.AlarmSoundInterval
        LocalPlayer():EmitSound(C.Sounds.Alarm, 75, 100, C.AlarmVolume)
    end
end)

---------------------------------------------------------------------------
-- Stromausfall: Abdunkeln in betroffenen Sektoren
---------------------------------------------------------------------------
hook.Add("RenderScreenspaceEffects", "ShipTech_Blackout", function()
    local S = ShipTech.State
    if not S then return end
    local dark = 0

    if C.GlobalBlackoutEffect and S.supply and (S.supply.output or 1) <= 0 then dark = 0.8 end

    if #(S.outages or {}) > 0 then
        local pos = LocalPlayer():GetPos()
        for _, b in ipairs(ShipTech.ConsoleList("breaker")) do
            if ShipTech.IsOutage(b:GetSector()) then
                local d = pos:Distance(b:GetPos())
                if d < C.BreakerRadius then
                    dark = math.max(dark, math.Clamp((C.BreakerRadius - d) / 200, 0, 1))
                end
            end
        end
    end
    if dark <= 0 then return end

    local flicker = 0.04 * math.max(0, math.sin(RealTime() * 1.3))  -- sanftes Pulsieren statt zufälliger Blitze
    DrawColorModify({
        ["$pp_colour_addr"] = 0, ["$pp_colour_addg"] = 0, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = -0.13 * dark + flicker * dark,
        ["$pp_colour_contrast"] = 1 - 0.45 * dark,
        ["$pp_colour_colour"] = 1 - 0.6 * dark,
        ["$pp_colour_mulr"] = 0, ["$pp_colour_mulg"] = 0, ["$pp_colour_mulb"] = 0,
    })
end)
