EoCSport = EoCSport or {}

local C = EoCSport.Config
local States = EoCSport.States

---------------------------------------------------------------------------
-- Design (wie die anderen EoC-Addons)
---------------------------------------------------------------------------
local T = {
    bg = Color(12, 15, 20, 235),
    panel = Color(20, 24, 31, 245),
    panel2 = Color(30, 35, 44, 255),
    hover = Color(40, 46, 57, 255),
    line = Color(255, 255, 255, 14),
    accent = Color(255, 190, 50),
    accentDim = Color(255, 190, 50, 40),
    text = Color(230, 234, 240),
    muted = Color(145, 153, 166),
    green = Color(95, 205, 115),
    red = Color(225, 85, 70),
}
EoCSport.Theme = T

surface.CreateFont("EoCSport_Huge", { font = "Bebas Neue", size = 120, weight = 500, extended = true })
surface.CreateFont("EoCSport_Title", { font = "Bebas Neue", size = 36, weight = 500, extended = true })
surface.CreateFont("EoCSport_Counter", { font = "Bebas Neue", size = 40, weight = 500, extended = true })
surface.CreateFont("EoCSport_Head", { font = "Bebas Neue", size = 24, weight = 500, extended = true })
surface.CreateFont("EoCSport_Sign", { font = "Bebas Neue", size = 52, weight = 500, extended = true })
surface.CreateFont("EoCSport_Text", { font = "Montserrat", size = 16, weight = 500, extended = true })
surface.CreateFont("EoCSport_TextBold", { font = "Montserrat", size = 16, weight = 700, extended = true })
surface.CreateFont("EoCSport_Small", { font = "Montserrat", size = 13, weight = 500, extended = true })

function EoCSport.Chat(msg)
    chat.AddText(T.accent, "[Sport] ", T.text, msg)
end

net.Receive("EoCSport_Notify", function()
    EoCSport.Chat(net.ReadString())
end)

hook.Add("EoCSport_LocalStopped", "EoCSport_Hud", function(st, reason)
    if st.group and (reason == "group" or reason == "cancel") then return end
    local ex = EoCSport.GetExercise(st.id)
    if not ex then return end
    local why = EoCSport.StopReasons[reason] or reason
    EoCSport.Chat(ex.name .. ": " .. EoCSport.FormatCount(ex, st.count, st.target) .. " – " .. why .. ".")
end)

local NUMBERS = { "EINS", "ZWEI", "DREI", "VIER", "FÜNF", "SECHS", "SIEBEN", "ACHT", "NEUN", "ZEHN" }

---------------------------------------------------------------------------
-- Gruppen-Nachrichten
---------------------------------------------------------------------------
net.Receive("EoCSport_Group", function()
    local op = net.ReadUInt(4)

    if op == EoCSport.G_INVITE then
        EoCSport.Invite = {
            leader = net.ReadString(),
            exId = net.ReadString(),
            target = net.ReadUInt(16),
            endTime = net.ReadFloat(),
            tempo = net.ReadBool(),
        }
        surface.PlaySound("buttons/blip1.wav")

    elseif op == EoCSport.G_INVITE_END then
        EoCSport.Invite = nil

    elseif op == EoCSport.G_COUNTDOWN then
        EoCSport.Countdown = {
            startAt = net.ReadFloat(),
            exId = net.ReadString(),
            target = net.ReadUInt(16),
            tempo = net.ReadBool(),
            lastSecond = -1,
        }
        EoCSport.Beat = nil

    elseif op == EoCSport.G_BEAT then
        EoCSport.Beat = { n = net.ReadUInt(16), time = net.ReadFloat(), shown = CurTime() }
        surface.PlaySound("buttons/blip2.wav")

    elseif op == EoCSport.G_EARLY then
        EoCSport.EarlyFlash = CurTime()
        surface.PlaySound("buttons/button10.wav")

    elseif op == EoCSport.G_LIST then
        local g = {
            state = net.ReadString(),
            exId = net.ReadString(),
            target = net.ReadUInt(16),
            tempo = net.ReadBool(),
            startAt = net.ReadFloat(),
            inviteEnd = net.ReadFloat(),
            beat = net.ReadUInt(16),
            entries = {},
        }
        for i = 1, net.ReadUInt(8) do
            g.entries[i] = {
                name = net.ReadString(),
                count = net.ReadUInt(16),
                state = EoCSport.MemberStates[net.ReadUInt(4)] or "?",
                doneTime = net.ReadFloat(),
            }
        end
        EoCSport.LeaderGroup = g

    elseif op == EoCSport.G_RESULT then
        local r = {
            exId = net.ReadString(),
            target = net.ReadUInt(16),
            cancelled = net.ReadBool(),
            leader = net.ReadString(),
            entries = {},
            showUntil = CurTime() + C.Group.ResultTime,
        }
        for i = 1, net.ReadUInt(8) do
            r.entries[i] = {
                name = net.ReadString(),
                count = net.ReadUInt(16),
                points = net.ReadUInt(16),
                state = EoCSport.MemberStates[net.ReadUInt(4)] or "?",
                doneTime = net.ReadFloat(),
            }
        end
        EoCSport.Result = r
        EoCSport.Countdown = nil
        EoCSport.Beat = nil

    elseif op == EoCSport.G_LEADER_END then
        EoCSport.LeaderGroup = nil
        EoCSport.Countdown = nil

    elseif op == EoCSport.G_PENALTY then
        EoCSport.MyPenalty = { id = net.ReadString(), count = net.ReadUInt(16), by = net.ReadString() }
        surface.PlaySound("buttons/button17.wav")

    elseif op == EoCSport.G_PENALTY_CLEAR then
        EoCSport.MyPenalty = nil
    end
end)

---------------------------------------------------------------------------
-- Zeichen-Helfer
---------------------------------------------------------------------------
local function Box(x, y, w, h, line)
    surface.SetDrawColor(T.bg)
    surface.DrawRect(x, y, w, h)
    if line ~= false then
        surface.SetDrawColor(T.accent)
        surface.DrawRect(x, y, w, 2)
    end
end
EoCSport.DrawBox = Box

local function Text(str, font, x, y, col, ax, ay)
    draw.SimpleText(str, font, x, y, col or T.text, ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP)
end

local function FormatTime(sec)
    if not sec or sec < 0 then return "–" end
    return string.format("%d:%04.1f", math.floor(sec / 60), sec % 60)
end
EoCSport.FormatTime = FormatTime

local function HintFor(ex)
    if ex.mode == "hold" and ex.hold == "toggle" then
        return C.RepKeyName .. " – Start/Stopp · " .. C.EndKeyName .. " – beenden"
    elseif ex.mode == "hold" then
        return C.RepKeyName .. " halten – zählen · loslassen – beenden"
    end
    return C.RepKeyName .. " – Wiederholung · " .. C.EndKeyName .. " – beenden"
end

---------------------------------------------------------------------------
-- Balken unten in der Mitte
---------------------------------------------------------------------------
local function DrawExerciseBar(now)
    local st = States[LocalPlayer()]
    if not st or st.leaving then return end
    local ex = EoCSport.GetExercise(st.id)
    if not ex then return end

    local w, h = 480, 82
    local x, y = math.floor(ScrW() / 2 - w / 2), ScrH() - h - 36
    Box(x, y, w, h)

    Text(string.upper(ex.name), "EoCSport_Head", x + 16, y + 10, T.accent)
    Text(EoCSport.FormatCount(ex, st.count, st.target), "EoCSport_Counter", x + w - 16, y + 4, T.text, TEXT_ALIGN_RIGHT)

    local status = HintFor(ex)
    local col = T.muted
    if st.done then
        status, col = "Ziel erreicht – warte auf die Gruppe · " .. C.EndKeyName .. " – beenden", T.green
    elseif EoCSport.Countdown and now < EoCSport.Countdown.startAt then
        status = "Gleich geht's los …"
    elseif EoCSport.EarlyFlash and now - EoCSport.EarlyFlash < 0.8 then
        status, col = "Zu früh – nur im Takt drücken!", T.red
    elseif st.group and EoCSport.Countdown and EoCSport.Countdown.tempo then
        status = "Takt: " .. C.RepKeyName .. " erst auf das Kommando des Ausbilders"
    elseif ex.mode == "hold" and st.holding then
        col = T.text
    end
    Text(status, "EoCSport_Small", x + 16, y + 42, col)

    if st.target > 0 then
        local frac = math.Clamp(st.count / st.target, 0, 1)
        surface.SetDrawColor(T.line)
        surface.DrawRect(x + 16, y + h - 14, w - 32, 4)
        surface.SetDrawColor(st.done and T.green or T.accent)
        surface.DrawRect(x + 16, y + h - 14, math.floor((w - 32) * frac), 4)
    end
end

---------------------------------------------------------------------------
-- Aufforderung, Countdown, Takt, Auswertung, Strafrunde
---------------------------------------------------------------------------
local function DrawInvite(now)
    local inv = EoCSport.Invite
    if not inv then return end
    local left = inv.endTime - now
    if left <= 0 then return end
    local ex = EoCSport.GetExercise(inv.exId)
    if not ex then return end

    local w, h = 520, 96
    local x, y = math.floor(ScrW() / 2 - w / 2), math.floor(ScrH() * 0.22)
    Box(x, y, w, h)
    Text("GRUPPENTRAINING", "EoCSport_Head", x + 16, y + 10, T.accent)
    Text(math.ceil(left) .. " s", "EoCSport_Head", x + w - 16, y + 10, T.muted, TEXT_ALIGN_RIGHT)
    Text(inv.leader .. ": " .. EoCSport.FormatCount(ex, inv.target) .. " " .. ex.name .. (inv.tempo and " (im Takt)" or ""),
        "EoCSport_TextBold", x + 16, y + 40)
    Text(C.RepKeyName .. " – annehmen · " .. C.DeclineKeyName .. " – ablehnen", "EoCSport_Small", x + 16, y + 66, T.muted)

    surface.SetDrawColor(T.accent)
    surface.DrawRect(x, y + h - 3, math.floor(w * math.Clamp(left / C.Group.InviteTime, 0, 1)), 3)
end

local function DrawCountdown(now)
    local cd = EoCSport.Countdown
    if not cd then return end
    local left = cd.startAt - now
    local text
    if left > 0 then
        local sec = math.ceil(left)
        text = tostring(sec)
        if sec ~= cd.lastSecond then
            cd.lastSecond = sec
            surface.PlaySound("buttons/blip1.wav")
        end
    elseif left > -0.9 then
        text = "LOS!"
        if cd.lastSecond ~= 0 then
            cd.lastSecond = 0
            surface.PlaySound("buttons/button3.wav")
        end
    else
        return
    end
    draw.SimpleTextOutlined(text, "EoCSport_Huge", ScrW() / 2, ScrH() * 0.3, T.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 200))
end

local function DrawBeat(now)
    local b = EoCSport.Beat
    if not b then return end
    local age = now - b.shown
    if age > 0.9 then return end
    local alpha = math.Clamp(255 * (1 - age / 0.9), 0, 255)
    local text = (NUMBERS[b.n] or tostring(b.n)) .. "!"
    draw.SimpleTextOutlined(text, "EoCSport_Huge", ScrW() / 2, ScrH() * 0.3,
        Color(T.accent.r, T.accent.g, T.accent.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, alpha * 0.8))
end

local function DrawResult(now)
    local r = EoCSport.Result
    if not r then return end
    if now > r.showUntil then EoCSport.Result = nil return end
    local ex = EoCSport.GetExercise(r.exId)
    local rows = math.min(#r.entries, 10)
    local w, h = 460, 70 + rows * 22
    local x, y = math.floor(ScrW() / 2 - w / 2), math.floor(ScrH() * 0.12)
    Box(x, y, w, h)

    local title = "AUSWERTUNG" .. (r.cancelled and " (ABGEBROCHEN)" or "")
    Text(title, "EoCSport_Head", x + 16, y + 10, T.accent)
    Text((ex and ex.name or r.exId) .. " · Ziel " .. r.target .. " · " .. r.leader, "EoCSport_Small", x + w - 16, y + 15, T.muted, TEXT_ALIGN_RIGHT)

    local weighted = ex and (ex.groupWeight or 1) ~= 1
    for i = 1, rows do
        local e = r.entries[i]
        local ry = y + 44 + (i - 1) * 22
        local done = e.state == "done"
        Text(i .. ".  " .. e.name, "EoCSport_Text", x + 16, ry, done and T.text or T.muted)
        local info = e.count .. (weighted and (" (" .. e.points .. " P)") or "")
        Text(info, "EoCSport_TextBold", x + w - 120, ry, T.text, TEXT_ALIGN_RIGHT)
        Text(done and FormatTime(e.doneTime) or (EoCSport.MemberStateNames[e.state] or e.state),
            "EoCSport_Text", x + w - 16, ry, done and T.green or T.red, TEXT_ALIGN_RIGHT)
    end
end

local function DrawPenalty()
    local pen = EoCSport.MyPenalty
    if not pen or States[LocalPlayer()] then return end
    local ex = EoCSport.GetExercise(pen.id)
    if not ex then return end
    local text = "STRAFRUNDE: " .. EoCSport.FormatCount(ex, pen.count) .. " " .. ex.name .. " (" .. pen.by .. ") – /sport"
    surface.SetFont("EoCSport_Head")
    local tw = surface.GetTextSize(text)
    local w, h = tw + 32, 36
    local x, y = math.floor(ScrW() / 2 - w / 2), 16
    Box(x, y, w, h)
    Text(text, "EoCSport_Head", x + 16, y + 7, T.accent)
end

-- Live-Liste für den Ausbilder
local function DrawLeaderList(now)
    local g = EoCSport.LeaderGroup
    if not g then return end
    local ex = EoCSport.GetExercise(g.exId)
    local rows = math.min(#g.entries, 14)
    local w, h = 330, 64 + rows * 20
    local x, y = ScrW() - w - 20, math.floor(ScrH() * 0.25)
    Box(x, y, w, h)

    Text("GRUPPE · " .. string.upper(ex and ex.name or g.exId) .. " " .. g.target, "EoCSport_Head", x + 12, y + 8, T.accent)

    local status
    if g.state == "invite" then
        status = "Aufforderung läuft (" .. math.max(0, math.ceil(g.inviteEnd - now)) .. " s)"
    elseif g.state == "countdown" then
        status = "Countdown"
    else
        status = "Läuft · " .. FormatTime(now - g.startAt) .. (g.tempo and (" · Takt " .. g.beat .. " (eoc_sport_takt)") or "")
    end
    Text(status, "EoCSport_Small", x + 12, y + 36, T.muted)

    for i = 1, rows do
        local e = g.entries[i]
        local ry = y + 56 + (i - 1) * 20
        local col = e.state == "done" and T.green or (e.state == "active" or e.state == "accepted" or e.state == "invited") and T.text or T.red
        Text(e.name, "EoCSport_Small", x + 12, ry, col)
        local right
        if e.state == "done" then
            right = e.count .. " · " .. FormatTime(e.doneTime)
        elseif e.state == "active" then
            right = tostring(e.count)
        else
            right = EoCSport.MemberStateNames[e.state] or e.state
        end
        Text(right, "EoCSport_Small", x + w - 12, ry, col, TEXT_ALIGN_RIGHT)
    end
end

hook.Add("HUDPaint", "EoCSport_Hud", function()
    local now = CurTime()
    DrawExerciseBar(now)
    DrawInvite(now)
    DrawCountdown(now)
    DrawBeat(now)
    DrawResult(now)
    DrawPenalty()
    DrawLeaderList(now)
end)

---------------------------------------------------------------------------
-- Schild über dem Kopf
---------------------------------------------------------------------------
hook.Add("PostDrawTranslucentRenderables", "EoCSport_Overhead", function(depth, skybox)
    if skybox then return end
    local eye = EyePos()
    local maxDist = C.Overhead.MaxDistance * C.Overhead.MaxDistance
    local camAng = EyeAngles()
    local ang = Angle(0, camAng.y - 90, 90)

    for ply, st in pairs(States) do
        if IsValid(ply) and not st.leaving and not ply:IsDormant() and ply:Alive() then
            local ex = EoCSport.GetExercise(st.id)
            if ex then
                local pos = ply:GetPos() + Vector(0, 0, ex.signHeight or 85)
                local dist = pos:DistToSqr(eye)
                if dist <= maxDist then
                    local alpha = math.Clamp(255 * (1 - dist / maxDist) * 2.5, 0, 255)
                    local text = ex.name .. "  " .. EoCSport.FormatCount(ex, st.count, st.target)
                    local col = (st.group and st.done) and T.green or T.accent

                    cam.Start3D2D(pos, ang, C.Overhead.Scale)
                        surface.SetFont("EoCSport_Sign")
                        local tw, th = surface.GetTextSize(text)
                        local w, h = tw + 40, th + 12
                        surface.SetDrawColor(T.bg.r, T.bg.g, T.bg.b, alpha * 0.9)
                        surface.DrawRect(-w / 2, -h / 2, w, h)
                        surface.SetDrawColor(col.r, col.g, col.b, alpha)
                        surface.DrawRect(-w / 2, -h / 2, w, 4)
                        draw.SimpleText(text, "EoCSport_Sign", 0, 2, Color(col.r, col.g, col.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                end
            end
        end
    end
end)
