local AID    = KrakenSquad.AID
local P      = KrakenSquad.P
local LerpColor   = KF.UI.LerpColor
local HOVER_SPEED = KrakenSquad.UI.HOVER_SPEED
local COOKIE_PREFIX = "kslayout_"

KrakenSquad.Layout = KrakenSquad.Layout or {}
local L = KrakenSquad.Layout

L.AdminLayout  = L.AdminLayout  or {}
L.ClientLayout = L.ClientLayout or {}
L._LivePreview = nil

L.Blocks = {
    { id = "orders",  labelKey = "layout_orders",  w = 0.11,  h = 0.22 },
}

L.Defaults = {
    sidebar = { x = 0.01,  y = 0.25,   anchor = "left", yAnchor = "top", scale = 1 },
    orders  = { x = 0.875, y = 0.1275, anchor = "left", yAnchor = "top", scale = 1 },
}

local function AutoAnchor(fx, fy)
    return fx < 0.35 and "left" or (fx > 0.65 and "right"  or "center"),
           fy < 0.35 and "top"  or (fy > 0.65 and "bottom" or "center")
end

local function NormToScreen(nx, ny, bw, bh, ah, av)
    local sw, sh = ScrW(), ScrH()
    local px = math.Clamp(nx or 0.5, 0, 1) * sw
    local py = math.Clamp(ny or 0.5, 0, 1) * sh
    local sx = ah == "center" and px - bw / 2 or (ah == "right"  and px - bw or px)
    local sy = av == "center" and py - bh / 2 or (av == "bottom" and py - bh or py)
    return sx, sy
end

local function ScreenToNorm(sx, sy, bw, bh, ah, av)
    local sw, sh = ScrW(), ScrH()
    local px = ah == "center" and sx + bw / 2 or (ah == "right"  and sx + bw or sx)
    local py = av == "center" and sy + bh / 2 or (av == "bottom" and sy + bh or sy)
    return math.Clamp(px / sw, 0, 1), math.Clamp(py / sh, 0, 1)
end

function L.Resolve(id)
    return (L._LivePreview and L._LivePreview[id])
        or L.ClientLayout[id]
        or L.AdminLayout[id]
        or L.Defaults[id]
        or { x = 0.5, y = 0.5, anchor = "center", yAnchor = "center", scale = 1 }
end

function L.GetScale(id) return L.Resolve(id).scale or 1 end

function L.BlockScaled(id, n) return KF.Scale(n) * L.GetScale(id) end

function L.ToPixels(id, bw, bh)
    local data  = L.Resolve(id)
    local scale = data.scale or 1
    if not bw then
        for _, b in ipairs(L.Blocks) do
            if b.id == id then
                bw = b.w * ScrW() * scale
                bh = b.h * ScrH() * scale
                break
            end
        end
    end
    local sx, sy = NormToScreen(data.x, data.y, bw or 0, bh or 0, data.anchor, data.yAnchor)
    return sx, sy, scale
end

function L.LoadClientLayout()
    L.ClientLayout = {}
    for _, block in ipairs(L.Blocks) do
        local raw = cookie.GetString(COOKIE_PREFIX .. block.id, "")
        if raw ~= "" then
            local x, y, a, ya, sc = raw:match("([%d%.]+),([%d%.]+),(%a+),(%a+),?([%d%.]*)")
            if x then
                L.ClientLayout[block.id] = {
                    x = tonumber(x), y = tonumber(y),
                    anchor = a, yAnchor = ya,
                    scale = tonumber(sc) or 1,
                }
            end
        end
    end
end

function L.SaveClientLayout()
    for _, block in ipairs(L.Blocks) do
        local cl = L.ClientLayout[block.id]
        cookie.Set(COOKIE_PREFIX .. block.id, cl
            and ("%.4f,%.4f,%s,%s,%.2f"):format(cl.x, cl.y, cl.anchor, cl.yAnchor, cl.scale or 1)
            or "")
    end
end

function L.ResetClientLayout()
    L.ClientLayout = {}
    for _, block in ipairs(L.Blocks) do cookie.Set(COOKIE_PREFIX .. block.id, "") end
end

L.LoadClientLayout()

local function MigrateAdmin()
    L.AdminLayout = {}
    local cfg = KrakenSquad.GetConfig("layout") or {}
    for _, block in ipairs(L.Blocks) do
        local d = cfg[block.id]
        if d and d.x then
            L.AdminLayout[block.id] = {
                x = d.x, y = d.y,
                anchor  = d.anchor  or "left",
                yAnchor = d.yAnchor or "top",
                scale   = d.scale   or 1,
            }
        end
    end
end
MigrateAdmin()
hook.Add("KrakenSquad.ConfigUpdated", "KS.LayoutMigrate", MigrateAdmin)

function KrakenSquad.OpenLayoutEditor(isAdmin)
    KF.Fonts.Create(AID)
    if IsValid(KrakenSquad._LayoutFrame) then KrakenSquad._LayoutFrame:Remove() end
    if isAdmin and not KrakenSquad.IsAdmin(LocalPlayer()) then return end

    local sw, sh = ScrW(), ScrH()
    local toolbarH = 80
    local overlay = vgui.Create("DPanel")
    overlay:SetSize(sw, sh); overlay:MakePopup()
    overlay:SetKeyboardInputEnabled(true)
    overlay._openLerp = 0
    KrakenSquad._LayoutFrame = overlay
    L._LivePreview = {}

    overlay.Paint = function(s, w, h)
        s._openLerp = Lerp(FrameTime() * 8, s._openLerp, 1)
        surface.SetDrawColor(0, 0, 0, math.floor(180 * s._openLerp))
        surface.DrawRect(0, 0, w, h)
        local ac = P("Accent")
        surface.SetDrawColor(ac.r, ac.g, ac.b, 20)
        surface.DrawRect(math.floor(w / 2), 0, 1, h)
        surface.DrawRect(0, math.floor(h / 2), w, 1)
        for i = 1, 3 do
            local f = i * 0.25
            surface.SetDrawColor(255, 255, 255, 8)
            surface.DrawRect(math.floor(w * f), 0, 1, h)
            surface.DrawRect(0, math.floor(h * f), w, 1)
        end
    end

    local toolbar = vgui.Create("DPanel", overlay)
    toolbar:SetPos(0, 0); toolbar:SetSize(sw, toolbarH)
    toolbar.Paint = function(_, w, h)
        KF.Menu.MenuNotchedBox(0, 0, w, h, P("BG"), 0)
        local ac = P("Accent")
        surface.SetDrawColor(ac); surface.DrawRect(0, h - 2, w, 2)
        local title = isAdmin and KrakenSquad.L("layout_editor") or KrakenSquad.L("layout_editor_client")
        draw.SimpleText(title, "KS.layout.title", 20, 18, ac, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(KrakenSquad.L("layout_hint_scroll"), "KS.layout.hint", w / 2, 60,
            P("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local editing = {}
    for _, block in ipairs(L.Blocks) do
        local src = isAdmin and L.AdminLayout[block.id]
                  or L.ClientLayout[block.id] or L.AdminLayout[block.id]
        local def = L.Defaults[block.id] or {}
        editing[block.id] = {
            x       = (src and src.x)       or def.x       or 0.5,
            y       = (src and src.y)       or def.y       or 0.5,
            anchor  = (src and src.anchor)  or def.anchor  or "center",
            yAnchor = (src and src.yAnchor) or def.yAnchor or "center",
            scale   = (src and src.scale)   or def.scale   or 1,
        }
        L._LivePreview[block.id] = editing[block.id]
    end

    local panels = {}
    for _, block in ipairs(L.Blocks) do
        local data = editing[block.id]
        local bwBase = math.floor(sw * block.w)
        local bhBase = math.floor(sh * block.h)
        local bw = math.floor(bwBase * data.scale)
        local bh = math.floor(bhBase * data.scale)
        local sx, sy = NormToScreen(data.x, data.y, bw, bh, data.anchor, data.yAnchor)

        local bp = vgui.Create("DPanel", overlay)
        bp:SetSize(bw, bh)
        bp:SetPos(math.Clamp(sx, 0, sw - bw), math.Clamp(sy, toolbarH, sh - bh))
        bp:SetCursor("sizeall"); bp:SetMouseInputEnabled(true)
        bp.BlockID, bp.BlockDef, bp.LayoutData = block.id, block, data
        bp._bwBase, bp._bhBase = bwBase, bhBase
        bp._hoverLerp = 0

        bp.Paint = function(s, w, h)
            s._hoverLerp = Lerp(FrameTime() * HOVER_SPEED, s._hoverLerp, (s.Hovered or s._dragging) and 1 or 0)
            surface.SetDrawColor(0, 0, 0, math.floor(140 + 40 * s._hoverLerp))
            surface.DrawRect(0, 0, w, h)
            local ac = P("Accent")
            local borderCol = LerpColor(s._hoverLerp, KF.UI.ColorAlpha(ac, 100), KF.UI.ColorAlpha(ac, 200))
            KF.Menu.MenuNotchedOutline(0, 0, w, h, borderCol, 4, 1)
            if s._dragging then
                surface.SetDrawColor(ac.r, ac.g, ac.b, math.floor(15 + 10 * s._hoverLerp))
                surface.DrawRect(1, 1, w - 2, h - 2)
                if s._dragAxis then
                    draw.SimpleText(s._dragAxis == "x" and "X" or "Y", "KS.layout.anchor",
                        w - 4, h - 4, KF.UI.ColorAlpha(ac, 200), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
                end
            end
            draw.SimpleText(KrakenSquad.L(s.BlockDef.labelKey):upper(), "KS.layout.block",
                w / 2, h / 2 - 6, P("TextBright"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText((s.LayoutData.anchor or "?"):sub(1, 1):upper() .. " \194\183 "
                .. (s.LayoutData.yAnchor or "?"):sub(1, 1):upper(),
                "KS.layout.anchor", w / 2, h / 2 + 8, P("TextMuted"), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            local cs = s.LayoutData.scale or 1
            if cs ~= 1 then
                draw.SimpleText(math.Round(cs * 100) .. "%", "KS.layout.anchor",
                    w / 2, h / 2 + 20, ac, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            if s.LayoutData.anchor == "left" then
                surface.SetDrawColor(ac.r, ac.g, ac.b, 180)
                surface.DrawRect(0, 4, 3, h - 8)
            elseif s.LayoutData.anchor == "right" then
                surface.SetDrawColor(ac.r, ac.g, ac.b, 180)
                surface.DrawRect(w - 3, 4, 3, h - 8)
            end
        end

        function bp:OnMouseWheeled(d)
            self.LayoutData.scale = math.Clamp(math.Round(((self.LayoutData.scale or 1) + d * 0.1) * 10) / 10, 0.5, 2)
            self:SetSize(math.floor(self._bwBase * self.LayoutData.scale),
                         math.floor(self._bhBase * self.LayoutData.scale))
            self:UpdateLayout()
        end

        function bp:OnMousePressed(btn)
            if btn ~= MOUSE_LEFT then return end
            self._dragging = true
            self._dragOX, self._dragOY = self:CursorPos()
            self._dragStartSX, self._dragStartSY = self:GetPos()
            self._dragAxis = nil
            self:MouseCapture(true)
        end

        function bp:OnMouseReleased(btn)
            if btn ~= MOUSE_LEFT or not self._dragging then return end
            self._dragging = false
            self:MouseCapture(false)
            self:UpdateLayout()
        end

        function bp:Think()
            if not self._dragging then return end
            local mx, my = gui.MousePos()
            local nx = math.Clamp(mx - self._dragOX, 0, sw - self:GetWide())
            local ny = math.Clamp(my - self._dragOY, toolbarH, sh - self:GetTall())
            local lockX = input.IsKeyDown(KEY_LSHIFT)   or input.IsKeyDown(KEY_RSHIFT)
            local lockY = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
            if lockX and not lockY then ny = self._dragStartSY; self._dragAxis = "x"
            elseif lockY and not lockX then nx = self._dragStartSX; self._dragAxis = "y"
            else self._dragAxis = nil end
            self:SetPos(nx, ny)
            self:UpdateLayout()
        end

        function bp:UpdateLayout()
            local sx2, sy2 = self:GetPos()
            local w2, h2 = self:GetSize()
            local ah, av = AutoAnchor((sx2 + w2 / 2) / sw, (sy2 + h2 / 2) / sh)
            self.LayoutData.x, self.LayoutData.y = ScreenToNorm(sx2, sy2, w2, h2, ah, av)
            self.LayoutData.anchor, self.LayoutData.yAnchor = ah, av
        end

        function bp:ResetToDefault()
            local def = L.Defaults[self.BlockID]
            if not def then return end
            self.LayoutData.x       = def.x
            self.LayoutData.y       = def.y
            self.LayoutData.anchor  = def.anchor  or "left"
            self.LayoutData.yAnchor = def.yAnchor or "top"
            self.LayoutData.scale   = 1
            self:SetSize(self._bwBase, self._bhBase)
            local nx, ny = NormToScreen(def.x, def.y, self._bwBase, self._bhBase, self.LayoutData.anchor, self.LayoutData.yAnchor)
            self:SetPos(math.Clamp(nx, 0, sw - self._bwBase), math.Clamp(ny, toolbarH, sh - self._bhBase))
        end

        panels[block.id] = bp
    end

    local S = KF.Scale
    local function MakeBtn(x, label, style, solid, onClick)
        local b = vgui.Create("KF.Button", overlay)
        b:SetAddon(AID); b:SetLabel(label)
        if style then b:SetStyle(style) end
        if solid then b:SetSolid(true) end
        b.DoClick = onClick
        b:SetSize(S(160), S(32))
        b:SetPos(x, toolbarH + S(16))
        return b
    end

    local btnBarX = sw - S(540)
    MakeBtn(btnBarX, KrakenSquad.L("admin_save"), "success", true, function()
        if isAdmin then
            local saveData = {}
            for id, bp in pairs(panels) do saveData[id] = table.Copy(bp.LayoutData) end
            KF.Net.SendJSON("KS.LayoutUpdate", saveData)
            L.AdminLayout = saveData
        else
            L.ClientLayout = {}
            for id, bp in pairs(panels) do L.ClientLayout[id] = table.Copy(bp.LayoutData) end
            L.SaveClientLayout()
        end
        L._LivePreview = nil
        overlay:Remove()
        KrakenSquad._LayoutFrame = nil
    end)

    MakeBtn(btnBarX + S(180), KrakenSquad.L("ctx_reset"), "danger", true, function()
        for _, bp in pairs(panels) do bp:ResetToDefault() end
        if isAdmin then
            L.AdminLayout = {}
            KF.Net.SendJSON("KS.LayoutUpdate", {})
        else
            L.ResetClientLayout()
        end
    end)

    MakeBtn(btnBarX + S(360), KrakenSquad.L("layout_cancel"), nil, false, function()
        L._LivePreview = nil
        overlay:Remove()
        KrakenSquad._LayoutFrame = nil
    end)

    function overlay:OnKeyCodePressed(key)
        if key == KEY_ESCAPE then
            L._LivePreview = nil
            self:Remove()
            KrakenSquad._LayoutFrame = nil
        end
    end
end

concommand.Add("krakensquad_layout",       function() KrakenSquad.OpenLayoutEditor(false) end)
concommand.Add("krakensquad_layout_admin", function() KrakenSquad.OpenLayoutEditor(true)  end)
