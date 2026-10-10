local AID    = KrakenSquad.AID
local P      = KrakenSquad.P
local D      = KrakenSquad.Draw
local Scaled = KF.Scale
local TruncText = KF.TruncateText
local SOUNDS = KrakenSquad.SOUNDS

KrakenSquad.ClientOrders      = KrakenSquad.ClientOrders or {}
KrakenSquad._OrderRevealTimes = KrakenSquad._OrderRevealTimes or {}
KrakenSquad._ClosingOrders    = KrakenSquad._ClosingOrders or {}
KrakenSquad.ActiveCommMarkers = KrakenSquad.ActiveCommMarkers or {}
KrakenSquad.ActiveMarks       = KrakenSquad.ActiveMarks or {}
KrakenSquad.MedicAlerts       = KrakenSquad.MedicAlerts or {}
KrakenSquad.NametagsOn        = KrakenSquad.GetClientPref("show_nametags", true)

function KrakenSquad.RequestLeave()
    net.Start("KS.RequestLeave") net.SendToServer()
end

function KrakenSquad.RequestKick(target)
    if not LocalPlayer():KSIsLeader() or not IsValid(target) then return end
    net.Start("KS.RequestKick") net.WriteEntity(target) net.SendToServer()
end

function KrakenSquad.RequestPosChange(target, pos)
    if not LocalPlayer():KSIsLeader() or not IsValid(target) then return end
    net.Start("KS.RequestPosChange")
        net.WriteEntity(target); net.WriteUInt(pos, 8)
    net.SendToServer()
end

function KrakenSquad.RequestInvite(target)
    net.Start("KS.InvitePlayer") net.WriteEntity(target) net.SendToServer()
end

function KrakenSquad.RequestComm(id)
    net.Start("KS.RequestComm") net.WriteString(id) net.SendToServer()
end

function KrakenSquad.RequestCommand(id)
    net.Start("KS.RequestCommand") net.WriteString(id) net.SendToServer()
end

function KrakenSquad.RequestJoinPublic(id)
    net.Start("KS.RequestJoinPublic") net.WriteUInt(id, 16) net.SendToServer()
end

function KrakenSquad.ToggleNametags()
    KrakenSquad.SetClientPref("show_nametags", not KrakenSquad.GetClientPref("show_nametags", true))
end

hook.Add("KrakenSquad.ClientPrefsChanged", "KS.NametagSync", function(key)
    if key == nil or key == "show_nametags" then
        KrakenSquad.NametagsOn = KrakenSquad.GetClientPref("show_nametags", true)
    end
end)

local cachedMembers, memberCacheTime, lastSquadID = {}, 0, -1

local function GetMembers()
    local lp = LocalPlayer()
    if not IsValid(lp) then return {} end
    local cur = lp:GetKSSquadID()
    if cur ~= lastSquadID then lastSquadID, memberCacheTime = cur, 0 end
    if CurTime() > memberCacheTime then
        local squad = lp:GetKSSquad()
        cachedMembers = squad and squad:GetMembers() or {}
        table.sort(cachedMembers, function(a, b)
            return (IsValid(a) and a:GetKSPosition() or 9999)
                 < (IsValid(b) and b:GetKSPosition() or 9999)
        end)
        memberCacheTime = CurTime() + ((#cachedMembers == 0 and cur ~= -1) and 0.5 or 3)
    end
    return cachedMembers
end

local function FlushMembers() memberCacheTime = 0 end

hook.Add("KrakenSquad.MembersUpdated",    "KS.FlushMembers",  FlushMembers)
hook.Add("KrakenSquad.LeftSquad",         "KS.FlushOnLeave",  function() cachedMembers = {}; lastSquadID = -1; FlushMembers() end)
hook.Add("KrakenSquad.SquadCreated",      "KS.FlushOnCreate", FlushMembers)
hook.Add("KrakenSquad.SquadListReceived", "KS.FlushOnList",   FlushMembers)
hook.Add("KrakenSquad.ConfigUpdated",     "KS.FlushOnConfig", FlushMembers)

-- Die Squad-Liste im HUD gibt es nicht mehr: Mitglieder, Entfernung und Richtung stehen jetzt
-- auf dem Comlink am linken Arm (Taste G, siehe helio_radio/cl/helio_radio_squadmenu.lua).

hook.Add("HUDPaint", "KrakenSquad.Nametags", function()
    if not KrakenSquad.NametagsOn then return end
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end
    if not lp:GetKSSquad() then return end

    local positions = KrakenSquad.GetPositions()
    local maxDist   = KrakenSquad.GetClientPref("nametag_distance", 2000)
    local maxSqr    = maxDist * maxDist
    local lpPos     = lp:GetPos()

    for _, ply in ipairs(GetMembers()) do
        if not IsValid(ply) or ply == lp or not ply:Alive() then continue end
        local sqr = lpPos:DistToSqr(ply:GetPos())
        if sqr > maxSqr then continue end
        local dist = math.sqrt(sqr)
        local pos  = (ply:GetPos() + Vector(0, 0, 40)):ToScreen()
        if not pos.visible then continue end
        local alpha = math.Clamp(255 * (1 - dist / maxDist), 40, 255)

        local pd = positions[ply:GetKSPosition()] or {}
        local iconMat
        if pd.icon and pd.icon ~= "" then
            local mat = KF.Materials.Get(pd.icon)
            if mat and not mat:IsError() then iconMat = mat end
        end

        D.TextShadow(ply:Nick(), "KS.tiny.bold", pos.x, pos.y - Scaled(3),
            KF.UI.ColorAlpha(color_white, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local mrs = KrakenSquad.GetPlayerMRSData(ply)
        local rowY = pos.y + Scaled(6)
        if mrs then
            surface.SetFont("KS.micro")
            local mrsW = surface.GetTextSize(mrs.name)
            local mIco = Scaled(10)
            local hasIcon = KrakenSquad.GetMRSConfig().showIcons and mrs.icon
            local total = mrsW + (hasIcon and (mIco + Scaled(2)) or 0)
            local sx = pos.x - total / 2
            if hasIcon then
                local mat = mrs.icon
                if type(mat) == "string" then mat = KF.Materials.Get(mat) end
                if mat and not mat:IsError() then
                    surface.SetDrawColor(255, 255, 255, math.floor(alpha * 0.9))
                    surface.SetMaterial(mat)
                    surface.DrawTexturedRect(sx, rowY - mIco / 2, mIco, mIco)
                    sx = sx + mIco + Scaled(2)
                end
            end
            D.TextShadow(mrs.name, "KS.micro", sx, rowY,
                KF.UI.ColorAlpha(P("TextSecondary"), math.floor(alpha * 0.85)),
                TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            rowY = rowY + Scaled(10)
        end

        if pd.name and pd.name ~= "" then
            local roleCol  = KrakenSquad.GetPositionColor(pd)
            local roleText = pd.name:upper()
            surface.SetFont("KS.tiny")
            local rw = surface.GetTextSize(roleText)
            local iconSz = Scaled(12)
            local total  = rw + (iconMat and (iconSz + Scaled(3)) or 0)
            local sx = pos.x - total / 2
            if iconMat then
                surface.SetDrawColor(roleCol.r, roleCol.g, roleCol.b, math.floor(alpha * 0.9))
                surface.SetMaterial(iconMat)
                surface.DrawTexturedRect(sx, rowY - iconSz / 2, iconSz, iconSz)
                sx = sx + iconSz + Scaled(3)
            end
            D.TextShadow(roleText, "KS.tiny", sx, rowY,
                KF.UI.ColorAlpha(roleCol, math.floor(alpha * 0.9)), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end)

hook.Add("HUDPaint", "KrakenSquad.MedicRevive", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end
    local pd = lp:GetKSPositionData()
    if not pd or not pd.isMedic or not lp:GetKSSquad() then return end

    local maxDist = KrakenSquad.GetClientPref("nametag_distance", 2000)
    local maxSqr = maxDist * maxDist
    local rev = P("Success")
    local pulse = 0.6 + math.sin(CurTime() * 4) * 0.4
    local lpPos = lp:GetPos()

    for _, ply in ipairs(GetMembers()) do
        if not IsValid(ply) or ply == lp or ply:Alive() then continue end
        local sqr = lpPos:DistToSqr(ply:GetPos())
        if sqr > maxSqr then continue end
        local dist = math.sqrt(sqr)
        local pos = (ply:GetPos() + Vector(0, 0, 10)):ToScreen()
        if not pos.visible then continue end
        local a = math.floor(math.Clamp(255 * (1 - dist / maxDist), 40, 255) * pulse)
        D.TextShadow(KrakenSquad.L("medic_revive"), "KS.tiny.bold", pos.x, pos.y - Scaled(14),
            KF.UI.ColorAlpha(rev, a), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetDrawColor(rev.r, rev.g, rev.b, math.floor(a * 0.4))
        local oSz = Scaled(20)
        surface.DrawOutlinedRect(pos.x - oSz, pos.y - oSz + Scaled(2), oSz * 2, oSz * 2, 1)
    end
end)

local function IsExcludedComm(commID, data)
    if data.triggerPing then return true end
    for _, pos in ipairs(KrakenSquad.GetPositions()) do
        for _, cid in ipairs(pos.medicComms or {}) do
            if cid == commID then return true end
        end
    end
    return false
end

hook.Add("KrakenSquad.CommReceived", "KS.CommMarkers", function(commID, ply)
    if KrakenSquad.GetConfig("commMarkers") == false then return end
    if KrakenSquad.GetClientPref("show_comm_markers", true) == false then return end
    if not IsValid(ply) then return end
    local data = KrakenSquad.GetCommunicationByID(commID)
    if not data or IsExcludedComm(commID, data) then return end
    KrakenSquad.ActiveCommMarkers[ply:EntIndex()] = {
        ply = ply, comm = data, expire = CurTime() + (data.duration or 5),
    }
end)

-- Player outlines disabled: only expire markers here, the overhead symbol is drawn below
hook.Add("Think", "KrakenSquad.CommMarkerCleanup", function()
    local now = CurTime()
    for idx, mark in pairs(KrakenSquad.ActiveCommMarkers) do
        if now > mark.expire or not IsValid(mark.ply) then
            KrakenSquad.ActiveCommMarkers[idx] = nil
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "KrakenSquad.CommOverhead", function()
    if KrakenSquad.GetConfig("commMarkers") == false then return end
    if KrakenSquad.GetClientPref("show_comm_markers", true) == false then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local now = CurTime()
    local maxDist = KrakenSquad.GetClientPref("nametag_distance", 2000)

    cam.Start2D()
    for _, mark in pairs(KrakenSquad.ActiveCommMarkers) do
        if now > mark.expire or not IsValid(mark.ply) then continue end
        if lp:GetPos():Distance(mark.ply:GetPos()) > maxDist then continue end
        local pos = (mark.ply:GetPos() + Vector(0, 0, 90)):ToScreen()
        if not pos.visible then continue end

        local c = mark.comm.color or { 255, 255, 255 }
        mark._col = mark._col or Color(c[1], c[2], c[3])
        local col = mark._col
        local life = (mark.expire - now) / (mark.comm.duration or 5)
        local fadeA = math.Clamp(life * 4, 0, 1) * 255
        local pulse = 0.7 + 0.3 * math.sin(now * 3)

        local plyName = mark.ply:Nick()
        local commTxt = KrakenSquad.ItemName(mark.comm):upper()
        local iconSz, iconMat = Scaled(14), nil
        if mark.comm.icon and mark.comm.icon ~= "" then
            local mat = KF.Materials.Get(mark.comm.icon)
            if mat and not mat:IsError() then iconMat = mat end
        end

        surface.SetFont("KS.small.bold"); local nameW = surface.GetTextSize(plyName)
        surface.SetFont("KS.micro");      local commW = surface.GetTextSize(commTxt)
        local contentW = commW + (iconMat and (iconSz + Scaled(4)) or 0)
        local panelW = math.max(nameW, contentW) + Scaled(28)
        local panelH = Scaled(38)
        local px, py = pos.x - panelW / 2, pos.y - panelH - Scaled(10)

        surface.SetDrawColor(0, 0, 0, math.floor(fadeA * 0.55))
        surface.DrawRect(px, py, panelW, panelH)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(fadeA * pulse))
        surface.DrawRect(px, py, 2, panelH)
        surface.DrawRect(px, py + panelH - 1, panelW, 1)

        draw.SimpleText(plyName, "KS.small.bold", pos.x, py + Scaled(4),
            KF.UI.ColorAlpha(col, math.floor(fadeA * pulse)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        local lineY = py + Scaled(18)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(fadeA * 0.25))
        surface.DrawRect(px + Scaled(8), lineY, panelW - Scaled(16), 1)

        local sx = pos.x - contentW / 2
        if iconMat then
            surface.SetDrawColor(255, 255, 255, math.floor(fadeA * 0.9))
            surface.SetMaterial(iconMat)
            surface.DrawTexturedRect(sx, lineY + Scaled(4), iconSz, iconSz)
            sx = sx + iconSz + Scaled(4)
        end
        draw.SimpleText(commTxt, "KS.micro", sx, lineY + Scaled(5),
            KF.UI.ColorAlpha(color_white, math.floor(fadeA * 0.7)), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        surface.SetDrawColor(col.r, col.g, col.b, math.floor(fadeA * pulse))
        surface.DrawLine(pos.x, py + panelH, pos.x, pos.y - Scaled(4))
    end
    cam.End2D()
end)

local pings = {}

hook.Add("KrakenSquad.PingReceived", "KS.QueuePing", function(pos, ply, pingType)
    if KrakenSquad.GetClientPref("show_pings", true) == false then return end
    local snd = (KrakenSquad.GetConfig("sounds") or {}).ping
    if snd then KF.Helpers.PlaySound(snd) end
    pings[#pings + 1] = {
        pos = pos, ply = ply, pingType = pingType,
        start = CurTime(), expire = CurTime() + 10,
    }
end)

hook.Add("HUDPaint", "KrakenSquad.PingsHUD", function()
    if KrakenSquad.GetClientPref("show_pings", true) == false then return end
    local now = CurTime()
    for i = #pings, 1, -1 do
        if now > pings[i].expire then table.remove(pings, i) end
    end
    if #pings == 0 then return end
    local lp = LocalPlayer()

    for _, pg in ipairs(pings) do
        local sp = pg.pos:ToScreen()
        if not sp.visible then continue end
        local age   = now - pg.start
        local alpha = math.floor(255 * math.Clamp(age / 0.2, 0, 1) * math.Clamp((pg.expire - now) / 1.5, 0, 1))
        if alpha < 5 then continue end

        local isEnemy = pg.pingType == "enemy"
        local col   = isEnemy and P("Enemy") or P("Warning")
        local label = (isEnemy and KrakenSquad.L("ping_enemy") or KrakenSquad.L("ping_normal")):upper()
        local plyName = IsValid(pg.ply) and pg.ply:Nick() or KrakenSquad.L("unknown_player")
        local dist = math.Round(lp:GetPos():Distance(pg.pos))

        surface.SetDrawColor(col.r, col.g, col.b, alpha)
        draw.NoTexture()
        local d = Scaled(3)
        surface.DrawPoly({
            { x = sp.x,     y = sp.y - d },
            { x = sp.x + d, y = sp.y     },
            { x = sp.x,     y = sp.y + d },
            { x = sp.x - d, y = sp.y     },
        })

        D.TextShadow(label,    "KS.tiny.bold", sp.x, sp.y - Scaled(20), KF.UI.ColorAlpha(col, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        D.TextShadow(plyName,  "KS.micro",     sp.x, sp.y - Scaled(10), KF.UI.ColorAlpha(P("TextSecondary"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        D.TextShadow(dist .. "m", "KS.micro",  sp.x, sp.y + Scaled(10), KF.UI.ColorAlpha(P("TextSecondary"), alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local pulse = math.fmod(age, 2) / 2
        if pulse < 0.6 then
            local ringR = Scaled(6) + Scaled(20) * (pulse / 0.6)
            local ringA = math.floor((1 - pulse / 0.6) * 40 * (alpha / 255))
            surface.SetDrawColor(col.r, col.g, col.b, ringA)
            local prevX, prevY
            for s = 0, 16 do
                local a = math.rad(360 * s / 16)
                local x = sp.x + math.cos(a) * ringR
                local y = sp.y + math.sin(a) * ringR
                if prevX then surface.DrawLine(prevX, prevY, x, y) end
                prevX, prevY = x, y
            end
        end
    end
end)

hook.Add("KrakenSquad.CommandReceived", "KS.ShowCommand", function(cmdID, ply)
    local sounds = KrakenSquad.GetConfig("sounds") or {}
    if sounds.command then KF.Helpers.PlaySound(sounds.command) end
    KF.Helpers.PlaySound(SOUNDS.success)
    local data = KrakenSquad.GetCommandByID(cmdID)
    if not data then return end
    local col = Color(data.color[1] or 255, data.color[2] or 255, data.color[3] or 255)
    local label = KrakenSquad.ItemName(data):upper()
    local leader = IsValid(ply) and ply:Nick() or KrakenSquad.L("unknown_player")
    KrakenSquad.ShowFullscreenNotify(label, col, leader, "KS.CmdNotify", 5)
end)

hook.Add("KrakenSquad.InviteReceived", "KS.ShowInvite", function(inviter, squadName)
    local sounds = KrakenSquad.GetConfig("sounds") or {}
    if sounds.invite then KF.Helpers.PlaySound(sounds.invite) end
    KrakenSquad.OpenInviteFrame(inviter, squadName)
end)

-- Die Squad-Taste (Standard G) öffnet jetzt das Squad-Menü auf dem Comlink statt des Radialmenüs.
-- Das alte Radialmenü gibt es nur noch über die Konsole: krakensquad_radial
concommand.Add("krakensquad_radial", function()
    if LocalPlayer():GetKSSquad() then KrakenSquad.OpenRadial() end
end)

KrakenSquad.Net.Receive("KS.MarkSync", function()
    local target   = net.ReadEntity()
    local markType = net.ReadString()
    local name     = net.ReadString()
    local marker   = net.ReadEntity()
    if not IsValid(target) then return end
    if name:StartWith("#") then
        local phrase = language.GetPhrase(name:sub(2))
        if phrase and phrase ~= "" then name = phrase end
    elseif name:StartWith("npc_") or name:StartWith("sent_") or name:StartWith("prop_") then
        local phrase = language.GetPhrase(name)
        if phrase and phrase ~= name then name = phrase end
    end
    KF.Helpers.PlaySound(SOUNDS.success)
    KrakenSquad.ActiveMarks[target:EntIndex()] = {
        ent = target, type = markType, name = name,
        marker = IsValid(marker) and marker:Nick() or KrakenSquad.L("unknown_player"),
        expire = CurTime() + 60,
    }
end)

KrakenSquad.Net.Receive("KS.MedicAlert", function()
    local target = net.ReadEntity()
    local hp     = net.ReadUInt(16)
    local maxHP  = net.ReadUInt(16)
    if not IsValid(target) then return end
    KF.Helpers.PlaySound(SOUNDS.error)
    KrakenSquad.MedicAlerts[target:EntIndex()] = {
        ply = target, hp = hp, maxHP = maxHP, expire = CurTime() + 8,
    }
end)

hook.Add("PreDrawHalos", "KrakenSquad.MarkHalos", function()
    local now = CurTime()
    local greens, reds = {}, {}
    for idx, mark in pairs(KrakenSquad.ActiveMarks) do
        if now > mark.expire or not IsValid(mark.ent) then
            KrakenSquad.ActiveMarks[idx] = nil
            continue
        end
        if mark.ent:IsPlayer() then continue end -- no outlines on players
        if mark.type == "enemy" then reds[#reds + 1] = mark.ent
        else greens[#greens + 1] = mark.ent end
    end
    if #greens > 0 then halo.Add(greens, P("MarkGreen"), 2, 2, 1, true, true) end
    if #reds   > 0 then halo.Add(reds,   P("MarkRed"),   2, 2, 1, true, true) end
end)

-- Player outlines disabled: only expire medic alerts here
hook.Add("Think", "KrakenSquad.MedicAlertCleanup", function()
    local now = CurTime()
    for idx, alert in pairs(KrakenSquad.MedicAlerts) do
        if now > alert.expire or not IsValid(alert.ply) then
            KrakenSquad.MedicAlerts[idx] = nil
        end
    end
end)

hook.Add("PostDrawTranslucentRenderables", "KrakenSquad.MarkOverhead", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local now = CurTime()
    local lpPos = lp:GetPos()

    cam.Start2D()
    for _, mark in pairs(KrakenSquad.ActiveMarks) do
        if now > mark.expire or not IsValid(mark.ent) then continue end
        local entPos = mark.ent:GetPos()
        local zOff = mark.ent:IsPlayer() and 80 or (mark.ent:IsNPC() and 70 or 40)
        local sp = (entPos + Vector(0, 0, zOff)):ToScreen()
        if not sp.visible then continue end

        local dist = math.Round(lpPos:Distance(entPos) * 0.01905)
        local isEnemy = mark.type == "enemy"
        local col = isEnemy and P("Enemy") or P("Success")
        local life = (mark.expire - now) / 60
        local pulse = 0.7 + 0.3 * math.sin(now * 3)
        local fadeA = math.Clamp(life * 5, 0, 1) * 255

        local label = mark.name:upper()
        local typeLabel = isEnemy and KrakenSquad.L("mark_enemy") or KrakenSquad.L("mark")
        surface.SetFont("KS.small.bold"); local nameW = surface.GetTextSize(label)
        surface.SetFont("KS.micro");      local typeW = surface.GetTextSize(typeLabel)
        local distText = dist .. "m"
        local distW = surface.GetTextSize(distText)
        local infoW = typeW + 12 + distW
        local panelW = math.max(nameW, infoW) + Scaled(28)
        local panelH = Scaled(42)
        local px, py = sp.x - panelW / 2, sp.y - panelH - Scaled(14)

        surface.SetDrawColor(0, 0, 0, math.floor(fadeA * 0.55))
        surface.DrawRect(px, py, panelW, panelH)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(fadeA * pulse))
        surface.DrawRect(px, py, 2, panelH)
        surface.DrawRect(px, py + panelH - 1, panelW, 1)

        local lineY = py + Scaled(22)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(fadeA * 0.25))
        surface.DrawRect(px + Scaled(8), lineY, panelW - Scaled(16), 1)

        draw.SimpleText(label, "KS.small.bold", sp.x, py + Scaled(5),
            KF.UI.ColorAlpha(col, math.floor(fadeA * pulse)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(typeLabel, "KS.micro", sp.x - Scaled(2) - distW / 2, lineY + Scaled(4),
            KF.UI.ColorAlpha(color_white, math.floor(fadeA * 0.6)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        draw.SimpleText(distText, "KS.micro", sp.x + typeW / 2 + Scaled(2), lineY + Scaled(4),
            KF.UI.ColorAlpha(col, math.floor(fadeA * 0.9)), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        surface.SetDrawColor(col.r, col.g, col.b, math.floor(fadeA * pulse))
        surface.DrawLine(sp.x, py + panelH, sp.x, sp.y - Scaled(4))

        local bSz, cl = Scaled(8), Scaled(6)
        for _, dir in ipairs({{-1,-1},{1,-1},{-1,1},{1,1}}) do
            local x = sp.x + dir[1] * bSz
            local y = sp.y + dir[2] * bSz
            surface.DrawLine(x, y, x, y - dir[2] * cl)
            surface.DrawLine(x, y, x - dir[1] * cl, y)
        end

        local dotSz = Scaled(2)
        surface.SetDrawColor(col.r, col.g, col.b, math.floor(fadeA * 0.9))
        surface.DrawRect(sp.x - dotSz, sp.y - dotSz, dotSz * 2, dotSz * 2)
    end
    cam.End2D()
end)

hook.Add("HUDPaint", "KrakenSquad.MedicAlertHUD", function()
    if next(KrakenSquad.MedicAlerts) == nil then return end
    local now = CurTime()
    local alerts = {}
    for _, a in pairs(KrakenSquad.MedicAlerts) do
        if now <= a.expire and IsValid(a.ply) then alerts[#alerts + 1] = a end
    end
    if #alerts == 0 then return end

    local sw     = ScrW()
    local panelW = Scaled(180)
    local baseX  = sw / 2 - panelW / 2
    local baseY  = Scaled(8)
    local accent = P("Warning")

    surface.SetDrawColor(0, 0, 0, 100)
    surface.DrawRect(baseX, baseY, panelW, Scaled(20))
    surface.SetDrawColor(accent.r, accent.g, accent.b, 120)
    surface.DrawRect(baseX, baseY + Scaled(20) - 1, panelW, 1)

    local pulse = math.abs(math.sin(CurTime() * 3))
    D.TextShadow(KrakenSquad.L("medic_alert"), "KS.orders.hud", sw / 2, baseY + Scaled(10),
        KF.UI.ColorAlpha(accent, math.floor(180 + 75 * pulse)), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local aY = baseY + Scaled(22)
    for _, alert in ipairs(alerts) do
        local frac = alert.maxHP > 0 and alert.hp / alert.maxHP or 0
        local hpCol
        if frac < 0.2     then hpCol = P("Error")
        elseif frac < 0.4 then hpCol = P("MedicLow")
        elseif frac < 0.6 then hpCol = P("Warning")
        else                   hpCol = P("Success") end
        surface.SetDrawColor(0, 0, 0, 70)
        surface.DrawRect(baseX, aY, panelW, Scaled(18))
        D.TextShadow(alert.ply:Nick(), "KS.orders.hudSm", baseX + Scaled(4), aY + Scaled(4),
            P("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local barW = Scaled(40)
        local barX = baseX + panelW - barW - Scaled(4)
        KF.Draw.ProgressBar(barX, aY + Scaled(6), barW, Scaled(4), frac, hpCol, P("BarBG"), AID)
        aY = aY + Scaled(20)
    end
end)

local _orderWrapCache = {}
local function ClearOrderCache() _orderWrapCache = {} end
hook.Add("KrakenSquad.OrdersUpdated", "KS.WrapCacheClear",       ClearOrderCache)
hook.Add("KrakenSquad.ConfigUpdated", "KS.WrapCacheClearCfg",    ClearOrderCache)
hook.Add("KrakenSquad.LayoutUpdated", "KS.WrapCacheClearLayout", ClearOrderCache)

KrakenSquad.Net.Receive("KS.OrderSync", function()
    local data = KF.Net.ReadJSON(65536)
    if not data then return end
    local prev = KrakenSquad.ClientOrders
    KrakenSquad.ClientOrders = {}
    local newOrders, newMap = {}, {}
    for _, o in ipairs(data) do
        KrakenSquad.ClientOrders[o.id] = o
        newMap[o.id] = true
        if not prev[o.id] then newOrders[#newOrders + 1] = o end
    end
    local now = CurTime()
    for id, o in pairs(prev) do
        if not newMap[id] and not KrakenSquad._ClosingOrders[id] then
            KrakenSquad._ClosingOrders[id] = { order = o, closeStart = now }
        end
    end
    for _, o in ipairs(newOrders) do
        if (o.expire or 0) - now > 5 then
            KrakenSquad._OrderRevealTimes[o.id] = now
            KrakenSquad.ShowOrderNotification(o)
        end
    end
    for id in pairs(KrakenSquad._OrderRevealTimes) do
        if not KrakenSquad.ClientOrders[id] then KrakenSquad._OrderRevealTimes[id] = nil end
    end
    hook.Run("KrakenSquad.OrdersUpdated")
end)

local STATUS_LABELS = {
    succeeded = "order_status_succeed",
    failed    = "order_status_failed",
    active    = "order_status_new",
    updated   = "order_updated",
}
local function StatusColor(s)
    if s == "succeeded" then return P("Success") end
    if s == "failed"    then return P("Error")   end
    return P("Accent")
end

KrakenSquad.Net.Receive("KS.OrderStatusNotify", function()
    local id     = net.ReadUInt(32)
    local status = net.ReadString()
    local title  = net.ReadString()
    local label = (KrakenSquad.L(STATUS_LABELS[status] or "") or status) .. ": " .. title:upper()
    local sounds = KrakenSquad.GetConfig("sounds") or {}
    if sounds.command then KF.Helpers.PlaySound(sounds.command) end
    KrakenSquad.ShowFullscreenNotify(label, StatusColor(status), "", "KS.OrderStatusNotify", 4)
end)

function KrakenSquad.ShowOrderNotification(order)
    local sounds = KrakenSquad.GetConfig("sounds") or {}
    if sounds.command then KF.Helpers.PlaySound(sounds.command) end
    KF.Helpers.PlaySound(SOUNDS.success)
    KrakenSquad.ShowFullscreenNotify(
        (order.title or KrakenSquad.L("order_fallback_title")):upper(),
        P("Accent"),
        order.issuer or KrakenSquad.L("order_fallback_issuer"),
        "KS.OrderNotify", 4.5)
end

local _ohCol = Color(0, 0, 0, 255)
local function tint(col, alpha)
    _ohCol.r, _ohCol.g, _ohCol.b, _ohCol.a = col.r, col.g, col.b, alpha
    return _ohCol
end

hook.Add("HUDPaint", "KrakenSquad.OrdersHUD", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end
    if KrakenSquad.GetClientPref("show_orders", true) == false then return end
    local lo = (KrakenSquad.GetConfig("layout") or {}).orders or {}
    if lo.visible == false then return end

    local orders   = KrakenSquad.ClientOrders
    local closing  = KrakenSquad._ClosingOrders
    if not next(orders) and not next(closing) then return end

    local ox, oy, scale = KrakenSquad.Layout.ToPixels("orders")
    local OS = function(n) return Scaled(n) * scale end
    local panelW = OS(210)
    local accent = P("Accent")
    local pad    = OS(8)
    local textW  = panelW - pad * 2
    local now = CurTime()
    local revealTimes = KrakenSquad._OrderRevealTimes
    local REVEAL_DELAY, ANIM_DUR = 3.8, 1.2
    local curY = oy

    local allRender = {}
    for id, o in pairs(orders) do allRender[id] = { order = o } end
    for id, c in pairs(closing) do
        if now - c.closeStart >= ANIM_DUR then
            closing[id] = nil
        elseif not allRender[id] then
            allRender[id] = { order = c.order, closeStart = c.closeStart }
        end
    end

    for id, entry in SortedPairs(allRender) do
        local order = entry.order
        local isPermanent = order.permanent
        local remaining
        if entry.closeStart then remaining = ANIM_DUR - (now - entry.closeStart)
        elseif isPermanent  then remaining = math.huge
        else remaining = (order.expire or 0) - now end
        if remaining <= 0 then continue end

        local revealStart = not entry.closeStart and revealTimes[id] or nil
        local animAge
        if revealStart then
            local elapsed = now - revealStart
            if elapsed < REVEAL_DELAY then continue end
            animAge = elapsed - REVEAL_DELAY
        end

        local panelAlpha, clipFW, clipFH = 1, 1, 1
        if animAge and animAge < ANIM_DUR then
            local ease = 1 - (1 - animAge / ANIM_DUR) ^ 3
            panelAlpha = ease
            clipFW = Lerp(ease, 0.3, 1)
            clipFH = Lerp(ease, 0.1, 1)
        end
        local isClosing = entry.closeStart or (not isPermanent and remaining <= ANIM_DUR)
        if isClosing then
            local f = math.Clamp(1 - remaining / ANIM_DUR, 0, 1)
            local e = f * f * f
            panelAlpha = panelAlpha * (1 - e)
            clipFW = Lerp(e, clipFW, 0.3)
            clipFH = Lerp(e, clipFH, 0.1)
        end

        local headerH, sepH = OS(24), OS(6)
        local descLineH, mainLineH, secLineH, secIndent = OS(14), OS(16), OS(14), OS(14)

        local cached = _orderWrapCache[id]
        if not cached then
            cached = { titleText = (order.title or ""):upper(), mainObjs = {}, secObjs = {} }
            for _, obj in ipairs(order.objectives or {}) do
                if (obj.priority or "main") == "secondary" then
                    cached.secObjs[#cached.secObjs + 1] = obj
                else
                    cached.mainObjs[#cached.mainObjs + 1] = obj
                end
            end
            cached.descLines = (order.description and order.description ~= "")
                and KrakenSquad.WrapText(order.description, "KS.orders.hudSm", textW) or {}
            cached.mainObjLines, cached.secObjLines = {}, {}
            for i, o in ipairs(cached.mainObjs) do
                cached.mainObjLines[i] = KrakenSquad.WrapText(o.text or "", "KS.orders.hudMain", textW - OS(10))
            end
            for i, o in ipairs(cached.secObjs) do
                cached.secObjLines[i] = KrakenSquad.WrapText(o.text or "", "KS.orders.hudSec", textW - OS(6) - secIndent)
            end
            _orderWrapCache[id] = cached
        end

        local descH = #cached.descLines * descLineH
        local mainH = 0
        for i = 1, #cached.mainObjs do
            mainH = mainH + #cached.mainObjLines[i] * mainLineH
            if i < #cached.mainObjs then mainH = mainH + OS(2) end
        end
        local secGap = (#cached.mainObjs > 0 and #cached.secObjs > 0) and OS(4) or 0
        local secH = 0
        for i = 1, #cached.secObjs do
            secH = secH + #cached.secObjLines[i] * secLineH
            if i < #cached.secObjs then secH = secH + OS(2) end
        end
        local issuerH = order.issuer and OS(18) or 0
        local totalH = headerH + sepH + descH + mainH + secGap + secH + issuerH + OS(8)

        local drawW = math.floor(panelW * clipFW)
        local drawH = math.floor(totalH  * clipFH)
        if panelAlpha < 1 then
            local clipX = ox + (panelW - drawW) / 2
            local clipY = curY + (totalH - drawH) / 2
            render.SetScissorRect(clipX, clipY, clipX + drawW, clipY + drawH, true)
        end

        local statusCol = StatusColor(order.status)
        D.PanelBG(ox, curY, panelW, totalH, {
            alpha       = math.floor(60 * panelAlpha),
            accentLine  = true, accentSide = "left",
            accentAlpha = math.floor(160 * panelAlpha),
            accentColor = statusCol,
        })

        local textRevealed = math.huge
        if (animAge and animAge < ANIM_DUR) or isClosing then
            local total = #cached.titleText
            for _, l in ipairs(cached.descLines) do total = total + #l end
            for _, ls in ipairs(cached.mainObjLines) do for _, l in ipairs(ls) do total = total + #l end end
            for _, ls in ipairs(cached.secObjLines)  do for _, l in ipairs(ls) do total = total + #l end end
            if order.issuer then total = total + #order.issuer end
            if animAge and animAge < ANIM_DUR then
                textRevealed = math.floor((animAge / ANIM_DUR) * (total + 10))
            end
            if isClosing then
                local f = math.Clamp(1 - remaining / ANIM_DUR, 0, 1)
                textRevealed = math.min(textRevealed, math.floor((1 - f) * (total + 10)))
            end
        end

        local alphaCol = math.floor(255 * panelAlpha)
        local charsUsed = 0
        local function Slice(text)
            if textRevealed == math.huge then return text end
            return text:sub(1, math.max(0, textRevealed - charsUsed))
        end

        local ty = curY + OS(5)
        D.TextShadow(Slice(cached.titleText), "KS.orders.hud", ox + pad, ty,
            tint(statusCol, alphaCol), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        charsUsed = charsUsed + #cached.titleText

        local timeStr = isPermanent and "\226\136\158" or
            ("%d:%02d"):format(math.floor(remaining / 60), math.floor(remaining % 60))
        local timeCol = (not isPermanent and remaining < 60) and P("Error") or P("TextSecondary")
        D.TextShadow(timeStr, "KS.orders.hudSm", ox + panelW - pad, ty + OS(2),
            tint(timeCol, alphaCol), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

        ty = ty + headerH
        surface.SetDrawColor(accent.r, accent.g, accent.b, math.floor(35 * panelAlpha))
        surface.DrawRect(ox + pad, ty, panelW - pad * 2, 1)
        ty = ty + sepH

        if #cached.descLines > 0 then
            local ts = P("TextSecondary")
            for _, line in ipairs(cached.descLines) do
                D.TextShadow(Slice(line), "KS.orders.hudSm", ox + pad, ty,
                    tint(ts, alphaCol), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                charsUsed = charsUsed + #line
                ty = ty + descLineH
            end
        end

        for idx, obj in ipairs(cached.mainObjs) do
            local dotCol = obj.done and P("Success") or P("TextMuted")
            local txtCol = obj.done and P("Success") or P("Text")
            for li, line in ipairs(cached.mainObjLines[idx]) do
                if li == 1 then
                    local dotR = OS(2)
                    KF.Draw.RoundedBox(ox + pad + OS(2) - dotR, ty + OS(5) - dotR, dotR * 2, dotR * 2, dotR,
                        tint(dotCol, alphaCol))
                end
                D.TextShadow(Slice(line), "KS.orders.hudMain",
                    ox + pad + OS(10), ty, tint(txtCol, alphaCol), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                charsUsed = charsUsed + #line
                ty = ty + mainLineH
            end
            if idx < #cached.mainObjs then ty = ty + OS(2) end
        end

        if #cached.secObjs > 0 then
            ty = ty + secGap
            for idx, obj in ipairs(cached.secObjs) do
                local sc = obj.done and P("Success") or P("TextSecondary")
                local oa = obj.done and math.floor(180 * panelAlpha) or alphaCol
                local prefix = obj.done and "+" or "-"
                for li, line in ipairs(cached.secObjLines[idx]) do
                    local sliced = Slice(line)
                    if li == 1 then
                        D.TextShadow("  " .. prefix .. " " .. sliced, "KS.orders.hudSec",
                            ox + pad + OS(6), ty, tint(sc, oa), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    else
                        D.TextShadow(sliced, "KS.orders.hudSec",
                            ox + pad + OS(6) + secIndent, ty, tint(sc, oa), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    end
                    charsUsed = charsUsed + #line
                    ty = ty + secLineH
                end
                if idx < #cached.secObjs then ty = ty + OS(2) end
            end
        end

        if order.issuer then
            surface.SetDrawColor(255, 255, 255, math.floor(8 * panelAlpha))
            surface.DrawRect(ox + pad, ty, panelW - pad * 2, 1)
            ty = ty + OS(4)
            D.TextShadow(Slice(order.issuer), "KS.orders.hudSm", ox + pad, ty,
                tint(P("TextSecondary"), alphaCol), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            charsUsed = charsUsed + #order.issuer
        end

        if panelAlpha < 1 then render.SetScissorRect(0, 0, 0, 0, false) end
        curY = curY + totalH + OS(6)
    end
end)
