--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Namensschild über Spielern
    Zeigt NUR Name (mit RP-ID) und Rang. Die Einheit wird bewusst nicht angezeigt.
-------------------------------------------------------------------------------------------------------------]]

local UI = symchars.ui
local UT = symchars.utils

local function Enabled()
    return symchars.Config("useoverheadhud") ~= false
end

-- DarkRP-Standardanzeige abschalten, solange unser Namensschild aktiv ist.
-- DarkRP lädt nach den Autorun-Dateien, deshalb erst nach dem Gamemode-Start ersetzen.
local function Override()
    local PLAYER = FindMetaTable("Player")
    if PLAYER.symchars_drawOverridden then return end
    local originalDraw = PLAYER.drawPlayerInfo
    PLAYER.drawPlayerInfo = function(self, ...)
        if Enabled() then return end
        if originalDraw then return originalDraw(self, ...) end
    end
    PLAYER.symchars_drawOverridden = true
end
hook.Add("Initialize", "symchars_overhead", Override)
hook.Add("InitPostEntity", "symchars_overhead", Override)
if GAMEMODE then Override() end

local function HeadPos(ply)
    local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
    if bone then
        local pos = ply:GetBonePosition(bone)
        if pos then return pos + Vector(0, 0, 14) end
    end
    return ply:EyePos() + Vector(0, 0, 12)
end

local traceData = { mask = MASK_VISIBLE_AND_NPCS, filter = {} }

hook.Add("PostDrawTranslucentRenderables", "symchars_overhead", function(depth, skybox)
    if skybox or depth or not Enabled() then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local eye = EyePos()
    local maxDist = symchars.Config("overheaddistance") or 220
    local maxSqr = maxDist * maxDist
    local drawAng = Angle(0, EyeAngles().y - 90, 90)

    for _, ply in ipairs(player.GetAll()) do
        if ply ~= lp and ply:Alive() and not ply:GetNoDraw() and ply:GetColor().a > 10 and not ply:InVehicle() then
            local char = ply:GetCharacter()
            local pos = HeadPos(ply)
            local distSqr = eye:DistToSqr(pos)
            if char and distSqr < maxSqr then
                traceData.start = eye
                traceData.endpos = pos
                traceData.filter[1] = lp
                traceData.filter[2] = ply
                local tr = util.TraceLine(traceData)
                if not tr.Hit then
                    local alpha = math.Clamp(1 - (math.sqrt(distSqr) - maxDist * 0.6) / (maxDist * 0.4), 0, 1)
                    local name = UT.BuildDisplayName(char)
                    local rank = symchars.Config("usefactions") and char:GetRankData() or nil

                    cam.Start3D2D(pos, drawAng, 0.065)
                        surface.SetAlphaMultiplier(alpha)
                        local y = 0
                        if rank and rank.icon and rank.icon ~= "" then
                            UI.DrawImage(rank.icon, -40, -96, 80, 80, color_white, "contain")
                        end
                        draw.SimpleTextOutlined(name, "symchars.overhead.name", 0, y, Color(236, 233, 224), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, Color(0, 0, 0, 200))
                        if rank then
                            local rc = rank.color and UI.Readable(rank.color, 130) or UI.Accent()
                            draw.SimpleTextOutlined(string.upper(rank.name), "symchars.overhead.rank", 0, y + 4, rc, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 200))
                        end
                        surface.SetAlphaMultiplier(1)
                    cam.End3D2D()
                end
            end
        end
    end
end)
