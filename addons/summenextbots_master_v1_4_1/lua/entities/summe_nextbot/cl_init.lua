-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
--[[
   _____ _    _ __  __ __  __ ______                   
  / ____| |  | |  \/  |  \/  |  ____|                  
 | (___ | |  | | \  / | \  / | |__                     
  \___ \| |  | | |\/| | |\/| |  __|                    
  ____) | |__| | |  | | |  | | |____                   
 |_____/_\____/|_| _|_|_|__|_|______|___ _______ _____ 
 | \ | |  ____\ \ / /__   __|  _ \ / __ \__   __/ ____|
 |  \| | |__   \ V /   | |  | |_) | |  | | | | | (___  
 | . ` |  __|   > <    | |  |  _ <| |  | | | |  \___ \ 
 | |\  | |____ / . \   | |  | |_) | |__| | | |  ____) |
 |_| \_|______/_/ \_\  |_|  |____/ \____/  |_| |_____/ 
                                                       
    Created by Summe: https://steamcommunity.com/id/DerSumme/ 
    Purchased content: https://discord.gg/k6YdMwj9w2
]]--

include("shared.lua")

local colorRed = Color(150, 0, 0, 230)
local colorGrey = Color(15, 15, 15, 230)
local colorWhite = Color(255,255,255)
local colorPink = Color(237,42,255)
local colorCyan = Color(42,248,2555)
local colorWhite50 = Color(255,255,255,26)

-- FUNCTION
-- This draws the nametag
--
function ENT:DrawNameTag(hpColor, extraPos)
    if not SummeNextbots.Config.ShowNameTags then return end

    local p = self:GetPos()

    local ang = self:GetAngles()
    ang:RotateAroundAxis( ang:Forward(), 90 )
    ang:RotateAroundAxis( ang:Up(), 90 )
    ang.y = LocalPlayer():EyeAngles().y - 90

    local health = self:Health()
    local maxHealth = self:GetMaxHealth()

    local extraPos1 = extraPos or 0

    if LocalPlayer():GetPos():DistToSqr( self:GetPos() ) < 512 * 512 then
        cam.Start3D2D(p + Vector( 0, 0, 60 + extraPos1 ), Angle( 0, ang.y, 90 ), .15)
            local width = draw.SimpleText(self.PrintName, "SummeNB.Title", 0, - 160, colorWhite, TEXT_ALIGN_CENTER)
    
            SY_RoundedBox(5, - width / 2, - 120, width, 8, colorGrey)

            if health > 0 then
                SY_RoundedBox(5, - width / 2, - 120, width * (health / maxHealth), 8, hpColor or colorRed)
            end
        cam.End3D2D()
    end

    if not SummeNextbots.Config.Debug then return end

    cam.Start3D2D(p + Vector( 0, 0, 5), Angle( 0, ang.y, 0 ), 1)
        surface.DrawCircle( 0, 0, self.ShootingRange * 1, Color( 255, 0, 0) )
        surface.DrawCircle( 0, 0, self.LooseRadius * 1, Color( 255, 120, 0 ) )
    cam.End3D2D()

    local enemy = self:GetNWEntity("targetEnemy", false)

    cam.Start3D2D(p + Vector( 0, 0, 120), Angle( 0, ang.y, 90 ), .15)
        draw.DrawText(self, "SummeNB.Debug", 0, 80, colorPink, TEXT_ALIGN_CENTER)
        draw.DrawText(health, "SummeNB.Debug", 0, 120, colorPink, TEXT_ALIGN_CENTER)
        draw.DrawText(enemy, "SummeNB.Debug", 0, 160, colorPink, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    if self:GetHitBoxGroupCount() != nil then
		for group=0, self:GetHitBoxGroupCount() - 1 do
		 	for hitbox=0, self:GetHitBoxCount(group) - 1 do
		 		local pos, ang =  self:GetBonePosition(self:GetHitBoxBone(hitbox, group))
		 		local mins, maxs = self:GetHitBoxBounds(hitbox, group)
				render.DrawWireframeBox(pos, ang, mins, maxs, colorWhite50, false)
			end
		end
		render.DrawWireframeBox(self:GetPos(), Angle(0,0,0), self:OBBMins(), self:OBBMaxs(), colorWhite50, false)
    end

    if not enemy then return end
    render.DrawLine(self:GetPos() + Vector(0, 0, 50), enemy:GetPos() + Vector(0, 0, 50), colorPink)

end

-- FUNCTION
-- Main draw method
--
function ENT:Draw()
    self:DrawModel()
    self:DrawNameTag()
end