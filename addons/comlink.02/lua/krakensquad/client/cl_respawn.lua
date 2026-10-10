local AID    = KrakenSquad.AID
local P      = KrakenSquad.P
local D      = KrakenSquad.Draw
local Scaled = KF.Scale
local SOUNDS = KrakenSquad.SOUNDS
local HOVER_SPEED = KrakenSquad.UI.HOVER_SPEED

KrakenSquad._RespawnActive          = false
KrakenSquad._RespawnMembers         = {}
KrakenSquad._RespawnCPs             = {}
KrakenSquad._RespawnSelected        = -1
KrakenSquad._RespawnSpectating      = nil
KrakenSquad._RespawnTimeout         = 0
KrakenSquad._RespawnTimeoutEnabled  = false
KrakenSquad._RespawnInCombatEnabled = true
KrakenSquad._RespawnStartTime       = 0
KrakenSquad._RespawnDelay           = 0

local BF2_HOOKS = {
    "BF2HUD_MainHUD", "BF2HUD_DrawHitMarkers", "BF2HUD_DrawSimpleOverhead",
    "BF2HUD_DrawCompass", "BF2HUD_DrawRadar", "BF2HUD_DrawKillFeed",
    "BF2HUD_WeaponSelect_Draw", "BF2HUD_LVS_HUD", "BF2HUD_Notifications",
    "BF2HUD_VoiceChat", "BF2HUD_DrawCrosshair",
}

local stashedHUD, stashedCalcView

local function StashHooks(event, names, exclude)
    local stash = {}
    local table = hook.GetTable()[event] or {}
    for _, name in ipairs(names or {}) do
        if table[name] then stash[name] = table[name]; hook.Remove(event, name) end
    end
    if exclude then
        for name, fn in pairs(table) do
            if name ~= exclude then stash[name] = fn; hook.Remove(event, name) end
        end
    end
    return stash
end

local function RestoreHooks(event, stash)
    if not stash then return end
    for name, fn in pairs(stash) do hook.Add(event, name, fn) end
end

local function GetMemberStatus(uid)
    local ply = Player(uid)
    if not IsValid(ply) then return "dead" end
    if not ply:Alive() then return "dead", ply end
    if KrakenSquad._RespawnInCombatEnabled then
        local last = ply:GetNWFloat("KS.LastDamage", 0)
        local cfg  = KrakenSquad.GetConfig("respawn") or {}
        if last > 0 and CurTime() - last < (cfg.inCombatDuration or 5) then
            return "combat", ply
        end
    end
    return "available", ply
end

KrakenSquad.Net.Receive("KS.RespawnSync", function()
    KrakenSquad._RespawnTimeoutEnabled  = net.ReadBool()
    KrakenSquad._RespawnTimeout         = net.ReadFloat()
    KrakenSquad._RespawnInCombatEnabled = net.ReadBool()
    KrakenSquad._RespawnDelay           = net.ReadFloat()

    local count = net.ReadUInt(8)
    local members = {}
    for i = 1, count do
        members[i] = { uid = net.ReadUInt(16), alive = net.ReadBool(), combat = net.ReadBool() }
    end
    local cpCount = net.ReadUInt(8)
    local cps = {}
    for i = 1, cpCount do
        cps[i] = { entIdx = net.ReadInt(32), name = net.ReadString(), pos = net.ReadVector() }
    end

    if BattleGrid and BattleGrid._RespawnActive then
        BattleGrid._RespawnActive = false
        BattleGrid._RespawnSelected = nil
        BattleGrid._RespawnSpectating = nil
        BattleGrid._RespawnSpectatePos = nil
        BattleGrid._RespawnCPs = {}
        if IsValid(BattleGrid._RespawnPanel) then
            BattleGrid._RespawnPanel:Remove()
            BattleGrid._RespawnPanel = nil
        end
    end

    if not KF.Integrations.PlayerInWorld(LocalPlayer()) then return end

    KrakenSquad._RespawnActive     = true
    KrakenSquad._RespawnMembers    = members
    KrakenSquad._RespawnCPs        = cps
    KrakenSquad._RespawnSelected   = -1
    KrakenSquad._RespawnSpectating = nil
    KrakenSquad._RespawnStartTime  = CurTime()

    KF.Fonts.Create(AID)
    if IsValid(KrakenSquad._RespawnPanel) then KrakenSquad._RespawnPanel:Remove() end
    KrakenSquad.OpenRespawnScreen()
end)

KrakenSquad.Net.Receive("KS.RespawnCancel", function() KrakenSquad.CloseRespawnScreen() end)

function KrakenSquad.CloseRespawnScreen()
    KrakenSquad._RespawnActive     = false
    KrakenSquad._RespawnSelected   = -1
    KrakenSquad._RespawnSpectating = nil
    KrakenSquad._RespawnCPs        = {}
    if IsValid(KrakenSquad._RespawnPanel) then
        KrakenSquad._RespawnPanel:Remove()
        KrakenSquad._RespawnPanel = nil
    end
    RestoreHooks("HUDPaint", stashedHUD);     stashedHUD = nil
    RestoreHooks("CalcView", stashedCalcView); stashedCalcView = nil
end

local function MakeStatusCard(parent, w, h, isSelected, drawContents)
    local card = vgui.Create("DButton", parent)
    card:SetSize(w, h); card:SetText("")
    card._hoverLerp = 0
    card.Paint = function(s, cw, ch)
        local sel = isSelected()
        s._hoverLerp = Lerp(FrameTime() * HOVER_SPEED, s._hoverLerp, (s.Hovered or sel) and 1 or 0)
        local accent = P("Accent")
        surface.SetDrawColor(0, 0, 0, math.floor(Lerp(s._hoverLerp, 40, 80)))
        surface.DrawRect(0, 0, cw, ch)
        if sel then
            surface.SetDrawColor(accent.r, accent.g, accent.b, 40)
            surface.DrawRect(0, 0, cw, ch)
            surface.SetDrawColor(accent)
            surface.DrawRect(0, ch - 2, cw, 2)
        end
        surface.SetDrawColor(P("Border").r, P("Border").g, P("Border").b, math.floor(60 + 60 * s._hoverLerp))
        surface.DrawOutlinedRect(0, 0, cw, ch, 1)
        if s._hoverLerp > 0.01 then
            surface.SetDrawColor(accent.r, accent.g, accent.b, math.floor(100 * s._hoverLerp))
            surface.DrawRect(0, 0, 2, ch)
        end
        drawContents(s, cw, ch)
    end
    card.OnCursorEntered = function() KF.Helpers.PlaySound(SOUNDS.hover) end
    return card
end

function KrakenSquad.OpenRespawnScreen()
    if IsValid(KrakenSquad._RespawnPanel) then KrakenSquad._RespawnPanel:Remove() end
    KF.Fonts.Create(AID)
    if BF2HUD and not stashedHUD then stashedHUD = StashHooks("HUDPaint", BF2_HOOKS) end
    if not stashedCalcView then stashedCalcView = StashHooks("CalcView", nil, "KrakenSquad.RespawnSpectate") end

    local sw, sh = ScrW(), ScrH()
    local panel = vgui.Create("DPanel")
    panel:SetPos(0, 0); panel:SetSize(sw, sh)
    panel:MakePopup(); panel:SetKeyboardInputEnabled(false)
    panel._openLerp = 0
    KrakenSquad._RespawnPanel = panel

    local cardH = Scaled(50)
    local gap   = Scaled(6)
    local positions = KrakenSquad.GetPositions()
    local accent = P("Accent")
    local cps = KrakenSquad._RespawnCPs

    local totalSlots = #KrakenSquad._RespawnMembers + 1 + #cps
    local maxW   = sw - Scaled(40)
    local cardW  = math.min(Scaled(180), math.floor((maxW - (totalSlots - 1) * gap) / totalSlots))
    local startX = (sw - (totalSlots * cardW + (totalSlots - 1) * gap)) / 2
    local cardsY = sh * 0.72

    panel.Paint = function(_, w, h)
        panel._openLerp = Lerp(FrameTime() * 6, panel._openLerp, 1)
        local a = panel._openLerp
        surface.SetDrawColor(0, 0, 0, math.floor(180 * a))
        surface.DrawRect(0, 0, w, h)

        KF.Draw.GlowText(KrakenSquad.L("respawn_title"), "KS.respawn.deploy", w / 2, sh * 0.08, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local s = LocalPlayer():GetKSSquad()
        if s then
            draw.SimpleText(s:GetTitle(), "KS.respawn.name", w / 2, sh * 0.12, P("TextSecondary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if #KrakenSquad._RespawnMembers == 0 and #cps == 0 then
            draw.SimpleText(KrakenSquad.L("respawn_no_teammates"), "KS.respawn.hint", w / 2, sh * 0.65, P("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif KrakenSquad._RespawnSelected == -1 then
            local pulse = 0.6 + math.sin(CurTime() * 3) * 0.4
            draw.SimpleText(KrakenSquad.L("respawn_select"), "KS.respawn.hint",
                w / 2, sh * 0.65, KF.UI.ColorAlpha(P("TextMuted"), math.floor(255 * pulse)),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        if KrakenSquad._RespawnTimeoutEnabled then
            local rem = math.max(0, math.ceil(KrakenSquad._RespawnTimeout - (CurTime() - KrakenSquad._RespawnStartTime)))
            local col = rem <= 5 and P("Error") or P("TextSecondary")
            draw.SimpleText(KrakenSquad.L("respawn_auto_in"), "KS.respawn.hint", w - Scaled(30), Scaled(8), P("TextMuted"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            draw.SimpleText(("%02d"):format(rem), "KS.respawn.timer", w - Scaled(30), Scaled(20), col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            if rem <= 10 and rem > 0 then
                draw.SimpleText(KrakenSquad.L("respawn_timeout_warn"):format(rem), "KS.respawn.hint",
                    w / 2, sh * 0.95, P("Warning"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        local revivePulse = 0.5 + math.sin(CurTime() * 2) * 0.5
        draw.SimpleText(KrakenSquad.L("respawn_revive_hint"), "KS.respawn.hint",
            w / 2, sh * 0.17, KF.UI.ColorAlpha(P("Warning"), math.floor(180 + 75 * revivePulse)),
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local delayRem = math.max(0, (KrakenSquad._RespawnDelay or 0) - (CurTime() - KrakenSquad._RespawnStartTime))
        if delayRem > 0 then
            draw.SimpleText(KrakenSquad.L("respawn_delay_remaining"):format(math.ceil(delayRem)),
                "KS.respawn.hint", w / 2, sh * 0.62, P("Warning"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        surface.SetDrawColor(accent.r, accent.g, accent.b, math.floor(30 * a))
        surface.DrawRect(0, cardsY - Scaled(20), w, cardH + Scaled(40))
        surface.SetDrawColor(accent.r, accent.g, accent.b, math.floor(60 * a))
        surface.DrawRect(0, cardsY - Scaled(20), w, 1)
        surface.DrawRect(0, cardsY + cardH + Scaled(20), w, 1)
    end

    for idx, m in ipairs(KrakenSquad._RespawnMembers) do
        local card = MakeStatusCard(panel, cardW, cardH,
            function() return KrakenSquad._RespawnSelected == m.uid end,
            function(_, cw, ch)
                local status, ply = GetMemberStatus(m.uid)
                local name = IsValid(ply) and KF.Integrations.GetPlayerName(ply) or KrakenSquad.L("unknown_player")
                local pd = positions[IsValid(ply) and ply:GetKSPosition() or #positions] or positions[#positions]
                local roleCol = KrakenSquad.GetPositionColor(pd)
                local textX = Scaled(6)

                if pd and pd.icon and pd.icon ~= "" then
                    local mat = KF.Materials.Get(pd.icon)
                    if mat and not mat:IsError() then
                        surface.SetDrawColor(roleCol.r, roleCol.g, roleCol.b, status == "available" and 230 or 60)
                        surface.SetMaterial(mat)
                        surface.DrawTexturedRect(textX, Scaled(8), Scaled(10), Scaled(10))
                        textX = textX + Scaled(14)
                    end
                end

                draw.SimpleText(name, "KS.respawn.name", textX, Scaled(6),
                    status == "available" and P("TextBright") or P("TextMuted"),
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                local mrs = KrakenSquad.GetPlayerMRSData(ply)
                local roleY = Scaled(22)
                if mrs then
                    local mc = KrakenSquad.GetMRSConfig()
                    local mrsX, mrsIco = textX, Scaled(8)
                    if mc.showIcons and mrs.icon then
                        local mat = mrs.icon
                        if type(mat) == "string" then mat = KF.Materials.Get(mat) end
                        if mat and not mat:IsError() then
                            surface.SetDrawColor(255, 255, 255, status == "available" and 180 or 50)
                            surface.SetMaterial(mat)
                            surface.DrawTexturedRect(mrsX, roleY, mrsIco, mrsIco)
                            mrsX = mrsX + mrsIco + Scaled(2)
                        end
                    end
                    draw.SimpleText(mrs.name, "KS.respawn.role", mrsX, roleY, P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    roleY = roleY + Scaled(10)
                end

                draw.SimpleText(pd and pd.name or "", "KS.respawn.role", textX, roleY,
                    status == "available" and roleCol or KF.UI.ColorAlpha(roleCol, 110),
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                local statusText, statusCol
                if status == "available" then statusText, statusCol = KrakenSquad.L("respawn_available"), P("Success")
                elseif status == "combat" then statusText, statusCol = KrakenSquad.L("respawn_in_combat"), P("Error")
                else                           statusText, statusCol = KrakenSquad.L("respawn_dead"),       P("TextMuted") end
                draw.SimpleText(statusText, "KS.respawn.status", cw - Scaled(6), Scaled(6),
                    statusCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

                if status == "available" and IsValid(ply) then
                    local frac = math.Clamp(math.max(ply:Health(), 0) / math.max(ply:GetMaxHealth(), 1), 0, 1)
                    local barW = cw - Scaled(12)
                    local barY = ch - Scaled(6)
                    surface.SetDrawColor(0, 0, 0, 40)
                    surface.DrawRect(Scaled(6), barY, barW, Scaled(2))
                    if frac > 0 then
                        local hpCol = frac < 0.3 and P("Error") or (frac < 0.7 and P("Warning") or P("Health"))
                        surface.SetDrawColor(hpCol)
                        surface.DrawRect(Scaled(6), barY, math.floor(barW * frac), Scaled(2))
                    end
                end

                if status == "combat" then
                    local pulse = 0.4 + math.sin(CurTime() * 6) * 0.3
                    surface.SetDrawColor(P("Error").r, P("Error").g, P("Error").b, math.floor(20 * pulse))
                    surface.DrawRect(0, 0, cw, ch)
                end
            end)
        card:SetPos(startX + idx * (cardW + gap), cardsY)
        card.DoClick = function()
            local _, ply = GetMemberStatus(m.uid)
            KF.Helpers.PlaySound(SOUNDS.click)
            KrakenSquad._RespawnSelected   = m.uid
            KrakenSquad._RespawnSpectating = IsValid(ply) and ply or nil
            net.Start("KS.RespawnSpectate")
                net.WriteInt(IsValid(ply) and ply:UserID() or -1, 32)
            net.SendToServer()
        end
    end

    local defaultCard = MakeStatusCard(panel, cardW, cardH,
        function() return KrakenSquad._RespawnSelected == 0 end,
        function(_, cw, ch)
            draw.SimpleText(KrakenSquad.L("respawn_default"), "KS.respawn.name",
                cw / 2, ch / 2 - Scaled(4), P("TextBright"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText(KrakenSquad.L("respawn_available"), "KS.respawn.status",
                cw / 2, ch / 2 + Scaled(10), P("Success"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end)
    defaultCard:SetPos(startX, cardsY)
    defaultCard.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        KrakenSquad._RespawnSelected   = 0
        KrakenSquad._RespawnSpectating = nil
    end

    local cpStartIdx = #KrakenSquad._RespawnMembers + 1
    for cpIdx, cp in ipairs(cps) do
        local diamond = { { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 }, { x = 0, y = 0 } }
        local card = MakeStatusCard(panel, cardW, cardH,
            function() return KrakenSquad._RespawnSelected == -cp.entIdx end,
            function(_, cw, ch)
                local d = Scaled(5)
                local dX = Scaled(6) + d
                local dY = ch / 2
                draw.NoTexture()
                surface.SetDrawColor(accent)
                diamond[1].x, diamond[1].y = dX,     dY - d
                diamond[2].x, diamond[2].y = dX + d, dY
                diamond[3].x, diamond[3].y = dX,     dY + d
                diamond[4].x, diamond[4].y = dX - d, dY
                surface.DrawPoly(diamond)

                local textX = dX + d + Scaled(6)
                draw.SimpleText(cp.name, "KS.respawn.name", textX, Scaled(6), P("TextBright"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(KrakenSquad.L("respawn_command_post"), "KS.respawn.role", textX, Scaled(22), P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(KrakenSquad.L("respawn_available"), "KS.respawn.status", cw - Scaled(6), Scaled(6), P("Success"), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            end)
        card:SetPos(startX + (cpStartIdx + cpIdx) * (cardW + gap), cardsY)
        card.DoClick = function()
            KF.Helpers.PlaySound(SOUNDS.click)
            KrakenSquad._RespawnSelected = -cp.entIdx
            local ent = Entity(cp.entIdx)
            KrakenSquad._RespawnSpectating = IsValid(ent) and ent or nil
            net.Start("KS.RespawnSpectate") net.WriteInt(-cp.entIdx, 32) net.SendToServer()
        end
    end

    local btnW, btnH = Scaled(160), Scaled(36)
    local deploy = vgui.Create("KF.Button", panel)
    deploy:SetAddon(AID); deploy:SetLabel(KrakenSquad.L("respawn_deploy")); deploy:SetSolid(true)
    deploy.DoClick = function()
        if KrakenSquad._RespawnSelected == -1 then return end
        local target = KrakenSquad._RespawnSelected == 0 and -1 or KrakenSquad._RespawnSelected
        net.Start("KS.RespawnRequest") net.WriteInt(target, 32) net.SendToServer()
        KrakenSquad.CloseRespawnScreen()
    end
    deploy:SetPos(sw / 2 - btnW / 2, cardsY + cardH + Scaled(30))
    deploy:SetSize(btnW, btnH)
    deploy:SetVisible(false)

    panel.Think = function()
        if not IsValid(deploy) then return end
        local delayDone = (CurTime() - KrakenSquad._RespawnStartTime) >= (KrakenSquad._RespawnDelay or 0)
        local sel = KrakenSquad._RespawnSelected
        if sel == -1 then deploy:SetVisible(false) return end
        if sel == 0 or sel < -1 then deploy:SetVisible(delayDone) return end
        deploy:SetVisible(GetMemberStatus(sel) == "available" and delayDone)
    end
end

hook.Add("CalcView", "KrakenSquad.RespawnSpectate", function(ply, _, _, fov)
    if not KrakenSquad._RespawnActive then return end
    local target = KrakenSquad._RespawnSpectating
    if not IsValid(target) then return end

    local pos, rotYaw
    if target:IsPlayer() then
        pos = target:GetPos() + Vector(0, 0, target:Alive() and 60 or 20)
        rotYaw = target:EyeAngles().y
    else
        pos = target:GetPos() + Vector(0, 0, 80)
        rotYaw = CurTime() * 15
    end

    local offset = Vector(-80, 40, 30); offset:Rotate(Angle(0, rotYaw, 0))
    local cam = pos + offset
    local tr = util.TraceLine({ start = pos, endpos = cam, filter = { target, ply }, mask = MASK_SOLID_BRUSHONLY })
    if tr.Hit then cam = tr.HitPos + tr.HitNormal * 5 end
    return { origin = cam, angles = (pos - cam):Angle(), fov = fov, drawviewer = false }
end)

hook.Add("ShouldDrawLocalPlayer", "KrakenSquad.RespawnDraw", function()
    if KrakenSquad._RespawnActive then return false end
end)

hook.Add("HUDShouldDraw", "KrakenSquad.RespawnHUD", function(name)
    if not KrakenSquad._RespawnActive then return end
    if name == "CHudHealth" or name == "CHudAmmo" or name == "CHudSecondaryAmmo"
        or name == "CHudCrosshair" or name == "CHudWeaponSelection" then
        return false
    end
end)

hook.Add("Think", "KrakenSquad.RespawnTick", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    if KrakenSquad._RespawnActive then
        if lp:Alive() then KrakenSquad.CloseRespawnScreen() end
        return
    end
    if lp:Alive() or not lp:GetNWBool("KS.InRespawn", false) then return end
    if not KF.Integrations.PlayerInWorld(lp) then return end
    if KrakenSquad._RespawnResyncTime and CurTime() < KrakenSquad._RespawnResyncTime then return end
    KrakenSquad._RespawnResyncTime = CurTime() + 2
    net.Start("KS.RespawnResync") net.SendToServer()
end)
