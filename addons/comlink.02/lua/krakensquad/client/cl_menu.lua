local AID    = KrakenSquad.AID
local P      = KrakenSquad.P
local SOUNDS = KrakenSquad.SOUNDS

local function F(n)  return KF.Fonts.Get(AID, n) end
local function FB(n) return KF.Fonts.GetBold(AID, n) end

function KrakenSquad.OpenCreator()
    if IsValid(KrakenSquad._CreatorFrame) then KrakenSquad._CreatorFrame:Remove() end
    KF.Helpers.PlaySound(SOUNDS.open)

    local fw, fh = math.min(KF.Scale(420), math.floor(ScrW() * 0.5)), KF.Scale(280)
    local frame = vgui.Create("KF.Frame")
    frame:SetSize(fw, fh); frame:Center(); frame:MakePopup()
    frame:SetAddon(AID); frame:SetFrameTitle(KrakenSquad.L("create_squad"))
    frame:SetHeaderHeight(42)
    KrakenSquad._CreatorFrame = frame
    KrakenSquad.MakeCloseButton(frame, fw - KF.Scale(42), KF.Scale(8))

    local title, isPublic = "", false
    local content = vgui.Create("DPanel", frame)
    content:SetPos(0, KF.Scale(42)); content:SetSize(fw, fh - KF.Scale(42))
    content.Paint = function() end

    local scroll = KrakenSquad.MakeScroll(content)
    local formW  = fw - KF.Scale(38)

    KrakenSquad.FormField(scroll, KrakenSquad.L("squad_name"), "", function(v) title = v end, { width = formW })
    KrakenSquad.FormToggle(scroll, KrakenSquad.L("public_squad"), false, function(v) isPublic = v end, nil, formW)
    KrakenSquad.FormDesc(scroll, KrakenSquad.L("creator_hint"))

    local create = vgui.Create("KF.Button", scroll)
    create:Dock(TOP); create:SetTall(KF.Scale(38))
    create:DockMargin(0, KF.Scale(14), 0, KF.Scale(8))
    create:SetAddon(AID); create:SetLabel(KrakenSquad.L("create"))
    create:SetStyle("success")
    create.DoClick = function()
        title = title:Trim()
        local ML = KrakenSquad.MAX_LENGTHS
        if #title < ML.squadNameMin or #title > ML.squadName then return end
        KF.Helpers.PlaySound(SOUNDS.success)
        net.Start("KS.RequestCreate")
            net.WriteString(title); net.WriteBool(isPublic)
        net.SendToServer()
        frame:AlphaTo(0, 0.2, 0, function() if IsValid(frame) then frame:Remove() end end)
    end
end

function KrakenSquad.OpenPublicList()
    if IsValid(KrakenSquad._ListFrame) then KrakenSquad._ListFrame:Remove() end
    KF.Helpers.PlaySound(SOUNDS.open)

    local sw, sh = ScrW(), ScrH()
    local fw = math.min(KF.Scale(440), math.floor(sw * 0.5))
    local fh = math.min(KF.Scale(500), math.floor(sh * 0.7))

    local frame = vgui.Create("KF.Frame")
    frame:SetSize(fw, fh); frame:Center(); frame:MakePopup()
    frame:SetAddon(AID); frame:SetFrameTitle(KrakenSquad.L("public_squads"))
    frame:SetHeaderHeight(42)
    KrakenSquad._ListFrame = frame
    KrakenSquad.MakeCloseButton(frame, fw - KF.Scale(42), KF.Scale(8))

    local content = vgui.Create("DPanel", frame)
    content:SetPos(0, KF.Scale(42)); content:SetSize(fw, fh - KF.Scale(48))
    content.Paint = function(_, w, h)
        KF.Draw.RoundedBox(0, 0, w, h, 0, KF.UI.ColorAlpha(P("Panel"), 60))
    end

    local scroll = KrakenSquad.MakeScroll(content)

    local function Populate(data)
        for _, child in ipairs(scroll:GetCanvas():GetChildren()) do child:Remove() end
        local hasAny = false
        for _, squad in ipairs(data) do
            if not squad.public then continue end
            hasAny = true
            local card = KrakenSquad.UI.MakeListCard(scroll, {
                cursor = "hand",
                paint = function(_, w, h)
                    draw.SimpleText(squad.name, FB("body"), KF.Scale(16), h / 2 - KF.Scale(6),
                        P("Accent"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    local meta = { KrakenSquad.L("members_count", squad.members or 0) }
                    if squad.leader then meta[#meta + 1] = squad.leader end
                    draw.SimpleText(table.concat(meta, " \xc2\xb7 "), F("tiny"), KF.Scale(16), h / 2 + KF.Scale(10),
                        P("TextMuted"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end,
            })
            local join = vgui.Create("KF.Button", card)
            join:Dock(RIGHT)
            join:DockMargin(0, KF.Scale(12), KF.Scale(8), KF.Scale(12))
            join:SetWide(KF.Scale(70)); join:SetAddon(AID)
            join:SetLabel(KrakenSquad.L("join")); join:SetSolid(true)
            join.DoClick = function()
                KF.Helpers.PlaySound(SOUNDS.click)
                KrakenSquad.RequestJoinPublic(squad.id)
                frame:Remove()
            end
        end
        if not hasAny then KrakenSquad.MakeEmptyLabel(scroll) end
    end

    hook.Add("KrakenSquad.SquadListReceived", "KS.PopulatePublicList", function(data)
        if not IsValid(scroll) then
            hook.Remove("KrakenSquad.SquadListReceived", "KS.PopulatePublicList")
            return
        end
        Populate(data)
    end)

    net.Start("KS.RequestSquads") net.SendToServer()
    frame:SetAlpha(0); frame:AlphaTo(255, 0.15)
end

function KrakenSquad.OpenInviteFrame(inviter, squadName)
    if IsValid(KrakenSquad._InviteFrame) then KrakenSquad._InviteFrame:Remove() end
    KF.Fonts.Create(AID)

    local S = KF.Scale
    local fw, fh = S(380), S(180)
    local hdrH, pad = S(42), S(12)

    local frame = vgui.Create("KF.Frame")
    frame:SetSize(fw, fh)
    frame:SetPos(ScrW() / 2 - fw / 2, ScrH() * 0.3)
    frame:MakePopup(); frame:SetKeyboardInputEnabled(false)
    frame:SetAddon(AID); frame:SetFrameTitle(KrakenSquad.L("invite_title"))
    frame:SetHeaderHeight(42)
    KrakenSquad._InviteFrame = frame
    KF.Helpers.PlaySound(SOUNDS.open)

    local inviterName = IsValid(inviter) and inviter:Nick() or KrakenSquad.L("unknown_player")
    local contentH = fh - hdrH - pad * 2
    local content = vgui.Create("DPanel", frame)
    content:SetPos(pad, hdrH + S(8)); content:SetSize(fw - pad * 2, contentH)
    content.Paint = function() end

    local info = vgui.Create("DPanel", content)
    info:SetPos(0, 0); info:SetSize(fw - pad * 2, S(40))
    info.Paint = function()
        draw.SimpleText(squadName,   "KS.invite.item", 0, S(4),  P("TextBright"))
        draw.SimpleText(inviterName, "KS.invite.sub",  0, S(22), P("TextMuted"))
    end

    local function Respond(accept)
        timer.Remove("KS.InviteTimeout")
        net.Start("KS.InviteDecision") net.WriteBool(accept) net.SendToServer()
        if IsValid(frame) then frame:Remove() end
    end

    local btnW, btnH, gap = S(130), S(32), S(12)
    local accept = vgui.Create("KF.Button", content)
    accept:SetAddon(AID); accept:SetLabel(KrakenSquad.L("accept"))
    accept:SetStyle("success"); accept:SetSolid(true)
    accept.DoClick = function() Respond(true) end
    accept:SetPos(0, contentH - btnH - S(4))
    accept:SetSize(btnW, btnH)

    local decline = vgui.Create("KF.Button", content)
    decline:SetAddon(AID); decline:SetLabel(KrakenSquad.L("decline"))
    decline:SetStyle("danger"); decline:SetSolid(true)
    decline.DoClick = function() Respond(false) end
    decline:SetPos(btnW + gap, contentH - btnH - S(4))
    decline:SetSize(btnW, btnH)

    timer.Create("KS.InviteTimeout", 20, 1, function() Respond(false) end)
end

local function PrefRow(parent, h)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP); row:SetTall(KF.Scale(h or 32))
    row:DockMargin(0, KF.Scale(2), 0, 0); row._hoverLerp = 0
    row.Paint = function(s, w, ph)
        KF.Anim.UpdateHoverLerp(s)
        KF.Draw.RoundedBox(0, 0, w, ph, 2, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
    end
    return row
end

local function ConfigToggle(parent, label, checked, onChange)
    local row = PrefRow(parent, 32)
    local cb = vgui.Create("KF.Checkbox", row)
    cb:Dock(FILL); cb:DockMargin(KF.Scale(12), 0, KF.Scale(12), 0)
    cb:SetAddon(AID); cb:SetLabel(label); cb:SetChecked(checked)
    DButton.SetText(cb, "")
    cb.OnChange = function(_, v)
        KF.Helpers.PlaySound(SOUNDS.click)
        onChange(v)
    end
end

local function ConfigSlider(parent, label, value, minVal, maxVal, onChange)
    local row = PrefRow(parent, 36)
    local origPaint = row.Paint
    row.Paint = function(s, w, ph)
        origPaint(s, w, ph)
        draw.SimpleText(label, F("small"), KF.Scale(12), ph / 2,
            P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local slider = vgui.Create("DNumSlider", row)
    slider:Dock(RIGHT); slider:DockMargin(0, KF.Scale(2), KF.Scale(12), KF.Scale(2))
    slider:SetWide(KF.Scale(200))
    slider:SetMin(minVal); slider:SetMax(maxVal); slider:SetDecimals(0)
    slider:SetValue(value); slider:SetText("")
    slider.Label:SetVisible(false)
    slider.OnValueChanged = function(_, v) onChange(math.floor(v)) end
end

local function KeyBinderRow(parent, label, currentKey, onChanged)
    local row = PrefRow(parent, 36)
    local origPaint = row.Paint
    row.Paint = function(s, w, ph)
        origPaint(s, w, ph)
        draw.SimpleText(label, F("small"), KF.Scale(12), ph / 2,
            P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local b = vgui.Create("DBinder", row)
    b:Dock(RIGHT); b:DockMargin(0, KF.Scale(4), KF.Scale(12), KF.Scale(4))
    b:SetWide(KF.Scale(140)); b:SetValue(currentKey); b:SetText("")
    b._hoverLerp = 0
    b.Paint = function(s, w, h)
        s._hoverLerp = KF.Anim.FastLerp(s._hoverLerp, s.Hovered and 1 or 0, 10)
        KF.Draw.RoundedBox(0, 0, w, h, 2, KF.UI.LerpColor(s._hoverLerp, P("PanelDark"), P("PanelHover")))
        surface.SetDrawColor(KF.UI.LerpColor(s._hoverLerp, P("Border"), P("Accent")))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        local key = s.Trapping and KrakenSquad.L("admin_press_key")
            or (input.GetKeyName(s:GetSelectedNumber()) or KrakenSquad.L("key_none"))
        draw.SimpleText(key:upper(), F("small"), w / 2, h / 2,
            P("TextPrimary"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.UpdateText = function(s) s:SetText("") end
    b.OnCursorEntered = function() KF.Helpers.PlaySound(SOUNDS.hover) end
    b.DoClick = function(s)
        KF.Helpers.PlaySound(SOUNDS.click)
        s:SetText(""); input.StartKeyTrapping(); s.Trapping = true
    end
    b.OnChange = function(_, num) if num and num > 0 then onChanged(num) end end
end

local function ConfigColorRow(parent, label, currentColor, onChange)
    local row = PrefRow(parent, 36)
    local origPaint = row.Paint
    row.Paint = function(s, w, ph)
        origPaint(s, w, ph)
        draw.SimpleText(label, F("small"), KF.Scale(12), ph / 2,
            P("TextPrimary"), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    local prev = vgui.Create("DButton", row)
    prev:Dock(RIGHT); prev:DockMargin(0, KF.Scale(4), KF.Scale(12), KF.Scale(4))
    prev:SetWide(KF.Scale(80)); prev:SetText("")
    prev._color = Color(currentColor[1] or 255, currentColor[2] or 255, currentColor[3] or 255)
    prev.Paint = function(s, w, h)
        KF.Draw.RoundedBox(0, 0, w, h, 4, s._color)
        surface.SetDrawColor(P("Border"))
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end
    prev.DoClick = function(s)
        KF.Helpers.PlaySound(SOUNDS.click)
        KrakenSquad.UI.OpenColorDialog(label, s._color, function(c)
            s._color = KF.UI.ColorAlpha(c, 255)
            onChange({ c.r, c.g, c.b })
        end)
    end
end

local CTX_TOGGLES = {
    { "show_pings",        "layout_pings"     },
    { "show_orders",       "ctx_orders"       },
    { "show_nametags",     "ctx_nametags"     },
    { "show_squad_events", "ctx_squad_events" },
    { "show_comm_markers", "ctx_comm_markers" },
}

local CTX_COLORS = {
    accent = "admin_accent", ally = "admin_ally",
    enemy  = "admin_enemy",  health = "admin_health_color",
}

function KrakenSquad.OpenContextMenu()
    if IsValid(KrakenSquad._CtxFrame) then KrakenSquad._CtxFrame:Remove() end

    local fw, fh = KF.Scale(420), KF.Scale(540)
    local footerH = KF.Scale(56)

    local frame = vgui.Create("KF.Frame")
    frame:SetSize(fw, fh); frame:Center(); frame:MakePopup()
    frame:SetAddon(AID); frame:SetFrameTitle(KrakenSquad.L("ctx_title"))
    frame:SetNotchSide("right"); frame:SetHeaderHeight(42)
    KrakenSquad._CtxFrame = frame
    KF.Helpers.PlaySound(SOUNDS.open)

    KrakenSquad.MakeCloseButton(frame, fw - KF.Scale(52), KF.Scale(8))

    local scroll = vgui.Create("KF.ScrollPanel", frame)
    scroll:SetPos(KF.Scale(8), KF.Scale(42))
    scroll:SetSize(fw - KF.Scale(16), fh - KF.Scale(42) - footerH - KF.Scale(4))
    scroll:SetAddon(AID)

    local function Section(name)
        return KF.Menu.Section(scroll, name, FB("small"), KrakenSquad.GetMenuColors())
    end

    Section(KrakenSquad.L("ctx_visibility"))
    for _, t in ipairs(CTX_TOGGLES) do
        ConfigToggle(scroll, KrakenSquad.L(t[2]),
            KrakenSquad.GetClientPref(t[1], true),
            function(v) KrakenSquad.SetClientPref(t[1], v) end)
    end

    Section(KrakenSquad.L("nametag_distance"))
    ConfigSlider(scroll, KrakenSquad.L("nametag_distance"),
        KrakenSquad.GetClientPref("nametag_distance", 2000), 200, 15000,
        function(v) KrakenSquad.SetClientPref("nametag_distance", v) end)

    Section(KrakenSquad.L("ctx_radial_key"))
    KeyBinderRow(scroll, KrakenSquad.L("admin_radial_key"),
        KrakenSquad.GetClientPref("radial_key", nil) or KrakenSquad.GetConfig("keybind") or KEY_G,
        function(num) KrakenSquad.SetClientPref("radial_key", num) end)

    Section(KrakenSquad.L("ctx_colors"))
    local serverCol = KrakenSquad.GetConfig("colors") or {}
    for ck, lk in pairs(CTX_COLORS) do
        local cur = KrakenSquad.GetClientPref("color_" .. ck, nil) or serverCol[ck] or { 255, 255, 255 }
        ConfigColorRow(scroll, KrakenSquad.L(lk):upper(),
            { cur[1] or 255, cur[2] or 255, cur[3] or 255 },
            function(v) KrakenSquad.SetClientPref("color_" .. ck, v) end)
    end

    local btnRow = vgui.Create("DPanel", frame)
    btnRow:SetPos(KF.Scale(8), fh - footerH)
    btnRow:SetSize(fw - KF.Scale(16), KF.Scale(44))
    btnRow.Paint = function() end

    local btnW = math.floor((fw - KF.Scale(24)) / 2)
    local btnH = KF.Scale(34)

    local layoutBtn = vgui.Create("KF.Button", btnRow)
    layoutBtn:SetPos(0, KF.Scale(4)); layoutBtn:SetSize(btnW, btnH)
    layoutBtn:SetAddon(AID); layoutBtn:SetLabel(KrakenSquad.L("ctx_layout_editor"))
    layoutBtn.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        frame:Remove()
        KrakenSquad.OpenLayoutEditor(false)
    end

    local resetBtn = vgui.Create("KF.Button", btnRow)
    resetBtn:SetPos(btnW + KF.Scale(8), KF.Scale(4)); resetBtn:SetSize(btnW, btnH)
    resetBtn:SetAddon(AID); resetBtn:SetLabel(KrakenSquad.L("ctx_reset"))
    resetBtn:SetStyle("danger"); resetBtn:SetSolid(true)
    resetBtn.DoClick = function()
        KF.Helpers.PlaySound(SOUNDS.click)
        KrakenSquad.ResetAllClientPrefs()
        frame:Remove()
        KrakenSquad.OpenContextMenu()
    end

    frame:SetAlpha(0); frame:AlphaTo(255, 0.15)
end

hook.Add("PopulateToolMenu", "KrakenSquad.ToolMenu", function()
    spawnmenu.AddToolMenuOption("Utilities", "KrakenSquad", "KrakenSquad_Settings",
        KrakenSquad.L("settings_title"), "", "", function(panel)
            panel:ClearControls()
            panel:Button(KrakenSquad.L("settings_open"), "krakensquad_context")
        end)
end)

hook.Add("AddToolMenuCategories", "KrakenSquad.ToolMenuCat", function()
    spawnmenu.AddToolCategory("Utilities", "KrakenSquad", "KrakenSquad")
end)

list.Set("DesktopWindows", "KrakenSquad", {
    title = KrakenSquad.L("settings_config"),
    icon  = "squads_system/squads_64.png",
    init  = function() KrakenSquad.OpenContextMenu() end,
})

concommand.Add("krakensquad_context", function() KrakenSquad.OpenContextMenu() end)
concommand.Add("krakensquad_create",  function() KrakenSquad.OpenCreator()    end)
concommand.Add("krakensquad_squads",  function() KrakenSquad.OpenPublicList() end)
