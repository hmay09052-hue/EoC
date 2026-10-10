GRNStore = GRNStore or {}
local S = GRNStore
local C = S.Config
local A = C and C.Armory

if not A or not A.Entity then return end

S.ArmoryWorldIconPanel = S.ArmoryWorldIconPanel or nil
S.ArmoryWorldIconMaterial = S.ArmoryWorldIconMaterial or nil

local function ensurePanel()
    if IsValid(S.ArmoryWorldIconPanel) then return S.ArmoryWorldIconPanel end
    local url = tostring(A.Entity.IconURL or "")
    if url == "" then return nil end

    local pnl = vgui.Create("DHTML")
    pnl:SetSize(tonumber(A.Entity.IconWidth) or 180, tonumber(A.Entity.IconHeight) or 180)
    pnl:SetPos(-10000, -10000)
    pnl:SetMouseInputEnabled(false)
    pnl:SetKeyboardInputEnabled(false)
    pnl:SetPaintedManually(true)
    pnl:SetHTML([[<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0;width:100%;height:100%;overflow:hidden;background:transparent}
body{display:flex;align-items:center;justify-content:center}
img{width:100%;height:100%;object-fit:contain;filter:drop-shadow(0 0 15px rgba(252,178,73,.42))}
</style></head><body><img src="]] .. url .. [["></body></html>]])

    S.ArmoryWorldIconPanel = pnl
    return pnl
end

local function iconMaterial()
    local pnl = ensurePanel()
    if not IsValid(pnl) then return nil end
    pnl:UpdateHTMLTexture()
    local mat = pnl:GetHTMLMaterial()
    if mat then S.ArmoryWorldIconMaterial = mat end
    return S.ArmoryWorldIconMaterial
end

function S.DrawArmoryIcon(ent)
    if not IsValid(ent) then return end
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local targetPos = ent:GetPos() + (A.Entity.IconOffset or Vector(0, 0, 72))
    local maxDist = tonumber(A.Entity.IconMaxDistance) or 900
    if ply:EyePos():DistToSqr(targetPos) > maxDist * maxDist then return end

    if (ent.GRNArmoryNextVisibilityCheck or 0) <= CurTime() then
        ent.GRNArmoryNextVisibilityCheck = CurTime() + (tonumber(A.Entity.IconVisibilityCheckInterval) or 0.12)
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = targetPos,
            filter = ply,
            mask = MASK_VISIBLE,
        })
        ent.GRNArmoryIconVisible = not tr.Hit or tr.Entity == ent or tr.HitPos:DistToSqr(targetPos) < 256
    end

    if ent.GRNArmoryIconVisible == false then return end

    local mat = iconMaterial()
    if not mat then return end

    local ang = Angle(0, EyeAngles().y - 90, 90)
    local scale = tonumber(A.Entity.IconScale) or 0.13
    local w = tonumber(A.Entity.IconWidth) or 180
    local h = tonumber(A.Entity.IconHeight) or 180

    cam.Start3D2D(targetPos, ang, scale)
        surface.SetDrawColor(255, 255, 255, 245)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(-w * 0.5, -h * 0.5, w, h)
    cam.End3D2D()
end

hook.Add("ShutDown", "GRNStoreArmory_DestroyWorldIconDHTML", function()
    if IsValid(S.ArmoryWorldIconPanel) then
        S.ArmoryWorldIconPanel:Remove()
    end
end)
