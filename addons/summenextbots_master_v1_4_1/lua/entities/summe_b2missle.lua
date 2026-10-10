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
ENT.PrintName = "SummeNextbots B2 Missle"
ENT.Category = "Other"

function ENT:Draw()
    self:DrawModel()
end

function ENT:Initialize()
    if SERVER then
        self:SetModel( "models/cs574/ammo/reworked_rocket.mdl" )
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
    else
        self.Emitter = ParticleEmitter(self:GetPos())
    end
    self.Delay = CurTime() + 8
    self.Damage = 150
end

function ENT:SetDamage(number)
    self.Damage = number
end

if SERVER then
    function ENT:Think()
            if self.Delay < CurTime() then
                SafeRemoveEntity( self )
            end
        
            Table={} 		
            Table[1]	=self.Owner 	
            Table[2]	=self.Entity 	
        
            local trace = {}
                trace.start = self.Entity:GetPos()
                trace.endpos = self.Entity:GetPos() + self.flightvector
                trace.filter = Table
            local tr = util.TraceLine( trace )
            
            if tr.HitSky then
                SafeRemoveEntity( self )
                return true
            end

            if tr.Hit then
                self:Explode()
            end

            local speed = self.Speed or 66

            self:SetPos(self:GetPos() + self.flightvector)
            self.flightvector = self.flightvector - self.flightvector/((10*39.37)/speed) + self:GetForward()*2 + Vector(math.Rand(-0.3,0.3), math.Rand(-0.3,0.3),math.Rand(-0.1,0.1)) + Vector(0,0,-0.111)
            self:SetAngles(self.flightvector:Angle() + Angle(0,0,0))
        self:NextThink(CurTime())
        return true
    end
end

if CLIENT then
    function ENT:Think()
        local pos = self:GetPos()
			for i = 1, 5 do
				local part = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), pos + (self:GetForward() * 0 * i))

				if part then
					part:SetVelocity((self:GetForward() * -45)+(VectorRand()* 45) )
					part:SetDieTime(math.Rand(1.1, 1.9))
					part:SetStartAlpha(math.Rand( 15, 30))
					part:SetEndAlpha(0)
					part:SetStartSize(math.Rand(15, 15))
					part:SetEndSize(math.Rand(0.01, 0.02))
					part:SetRoll(math.Rand(0, 360))
					part:SetRollDelta(math.Rand(-1, 1))
					part:SetColor(85 , 85 , 85) 
					part:SetAirResistance(200) 
					part:SetGravity(Vector(0, 0, 0)) 	
				end

			end
    end
end

function ENT:Explode()
	local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("HelicopterMegaBomb", effectdata)

    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())			
    effectdata:SetEntity(self)	
    effectdata:SetScale(10)			
    effectdata:SetRadius(100)		
    effectdata:SetMagnitude(6)			
    util.Effect( "HelicopterMegaBomb", effectdata )
    util.ScreenShake(self:GetPos(), 10, 5, 1, 3000 )
    --util.Decal("Scorch", self:GetPos() + tr.HitNormal, self:GetPos() - tr.HitNormal)
    sound.Play( "Explosion.Boom", self:GetPos())
    sound.Play( "ambient/explosions/explode_" .. math.random(1, 4) .. ".wav", self:GetPos(), 100, 80 )

    util.BlastDamage( self, self, self:GetPos(), 350, self.Damage )
    local spos = self:GetPos()
    local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-32), filter=self})
    util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)    

    self.Explo = ents.Create( "env_explosion" )
    self.Explo:SetKeyValue( "spawnflags", 144 )
    self.Explo:SetKeyValue( "iMagnitude", 15 )
    self.Explo:SetKeyValue( "iRadiusOverride", 256 )
    self.Explo:SetPos( self:GetPos() )
    self.Explo:Spawn()
    self.Explo:Fire( "explode", "", 0 )

    self:Remove()
end

function ENT:OnRemove()
end