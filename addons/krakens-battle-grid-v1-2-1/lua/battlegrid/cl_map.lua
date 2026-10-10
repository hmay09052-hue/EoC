local S = KF.Scale

local ORTHO_ADJUST = 0.945
local MAP_BOUND = 15500

BattleGrid._renderingMap = false
BattleGrid._renderingParams = nil

hook.Add("PreDrawSkyBox", "BattleGrid.SuppressSkybox", function()
    if BattleGrid._renderingMap then return true end
end)

hook.Add("PostDrawOpaqueRenderables", "BattleGrid.VoidFloor", function(isDepth, isSkybox)
    if not BattleGrid._renderingMap or isSkybox or isDepth then return end
    local p = BattleGrid._renderingParams
    if not p then return end
    render.SetColorMaterial()
    render.DrawQuadEasy(Vector(p.cx, p.cy, p.floorZ), Vector(0, 0, 1), 131072, 131072, BattleGrid.C("VoidFloor"), 0)
end)

-- Z-view is kept per map; the slider writes it and every renderer reads this cached copy instead of the cookie.
local zViewCookie = "BattleGrid.z_view_" .. game.GetMap()
local zView = tonumber(cookie.GetString(zViewCookie, "0")) or 0

local function RenderTopDown(view, cx, cy, extent, cameraZ, renderZ)
    local zfar = renderZ + 16384
    view.origin = Vector(cx, cy, renderZ)
    view.znear = zView > 0 and math.max(renderZ - (cameraZ - zView), 1) or 1
    view.zfar = zfar
    view.drawviewmodel = false
    view.drawmonitors = false
    view.drawhud = false
    view.ortho = true

    BattleGrid._renderingMap = true
    BattleGrid._renderingParams = { cx = cx, cy = cy, extent = extent, floorZ = renderZ - zfar + 200 }
    BattleGrid:SetEntitiesNoDraw(true)
    render.SuppressEngineLighting(true)
    render.SetShadowsDisabled(true)
    render.PushFlashlightMode(false)
    render.PushFilterMag(TEXFILTER.NONE)
    render.PushFilterMin(TEXFILTER.NONE)

    render.RenderView(view)

    render.PopFilterMin()
    render.PopFilterMag()
    render.PopFlashlightMode()
    render.SetShadowsDisabled(false)
    render.SuppressEngineLighting(false)
    BattleGrid:SetEntitiesNoDraw(false)
    BattleGrid._renderingMap = false
    BattleGrid._renderingParams = nil
end

local function GroundZ(x, y)
    local tr = util.TraceLine({
        start = Vector(x, y, 16384),
        endpos = Vector(x, y, -16384),
        mask = MASK_SOLID_BRUSHONLY,
    })
    return tr.Hit and tr.HitPos.z or 0
end

local PORTRAIT_RT_SIZE = 128
local _portraits = {}

local function CleanupPortrait(sid)
    local data = _portraits[sid]
    if not data then return end
    if IsValid(data.csmodel) then data.csmodel:Remove() end
    _portraits[sid] = nil
end

local function CleanupAllPortraits()
    for sid, data in pairs(_portraits) do
        if IsValid(data.csmodel) then data.csmodel:Remove() end
    end
    _portraits = {}
end

local function EnsurePortrait(ply)
    if not IsValid(ply) then return nil end
    local sid = ply:SteamID64()
    if not sid then return nil end

    local data = _portraits[sid]
    local model = ply:GetModel()

    if not data then
        local rtName = "BG_Portrait_" .. sid
        local rt = GetRenderTargetEx(rtName, PORTRAIT_RT_SIZE, PORTRAIT_RT_SIZE, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(2, 256), 0, IMAGE_FORMAT_RGBA8888)
        local mat = CreateMaterial("BG_PortraitMat_" .. sid, "UnlitGeneric", {
            ["$basetexture"] = rt:GetName(),
            ["$translucent"] = 1,
            ["$vertexalpha"] = 1,
        })
        data = { rt = rt, mat = mat, model = "", lastUpdate = 0 }
        _portraits[sid] = data
    end

    if data.model ~= model then
        if IsValid(data.csmodel) then data.csmodel:Remove() end
        local csEnt = ClientsideModel(model, RENDERGROUP_OTHER)
        if not IsValid(csEnt) then return data end
        csEnt:SetNoDraw(true)
        csEnt:SetPos(Vector(0, 0, 0))
        csEnt:SetAngles(Angle(0, 0, 0))
        local seq = csEnt:LookupSequence("idle_all_01")
        if not seq or seq <= 0 then seq = csEnt:LookupSequence("idle_all") end
        if not seq or seq <= 0 then seq = 0 end
        csEnt:SetSequence(seq)
        csEnt:SetCycle(0)
        data.csmodel = csEnt
        data.model = model
        data.lastUpdate = 0
    end

    return data
end

local function RenderPortrait(data)
    if not IsValid(data.csmodel) then return end
    local now = RealTime()
    if now - data.lastUpdate < 2 then return end
    data.lastUpdate = now

    local ent = data.csmodel
    local _, maxs = ent:GetRenderBounds()
    local eyeZ = maxs.z * 0.82
    local camPos = Vector(45, 0, eyeZ)
    local lookAt = Vector(0, 0, eyeZ)

    render.PushRenderTarget(data.rt)
    render.Clear(0, 0, 0, 0)
    render.ClearDepth()
    cam.Start3D(camPos, (lookAt - camPos):Angle(), 28, 0, 0, PORTRAIT_RT_SIZE, PORTRAIT_RT_SIZE)
    render.SuppressEngineLighting(true)
    render.SetModelLighting(BOX_FRONT, 0.85, 0.85, 0.85)
    render.SetModelLighting(BOX_BACK, 0.35, 0.35, 0.35)
    render.SetModelLighting(BOX_RIGHT, 0.6, 0.6, 0.6)
    render.SetModelLighting(BOX_LEFT, 0.6, 0.6, 0.6)
    render.SetModelLighting(BOX_TOP, 0.95, 0.95, 0.95)
    render.SetModelLighting(BOX_BOTTOM, 0.25, 0.25, 0.25)
    ent:DrawModel()
    render.SuppressEngineLighting(false)
    cam.End3D()
    render.PopRenderTarget()
end

hook.Add("PostRender", "BattleGrid.PlayerPortraits", function()
    if not IsValid(BattleGrid.MapFrame) then return end
    for sid, data in pairs(_portraits) do
        RenderPortrait(data)
    end
end)

local gridLetters = {}

function BattleGrid:OpenMap()
    gridLetters = {}
    local letters = BattleGrid:L("MAP_GRID_LETTERS")
    for i = 1, #letters do gridLetters[i] = string.sub(letters, i, i) end

    if IsValid(self.PrefFrame) then self.PrefFrame:Remove() end

    if not BattleGrid:IsMapAllowed() then
        chat.AddText(BattleGrid.C("Error"), BattleGrid:GetPrefixText(), BattleGrid.C("TextPrimary"), BattleGrid:L("MAP_BLOCKED"))
        return
    end

    if IsValid(self.MapFrame) then self.MapFrame:Remove() end

    local scrW, scrH = ScrW(), ScrH()
    local width = scrW
    local height = scrH

    self.MapFrame = vgui.Create("DFrame")
    self.MapFrame:SetTitle("")
    self.MapFrame:SetSize(width, height)
    self.MapFrame:SetPos(0, 0)
    self.MapFrame:MakePopup()
    self.MapFrame:SetDraggable(false)
    self.MapFrame:ShowCloseButton(false)
    self.MapFrame:DockPadding(0, 0, 0, 0)
    self.MapFrame:SetAlpha(0)
    self.MapFrame:AlphaTo(255, 0.15)

    local frame = self.MapFrame

    function frame:Paint(w, h)
        KF.Materials.DrawBlur(self, 3)
        surface.SetDrawColor(BattleGrid.C("Background"))
        surface.DrawRect(0, 0, w, h)
    end

    function frame:OnRemove()
        hook.Remove("PlayerBindPress", "BattleGrid.BlockEscMenu")
        hook.Remove("BattleGrid.CommandPostsUpdated", "BattleGrid.FactionPanelRefresh")
        if IsValid(BattleGrid.RadialWheel) then BattleGrid.RadialWheel:Remove() end
        if IsValid(BattleGrid.WaypointEditorFrame) then BattleGrid.WaypointEditorFrame:Remove() end
        if IsValid(BattleGrid.AreaEditorFrame) then BattleGrid.AreaEditorFrame:Remove() end
        BattleGrid.RadialWheel = nil
        BattleGrid.MapSettingsPanel = nil
        BattleGrid.FactionPanel = nil
        CleanupAllPortraits()
    end

    local headerH = S(80)
    local headerPanel = vgui.Create("DPanel", frame)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(headerH)
    headerPanel.Paint = function(_, w, h)
        surface.SetDrawColor(BattleGrid.C("PanelDark"))
        surface.DrawRect(0, 0, w, h)

        draw.SimpleText(string.upper(BattleGrid:L("ADDON_NAME")), BattleGrid.F("Header"), S(15), S(12),
            BattleGrid.C("Accent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local mapName = game.GetMap()
        draw.SimpleText(string.upper(mapName), BattleGrid.F("small"), S(15), S(42),
            BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        surface.SetDrawColor(BattleGrid.C("MapSeparator"))
        surface.DrawRect(0, h - 2, w, 2)
    end

    local closeBtnSize = S(26)
    local closeBtn = BattleGrid:CreateCloseButton(frame, function()
        frame:AlphaTo(0, 0.1, 0, function()
            if IsValid(frame) then frame:Remove() end
        end)
    end)
    closeBtn:SetSize(closeBtnSize, closeBtnSize)
    closeBtn:SetPos(width - closeBtnSize - S(12), (headerH - closeBtnSize) / 2)

    local prefBtnW = S(100)
    local prefBtnH = S(26)
    local settingsBtn = vgui.Create("DButton", frame)
    settingsBtn:SetPos(width - closeBtnSize - S(12) - prefBtnW - S(8), (headerH - prefBtnH) / 2)
    settingsBtn:SetSize(prefBtnW, prefBtnH)
    settingsBtn:SetText("")
    settingsBtn:SetCursor("hand")
    settingsBtn._hoverAlpha = 0

    function settingsBtn:Paint(w, h)
        KF.Helpers.HandleHoverSound(self, BattleGrid.Sounds.Hover)
        KF.Anim.UpdateHoverLerp(self, 8, "_hoverAlpha")
        local isOpen = IsValid(BattleGrid.MapSettingsPanel)

        local bgAlpha = isOpen and 255 or math.floor(self._hoverAlpha * 255)
        local bgCol = KF.UI.ColorAlpha(BattleGrid.C("PanelHover"), bgAlpha)
        KF.Menu.MenuNotchedBox(0, 0, w, h, bgCol, KF.Menu.NOTCH)
        KF.Menu.MenuNotchedOutline(0, 0, w, h, BattleGrid.C("Border"), KF.Menu.NOTCH, 1)

        if isOpen then
            surface.SetDrawColor(BattleGrid.C("Accent"))
            surface.DrawRect(0, h - 2, w, 2)
        end

        local textCol = isOpen and BattleGrid.C("Accent") or KF.UI.LerpColor(self._hoverAlpha, BattleGrid.C("TextMuted"), BattleGrid.C("TextPrimary"))
        draw.SimpleText(string.upper(BattleGrid:L("PREF_BTN")), BattleGrid.FB("caption"), w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function settingsBtn:DoClick()
        BattleGrid:PlaySound("Click")
        BattleGrid:ToggleMapSettings()
    end
    local facBtnW = S(100)
    local facBtnH = S(26)
    local factionBtn = vgui.Create("DButton", frame)
    factionBtn:SetPos(width - closeBtnSize - S(12) - prefBtnW - S(8) - facBtnW - S(8), (headerH - facBtnH) / 2)
    factionBtn:SetSize(facBtnW, facBtnH)
    factionBtn:SetText("")
    factionBtn:SetCursor("hand")
    factionBtn._hoverAlpha = 0

    function factionBtn:Paint(w, h)
        KF.Helpers.HandleHoverSound(self, BattleGrid.Sounds.Hover)
        KF.Anim.UpdateHoverLerp(self, 8, "_hoverAlpha")
        local isOpen = IsValid(BattleGrid.FactionPanel)

        local bgAlpha = isOpen and 255 or math.floor(self._hoverAlpha * 255)
        local bgCol = KF.UI.ColorAlpha(BattleGrid.C("PanelHover"), bgAlpha)
        KF.Menu.MenuNotchedBox(0, 0, w, h, bgCol, KF.Menu.NOTCH)
        KF.Menu.MenuNotchedOutline(0, 0, w, h, BattleGrid.C("Border"), KF.Menu.NOTCH, 1)

        if isOpen then
            surface.SetDrawColor(BattleGrid.C("Accent"))
            surface.DrawRect(0, h - 2, w, 2)
        end

        local textCol = isOpen and BattleGrid.C("Accent") or KF.UI.LerpColor(self._hoverAlpha, BattleGrid.C("TextMuted"), BattleGrid.C("TextPrimary"))
        draw.SimpleText(string.upper(BattleGrid:L("FACTIONS")), BattleGrid.FB("caption"), w / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function factionBtn:DoClick()
        BattleGrid:PlaySound("Click")
        BattleGrid:ToggleFactionPanel()
    end

    local footerH = S(32)
    local footer = vgui.Create("DPanel", frame)
    footer:Dock(BOTTOM)
    footer:SetTall(footerH)

    local zSliderW = S(280)
    local zSliderPanel = vgui.Create("DPanel", footer)
    zSliderPanel:SetSize(zSliderW, footerH)
    zSliderPanel:SetPaintBackground(false)

    local zLabel = vgui.Create("DLabel", zSliderPanel)
    zLabel:Dock(LEFT)
    zLabel:SetText(BattleGrid:L("MAP_Z_VIEW"))
    zLabel:SetFont(BattleGrid.F("tiny"))
    zLabel:SetTextColor(BattleGrid.C("TextMuted"))
    zLabel:SizeToContents()
    zLabel:DockMargin(0, 0, S(6), 0)

    local zSlider = vgui.Create("DNumSlider", zSliderPanel)
    zSlider:Dock(FILL)
    zSlider:SetMin(0)
    zSlider:SetMax(32000)
    zSlider:SetDecimals(0)
    zSlider:SetValue(zView)
    BattleGrid:StyleSlider(zSlider, BattleGrid.F("tiny"))
    function zSlider:OnValueChanged(val)
        zView = math.floor(val)
        cookie.Set(zViewCookie, tostring(zView))
    end

    footer.PerformLayout = function(self, w, h)
        zSliderPanel:SetPos(w / 2 - zSliderW / 2, 0)
    end

    function footer:Paint(w, h)
        surface.SetDrawColor(BattleGrid.C("PanelDark"))
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(BattleGrid.C("Border"))
        surface.DrawRect(0, 0, w, 1)

        if IsValid(self:GetParent()) and self:GetParent().MapPanel then
            local mapPanel = self:GetParent().MapPanel
            if IsValid(mapPanel) then
                local zoomPct = math.Round((1 - (mapPanel:GetZoom() - 10) / 9990) * 100)
                draw.SimpleText(zoomPct .. "%", BattleGrid.F("small"), w - S(120), h / 2, BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        local shortcuts = {
            {"C", BattleGrid:L("SHORTCUT_CENTER")},
            {"R", BattleGrid:L("SHORTCUT_MEASURE")},
            {"CTRL+Z", BattleGrid:L("SHORTCUT_UNDO")},
            {"ESC", BattleGrid:L("SHORTCUT_CLOSE")},
        }
        local sx = S(14)
        local badgeFont = BattleGrid.FB("caption")
        local labelFont = BattleGrid.F("small")
        local badgeH = S(20)
        local badgeY = math.floor(h / 2 - badgeH / 2)
        local textCol = BattleGrid.C("TextPrimary")
        local mutedCol = BattleGrid.C("TextMuted")
        local borderCol = BattleGrid.C("Border")
        for _, sc in ipairs(shortcuts) do
            surface.SetFont(badgeFont)
            local kw = surface.GetTextSize(sc[1])
            local bw = kw + S(12)
            surface.SetDrawColor(borderCol)
            surface.DrawOutlinedRect(sx, badgeY, bw, badgeH, 1)
            draw.SimpleText(sc[1], badgeFont, sx + bw / 2, h / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            sx = sx + bw + S(6)
            surface.SetFont(labelFont)
            local lw = surface.GetTextSize(string.upper(sc[2]))
            draw.SimpleText(string.upper(sc[2]), labelFont, sx, h / 2, mutedCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            sx = sx + lw + S(16)
        end
    end

    local footerRight = vgui.Create("DLabel", footer)
    footerRight:Dock(RIGHT)
    footerRight:DockMargin(0, 0, S(50), 0)
    footerRight:SetText(GetHostName() or "")
    footerRight:SetFont(BattleGrid.F("small"))
    footerRight:SetTextColor(BattleGrid.C("TextMuted"))
    footerRight:SizeToContents()

    local measureMode = false
    local measureP1 = nil
    local measureP2 = nil

    function BattleGrid:ToggleMeasureMode()
        measureMode = not measureMode
        measureP1 = nil
        measureP2 = nil
        if measureMode then
            BattleGrid:Toast(BattleGrid:L("MEASURE_START"), "info", 3)
        end
    end

    function BattleGrid:CenterOnPlayer()
        local mp = BattleGrid.MapPanel
        if IsValid(mp) then
            mp.campos.x = LocalPlayer():GetPos().x
            mp.campos.y = LocalPlayer():GetPos().y
            BattleGrid:Toast(BattleGrid:L("TOAST_CENTERED"), "info", 2)
        end
    end

    local function BuildFactionPanelContent(scroll, factionPanelW)
        scroll:Clear()

        local totalCPs = BattleGrid:IsCPSystemEnabled() and #BattleGrid.Cache.CommandPosts or 0

        if totalCPs > 0 then
            local overviewBar = vgui.Create("DPanel", scroll)
            overviewBar:Dock(TOP)
            overviewBar:SetTall(S(6))
            overviewBar:DockMargin(S(10), S(6), S(10), S(6))
            overviewBar.Paint = function(_, w, h)
                surface.SetDrawColor(BattleGrid.C("BarTrack"))
                surface.DrawRect(0, 0, w, h)
                local xOff = 0
                for _, f in ipairs(BattleGrid.FactionList) do
                    local count = 0
                    for _, cp in ipairs(BattleGrid.Cache.CommandPosts) do
                        if cp.owner == f.id then count = count + 1 end
                    end
                    if count > 0 then
                        local segW = math.floor(w * count / totalCPs)
                        surface.SetDrawColor(f.color or BattleGrid.C("Accent"))
                        surface.DrawRect(xOff, 0, segW, h)
                        xOff = xOff + segW
                    end
                end
            end
        end

        for fIdx, faction in ipairs(BattleGrid.FactionList) do
            local fColor = faction.color or BattleGrid.C("Accent")

            local ownedCPs = {}
            if BattleGrid:IsCPSystemEnabled() then
                for _, cp in ipairs(BattleGrid.Cache.CommandPosts) do
                    if cp.owner == faction.id then
                        table.insert(ownedCPs, cp)
                    end
                end
            end

            local headerRow = vgui.Create("DPanel", scroll)
            headerRow:Dock(TOP)
            headerRow:SetTall(S(32))
            headerRow:DockMargin(S(10), fIdx == 1 and S(2) or S(6), S(10), 0)
            headerRow.Paint = function(_, w, h)
                KF.Draw.NotchedBox(0, 0, w, h, S(6), KF.UI.ColorAlpha(fColor, 18), fColor, 1, "right")
            end

            local iconSize = S(20)
            local fIcon = vgui.Create("DPanel", headerRow)
            fIcon:SetSize(iconSize, iconSize)
            fIcon:SetPos(S(8), (S(32) - iconSize) / 2)
            fIcon:SetPaintBackground(false)
            fIcon.Paint = function(_, w, h)
                if faction.icon and faction.icon ~= "" then
                    BattleGrid:DrawIcon(faction.icon, 0, 0, w, h, fColor)
                else
                    draw.RoundedBox(w / 2, 0, 0, w, h, fColor)
                end
            end

            local fNameX = S(8) + iconSize + S(6)
            local fNameW = factionPanelW - iconSize - S(70)
            local fNameText = string.upper(faction.name)
            local fNameFont = BattleGrid.FB("caption")
            local fNameId = "faction_name_" .. faction.id

            local fName = vgui.Create("DPanel", headerRow)
            fName:SetPos(fNameX, 0)
            fName:SetSize(fNameW, S(32))
            fName:SetPaintBackground(false)
            fName.Paint = function(pnl, w, h)
                local sx, sy = pnl:LocalToScreen(0, 0)
                KF.Draw.ScrollingText(fNameId, fNameText, fNameFont, 0, h / 2, w, fColor, TEXT_ALIGN_CENTER, {
                    scrollSpeed = 30,
                    pauseTime = 2.5,
                    screenX = sx,
                    screenY = sy,
                })
            end

            local statsRow = vgui.Create("DPanel", scroll)
            statsRow:Dock(TOP)
            statsRow:SetTall(S(16))
            statsRow:DockMargin(S(10), S(2), S(10), 0)
            statsRow:SetPaintBackground(false)
            statsRow.Paint = function(_, w, h)
                local midY = h / 2
                local pc = 0
                for _, ply in ipairs(player.GetAll()) do
                    if IsValid(ply) then
                        local pf = BattleGrid:GetPlayerFaction(ply)
                        if pf and pf.id == faction.id then pc = pc + 1 end
                    end
                end
                local plyText = BattleGrid:L("FACTION_PLAYER_COUNT", pc)
                draw.SimpleText(plyText, BattleGrid.F("tiny"), S(4), midY, BattleGrid.C("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                if BattleGrid:IsCPSystemEnabled() then
                    local cpText = #ownedCPs .. "/" .. totalCPs .. " P"
                    local cpCol = #ownedCPs > 0 and fColor or BattleGrid.C("TextMuted")
                    draw.SimpleText(cpText, BattleGrid.F("tiny"), w - S(4), midY, cpCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                end
            end

            if BattleGrid:IsCPSystemEnabled() and totalCPs > 0 then
                local progressRow = vgui.Create("DPanel", scroll)
                progressRow:Dock(TOP)
                progressRow:SetTall(S(4))
                progressRow:DockMargin(S(14), S(2), S(14), S(2))
                progressRow:SetPaintBackground(false)
                progressRow.Paint = function(_, w, h)
                    surface.SetDrawColor(BattleGrid.C("BarTrackLight"))
                    surface.DrawRect(0, 0, w, h)
                    local frac = #ownedCPs / totalCPs
                    if frac > 0 then
                        surface.SetDrawColor(fColor)
                        surface.DrawRect(0, 0, math.ceil(w * frac), h)
                    end
                end
            end

            if BattleGrid:IsCPSystemEnabled() and #ownedCPs > 0 then
                for _, cp in ipairs(ownedCPs) do
                    local cpOwnerCol = BattleGrid:GetCPOwnerColor(cp)
                    local cpRow = vgui.Create("DButton", scroll)
                    cpRow:Dock(TOP)
                    cpRow:SetTall(S(20))
                    cpRow:DockMargin(S(14), S(1), S(10), S(1))
                    cpRow:SetText("")
                    cpRow:SetCursor("hand")
                    cpRow._hoverAlpha = 0
                    cpRow.Paint = function(pnl, w, h)
                        KF.Anim.UpdateHoverLerp(pnl, 10, "_hoverAlpha")
                        local canTravel = BattleGrid:CanFastTravel(cp)
                        local hoverA = pnl._hoverAlpha

                        local bgA = math.floor(hoverA * (canTravel and 40 or 15))
                        if bgA > 0 then
                            surface.SetDrawColor(KF.UI.ColorAlpha(color_white, bgA))
                            surface.DrawRect(0, 0, w, h)
                        end

                        local hexR = S(7)
                        local hexX = hexR + S(1)
                        local hexY = h / 2
                        BattleGrid:DrawHex(hexX, hexY, hexR, cpOwnerCol, KF.UI.ColorAlpha(color_white, 50))
                        local prefix = cp.prefix or ""
                        if prefix ~= "" then
                            draw.SimpleText(prefix, BattleGrid.F("tiny"), hexX, hexY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        end

                        local textX = hexX + hexR + S(5)
                        draw.SimpleText(cp.name or BattleGrid:L("FACTION_JOB_UNKNOWN"), BattleGrid.F("small"), textX, hexY, BattleGrid.C("TextSecondary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                        if canTravel and hoverA > 0.3 then
                            local travelText = BattleGrid:L("FAST_TRAVEL")
                            local cost = BattleGrid:CalcFastTravelCost(LocalPlayer():GetPos(), cp.pos)
                            if cost > 0 then
                                travelText = travelText .. " ($" .. cost .. ")"
                            end
                            local travelAlpha = math.floor(math.Clamp((hoverA - 0.3) / 0.7, 0, 1) * 255)
                            draw.SimpleText(travelText, BattleGrid.F("tiny"), w - S(2), hexY, ColorAlpha(BattleGrid.C("Accent"), travelAlpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        else
                            local stateKey = BattleGrid:GetCPStateKey(cp.state)
                            local stateText = BattleGrid:L(stateKey)
                            draw.SimpleText(stateText, BattleGrid.F("tiny"), w - S(2), hexY, KF.UI.ColorAlpha(cpOwnerCol, 160), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
                        end
                    end

                    cpRow.DoClick = function()
                        BattleGrid:PlaySound("Click")
                        BattleGrid:RequestFastTravel(cp.identifier)
                    end
                end
            end

            if fIdx < #BattleGrid.FactionList then
                local sep = vgui.Create("DPanel", scroll)
                sep:Dock(TOP)
                sep:SetTall(S(1))
                sep:DockMargin(S(20), S(6), S(20), 0)
                sep.Paint = function(_, w, h)
                    surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("Border"), 40))
                    surface.DrawRect(0, 0, w, h)
                end
            end
        end
    end

    function BattleGrid:ToggleFactionPanel()
        if IsValid(self.FactionPanel) then
            local panel = self.FactionPanel
            self.FactionPanel = nil
            hook.Remove("BattleGrid.CommandPostsUpdated", "BattleGrid.FactionPanelRefresh")
            panel:SizeTo(0, -1, 0.2, 0, -1, function()
                if IsValid(panel) then panel:Remove() end
            end)
            return
        end

        if not self:IsFactionSystemEnabled() or #self.FactionList < 2 then
            return
        end

        local factionPanelW = S(260)
        local leftPanel = vgui.Create("DPanel", frame)
        leftPanel:Dock(LEFT)
        leftPanel:SetWide(0)
        leftPanel:SetAlpha(0)
        leftPanel.Paint = function(_, w, h)
            surface.SetDrawColor(KF.UI.ColorAlpha(color_black, 220))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("Border"), 80))
            surface.DrawRect(w - 1, 0, 1, h)
        end

        local scroll = vgui.Create("KF.ScrollPanel", leftPanel)
        scroll:Dock(FILL)
        scroll:SetAddon("battlegrid")
        scroll:DockMargin(0, S(4), 0, 0)

        BuildFactionPanelContent(scroll, factionPanelW)

        hook.Add("BattleGrid.CommandPostsUpdated", "BattleGrid.FactionPanelRefresh", function()
            if not IsValid(scroll) then
                hook.Remove("BattleGrid.CommandPostsUpdated", "BattleGrid.FactionPanelRefresh")
                return
            end
            BuildFactionPanelContent(scroll, factionPanelW)
        end)

        leftPanel:SizeTo(factionPanelW, -1, 0.2, 0, -1)
        leftPanel:AlphaTo(255, 0.15, 0.05)

        self.FactionPanel = leftPanel
    end

    function BattleGrid:ToggleMapSettings()
        if IsValid(self.MapSettingsPanel) then
            local panel = self.MapSettingsPanel
            self.MapSettingsPanel = nil
            panel:SizeTo(0, -1, 0.2, 0, -1, function()
                if IsValid(panel) then panel:Remove() end
            end)
            return
        end

        local settingsW = S(340)
        local sidePanel = vgui.Create("DPanel", frame)
        sidePanel:Dock(RIGHT)
        sidePanel:SetWide(0)
        sidePanel:SetAlpha(0)
        sidePanel.Paint = function(_, w, h)
            surface.SetDrawColor(BattleGrid.C("PanelDark"))
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(BattleGrid.C("BorderSubtle"))
            surface.DrawRect(0, 0, 1, h)
        end

        BattleGrid:PopulateSettingsPanel(sidePanel)

        sidePanel:SizeTo(settingsW, -1, 0.2, 0, -1)
        sidePanel:AlphaTo(255, 0.15, 0.05)

        self.MapSettingsPanel = sidePanel
    end

    self.MapPanel = vgui.Create("DPanel", frame)
    self.MapPanel:Dock(FILL)
    self.MapPanel:DockMargin(0, 0, 0, 0)
    self.MapPanel:SetCursor("sizeall")

    local panel = self.MapPanel

    local cameraZ = BattleGrid:GetConfigNumber("map_camera_distance")
    panel.zoom = BattleGrid:GetConfigNumber("map_default_zoom")
    panel.campos = Vector(LocalPlayer():GetPos().x, LocalPlayer():GetPos().y, cameraZ)

    panel.lastPress = nil

    function panel:AspectRatio()
        local pw, ph = self:GetWide(), self:GetTall()
        if ph == 0 or pw == 0 then return 1, 1 end
        local aw = pw / ph
        local ah = 1 / aw
        if aw > 1 then ah = 1 else aw = 1 end
        return aw, ah
    end

    function panel:GetZoom() return self.zoom end
    function panel:SetZoom(v) self.zoom = v end

    local selectArea = false
    local areaPos1, areaPos2 = nil, nil

    local dragWP = nil

    BattleGrid._undoStack = BattleGrid._undoStack or {}

    local function PushUndo(actionType, data)
        table.insert(BattleGrid._undoStack, { type = actionType, data = data, time = RealTime() })
        if #BattleGrid._undoStack > 50 then
            table.remove(BattleGrid._undoStack, 1)
        end
    end

    function panel:HitTestWaypoint(sx, sy)
        local hitR = S(16)
        for _, wp in ipairs(BattleGrid.Cache.Waypoints) do
            local wx, wy = self:WorldToScreen(wp.pos)
            local dx, dy = sx - wx, sy - wy
            if dx * dx + dy * dy < hitR * hitR then
                return wp
            end
        end
        return nil
    end

    function panel:HitTestArea(sx, sy)
        for _, area in ipairs(BattleGrid.Cache.Areas) do
            local x1, y1 = self:WorldToScreen(area.pos1)
            local x2, y2 = self:WorldToScreen(area.pos2)

            if area.type == BattleGrid.AreaTypes.RECTANGULAR then
                local minX, maxX = math.min(x1, x2), math.max(x1, x2)
                local minY, maxY = math.min(y1, y2), math.max(y1, y2)
                if sx >= minX and sx <= maxX and sy >= minY and sy <= maxY then
                    return area
                end
            elseif area.type == BattleGrid.AreaTypes.ROUND then
                local dx, dy = sx - x1, sy - y1
                local r = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
                if dx * dx + dy * dy < r * r then
                    return area
                end
            end
        end
        return nil
    end

    function panel:Paint(w, h)
        local aw, ah = self:AspectRatio()
        local x, y = frame:LocalToScreen(self:GetPos())
        local zoom = self:GetZoom()

        self._zFilterZ = (zView > 0 and BattleGrid:GetPref("z_filter_markers")) and (cameraZ - zView) or nil
        RenderTopDown({
            angles = Angle(90, 0, 0),
            x = x, y = y, w = w, h = h,
            ortholeft   = -zoom / 2 * aw,
            orthotop    = -zoom / 2 * ah,
            orthoright  =  zoom / 2 * aw,
            orthobottom =  zoom / 2 * ah,
        }, self.campos.x, self.campos.y, zoom * math.max(aw, ah) * 0.75, cameraZ, GroundZ(self.campos.x, self.campos.y) + 128)

        draw.RoundedBox(0, 0, 0, w, h, KF.UI.ColorAlpha(BattleGrid.C("MapOverlay"), BattleGrid:GetConfigNumber("map_overlay_alpha")))

        self:DrawAreas()
        self:DrawWaypoints(zoom)
        self:DrawDisturbances()
        BattleGrid:DrawMapCommandPosts(self, zoom)
        if BattleGrid:GetPref("show_grid") then
            self:DrawGrid()
        end

        if BattleGrid:GetPref("show_player") then
            local lpX, lpY = self:WorldToScreen(LocalPlayer():GetPos())
            self:DrawPlayerMarker(lpX, lpY, BattleGrid.C("PlayerIcon"), BattleGrid:L("MARKER_YOU"), true)
        end

        if BattleGrid:GetPref("show_squad") then
            self:DrawSquadMembers()
        end

        if selectArea and areaPos1 then
            self:DrawAreaSelection(selectArea, areaPos1, areaPos2, h)
        end

        if dragWP then
            local dmx, dmy = self:GetLocalMouse()
            local iconSize = S(20)
            surface.SetDrawColor(KF.UI.ColorAlpha(dragWP.color, 180))
            if dragWP.icon and dragWP.icon ~= "" then
                BattleGrid:DrawIcon(dragWP.icon, dmx - iconSize / 2, dmy - iconSize / 2, iconSize, iconSize, KF.UI.ColorAlpha(dragWP.color, 180))
            else
                draw.NoTexture()
                BattleGrid:DrawCircle(dmx, dmy, iconSize / 3, 16)
            end
            draw.SimpleText(dragWP.name, BattleGrid.F("MapLabel"), dmx, dmy + iconSize * 0.7, KF.UI.ColorAlpha(dragWP.color, 180), TEXT_ALIGN_CENTER)
        end

        if measureP1 then
            local mx1, my1 = self:WorldToScreen(measureP1)
            surface.SetDrawColor(BattleGrid.C("Warning"))
            draw.NoTexture()
            BattleGrid:DrawCircle(mx1, my1, S(5), 12)
            draw.SimpleText(BattleGrid:L("MAP_MEASURE_POINT_A"), BattleGrid.F("MapLabel"), mx1, my1 - S(12), BattleGrid.C("Warning"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

            local endX, endY
            if measureP2 then
                endX, endY = self:WorldToScreen(measureP2)
            else
                endX, endY = self:GetLocalMouse()
            end

            surface.SetDrawColor(BattleGrid.C("Warning"))
            surface.DrawLine(mx1, my1, endX, endY)

            local endWorld = measureP2 or self:GetMouseWorldPos()
            local dist = measureP1:Distance(endWorld)
            local midX = (mx1 + endX) / 2
            local midY = (my1 + endY) / 2
            local distStr = BattleGrid:FormatDistance(dist)

            surface.SetFont(BattleGrid.F("MapLabel"))
            local distTextW = surface.GetTextSize(distStr)
            local boxW = math.max(S(80), distTextW + S(16))
            local panelDark = BattleGrid.C("PanelDark")
            draw.RoundedBox(4, midX - boxW / 2, midY - S(12), boxW, S(24), KF.UI.ColorAlpha(panelDark, 200))
            draw.SimpleText(distStr, BattleGrid.F("MapLabel"), midX, midY, BattleGrid.C("Warning"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            if measureP2 then
                draw.NoTexture()
                surface.SetDrawColor(BattleGrid.C("Warning"))
                BattleGrid:DrawCircle(endX, endY, S(5), 12)
                draw.SimpleText(BattleGrid:L("MAP_MEASURE_POINT_B"), BattleGrid.F("MapLabel"), endX, endY - S(12), BattleGrid.C("Warning"), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
        end

        if measureMode and not measureP1 then
            draw.SimpleText(BattleGrid:L("MEASURE_HINT"), BattleGrid.F("MapLabel"), w / 2, h - S(30), BattleGrid.C("Warning"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if BattleGrid:GetPref("show_compass") then
            self:DrawCompass(w, h)
        end

        if not BattleGrid.Cache._wpSynced or not BattleGrid.Cache._areaSynced then
            draw.SimpleText(BattleGrid:L("MAP_SYNCING"), BattleGrid.F("small"), w / 2, S(12), BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        end

        BattleGrid:DrawFactionHUD(w, h)
    end

    function panel:WorldToScreen(worldPos)
        local aw, ah = self:AspectRatio()
        local adjustW = aw * ORTHO_ADJUST
        local adjustH = ah * ORTHO_ADJUST
        local zoom = self:GetZoom()

        local offset = self.campos - worldPos
        local sx = offset.y / (zoom * adjustW)
        local sy = offset.x / (zoom * adjustH)

        return sx * self:GetWide() + self:GetWide() / 2,
               sy * self:GetTall() + self:GetTall() / 2
    end

    function panel:ScreenToWorld(pos, cx, cy)
        local aw, ah = self:AspectRatio()
        local adjustW = aw * ORTHO_ADJUST
        local adjustH = ah * ORTHO_ADJUST
        local zoom = self:GetZoom()

        local sx = cx * (zoom * adjustW) / self:GetWide()
        local sy = cy * (zoom * adjustH) / self:GetTall()

        return pos.x - sy, pos.y - sx
    end

    function panel:CalculateWorldPos(screenX, screenY)
        local halfW = self:GetWide() / 2
        local halfH = self:GetTall() / 2

        local worldPos = Vector()
        worldPos.x, worldPos.y = self:ScreenToWorld(self.campos, screenX - halfW, screenY - halfH)

        worldPos.z = zView > 0 and (cameraZ - zView) or cameraZ

        local tr = util.TraceLine({
            start = worldPos,
            endpos = worldPos - Vector(0, 0, 32768),
            mask = MASK_SOLID_BRUSHONLY,
            filter = LocalPlayer(),
        })

        worldPos.z = tr.HitPos.z
        return worldPos
    end

    function panel:GetMouseWorldPos()
        local mx, my = self:ScreenToLocal(gui.MousePos())
        return self:CalculateWorldPos(mx, my)
    end

    function panel:GetLocalMouse()
        return self:ScreenToLocal(gui.MousePos())
    end

    function panel:DrawPlayerMarker(x, y, col, label, isLocal)
        if isLocal then
            local chevH = height * 0.018
            local chevW = chevH * 0.7
            local compassState = BattleGrid.Compat.CompassState()
            local yaw = compassState and compassState.smoothedYaw or LocalPlayer():EyeAngles().y
            local rad = math.rad(yaw + 90)

            local cosR = math.cos(rad)
            local sinR = math.sin(rad)

            local tipX  = x + cosR * chevH
            local tipY  = y - sinR * chevH
            local lX    = x + (cosR * (-chevH * 0.4) - sinR * (-chevW))
            local lY    = y - (sinR * (-chevH * 0.4) + cosR * (-chevW))
            local rX    = x + (cosR * (-chevH * 0.4) - sinR * chevW)
            local rY    = y - (sinR * (-chevH * 0.4) + cosR * chevW)
            local nX    = x + cosR * (-chevH * 0.15)
            local nY    = y - sinR * (-chevH * 0.15)

            surface.SetDrawColor(KF.UI.ColorAlpha(col, 230))
            surface.DrawLine(tipX, tipY, lX, lY)
            surface.DrawLine(tipX, tipY, rX, rY)
            surface.DrawLine(lX, lY, nX, nY)
            surface.DrawLine(rX, rY, nX, nY)

            draw.SimpleText(label, BattleGrid.F("small"), x, y + chevH + S(3), col, TEXT_ALIGN_CENTER)
        else
            local pulse = math.sin(CurTime() * 3) * 8
            draw.NoTexture()
            surface.SetDrawColor(KF.UI.ColorAlpha(col, 15))
            BattleGrid:DrawCircle(x, y, height * 0.025 + pulse, 24)
            surface.SetDrawColor(col)
            BattleGrid:DrawCircle(x, y, height * 0.008, 16)
            draw.SimpleText(label, BattleGrid.F("MapLabel"), x, y + height * 0.03, col, TEXT_ALIGN_CENTER)
        end
    end

    function panel:DrawSquadMemberMarker(x, y, col, label, ply)
        local portrait = EnsurePortrait(ply)
        local size = height * 0.028
        local half = size / 2
        local bord = 2

        surface.SetDrawColor(KF.UI.ColorAlpha(color_black, 200))
        surface.DrawRect(x - half, y - half, size, size)

        if portrait and portrait.mat and portrait.lastUpdate > 0 then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(portrait.mat)
            surface.DrawTexturedRect(x - half + bord, y - half + bord, size - bord * 2, size - bord * 2)
        end

        surface.SetDrawColor(col)
        surface.DrawOutlinedRect(x - half, y - half, size, size, bord)

        draw.SimpleText(label, BattleGrid.F("tiny"), x, y + half + S(3), col, TEXT_ALIGN_CENTER)
    end

    function panel:DrawSquadMembers()
        for _, member in ipairs(BattleGrid.Compat.SquadMembers(LocalPlayer())) do
            if IsValid(member) and member ~= LocalPlayer() and BattleGrid:ShouldShowPlayer(member) then
                if self._zFilterZ and member:GetPos().z > self._zFilterZ then continue end
                local mx, my = self:WorldToScreen(member:GetPos())
                self:DrawSquadMemberMarker(mx, my, BattleGrid.C("SquadIcon"), BattleGrid.Compat.PlayerDisplayName(member), member)
            end
        end
    end

    function panel:DrawWaypoints(zoom)
        if not BattleGrid:GetPref("show_wp_map") then return end

        for _, wp in ipairs(BattleGrid.Cache.Waypoints) do
            if self._zFilterZ and wp.pos.z > self._zFilterZ then continue end
            local wx, wy = self:WorldToScreen(wp.pos)
            local iconSize = S(20)

            draw.NoTexture()
            surface.SetDrawColor(wp.color)

            if wp.icon and wp.icon ~= "" then
                BattleGrid:DrawIcon(wp.icon, wx - iconSize / 2, wy - iconSize / 2, iconSize, iconSize, wp.color)
            else
                BattleGrid:DrawCircle(wx, wy, iconSize / 3, 16)
            end

            draw.SimpleText(wp.name, BattleGrid.F("MapLabel"), wx, wy + iconSize * 0.7, wp.color, TEXT_ALIGN_CENTER)

            if zoom <= 2500 then
                local dist = LocalPlayer():GetPos():Distance(wp.pos)
                draw.SimpleText(BattleGrid:FormatDistance(dist), BattleGrid.F("MapLabelSmall"), wx, wy + iconSize * 1.3, BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER)
                draw.SimpleText(BattleGrid:GetStateDisplay(wp.state), BattleGrid.F("MapLabelSmall"), wx, wy + iconSize * 1.8, BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER)
            end
        end
    end

    function panel:DrawAreas()
        if not BattleGrid:GetPref("show_area_map") then return end

        for _, area in ipairs(BattleGrid.Cache.Areas) do
            local x1, y1 = self:WorldToScreen(area.pos1)
            local x2, y2 = self:WorldToScreen(area.pos2)

            local areaId = area.identifier or tostring(area)
            if not panel._brightCache then panel._brightCache = {} end
            if not panel._brightCache[areaId] or panel._brightCache[areaId].src ~= area.color then
                panel._brightCache[areaId] = { src = area.color, col = BattleGrid:BrightenColor(area.color, 50) }
            end
            local brighter = panel._brightCache[areaId].col

            if area.type == BattleGrid.AreaTypes.RECTANGULAR then
                surface.SetDrawColor(KF.UI.ColorAlpha(area.color, 25))
                draw.NoTexture()
                BattleGrid:DrawRectFromPoints(x1, y1, x2, y2)

                surface.SetDrawColor(area.color)
                BattleGrid:DrawOutlinedRectFromPoints(x1, y1, x2, y2, 2)

                local midX = (x1 + x2) / 2
                local midY = (y1 + y2) / 2
                draw.SimpleText(area.name, BattleGrid.F("MapLabel"), midX, midY, brighter, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif area.type == BattleGrid.AreaTypes.ROUND then
                surface.SetDrawColor(KF.UI.ColorAlpha(area.color, 25))
                draw.NoTexture()
                BattleGrid:DrawCircleFromPoints(x1, y1, x2, y2, 30)

                surface.SetDrawColor(area.color)
                BattleGrid:DrawOutlinedCircleFromPoints(x1, y1, x2, y2, 30, 2)

                draw.SimpleText(area.name, BattleGrid.F("MapLabel"), x1, y1, brighter, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    local jamGlitch = {}

    function panel:DrawDisturbances()
        local ct = CurTime()

        for idx, data in ipairs(BattleGrid.Cache.Jammers) do
            local x, y = self:WorldToScreen(data.pos)
            local errorCol = BattleGrid.C("Error")

            local worldEdge = data.pos + Vector(data.radius, 0, 0)
            local ex, ey = self:WorldToScreen(worldEdge)
            local visualRadius = math.sqrt((ex - x)^2 + (ey - y)^2)

            if not jamGlitch[idx] then
                jamGlitch[idx] = { active = false, endTime = 0, nextTime = ct + 2 + math.random() * 4, slices = {} }
            end
            local g = jamGlitch[idx]

            if not g.active and ct >= g.nextTime then
                g.active = true
                g.endTime = ct + 0.08 + math.random() * 0.15
                g.slices = {}
                local numSlices = math.random(3, 7)
                for i = 1, numSlices do
                    g.slices[i] = {
                        yOff = math.random() * 1.0,
                        h = 0.02 + math.random() * 0.08,
                        xShift = (math.random() - 0.5) * 0.12,
                        col = math.random() < 0.4,
                    }
                end
            elseif g.active and ct >= g.endTime then
                g.active = false
                g.nextTime = ct + 1.5 + math.random() * 5
                g.slices = {}
            end

            render.SetStencilEnable(true)
            render.ClearStencil()
            render.SetStencilWriteMask(1)
            render.SetStencilTestMask(1)
            render.SetStencilFailOperation(STENCILOPERATION_KEEP)
            render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
            render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
            render.SetStencilReferenceValue(1)

            draw.NoTexture()
            surface.SetDrawColor(KF.UI.ColorAlpha(color_white, 1))
            BattleGrid:DrawCircle(x, y, visualRadius, 48)

            render.SetStencilPassOperation(STENCILOPERATION_KEEP)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

            local bx = x - visualRadius
            local by = y - visualRadius
            local bw = visualRadius * 2
            local bh = visualRadius * 2

            surface.SetDrawColor(BattleGrid.C("Panel"))
            surface.DrawRect(bx, by, bw, bh)

            local lineH = math.max(2, math.floor(visualRadius / 40))
            local scroll = (ct * 30) % (lineH * 2)
            surface.SetDrawColor(KF.UI.ColorAlpha(errorCol, 14))
            for ly = by - lineH * 2, by + bh, lineH * 2 do
                surface.DrawRect(bx, ly + scroll, bw, lineH)
            end

            local flicker = math.sin(ct * 3.7) * 0.5 + 0.5
            draw.NoTexture()
            for i = 1, 18 do
                local nx = bx + math.random() * bw
                local ny = by + math.random() * bh
                local ns = 1 + math.random() * 3
                surface.SetDrawColor(errorCol.r * 0.5, errorCol.g * 0.3, errorCol.b * 0.3, 10 + math.random(0, 15))
                surface.DrawRect(nx, ny, ns, ns)
            end

            if g.active then
                for _, slice in ipairs(g.slices) do
                    local sy = by + slice.yOff * bh
                    local sh = slice.h * bh
                    local sx = bx + slice.xShift * bw

                    if slice.col then
                        surface.SetDrawColor(errorCol.r, 0, 0, 80)
                        surface.DrawRect(sx, sy, bw, sh)
                        surface.SetDrawColor(0, errorCol.r * 0.3, errorCol.r * 0.3, 60)
                        surface.DrawRect(sx + 2, sy, bw, sh)
                    else
                        surface.SetDrawColor(BattleGrid.C("PanelLight"))
                        surface.DrawRect(sx, sy, bw, sh)
                    end
                end

                surface.SetDrawColor(errorCol.r, errorCol.g * 0.3, errorCol.b * 0.3, 30)
                surface.DrawRect(bx, by, bw, bh)
            end

            local pulse = math.sin(ct * 2) * 0.3 + 0.7
            local ringA = math.floor(pulse * 80)
            surface.SetDrawColor(KF.UI.ColorAlpha(errorCol, ringA))
            BattleGrid:DrawOutlinedCircleFromPoints(x, y, x + visualRadius, y, 48, 2)

            render.SetStencilEnable(false)

            local glowA = math.floor(pulse * 30)
            surface.SetDrawColor(KF.UI.ColorAlpha(errorCol, glowA))
            draw.NoTexture()
            BattleGrid:DrawCircle(x, y, visualRadius + 3, 48)

            local labelA = g.active and (math.random() < 0.5 and 60 or 220) or math.floor(160 + flicker * 60)
            local labelX = g.active and (x + math.random(-4, 4)) or x
            draw.SimpleText(BattleGrid:L("SIGNAL_LOST"), BattleGrid.F("MapLabel"), labelX, y, KF.UI.ColorAlpha(errorCol, labelA), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    function panel:DrawGrid()
        local gridLines = 24
        local halfGrid = gridLines / 2
        local mapBound = MAP_BOUND
        local pw, ph = self:GetWide(), self:GetTall()

        for i = 1, gridLines do
            local x = i - halfGrid
            local worldCoord = x * (mapBound / halfGrid)

            local vx, _ = self:WorldToScreen(Vector(0, worldCoord, 0))
            surface.SetDrawColor(BattleGrid.C("GridDots"))
            surface.DrawLine(vx, 0, vx, ph)

            if i <= #gridLetters then
                draw.SimpleText(tostring(gridLines + 1 - i), BattleGrid.F("MapLabel"), vx + 4, 25, BattleGrid.C("TextPrimary"))
            end

            local _, hy = self:WorldToScreen(Vector(worldCoord, 0, 0))
            surface.SetDrawColor(BattleGrid.C("GridDots"))
            surface.DrawLine(0, hy, pw, hy)

            if i <= #gridLetters then
                draw.SimpleText(gridLetters[gridLines + 1 - i] or "", BattleGrid.F("MapLabel"), 8, hy + 4, BattleGrid.C("TextPrimary"))
            end
        end
    end

    function panel:DrawCompass(w, h)
        local yaw = LocalPlayer():EyeAngles().y
        local bearingOverride
        local compassState = BattleGrid.Compat.CompassState()
        if compassState then
            yaw = compassState.smoothedYaw or yaw
            bearingOverride = compassState.displayHeading
        end

        local radius = S(56)
        local cx = w - S(28) - radius
        local cy = S(60) + radius

        draw.NoTexture()
        local panelDark = BattleGrid.C("PanelDark")
        surface.SetDrawColor(KF.UI.ColorAlpha(panelDark, 160))
        BattleGrid:DrawCircle(cx, cy, radius + S(2), 48)

        local ringSegs = 64
        local function drawRing(r, alpha)
            surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("Border"), alpha))
            for i = 0, ringSegs - 1 do
                local a1 = (i / ringSegs) * math.pi * 2
                local a2 = ((i + 1) / ringSegs) * math.pi * 2
                surface.DrawLine(
                    cx + math.cos(a1) * r, cy + math.sin(a1) * r,
                    cx + math.cos(a2) * r, cy + math.sin(a2) * r
                )
            end
        end
        drawRing(radius, 100)
        drawRing(radius * 0.72, 40)

        local cardinalScreenAngles = {
            N  = math.rad(270),
            NE = math.rad(315),
            E  = math.rad(0),
            SE = math.rad(45),
            S  = math.rad(90),
            SW = math.rad(135),
            W  = math.rad(180),
            NW = math.rad(225),
        }

        for i = 0, 15 do
            local screenAng = math.rad(i * 22.5 + 180)
            local isCardinal = (i % 4 == 0)
            local isIntercardinal = (i % 4 == 2)
            local tickOuter = radius - S(1)
            local tickInner
            local tickAlpha

            if isCardinal then
                tickInner = radius - S(10)
                tickAlpha = 200
            elseif isIntercardinal then
                tickInner = radius - S(7)
                tickAlpha = 120
            else
                tickInner = radius - S(4)
                tickAlpha = 50
            end

            surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("TextSecondary"), tickAlpha))
            surface.DrawLine(
                cx + math.cos(screenAng) * tickInner, cy + math.sin(screenAng) * tickInner,
                cx + math.cos(screenAng) * tickOuter, cy + math.sin(screenAng) * tickOuter
            )
        end

        local cardinals = {
            { label = BattleGrid:L("COMPASS_N"),  ang = cardinalScreenAngles.N,  color = BattleGrid.C("Accent"),        font = BattleGrid.FB("caption") },
            { label = BattleGrid:L("COMPASS_NE"), ang = cardinalScreenAngles.NE, color = BattleGrid.C("TextMuted"),      font = BattleGrid.F("tiny") },
            { label = BattleGrid:L("COMPASS_E"),  ang = cardinalScreenAngles.E,  color = BattleGrid.C("TextSecondary"),  font = BattleGrid.FB("caption") },
            { label = BattleGrid:L("COMPASS_SE"), ang = cardinalScreenAngles.SE, color = BattleGrid.C("TextMuted"),      font = BattleGrid.F("tiny") },
            { label = BattleGrid:L("COMPASS_S"),  ang = cardinalScreenAngles.S,  color = BattleGrid.C("TextSecondary"),  font = BattleGrid.FB("caption") },
            { label = BattleGrid:L("COMPASS_SW"), ang = cardinalScreenAngles.SW, color = BattleGrid.C("TextMuted"),      font = BattleGrid.F("tiny") },
            { label = BattleGrid:L("COMPASS_W"),  ang = cardinalScreenAngles.W,  color = BattleGrid.C("TextSecondary"),  font = BattleGrid.FB("caption") },
            { label = BattleGrid:L("COMPASS_NW"), ang = cardinalScreenAngles.NW, color = BattleGrid.C("TextMuted"),      font = BattleGrid.F("tiny") },
        }

        local labelR = radius * 0.52
        local interLabelR = radius * 0.54
        for _, c in ipairs(cardinals) do
            local r = (#c.label == 2) and interLabelR or labelR
            local lx = cx + math.cos(c.ang) * r
            local ly = cy + math.sin(c.ang) * r
            draw.SimpleText(c.label, c.font, lx, ly, c.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        draw.NoTexture()
        surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("Accent"), 120))
        BattleGrid:DrawCircle(cx, cy, S(2), 8)

        local needleAng = math.rad(270 - yaw)
        local needleLen = radius * 0.82
        local needleTip = radius * 0.35

        local nx1 = cx + math.cos(needleAng) * needleTip
        local ny1 = cy + math.sin(needleAng) * needleTip
        local nx2 = cx + math.cos(needleAng) * needleLen
        local ny2 = cy + math.sin(needleAng) * needleLen

        local accentCol = BattleGrid.C("Accent")
        surface.SetDrawColor(KF.UI.ColorAlpha(accentCol, 200))
        surface.DrawLine(nx1, ny1, nx2, ny2)

        local arrowSize = S(5)
        local perpAng = needleAng + math.rad(90)
        local ax1 = nx2 - math.cos(needleAng) * arrowSize + math.cos(perpAng) * arrowSize * 0.5
        local ay1 = ny2 - math.sin(needleAng) * arrowSize + math.sin(perpAng) * arrowSize * 0.5
        local ax2 = nx2 - math.cos(needleAng) * arrowSize - math.cos(perpAng) * arrowSize * 0.5
        local ay2 = ny2 - math.sin(needleAng) * arrowSize - math.sin(perpAng) * arrowSize * 0.5
        surface.DrawLine(nx2, ny2, ax1, ay1)
        surface.DrawLine(nx2, ny2, ax2, ay2)

        local tailLen = radius * 0.25
        local tx = cx - math.cos(needleAng) * tailLen
        local ty = cy - math.sin(needleAng) * tailLen
        local textMuted = BattleGrid.C("TextMuted")
        surface.SetDrawColor(KF.UI.ColorAlpha(textMuted, 80))
        surface.DrawLine(cx, cy, tx, ty)

        local bearing = bearingOverride or (math.floor((360 - (yaw % 360)) + 0.5) % 360)
        draw.SimpleText(string.format("%03d°", bearing), BattleGrid.F("tiny"), cx, cy + radius + S(8), BattleGrid.C("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    function panel:DrawAreaSelection(areaType, pos1, pos2, h)
        local defCol = BattleGrid.C("AreaDefine")

        if areaType == BattleGrid.AreaTypes.RECTANGULAR then
            self:DrawPlayerMarker(pos1[1], pos1[2], defCol, BattleGrid:L("AREA_POS1"), false)

            if not pos2 then
                draw.SimpleText(BattleGrid:L("AREA_POS2_HINT"), BattleGrid.F("MapLabel"), pos1[1], pos1[2] + h * 0.06, BattleGrid.C("Warning"), TEXT_ALIGN_CENTER)
                return
            end

            self:DrawPlayerMarker(pos2[1], pos2[2], defCol, BattleGrid:L("AREA_POS2"), false)

            surface.SetDrawColor(KF.UI.ColorAlpha(defCol, 25))
            BattleGrid:DrawRectFromPoints(pos1[1], pos1[2], pos2[1], pos2[2])
            surface.SetDrawColor(KF.UI.ColorAlpha(defCol, 90))
            BattleGrid:DrawOutlinedRectFromPoints(pos1[1], pos1[2], pos2[1], pos2[2], 2)

        elseif areaType == BattleGrid.AreaTypes.ROUND then
            self:DrawPlayerMarker(pos1[1], pos1[2], defCol, BattleGrid:L("AREA_POS1"), false)

            if not pos2 then
                draw.SimpleText(BattleGrid:L("AREA_POS2_HINT"), BattleGrid.F("MapLabel"), pos1[1], pos1[2] + h * 0.06, BattleGrid.C("Warning"), TEXT_ALIGN_CENTER)
                return
            end

            self:DrawPlayerMarker(pos2[1], pos2[2], defCol, BattleGrid:L("AREA_POS2"), false)

            surface.SetDrawColor(KF.UI.ColorAlpha(defCol, 25))
            draw.NoTexture()
            BattleGrid:DrawCircleFromPoints(pos1[1], pos1[2], pos2[1], pos2[2], 30)
            surface.SetDrawColor(KF.UI.ColorAlpha(defCol, 90))
            BattleGrid:DrawOutlinedCircleFromPoints(pos1[1], pos1[2], pos2[1], pos2[2], 30, 2)
        end
    end

    function panel:OnCursorMoved(x, y)
        if input.IsMouseDown(MOUSE_LEFT) then
            if dragWP then return end

            if selectArea then
                areaPos2 = {self:GetLocalMouse()}
                return
            end

            if not self.lastPress then
                self.lastPress = Vector(x, y)
                return
            end

            local dx = x - self.lastPress.x
            local dy = self.lastPress.y - y
            local mod = 10

            self.campos.x = self.campos.x - dy * mod
            self.campos.y = self.campos.y + dx * mod
            self.lastPress = Vector(x, y)
        else
            self.lastPress = nil
        end
    end

    function panel:OnMouseWheeled(delta)
        local zoom = self:GetZoom()
        if delta > 0 then
            self:SetZoom(math.Clamp(zoom - 250, 10, 10000))
        else
            self:SetZoom(math.Clamp(zoom + 250, 10, 10000))
        end
    end

    function panel:OnMousePressed(code)
        local lx, ly = self:GetLocalMouse()

        if code == MOUSE_LEFT then
            if measureMode then
                local worldPos = self:GetMouseWorldPos()
                if not measureP1 then
                    measureP1 = worldPos
                elseif not measureP2 then
                    measureP2 = worldPos
                else
                    measureP1 = nil
                    measureP2 = nil
                    measureMode = false
                end
                return
            end

            local wp = self:HitTestWaypoint(lx, ly)
            if wp and wp.identifier and BattleGrid:CanEditMarker(LocalPlayer(), wp) then
                dragWP = wp
                self:SetCursor("hand")
                return
            end
            return
        end

        if code ~= MOUSE_RIGHT then return end

        if measureMode then
            measureMode = false
            measureP1 = nil
            measureP2 = nil
            return
        end

        timer.Simple(0.15, function()
            if not IsValid(self) then return end
            if input.IsMouseDown(MOUSE_LEFT) then return end

            local localX, localY = self:GetLocalMouse()
            local worldPos = self:GetMouseWorldPos()
            local mousePos = {localX, localY}
            local mx, my = gui.MousePos()

            local hitWP = self:HitTestWaypoint(localX, localY)
            if hitWP and hitWP.identifier then
                local items = {}
                if BattleGrid:CanEditMarker(LocalPlayer(), hitWP) then
                    items[#items + 1] = { text = BattleGrid:L("CTX_EDIT_WP"), callback = function()
                        BattleGrid:OpenWaypointEditor(hitWP, hitWP.pos)
                    end }
                end
                if BattleGrid:CanDeleteMarker(LocalPlayer(), hitWP, "BattleGrid.PublicWaypoint", "BattleGrid.PermanentWaypoint") then
                    items[#items + 1] = { text = BattleGrid:L("CTX_DELETE_WP"), color = BattleGrid.C("Error"), callback = function()
                        PushUndo("create_waypoint", table.Copy(hitWP))
                        BattleGrid:RequestDeleteWaypoint(hitWP.identifier)
                        BattleGrid:Toast(BattleGrid:L("TOAST_WP_DELETED"), "success")
                    end }
                end
                if #items > 0 then BattleGrid:OpenContextMenu(items) end
                return
            end

            local hitArea = self:HitTestArea(localX, localY)
            if hitArea and hitArea.identifier then
                local items = {}
                if BattleGrid:CanEditMarker(LocalPlayer(), hitArea) then
                    items[#items + 1] = { text = BattleGrid:L("CTX_EDIT_AREA"), callback = function()
                        BattleGrid:OpenAreaEditor(hitArea, hitArea.pos1, hitArea.pos2, hitArea.type)
                    end }
                end
                if BattleGrid:CanDeleteMarker(LocalPlayer(), hitArea, "BattleGrid.PublicArea", "BattleGrid.PermanentArea") then
                    items[#items + 1] = { text = BattleGrid:L("CTX_DELETE_AREA"), color = BattleGrid.C("Error"), callback = function()
                        PushUndo("create_area", table.Copy(hitArea))
                        BattleGrid:RequestDeleteArea(hitArea.identifier)
                        BattleGrid:Toast(BattleGrid:L("TOAST_AREA_DELETED"), "success")
                    end }
                end
                if #items > 0 then BattleGrid:OpenContextMenu(items) end
                return
            end

            local outerR = S(130)
            local innerR = S(40)
            local segCount = 64

            if IsValid(BattleGrid.RadialWheel) then BattleGrid.RadialWheel:Remove() end

            local wheelFrame = vgui.Create("DPanel")
            wheelFrame:SetPos(0, 0)
            wheelFrame:SetSize(ScrW(), ScrH())
            wheelFrame:MakePopup()
            wheelFrame:SetKeyboardInputEnabled(false)
            wheelFrame._hoverIdx = 0
            wheelFrame._startTime = SysTime()
            BattleGrid.RadialWheel = wheelFrame

            local items = {
                { label = BattleGrid:L("WP_SINGULAR"),      icon = "+",  action = function() BattleGrid:OpenWaypointEditor(nil, worldPos) end },
                { label = BattleGrid:L("AREA_TYPE_RECT"),   icon = "▭", action = function() selectArea = BattleGrid.AreaTypes.RECTANGULAR areaPos1 = mousePos areaPos2 = nil end },
                { label = BattleGrid:L("AREA_TYPE_ROUND"),  icon = "○", action = function() selectArea = BattleGrid.AreaTypes.ROUND areaPos1 = mousePos areaPos2 = nil end },
            }

            local itemCount = #items
            local sliceAngle = (math.pi * 2) / itemCount
            local baseAngle = -math.pi / 2

            local function DrawFilledArc(cx, cy, rOuter, rInner, aStart, aEnd, col, segs)
                draw.NoTexture()
                surface.SetDrawColor(col)
                local step = (aEnd - aStart) / segs
                for s = 0, segs - 1 do
                    local a1 = aStart + s * step
                    local a2 = aStart + (s + 1) * step
                    surface.DrawPoly({
                        { x = cx + math.cos(a1) * rInner, y = cy + math.sin(a1) * rInner },
                        { x = cx + math.cos(a1) * rOuter, y = cy + math.sin(a1) * rOuter },
                        { x = cx + math.cos(a2) * rOuter, y = cy + math.sin(a2) * rOuter },
                        { x = cx + math.cos(a2) * rInner, y = cy + math.sin(a2) * rInner },
                    })
                end
            end

            function wheelFrame:Paint(w, h)
                local elapsed = SysTime() - self._startTime
                local anim = math.min(1, elapsed / 0.15)
                local curScale = 0.8 + 0.2 * anim
                local alpha = anim

                local rO = outerR * curScale
                local rI = innerR * curScale

                surface.SetDrawColor(KF.UI.ColorAlpha(color_black, math.floor(80 * alpha)))
                surface.DrawRect(0, 0, w, h)

                local curX, curY = gui.MousePos()
                local dx, dy = curX - mx, curY - my
                local dist = math.sqrt(dx * dx + dy * dy)
                local hoveredItem = 0

                if dist > rI * 0.5 and dist < rO * 1.2 then
                    local mouseAng = math.atan2(dy, dx)
                    for i = 1, itemCount do
                        local aStart = baseAngle + (i - 1) * sliceAngle - sliceAngle / 2
                        local diff = mouseAng - aStart
                        diff = math.atan2(math.sin(diff), math.cos(diff))
                        if diff >= 0 and diff < sliceAngle then
                            hoveredItem = i
                            break
                        end
                    end
                end

                self._hoverIdx = hoveredItem

                for i = 1, itemCount do
                    local aStart = baseAngle + (i - 1) * sliceAngle - sliceAngle / 2
                    local aEnd = aStart + sliceAngle
                    local isHovered = (hoveredItem == i)

                    local bgCol = isHovered
                        and KF.UI.ColorAlpha(BattleGrid.C("RadialHover"), math.floor(230 * alpha))
                        or KF.UI.ColorAlpha(BattleGrid.C("RadialBg"), math.floor(220 * alpha))
                    DrawFilledArc(mx, my, rO, rI, aStart, aEnd, bgCol, 20)

                    surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("BorderSubtle"), 160 * alpha))
                    surface.DrawLine(
                        mx + math.cos(aStart) * rI, my + math.sin(aStart) * rI,
                        mx + math.cos(aStart) * rO, my + math.sin(aStart) * rO
                    )

                    local midAngle = aStart + sliceAngle / 2
                    local textR = (rO + rI) / 2
                    local tx = mx + math.cos(midAngle) * textR
                    local ty = my + math.sin(midAngle) * textR

                    local iconCol = isHovered and BattleGrid.C("Accent") or KF.UI.ColorAlpha(BattleGrid.C("TextPrimary"), 200 * alpha)
                    draw.SimpleText(items[i].icon, BattleGrid.F("header"), tx, ty - S(8), iconCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    local labelCol = isHovered and KF.UI.ColorAlpha(BattleGrid.C("TextPrimary"), 255 * alpha) or KF.UI.ColorAlpha(BattleGrid.C("TextSecondary"), 180 * alpha)
                    draw.SimpleText(items[i].label, BattleGrid.FB("caption"), tx, ty + S(10), labelCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end

                surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("Border"), 120 * alpha))
                for s = 0, segCount - 1 do
                    local a1 = (s / segCount) * math.pi * 2
                    local a2 = ((s + 1) / segCount) * math.pi * 2
                    surface.DrawLine(mx + math.cos(a1) * rO, my + math.sin(a1) * rO, mx + math.cos(a2) * rO, my + math.sin(a2) * rO)
                end

                surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("Accent"), 180 * alpha))
                for s = 0, segCount - 1 do
                    local a1 = (s / segCount) * math.pi * 2
                    local a2 = ((s + 1) / segCount) * math.pi * 2
                    surface.DrawLine(mx + math.cos(a1) * rI, my + math.sin(a1) * rI, mx + math.cos(a2) * rI, my + math.sin(a2) * rI)
                end

                draw.NoTexture()
                surface.SetDrawColor(KF.UI.ColorAlpha(BattleGrid.C("BackgroundDark"), math.floor(240 * alpha)))
                BattleGrid:DrawCircle(mx, my, rI - 1, segCount)

                draw.SimpleText(string.upper(BattleGrid:L("ADDON_NAME")), BattleGrid.F("tiny"), mx, my, KF.UI.ColorAlpha(BattleGrid.C("Accent"), 255 * alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            function wheelFrame:OnMousePressed(code)
                if code == MOUSE_LEFT and self._hoverIdx > 0 then
                    BattleGrid:PlaySound("Click")
                    items[self._hoverIdx].action()
                end
                self:Remove()
                BattleGrid.RadialWheel = nil
            end

            function wheelFrame:OnKeyCodePressed(key)
                if key == KEY_ESCAPE then
                    self:Remove()
                    BattleGrid.RadialWheel = nil
                end
            end
        end)
    end

    function panel:OnMouseReleased(code)
        if code == MOUSE_LEFT and dragWP then
            local newPos = self:GetMouseWorldPos()
            local oldPos = Vector(dragWP.pos.x, dragWP.pos.y, dragWP.pos.z)

            PushUndo("move_waypoint", { identifier = dragWP.identifier, pos = oldPos })

            local payload = table.Copy(dragWP)
            payload.pos = newPos
            BattleGrid:RequestCreateWaypoint(payload)
            BattleGrid:Toast(BattleGrid:L("TOAST_WP_MOVED"), "success")

            dragWP = nil
            self:SetCursor("sizeall")
            return
        end

        if not selectArea or not areaPos1 or not areaPos2 then return end

        BattleGrid:OpenContextMenu({
            { text = BattleGrid:L("CTX_CREATE_AREA_TITLE"), callback = function()
                local p1 = panel:CalculateWorldPos(areaPos1[1], areaPos1[2])
                local p2 = panel:CalculateWorldPos(areaPos2[1], areaPos2[2])
                BattleGrid:OpenAreaEditor(nil, p1, p2, selectArea)
                selectArea = false
                areaPos1, areaPos2 = nil, nil
            end },
            { text = BattleGrid:L("CTX_CANCEL"), color = BattleGrid.C("Error"), callback = function()
                selectArea = false
                areaPos1, areaPos2 = nil, nil
            end },
        })
    end

    frame._escDown = false
    frame._keyC = false
    frame._keyR = false
    frame._keyZ = false

    hook.Add("PlayerBindPress", "BattleGrid.BlockEscMenu", function(ply, bind)
        if bind == "cancelselect" and IsValid(frame) then
            return true
        end
    end)

    function frame:Think()
        if input.IsKeyDown(KEY_ESCAPE) then
            if not self._escDown then
                self._escDown = true
                if measureMode then
                    measureMode = false
                    measureP1 = nil
                    measureP2 = nil
                else
                    self:AlphaTo(0, 0.1, 0, function()
                        if IsValid(self) then self:Remove() end
                    end)
                end
            end
        else
            self._escDown = false
        end

        if input.IsKeyDown(KEY_C) then
            if not self._keyC then
                self._keyC = true
                BattleGrid:CenterOnPlayer()
            end
        else
            self._keyC = false
        end

        if input.IsKeyDown(KEY_R) then
            if not self._keyR then
                self._keyR = true
                BattleGrid:ToggleMeasureMode()
            end
        else
            self._keyR = false
        end

        if input.IsKeyDown(KEY_Z) and input.IsKeyDown(KEY_LCONTROL) then
            if not self._keyZ then
                self._keyZ = true
                local stack = BattleGrid._undoStack
                if #stack == 0 then
                    BattleGrid:Toast(BattleGrid:L("UNDO_EMPTY"), "warning", 2)
                    return
                end

                local action = table.remove(stack)
                if action.type == "create_waypoint" then
                    BattleGrid:RequestCreateWaypoint(action.data)
                    BattleGrid:Toast(BattleGrid:L("UNDO_WP_RESTORED"), "success")
                elseif action.type == "create_area" then
                    BattleGrid:RequestCreateArea(action.data)
                    BattleGrid:Toast(BattleGrid:L("UNDO_AREA_RESTORED"), "success")
                elseif action.type == "move_waypoint" then
                    local wp = BattleGrid:FindByIdentifier(BattleGrid.Cache.Waypoints, action.data.identifier)
                    if wp then
                        local payload = table.Copy(wp)
                        payload.pos = action.data.pos
                        BattleGrid:RequestCreateWaypoint(payload)
                    end
                    BattleGrid:Toast(BattleGrid:L("UNDO_MOVE_RESTORED"), "success")
                end
            end
        else
            self._keyZ = false
        end
    end
end

local SNAP_SIZE = 1024
local SNAP_MARGIN = 1.75
local SNAP_STEP_Z = 96

local snapRT = GetRenderTarget("BG_RadarSnapshotRT", SNAP_SIZE, SNAP_SIZE)
local snapMat = CreateMaterial("BG_RadarSnapshotMat", "UnlitGeneric", {
    ["$basetexture"] = snapRT:GetName(),
    ["$nolod"] = "1",
})
local snap = { x = 0, y = 0, z = 0, half = 0 }
local radar = {}

local function RadarPolygon(cx, cy, r, sides)
    local pts = {}
    for i = 0, sides - 1 do
        local ang = (i / sides) * math.pi * 2 + math.rad(22.5)
        pts[i + 1] = { x = cx + math.cos(ang) * r, y = cy + math.sin(ang) * r }
    end
    return pts
end

local function DrawPolyOutline(poly, alpha, double)
    surface.SetDrawColor(KF.UI.ColorAlpha(color_white, alpha))
    for i = 1, #poly do
        local p0 = poly[i]
        local p1 = poly[(i % #poly) + 1]
        surface.DrawLine(p0.x, p0.y, p1.x, p1.y)
        if double then surface.DrawLine(p0.x + 1, p0.y, p1.x + 1, p1.y) end
    end
end

local function UpdateSnapshot(pos, halfZoom)
    local half = halfZoom * SNAP_MARGIN
    local slack = half - halfZoom
    if snap.half == half
        and math.abs(pos.x - snap.x) <= slack
        and math.abs(pos.y - snap.y) <= slack
        and math.abs(pos.z - snap.z) <= SNAP_STEP_Z then
        return
    end

    snap.x, snap.y, snap.z, snap.half = pos.x, pos.y, pos.z, half

    render.PushRenderTarget(snapRT)
    render.Clear(10, 12, 15, 255, true, true)
    RenderTopDown({
        angles = Angle(90, 0, 0),
        x = 0, y = 0, w = SNAP_SIZE, h = SNAP_SIZE,
        ortholeft = -half, orthotop = -half, orthoright = half, orthobottom = half,
    }, snap.x, snap.y, half * 1.5, BattleGrid:GetConfigNumber("map_camera_distance"), GroundZ(snap.x, snap.y) + 64)
    render.PopRenderTarget()
end

local function SnapshotQuad(geo)
    local pos, half, scale = radar.pos, snap.half, radar.scale
    local yaw = math.rad(radar.yaw)
    local sn, cs = math.sin(yaw), math.cos(yaw)
    local verts = {}
    for i = 1, 4 do
        local u = (i == 2 or i == 3) and 1 or 0
        local v = i > 2 and 1 or 0
        local dx = snap.x + (0.5 - v) * 2 * half - pos.x
        local dy = snap.y + (0.5 - u) * 2 * half - pos.y
        verts[i] = {
            x = geo.cx + (dx * sn - dy * cs) * scale,
            y = geo.cy - (dx * cs + dy * sn) * scale,
            u = u, v = v,
        }
    end
    return verts
end

hook.Add("PreRender", "BattleGrid.RadarMapRender", function()
    radar.geo = nil
    if not BattleGrid:IsMapAllowed() or not BattleGrid:GetConfigBool("radar_map_enabled") then return end
    if not BattleGrid:GetPref("radar_map_show") then return end

    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:Alive() then return end

    local geo = BattleGrid.Compat.RadarGeometry()
    if not geo then return end

    local halfZoom = geo.dotRange / 0.9
    radar.geo = geo
    radar.poly = RadarPolygon(geo.cx, geo.cy, geo.r, geo.sides)
    radar.scale = geo.r / halfZoom
    radar.pos = lp:GetPos()
    radar.yaw = lp:EyeAngles().y

    UpdateSnapshot(radar.pos, halfZoom)
end)

hook.Add("HUDPaintBackground", "BattleGrid.RadarMap", function()
    local geo = radar.geo
    if not geo then return end

    draw.NoTexture()
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(0xFF)
    render.SetStencilTestMask(0xFF)
    render.SetStencilReferenceValue(2)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)

    surface.SetDrawColor(KF.UI.ColorAlpha(color_black, 1))
    surface.DrawPoly(radar.poly)

    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)

    surface.SetMaterial(snapMat)
    surface.SetDrawColor(color_white)
    surface.DrawPoly(SnapshotQuad(geo))

    render.SetStencilEnable(false)
end)

hook.Add("HUDPaint", "BattleGrid.RadarMapBorders", function()
    local geo = radar.geo
    if not geo then return end

    local cx, cy, r, sides = geo.cx, geo.cy, geo.r, geo.sides
    local outerPoly = radar.poly
    DrawPolyOutline(outerPoly, 80, true)
    DrawPolyOutline(RadarPolygon(cx, cy, r * geo.midFrac, sides), 40)
    DrawPolyOutline(RadarPolygon(cx, cy, r * geo.innerFrac, sides), 30)

    local crossLen = r * 0.15
    surface.SetDrawColor(KF.UI.ColorAlpha(color_white, 35))
    surface.DrawRect(cx - math.floor(crossLen / 2), cy, math.floor(crossLen), 1)
    surface.DrawRect(cx, cy - math.floor(crossLen / 2), 1, math.floor(crossLen))

    surface.SetDrawColor(KF.UI.ColorAlpha(color_white, 60))
    for i = 1, #outerPoly do
        local p0 = outerPoly[i]
        local p1 = outerPoly[(i % #outerPoly) + 1]
        local mx = (p0.x + p1.x) * 0.5
        local my = (p0.y + p1.y) * 0.5
        local dx, dy = mx - cx, my - cy
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            local tSize = r * 0.08
            surface.DrawLine(mx, my, mx - dx / len * tSize, my - dy / len * tSize)
        end
    end
end)
