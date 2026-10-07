GRNStore = GRNStore or {}
local S = GRNStore
local C = S.Config

S.WorldIconPanel = S.WorldIconPanel or nil
S.WorldIconMaterial = S.WorldIconMaterial or nil

local function ensureIconPanel()
    if IsValid(S.WorldIconPanel) then return S.WorldIconPanel end
    if not C or not C.Entity or not C.Entity.IconURL or C.Entity.IconURL == "" then return nil end

    local pnl = vgui.Create("DHTML")
    pnl:SetSize(C.Entity.IconWidth or 180, C.Entity.IconHeight or 180)
    pnl:SetPos(-10000, -10000)
    pnl:SetMouseInputEnabled(false)
    pnl:SetKeyboardInputEnabled(false)
    pnl:SetPaintedManually(true)
    pnl:SetHTML([[<!doctype html><html><head><meta charset="utf-8"><style>
        html,body{margin:0;width:100%;height:100%;overflow:hidden;background:transparent}
        body{display:flex;align-items:center;justify-content:center}
        img{width:100%;height:100%;object-fit:contain;filter:drop-shadow(0 0 14px rgba(70,205,240,.5))}
    </style></head><body><img src="]] .. C.Entity.IconURL .. [["></body></html>]])

    S.WorldIconPanel = pnl
    return pnl
end

local function updateIconMaterial()
    local pnl = ensureIconPanel()
    if not IsValid(pnl) then return nil end

    pnl:UpdateHTMLTexture()
    local mat = pnl:GetHTMLMaterial()
    if mat then S.WorldIconMaterial = mat end
    return S.WorldIconMaterial
end

function S.DrawVendorIcon(ent)
    if not C or not C.Entity then return end
    if not IsValid(ent) then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local targetPos = ent:GetPos() + (C.Entity.IconOffset or Vector(0, 0, 88))
    local maxDist = tonumber(C.Entity.IconMaxDistance) or 900
    if ply:EyePos():DistToSqr(targetPos) > maxDist * maxDist then return end

    if (ent.GRNStoreNextVisibilityCheck or 0) <= CurTime() then
        ent.GRNStoreNextVisibilityCheck = CurTime() + (C.Entity.IconVisibilityCheckInterval or 0.12)

        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = targetPos,
            filter = ply,
            mask = MASK_VISIBLE,
        })

        ent.GRNStoreIconVisible = not tr.Hit or tr.Entity == ent or tr.HitPos:DistToSqr(targetPos) < 256
    end

    if ent.GRNStoreIconVisible == false then return end

    local mat = updateIconMaterial()
    if not mat then return end

    local ang = Angle(0, EyeAngles().y - 90, 90)
    local scale = tonumber(C.Entity.IconScale) or 0.13
    local w = C.Entity.IconWidth or 180
    local h = C.Entity.IconHeight or 180

    cam.Start3D2D(targetPos, ang, scale)
        surface.SetDrawColor(255, 255, 255, 245)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(-w * 0.5, -h * 0.5, w, h)
    cam.End3D2D()
end

hook.Add("ShutDown", "GRNStore_DestroyWorldIconDHTML", function()
    if IsValid(S.WorldIconPanel) then
        S.WorldIconPanel:Remove()
    end
end)
