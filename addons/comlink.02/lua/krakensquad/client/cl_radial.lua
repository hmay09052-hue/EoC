local AID = KrakenSquad.AID
local P   = KrakenSquad.P
local D   = KrakenSquad.Draw
local LerpColor   = KF.UI.LerpColor
local HOVER_SPEED = KrakenSquad.UI.HOVER_SPEED
local Scaled      = KF.Scale
local TruncText   = KF.TruncateText
local SOUNDS      = KrakenSquad.SOUNDS

local soundExists = {}

local function PlayConfigSound(key, fallback)
    local snd = (KrakenSquad.GetConfig("sounds") or {})[key]
    if snd and snd ~= "" then
        if soundExists[snd] == nil then
            soundExists[snd] = file.Exists("sound/" .. snd, "GAME")
        end
        if soundExists[snd] then KF.Helpers.PlaySound(snd) return end
    end
    KF.Helpers.PlaySound(SOUNDS[fallback])
end

hook.Add("KrakenSquad.ConfigUpdated", "KS.RadialSoundCacheClear", function() soundExists = {} end)

local PANEL = {}

function PANEL:Init()
    KF.Fonts.Create(AID)
    self.Scale       = math.max(0.6, ScrH() / 1080)
    self.CenterX     = ScrW() / 2
    self.CenterY     = ScrH() / 2
    self.HoveredIdx  = -1
    self.Radius      = 170 * self.Scale
    self.InnerRadius =  50 * self.Scale
    self.Title       = "RADIAL"
    self.SelectedTitle = ""
    self.Items       = {}
    self.OpenLerp    = 0
end

function PANEL:SetTitle(t) self.Title = t end

function PANEL:AddItem(item)
    local cached = { data = item, hoverLerp = 0, label = (item.text or ""):upper() }
    if item.icon and item.icon ~= "" then
        local mat = KF.Materials.Get(item.icon)
        if mat and not mat:IsError() then cached.mat = mat end
    end
    self.Items[#self.Items + 1] = cached
end

function PANEL:Close()
    if self.ActivePanel and self.ActivePanel.data and self.ActivePanel.data.func then
        PlayConfigSound("radialSelect", "click")
        self.ActivePanel.data.func()
    end
    self:Remove()
end

function PANEL:OnMousePressed(key)
    if key == MOUSE_LEFT or key == MOUSE_RIGHT then self:Close() end
end

local arcPoly = { { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 } }

local function DrawArc(cx, cy, rIn, rOut, sa, ea, col)
    draw.NoTexture()
    surface.SetDrawColor(col)
    local range = ea - sa
    for i = 0, 23 do
        local a1 = math.rad(sa + range * (i / 24))
        local a2 = math.rad(sa + range * ((i + 1) / 24))
        local c1, s1 = math.cos(a1), math.sin(a1)
        local c2, s2 = math.cos(a2), math.sin(a2)
        arcPoly[1].x, arcPoly[1].y = cx + c1 * rOut, cy + s1 * rOut
        arcPoly[2].x, arcPoly[2].y = cx + c2 * rOut, cy + s2 * rOut
        arcPoly[3].x, arcPoly[3].y = cx + c2 * rIn,  cy + s2 * rIn
        arcPoly[4].x, arcPoly[4].y = cx + c1 * rIn,  cy + s1 * rIn
        surface.DrawPoly(arcPoly)
    end
end

local segBg     = Color(0, 0, 0, 255)
local hoverFill = Color(0, 0, 0, 0)
local accentBar = Color(0, 0, 0, 0)
local accentEdge= Color(0, 0, 0, 0)
local textCol   = Color(255, 255, 255, 255)
local titleCol  = Color(0, 0, 0, 255)
local selCol    = Color(0, 0, 0, 255)

function PANEL:Paint(w, h)
    local count = #self.Items
    if count == 0 then return end

    self.OpenLerp = Lerp(FrameTime() * 10, self.OpenLerp, 1)
    local ol = self.OpenLerp
    local cx, cy = self.CenterX, self.CenterY
    local rIn, rOut = self.InnerRadius * ol, self.Radius * ol
    local accent = P("Accent")
    local bg = P("BG")

    local mx, my = gui.MousePos()
    local dx, dy = mx - cx, my - cy
    local mDist = math.sqrt(dx * dx + dy * dy)
    local mAng  = math.deg(math.atan2(dy, dx))
    local sect, startO = 360 / count, -90 - 360 / count / 2

    local newHovered = -1
    if mDist > rIn and mDist < rOut * 1.3 then
        for i = 0, count - 1 do
            if (mAng - (startO + i * sect)) % 360 < sect then newHovered = i break end
        end
    end

    if newHovered ~= self.HoveredIdx then
        self.HoveredIdx = newHovered
        self.ActivePanel = nil
        self.SelectedTitle = ""
        if newHovered >= 0 and self.Items[newHovered + 1] then
            self.ActivePanel = self.Items[newHovered + 1]
            self.SelectedTitle = self.ActivePanel.data.text or ""
            PlayConfigSound("radialHover", "hover")
        end
    end

    surface.SetDrawColor(0, 0, 0, math.floor(60 * ol))
    surface.DrawRect(0, 0, w, h)

    local maxTextW = (self.Radius - self.InnerRadius) - Scaled(8)
    segBg.r, segBg.g, segBg.b = bg.r + 4, bg.g + 6, bg.b + 10
    segBg.a = math.floor(255 * ol)

    for i, item in ipairs(self.Items) do
        local idx = i - 1
        local hovered = idx == self.HoveredIdx
        item.hoverLerp = Lerp(FrameTime() * HOVER_SPEED, item.hoverLerp, hovered and 1 or 0)
        local hl = item.hoverLerp
        local sa = startO + idx * sect + 0.75
        local ea = startO + (idx + 1) * sect - 0.75

        DrawArc(cx, cy, rIn + 2, rOut, sa, ea, segBg)
        if hl > 0.01 then
            hoverFill.r, hoverFill.g, hoverFill.b = accent.r, accent.g, accent.b
            hoverFill.a = math.floor(30 * hl * ol)
            DrawArc(cx, cy, rIn + 2, rOut, sa, ea, hoverFill)
            local pulse = 1 + math.sin(CurTime() * 4) * 0.15
            accentBar.r, accentBar.g, accentBar.b = accent.r, accent.g, accent.b
            accentBar.a = math.Clamp(math.floor(180 * hl * ol * pulse), 0, 255)
            DrawArc(cx, cy, rIn + 2, rIn + Scaled(3), sa, ea, accentBar)
            accentEdge.r, accentEdge.g, accentEdge.b = accent.r, accent.g, accent.b
            accentEdge.a = math.floor(35 * hl * ol)
            DrawArc(cx, cy, rOut - Scaled(2), rOut, sa, ea, accentEdge)
        end

        local midAng = math.rad((sa + ea) / 2)
        local midR   = (rIn + rOut) / 2
        local ix, iy = cx + math.cos(midAng) * midR, cy + math.sin(midAng) * midR

        if not item._wrappedLines then
            item._wrappedLines = KrakenSquad.WrapText(item.label, "KS.radial.item", maxTextW)
        end
        local lines = item._wrappedLines
        local nLines = #lines

        if item.mat then
            local iSz = Scaled(18) * ol
            local iconOff = nLines > 1 and Scaled(10) or Scaled(6)
            surface.SetDrawColor(255, 255, 255, math.floor(Lerp(hl, 160, 255) * ol))
            surface.SetMaterial(item.mat)
            surface.DrawTexturedRect(ix - iSz / 2, iy - iSz / 2 - iconOff * ol, iSz, iSz)
        end

        local src = LerpColor(hl, P("TextSecondary"), P("TextBright"))
        textCol.r, textCol.g, textCol.b = src.r, src.g, src.b
        textCol.a = math.floor((src.a or 255) * ol)
        local textBaseY = iy + Scaled(nLines > 1 and 4 or 8) * ol
        local lineH = Scaled(11) * ol
        for li, line in ipairs(lines) do
            D.TextShadow(line, "KS.radial.item", ix, textBaseY + (li - 1) * lineH,
                textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    if not self._centerVerts or self._centerVertsR ~= rIn then
        self._centerVertsR = rIn
        local verts = {}
        for i = 0, 48 do
            local a = math.rad((i / 48) * 360)
            verts[#verts + 1] = { x = cx + math.cos(a) * rIn, y = cy + math.sin(a) * rIn }
        end
        self._centerVerts = verts
    end
    draw.NoTexture()
    surface.SetDrawColor(bg.r, bg.g, bg.b, math.floor(255 * ol))
    surface.DrawPoly(self._centerVerts)

    local pulse = 0.7 + math.sin(CurTime() * 2) * 0.3
    surface.SetDrawColor(accent.r, accent.g, accent.b, math.floor(55 * pulse * ol))
    for i = 1, #self._centerVerts - 1 do
        surface.DrawLine(self._centerVerts[i].x, self._centerVerts[i].y,
            self._centerVerts[i + 1].x, self._centerVerts[i + 1].y)
    end

    titleCol.r, titleCol.g, titleCol.b = accent.r, accent.g, accent.b
    titleCol.a = math.floor(255 * ol)
    D.TextShadow(self.Title:upper(), "KS.radial.title", cx, cy - Scaled(4) * ol, titleCol,
        TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if self.SelectedTitle ~= "" then
        local sec = P("TextSecondary")
        selCol.r, selCol.g, selCol.b = sec.r, sec.g, sec.b
        selCol.a = math.floor(220 * ol)
        D.TextShadow(TruncText(self.SelectedTitle:upper(), "KS.radial.sub", rIn * 1.6),
            "KS.radial.sub", cx, cy + Scaled(8) * ol, selCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

vgui.Register("KrakenSquad.Radial", PANEL, "DPanel")

local function OpenSubRadial(title)
    local sub = vgui.Create("KrakenSquad.Radial")
    sub:SetSize(ScrW(), ScrH()); sub:Center(); sub:MakePopup()
    sub:SetKeyboardInputEnabled(false)
    sub:SetTitle(title)
    KrakenSquad._Radial = sub
    return sub
end

local function LocalizedItemName(item)
    return KrakenSquad.ItemName(item)
end

function KrakenSquad.OpenRadial()
    if IsValid(KrakenSquad._Radial) then KrakenSquad._Radial:Remove() end
    KF.Helpers.PlaySound(SOUNDS.open)
    local pnl = OpenSubRadial(KrakenSquad.L("squad"))
    local lp  = LocalPlayer()

    pnl:AddItem({ text = KrakenSquad.L("leave"), icon = "kraken/squads/icons/leave.png", func = KrakenSquad.RequestLeave })

    local current = lp:GetKSSquad()
    if current and current.preset then
        local switchTargets = {}
        for _, p in ipairs(KrakenSquad.GetConfig("presetSquads") or {}) do
            if p.name ~= current.name and p.filters and #p.filters > 0
               and KrakenSquad.PlayerMatchesFilters(lp, p.filters) then
                switchTargets[#switchTargets + 1] = p.name
            end
        end
        if #switchTargets > 0 then
            pnl:AddItem({
                text = KrakenSquad.L("switch_squad"),
                icon = "kraken/squads/icons/invite.png",
                func = function()
                    local sub = OpenSubRadial(KrakenSquad.L("switch_squad"))
                    for _, name in ipairs(switchTargets) do
                        sub:AddItem({
                            text = name, icon = "kraken/squads/icons/invite.png",
                            func = function()
                                net.Start("KS.RequestSwitchPreset")
                                net.WriteString(name)
                                net.SendToServer()
                            end,
                        })
                    end
                end,
            })
        end
    end

    if lp:KSIsLeader() then
        pnl:AddItem({
            text = KrakenSquad.L("commands"),
            icon = "kraken/squads/icons/command.png",
            func = function()
                local sub = OpenSubRadial(KrakenSquad.L("commands"))
                for _, c in ipairs(KrakenSquad.GetCommands()) do
                    sub:AddItem({
                        text = LocalizedItemName(c), icon = c.icon,
                        func = function() KrakenSquad.RequestCommand(c.id) end,
                    })
                end
            end,
        })
        pnl:AddItem({
            text = KrakenSquad.L("assign_roles"),
            icon = "kraken/squads/icons/leader.png",
            func = function()
                local squad = lp:GetKSSquad()
                if not squad then return end
                local sub = OpenSubRadial(KrakenSquad.L("assign_roles"))
                for _, ply in ipairs(squad:GetMembers()) do
                    if IsValid(ply) and ply ~= lp then
                        local name = KF.Integrations.GetPlayerName(ply)
                        sub:AddItem({
                            text = name, icon = ply:GetKSPositionData().icon or "",
                            func = function()
                                local roleSub = OpenSubRadial(name)
                                for posIdx, posData in ipairs(KrakenSquad.GetPositions()) do
                                    if posIdx > 1 then
                                        roleSub:AddItem({
                                            text = posData.name, icon = posData.icon or "",
                                            func = function() KrakenSquad.RequestPosChange(ply, posIdx) end,
                                        })
                                    end
                                end
                            end,
                        })
                    end
                end
            end,
        })
    end

    pnl:AddItem({
        text = KrakenSquad.L("communications"),
        icon = "kraken/squads/icons/comms.png",
        func = function()
            local sub = OpenSubRadial(KrakenSquad.L("communications"))
            for _, c in ipairs(KrakenSquad.GetCommunications()) do
                sub:AddItem({
                    text = LocalizedItemName(c), icon = c.icon,
                    func = function() KrakenSquad.RequestComm(c.id) end,
                })
            end
        end,
    })

    pnl:AddItem({
        text = KrakenSquad.L("toggle_nametags"),
        icon = "kraken/squads/icons/nametag.png",
        func = KrakenSquad.ToggleNametags,
    })

    pnl:AddItem({
        text = KrakenSquad.L("invite_player"),
        icon = "kraken/squads/icons/invite.png",
        func = function()
            local ent = lp:GetEyeTrace().Entity
            if IsValid(ent) and ent:IsPlayer() then KrakenSquad.RequestInvite(ent) end
        end,
    })
end
