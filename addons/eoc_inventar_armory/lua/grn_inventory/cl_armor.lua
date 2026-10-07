--[[
    GRN Inventory - armor visuals

    1) World: worn armor pieces are bone-merged onto players (only on models
       allowed by C.Armor.VisualMode / BaseModels).
    2) Inventory: the character preview (paper doll) in the middle of the
       loadout column, positioned over the HTML viewport reported by JS.
]]

local INV = GRNInventory
local C = INV.Config

local function decodeVisuals(raw)
    if not isstring(raw) or raw == "" then return {} end
    local list = util.JSONToTable(raw)
    return istable(list) and list or {}
end

local function applyLook(ent, piece)
    ent:SetSkin(tonumber(piece.k) or 0)
    if istable(piece.b) then
        for index, value in pairs(piece.b) do
            ent:SetBodygroup(tonumber(index) or 0, tonumber(value) or 0)
        end
    end
end

local function createPart(piece, parent)
    if not util.IsValidModel(tostring(piece.m or "")) then return nil end
    local ent = ClientsideModel(piece.m, RENDERGROUP_OPAQUE)
    if not IsValid(ent) then return nil end
    ent:SetNoDraw(true)
    ent:SetParent(parent)
    ent:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))
    applyLook(ent, piece)
    return ent
end

local function removeParts(holder)
    if not holder or not holder.parts then return end
    for _, ent in ipairs(holder.parts) do
        if IsValid(ent) then ent:Remove() end
    end
    holder.parts = {}
end

-- -----------------------------------------------------------------------
-- World rendering
-- -----------------------------------------------------------------------
local worldParts = {} -- ply -> { sig = string, parts = {} }

hook.Add("PostPlayerDraw", "GRNInventory_ArmorVisuals", function(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if C.Armor and C.Armor.Enabled == false then return end

    local raw = ply:GetNW2String("GRNArmorVisual", "")
    local holder = worldParts[ply]

    if raw == "" or not INV.ArmorVisualAllowed(ply:GetModel()) then
        if holder then removeParts(holder) worldParts[ply] = nil end
        return
    end

    if not holder or holder.sig ~= raw then
        if holder then removeParts(holder) end
        holder = { sig = raw, parts = {} }
        worldParts[ply] = holder
        for _, piece in ipairs(decodeVisuals(raw)) do
            local ent = createPart(piece, ply)
            if ent then holder.parts[#holder.parts + 1] = ent end
        end
    end

    for _, ent in ipairs(holder.parts) do
        if IsValid(ent) then
            if ent:GetParent() ~= ply then
                ent:SetParent(ply)
                ent:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))
            end
            ent:DrawModel()
        end
    end
end)

timer.Create("GRNInventory_ArmorVisualCleanup", 5, 0, function()
    for ply, holder in pairs(worldParts) do
        if not IsValid(ply) then
            removeParts(holder)
            worldParts[ply] = nil
        end
    end
end)

-- -----------------------------------------------------------------------
-- Inventory character preview
-- -----------------------------------------------------------------------
local doll

local function dollConfig()
    return (C.Armor and C.Armor.Doll) or {}
end

function INV.RemoveArmorDoll()
    if IsValid(doll) then
        removeParts(doll.GRNHolder)
        doll:Remove()
    end
    doll = nil
end

local function fitDoll(panel)
    local ent = panel.Entity
    if not IsValid(ent) then return end
    local mins, maxs = ent:GetRenderBounds()
    -- Player hulls are ~72 units; helmets/antennas stick out above that.
    local bottom = math.min(0, mins.z)
    local top = math.max(maxs.z, 78)
    local height = top - bottom
    local center = Vector(0, 0, bottom + height * 0.5)
    local fov = math.Clamp(tonumber(dollConfig().FOV) or 26, 10, 80)

    -- Source treats the FOV as horizontal for a 4:3 view, so the vertical
    -- half-angle is atan(tan(fov/2) * 3/4). Fit the full height plus margin,
    -- and also the width when the panel is narrow.
    local tanHalf = math.tan(math.rad(fov * 0.5))
    local tanV = tanHalf * 0.75
    local w, h = panel:GetSize()
    local aspect = math.max(0.2, w / math.max(1, h))
    local tanH = tanV * aspect
    local margin = tonumber(dollConfig().Margin) or 1.26
    local distV = (height * 0.5 * margin) / tanV
    local distH = (math.max(36, (maxs.x - mins.x), (maxs.y - mins.y)) * 0.5 * margin) / tanH
    local dist = math.max(distV, distH)

    panel:SetFOV(fov)
    panel:SetLookAt(center)
    panel:SetCamPos(center + Vector(dist, 0, 0))
    panel.GRNFitSize = w .. "x" .. h
end

local function refreshDollModel(panel)
    local ply = LocalPlayer()
    if not IsValid(ply) or not IsValid(panel) then return end

    local model = ply:GetModel()
    if panel.GRNModel ~= model then
        panel:SetModel(model)
        panel.GRNModel = model
        panel.GRNArmorSig = nil
        local ent = panel.Entity
        if IsValid(ent) then
            local seq = ent:LookupSequence(tostring(dollConfig().Sequence or "idle_all_01"))
            if not seq or seq < 0 then seq = ent:LookupSequence("idle_all_01") end
            if seq and seq >= 0 then ent:ResetSequence(seq) end
        end
        fitDoll(panel)
    end

    local ent = panel.Entity
    if not IsValid(ent) then return end
    ent:SetSkin(ply:GetSkin())
    for i = 0, ply:GetNumBodyGroups() - 1 do
        ent:SetBodygroup(i, ply:GetBodygroup(i))
    end

    -- Armor parts (same rules as in the world).
    local raw = INV.ArmorVisualAllowed(model) and ply:GetNW2String("GRNArmorVisual", "") or ""
    if panel.GRNArmorSig ~= raw then
        panel.GRNArmorSig = raw
        panel.GRNHolder = panel.GRNHolder or { parts = {} }
        removeParts(panel.GRNHolder)
        for _, piece in ipairs(decodeVisuals(raw)) do
            local part = createPart(piece, ent)
            if part then panel.GRNHolder.parts[#panel.GRNHolder.parts + 1] = part end
        end
    end
end

local function ensureDoll()
    if not IsValid(INV.UI) then return nil end
    if IsValid(doll) and doll:GetParent() == INV.UI then return doll end
    INV.RemoveArmorDoll()

    local panel = vgui.Create("DModelPanel", INV.UI)
    panel:SetMouseInputEnabled(false)
    panel:SetKeyboardInputEnabled(false)
    if panel.SetPaintBackground then panel:SetPaintBackground(false) end
    panel:SetAmbientLight(Color(70, 78, 92))
    panel:SetDirectionalLight(BOX_FRONT, Color(255, 244, 222))
    panel:SetDirectionalLight(BOX_TOP, Color(200, 205, 215))
    panel:SetDirectionalLight(BOX_RIGHT, Color(255, 190, 50))
    panel:SetDirectionalLight(BOX_LEFT, Color(70, 90, 120))
    panel:SetDirectionalLight(BOX_BACK, Color(60, 70, 90))
    panel:SetVisible(false)
    panel.GRNHolder = { parts = {} }

    panel.LayoutEntity = function(self, ent)
        local cfg = dollConfig()
        local yaw = tonumber(cfg.Yaw) or 18
        if cfg.Spin then yaw = yaw + (RealTime() * (tonumber(cfg.SpinSpeed) or 12)) % 360 end
        ent:SetAngles(Angle(0, yaw, 0))
        self:RunAnimation()
    end

    panel.PostDrawModel = function(self, ent)
        for _, part in ipairs(self.GRNHolder.parts or {}) do
            if IsValid(part) then
                if part:GetParent() ~= ent then
                    part:SetParent(ent)
                    part:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL))
                end
                part:DrawModel()
            end
        end
    end

    panel.OnRemove = function(self)
        removeParts(self.GRNHolder)
    end

    doll = panel
    return panel
end

-- Called from the inventory HTML with the screen rect of #dollViewport.
function INV.SyncArmorDoll(rawJSON)
    if not IsValid(INV.UI) then return end
    local payload = util.JSONToTable(tostring(rawJSON or ""))
    if not istable(payload) then return end

    local x, y = tonumber(payload.x), tonumber(payload.y)
    local w, h = tonumber(payload.w), tonumber(payload.h)
    if not x or not y or not w or not h or w < 24 or h < 24 then
        if IsValid(doll) then doll:SetVisible(false) end
        return
    end

    local panel = ensureDoll()
    if not IsValid(panel) then return end

    local vw = math.max(1, tonumber(payload.viewportW) or INV.UI:GetWide())
    local vh = math.max(1, tonumber(payload.viewportH) or INV.UI:GetTall())
    local sx, sy = INV.UI:GetWide() / vw, INV.UI:GetTall() / vh

    panel:SetPos(math.floor(x * sx + 0.5), math.floor(y * sy + 0.5))
    panel:SetSize(math.max(24, math.floor(w * sx + 0.5)), math.max(24, math.floor(h * sy + 0.5)))
    refreshDollModel(panel)
    local pw, ph = panel:GetSize()
    if panel.GRNFitSize ~= (pw .. "x" .. ph) then fitDoll(panel) end
    panel:SetVisible(true)
end

hook.Add("Think", "GRNInventory_ArmorDollRefresh", function()
    if not IsValid(doll) or not doll:IsVisible() then return end
    if (doll.GRNNextRefresh or 0) > RealTime() then return end
    doll.GRNNextRefresh = RealTime() + 0.5
    refreshDollModel(doll)
end)
