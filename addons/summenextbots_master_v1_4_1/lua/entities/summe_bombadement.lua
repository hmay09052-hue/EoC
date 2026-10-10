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

AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = true
ENT.PrintName = "SummeNextbots Bombadement Marker"
ENT.Category = "Other"

function ENT:Draw()
    self:DrawModel()
end

function ENT:Initialize()
    if SERVER then
        self:SetModel( "models/props_borealis/bluebarrel001.mdl" )
        self:PhysicsInit( SOLID_VPHYSICS )     
        self:SetMoveType( MOVETYPE_NONE )    	
        self:SetSolid( SOLID_VPHYSICS )    

        self.flightvector = self:GetForward() * ((110*52.5)/66)

        self.Glow = ents.Create("env_sprite")
        self.Glow:SetKeyValue("model","orangecore2.vmt")
        self.Glow:SetKeyValue("rendercolor","235 52 222")
        self.Glow:SetKeyValue("scale","0.3")
        self.Glow:SetPos(self:GetPos())
        self.Glow:SetParent(self)
        self.Glow:Spawn()
        self.Glow:Activate()

        self:DrawShadow( true )

        self:SpawnMissles()
    else
        self.Emitter = ParticleEmitter(self:GetPos())
    end
    self.Delay = CurTime() + 3
    self.Damage = 40
end

if SERVER then
    function ENT:SpawnMissles()

        for i = 1, 15 do
            local missle = ents.Create("summe_b2missle")
            missle:SetPos(self:GetPos() + Vector(math.random(-700, 700), math.random(-700, 700), math.random(2000, 4500)))
            missle:SetAngles(Angle(90, 0, 0))
            missle:SetOwner(self)
            missle.Speed = 80
            missle:Spawn()
        end
    end
end