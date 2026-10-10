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

include('shared.lua')

local colorRed = Color(0, 127, 150, 230)
local colorGrey = Color(15, 15, 15, 230)
local colorWhite = Color(255,255,255)

function ENT:Draw()
    self:DrawModel()

    local p = self:GetPos()

    local ang = self:GetAngles()
    ang:RotateAroundAxis( ang:Forward(), 90 )
    ang:RotateAroundAxis( ang:Up(), 90 )
    ang.y = LocalPlayer():EyeAngles().y - 90

    local health = self:Health()
    local maxHealth = self:GetMaxHealth()
    local height = 0
    local model = self:GetModel()
    if model == "models/props/starwars/vehicles/sbd_dispenser.mdl" then
        height = 170
    elseif model == "models/props/starwars/vehicles/droideka_dispenser.mdl" then
        height = 220
    else
        height = 100
    end

    if LocalPlayer():GetPos():DistToSqr( self:GetPos() ) < 512 * 512 then
        cam.Start3D2D(p + Vector( 0, 0, height ), Angle( 0, ang.y, 90 ), .15)
            local width = draw.SimpleText("Droid Dispenser", "SummeNB.Title", 0, - 160, colorWhite, TEXT_ALIGN_CENTER)
    
            SY_RoundedBox(5, - width / 2, - 120, width, 8, colorGrey)

            if health > 0 then
                SY_RoundedBox(5, - width / 2, - 120, width * (health / maxHealth), 8, colorRed)
            end
        cam.End3D2D()
    end
end