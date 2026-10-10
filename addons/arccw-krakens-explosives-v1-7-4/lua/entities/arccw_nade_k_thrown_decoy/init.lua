AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')
function ENT:Initialize()
	self.VJExists = (file.Exists("lua/autorun/vj_base_autorun.lua","GAME") or false)
	if self.VJExists then
		for _, x in ipairs(ents.FindInSphere(self:GetPos(),4000)) do
			if x:IsNPC() && string.find(x:GetClass(),"npc_vj_l4d_com_") && x.Zombie_CanHearPipe == true then
				table.insert(x.VJ_AddCertainEntityAsEnemy,self)
				x:AddEntityRelationship(self,D_HT,99)
				x.MyEnemy = self
				x:SetEnemy(self)
				table.insert(self.Zombies,x)
			end
		end
	end
	if SERVER then
		if BaseClass and BaseClass.Initialize then
			BaseClass.Initialize(self)
		else
			local base = baseclass.Get(self.Base or ENT.Base)
			if base and base.Initialize then
				base.Initialize(self)
			end
		end
		self:SetModel( "models/arccw/kraken/sw/explosives/world/w_grenade_train.mdl" )
		self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
		self:DrawShadow( false )
		util.SpriteTrail(self, 0, Color(255, 200, 100, 150), false, 6, 1, 0.25, 1 / 6, "trails/laser")
	end
	self.particleCreated = false
	timer.Simple(15,function()
		if IsValid(self) then self.active = false self:Explode() self:Remove() end
	end)
	self:Think()
end
function ENT:OnThink()
	if self.VJExists then
		if self.HasShot != false then
			for _,v in ipairs(self.Zombies) do
			if IsValid(v) then
				v:SetLastPosition(self:GetPos())
				v:VJ_TASK_GOTO_LASTPOS()
				end
			end
		end
	else
		return false
	end
end
function ENT:Think()
	ArcCW_Kraken_GrenadeEntitySweep(self)
	if !self.lasttick then self.lasttick = CurTime()-0.1 end
	if self:GetVelocity():Length()<5 then
		self.active = true
		if self.ParticleCreated ~= true then
			local ground = ents.Create( "info_particle_system" )
			ground:SetKeyValue( "effect_name", "weapon_decoy_ground_effect" )
			ground:SetOwner( self )
			ground:SetParent(self)
			ground:Spawn()
			ground:Activate()
			ground:Fire( "start", "", 0 )
			ground:Fire( "kill", "", 15 )
			self.ParticleCreated = true
		end
		if math.random(1,1/(CurTime()-self.lasttick)*2)==1 and IsValid(self.Owner) then
			local bul = {}
			bul.Attacker = self.Owner
			bul.Inflictor = self
			bul.Damage = 0
			bul.Force = 0.1
			bul.Dir = Vector(0,0,-1)
			bul.Tracer = 0
			bul.Spread = vector_origin
			bul.Src = self:GetPos()
			self.Owner:FireBullets(bul,true)
			local fsound = Sound("ArcCW_Kraken.Explosives.Decoy_Random")
			if self.Owner.GetActiveWeapon then
				local wep = self.Owner:GetActiveWeapon()
				if IsValid(wep) and wep.Primary and wep.Primary.Sound then
					fsound = wep.Primary.Sound
				end
			end
			self:EmitSound(fsound)
			local shot = ents.Create( "info_particle_system" )
			shot:SetKeyValue( "effect_name", "weapon_decoy_ground_effect_shot" )
			shot:SetOwner( self )
			shot:SetParent(self)
			shot:Spawn()
			shot:Activate()
			shot:Fire( "start", "", 0 )
			shot:Fire( "kill", "", 0.001 )
			self.HasShot = true
		end
	end
	self:OnThink()
	self.lasttick=CurTime()
	self:NextThink(CurTime())
	return true
end
function ENT:Explode()
if SERVER then
	ArcCW_Kraken_GrenadeExplosionFX(self:GetPos())
	self:EmitSound("ArcCW_Kraken.Explosives.Explosion")
	self:EmitSound("ArcCW_Kraken.Explosives.Explosion_Distant")
	self:EmitSound("ArcCW_Kraken.Explosives.Explosion_FarDist")
end
	util.BlastDamage( self, self.Owner, self:GetPos(), 354, 7 )
	local spos = self:GetPos()
	local trs = util.TraceLine({start=spos + Vector(0,0,64), endpos=spos + Vector(0,0,-32), filter=self})
	util.Decal("Scorch", trs.HitPos + trs.HitNormal, trs.HitPos - trs.HitNormal)
end

function ENT:OnTakeDamage( dmginfo )
end

function ENT:Use( activator, caller, type, value )
end
function ENT:GetThrower()
	return self:GetOwner()
end
function ENT:StartTouch( otherent )
	local VJExists = file.Exists("lua/autorun/vj_base_autorun.lua","GAME")
	if VJExists == true then
		if otherent:IsNPC() && string.find(otherent:GetClass(),"npc_vj_l4d_com_") then
			return false
		end
	end
	self:ResolveFlyCollisionCustom( self:GetTouchTrace() , self:GetVelocity() )
end
function ENT:Touch( otherent )
	local VJExists = file.Exists("lua/autorun/vj_base_autorun.lua","GAME")
	if VJExists == true then
		if otherent:IsNPC() && string.find(otherent:GetClass(),"npc_vj_l4d_com_") then
			return false
		else
			if otherent == self:GetThrower() then
				return
			end
		end
	else
		if otherent == self:GetThrower() then
			return
		end
	end
end
local function PhysicsClipVelocity( inv, normal, out, overbounce )
	local	backoff
	local	change = 0
	local	angle
	local	i
	local STOP_EPSILON = 0.1
	angle = normal.z
	backoff = inv:DotProduct( normal ) * overbounce
	for i = 1 , 3 do
		change = normal[i] * backoff
		out[i] = inv[i] - change
		if out[i] > -STOP_EPSILON and out[i] < STOP_EPSILON then
			out[i] = 0
		end
	end
end
local function PhysicsCheckSweep( pEntity, vecAbsStart, vecAbsDelta, pTrace )
	local mask = MASK_SOLID
	local vecAbsEnd = vecAbsStart + vecAbsDelta
	if not pEntity:IsSolid() then
		if IsValid( pEntity:GetMoveParent() ) then
			pTrace.Fraction = 1
			pTrace.FractionLeftSolid = 0
			return
		end
	end
end
function ENT:PhysicsPushEntity( push, pTrace )
	local prevOrigin = self:GetPos() * 1
	PhysicsCheckSweep( self, prevOrigin, push, pTrace )
	if pTrace.Fraction == 1 then
		self:SetPos( pTrace.HitPos )
	end
end
local function IsStandable( ent )
	return ent:GetSolid() == SOLID_BSP or ent:GetSolid() == SOLID_VPHYSICS or ent:GetSolid() == SOLID_BBOX
end
function ENT:ResolveFlyCollisionCustom( trace , vecVelocity )
	local flSurfaceElasticity = 1
	if IsValid( trace.Entity ) and trace.Entity:IsPlayer() then
		flSurfaceElasticity = 0.3
	end
	local breakthrough = false
	if IsValid( trace.Entity ) and trace.Entity:GetClass() == "func_breakable" then
		breakthrough = true
	end
	if IsValid( trace.Entity ) and trace.Entity:GetClass() == "func_breakable_surf" then
		breakthrough = true
	end
	local flTotalElasticity = self:GetElasticity() * flSurfaceElasticity
	flTotalElasticity = math.Clamp( flTotalElasticity, 0, 0.9 )
	local vecAbsVelocity = Vector()
	PhysicsClipVelocity( vecVelocity, trace.Normal, vecAbsVelocity, 2.0 )
	vecAbsVelocity = vecAbsVelocity * flTotalElasticity
	local flSpeedSqr = vecVelocity:DotProduct( vecVelocity )
	if trace.Normal.z > 0.7 then
		local pEntity = trace.Entity
		self:SetVelocity( vecAbsVelocity )
		if flSpeedSqr < ( 30 * 30 ) then
			if IsStandable( pEntity ) then
				self:SetGroundEntity( pEntity )
			end
			self:SetVelocity( vector_origin )
			self:SetLocalAngularVelocity( angle_zero )
			local angle = trace.Normal:Angle()
			angle[1] = math.random( 0, 360 )
			self:SetAngles( angle )			
		else
			local vecDelta = vecVelocity - vecAbsVelocity	
			local vecBaseDir = vecVelocity
			vecBaseDir:Normalize()
			local flScale = vecDelta:Dot( vecBaseDir )
			local ft = ( 1.0 - trace.Fraction ) * FrameTime()
			vecVelocity = vecAbsVelocity * ft
			vecVelocity = vecVelocity + ( vecDelta * flScale ) * ft
			self:PhysicsPushEntity( vecVelocity, trace )
		end
	else
		if flSpeedSqr < ( 30 * 30 ) then
			self:SetVelocity( vector_origin )
			self:SetLocalAngularVelocity( angle_zero )
		else
			self:SetVelocity( vecAbsVelocity )
		end
	end
end
