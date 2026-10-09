AddCSLuaFile()
if SERVER then util.AddNetworkString("ARC9_GSR_SONAR_EXPLODE") end

ENT.Type = "anim"
ENT.Base = "arccw_kraken_nade_base"
ENT.PrintName = "Sonar Grenade"
ENT.Spawnable = false
ENT.AdminSpawnable = false
ENT.RenderGroup = RENDERGROUP_BOTH
ENT.CollisionGroup = COLLISION_GROUP_PROJECTILE
ENT.FindRadius = 500
ENT.Model = "models/arccw/kraken/sw/explosives/world/w_impact.mdl"
DEFINE_BASECLASS("arccw_kraken_nade_base")

local glowMat = Material("sprites/light_glow02_add")
local sonarMat = Material("sprites/glow04_noz")

function ENT:Initialize()
	if SERVER then
		BaseClass.Initialize(self)
		self:SetModel(self.Model)
		self:SetCollisionGroup(COLLISION_GROUP_NONE)
		self:DrawShadow(false)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:Wake() end
		util.SpriteTrail(self, 0, Color(100, 255, 150, 150), false, 8, 2, 0.3, 1 / 8, "trails/laser")
	end
	self:EmitSound("kraken/explosives/sonicimploder/active.wav", 125)
end

function ENT:Think()
    ArcCW_Kraken_GrenadeEntitySweep(self)
end
function ENT:Use() return false end
function ENT:OnRemove() return false end
local function EntityFacingFactor(ent1, ent2)
	local dir       = ent2:EyeAngles():Forward()
	local facingdir = (ent1:GetPos() - (ent2.EyePos and ent2:EyePos() or ent2:GetPos())):GetNormalized()
	return (facingdir:Dot(dir) + 1) / 2
end
if SERVER then
	local tr = {}
	function ENT:Detonate()
		if self.Defused then return end
		self.Defused = true
		local origin = self:GetPos()
		
		if IsValid(self.Owner) then
			local _ents = ents.FindInSphere(origin, self.FindRadius)
			local tab, maxEntities = {}, 50
			for _, v in ipairs(_ents) do
				if #tab >= maxEntities then break end
				if (v:IsNPC() or v:IsPlayer() or v:IsNextBot()) and v ~= self.Owner then
					table.insert(tab, v)
				end
			end
			net.Start("ARC9_GSR_SONAR_EXPLODE")
			net.WriteTable(tab)
			net.Send(self.Owner)
		end
		
		tr.start, tr.mask = origin, MASK_SOLID
		for _, v in ipairs(player.GetAll()) do
			tr.endpos = v:EyePos()
			tr.filter = {self, v, v:GetActiveWeapon()}
			local trace = util.TraceLine(tr)
			if not trace.Hit or trace.Fraction >= 1 or trace.Fraction <= 0 then
				v:SetNWFloat("ARC9_GSR_LastFlash", CurTime() - 4)
				v:SetNWFloat("ARC9_GSR_FlashDistance", tr.endpos:Distance(origin))
				v:SetNWFloat("ARC9_GSR_FlashFactor", EntityFacingFactor(self, v) * 0.5)
			end
		end
		
		self:EmitSound("kraken/explosives/sensorgrenade/sensor_explode.wav", 125)
		sound.Play("kraken/explosives/sensorgrenade/sensor_explode.wav", origin, 155, math.random(85, 100), 1)
		
		local explode = ents.Create("info_particle_system")
		explode:SetKeyValue("effect_name", "weapon_sensorgren_detonate")
		explode:SetOwner(self.Owner)
		explode:SetPos(self:GetPos())
		explode:Spawn()
		explode:Activate()
		explode:Fire("start", "", 0)
		explode:Fire("kill", "", 30)
		SafeRemoveEntity(self)
	end
	function ENT:Fuse(ent)
		self.WeldEnt = constraint.Weld(self, ent, 0, 0, 0, true, false)
		self:EmitSound("kraken/explosives/sensorgrenade/sensor_arm.wav", 125)
		timer.Simple(3, function()
			if IsValid(self) then
				self:StopParticles()
				self:Detonate()
			end
		end)
	end
	
	local function orient_angles(obj, data)
		local n = data.HitNormal
		local offset = Vector(0, 0, 0)
		if math.abs(n.z) > 0.5 then
			offset = n.z > 0 and Vector(-90, 0, 0) or Vector(0, 90, 0)
		else
			offset = Vector(0, 0, 90)
		end
		obj:SetAngles((n + offset):Angle())
	end
	
	function ENT:PhysicsCollide(data, physObj)
		if self:GetNWBool("Fused") then return end
		if not data.HitEntity or data.HitEntity:IsNPC() or data.HitEntity:IsPlayer() or data.HitEntity:IsNextBot() then return end
		
		self:SetNWBool("Fused", true)
		timer.Simple(0, function()
			if not IsValid(self) then return end
			self:EmitSound("kraken/explosives/sensorgrenade/sensor_land.wav", 125)
			self:Fuse(data.HitEntity)
		end)
		orient_angles(physObj, data)
	end
end
if CLIENT then
	local tr, col = {}, Color(255, 25, 25)
	local glow = Material("csgo/sprites/flare_sprite_02")
	function ENT:Draw()
		self:DrawModel()
		local pos = self:GetPos()
		local isFused = self:GetNWBool("Fused", false)
		local pulse = isFused and (0.5 + math.sin(CurTime() * 15) * 0.5) or (0.7 + math.sin(CurTime() * 8) * 0.3)
		local glowSize = isFused and (20 * pulse) or (15 * pulse)
		
		render.SetMaterial(glowMat)
		render.DrawSprite(pos, glowSize, glowSize, Color(100, 255, 150, 180 * pulse))
		
		render.SetMaterial(sonarMat)
		render.DrawSprite(pos, glowSize * 0.6, glowSize * 0.6, Color(150, 255, 180, 200))
		
		local dlight = DynamicLight(self:EntIndex())
		if dlight then
			dlight.pos = pos
			dlight.r = 100
			dlight.g = 255
			dlight.b = 150
			dlight.brightness = isFused and (3 * pulse) or (2 * pulse)
			dlight.decay = 1000
			dlight.size = isFused and 120 or 100
			dlight.dietime = CurTime() + 0.1
		end
	end
	local ARC9_HaloManager = {}
	ARC9_HaloManager.EVENT_NAME = "ARC9_GSR_SONAR"
	local function ARC9_GSR_SONAR_CREATE_HALOS(len, ply)
		local _ents = net.ReadTable()
		timer.Simple(0.5, function()
			if istable(_ents) then
				for k, v in pairs(_ents) do
					if IsValid(v) then
						ARC9_HaloManager:Add(v, 3)
					end
				end
			end
		end)
	end
	local function GetEntityAABB(ent)
		local mins = ent:OBBMins()
		local maxs = ent:OBBMaxs()
		local pos = {
			ent:LocalToWorld(Vector(maxs.x, maxs.y, maxs.z)):ToScreen(),
			ent:LocalToWorld(Vector(maxs.x, mins.y, maxs.z)):ToScreen(),
			ent:LocalToWorld(Vector(maxs.x, maxs.y, mins.z)):ToScreen(),
			ent:LocalToWorld(Vector(maxs.x, mins.y, mins.z)):ToScreen(),
			ent:LocalToWorld(Vector(mins.x, maxs.y, maxs.z)):ToScreen(),
			ent:LocalToWorld(Vector(mins.x, mins.y, maxs.z)):ToScreen(),
			ent:LocalToWorld(Vector(mins.x, maxs.y, mins.z)):ToScreen(),
			ent:LocalToWorld(Vector(mins.x, mins.y, mins.z)):ToScreen()
		}
		local minX = pos[1].x
		local minY = pos[1].y
		local maxX = pos[1].x
		local maxY = pos[1].y
		for k = 2, 8 do
			if pos[k].x > maxX then
				maxX = pos[k].x
			end
			if pos[k].y > maxY then
				maxY = pos[k].y
			end
			if pos[k].x < minX then
				minX = pos[k].x
			end
			if pos[k].y < minY then
				minY = pos[k].y
			end
		end
		return Vector(minX, minY), Vector(maxX, maxY)
	end
	net.Receive("ARC9_GSR_SONAR_EXPLODE", ARC9_GSR_SONAR_CREATE_HALOS)
	function ARC9_HaloManager:Add(ent, t)
		table.insert(self, {ent = ent, t = CurTime() + t})
		self:Enable()
	end
	local _ents = {}
	local halo_color = Color(255, 0, 0)
	function ARC9_HaloManager:Enable()
		local events = hook.GetTable()
		local tab = events["PreDrawHalos"]
		if tab and not tab[self.EVENT_NAME] or not tab then
			hook.Add("PreDrawHalos", self.EVENT_NAME, function()
				self:DrawHalo()
			end)
		end
		local tab = events["PostDrawOpaqueRenderables"]
		if tab and not tab[self.EVENT_NAME] or not tab then
			hook.Add("PostDrawOpaqueRenderables", self.EVENT_NAME, function()
				self:Draw()
			end)
		end
	end
	function ARC9_HaloManager:Disable()
		hook.Remove("PreDrawHalos", self.EVENT_NAME)
		hook.Remove("PostDrawOpaqueRenderables", self.EVENT_NAME)
	end
	local mat1 = Material("models/debug/debugwhite")
	function ARC9_HaloManager:Draw()
		for k, v in ipairs(self) do
			if not IsValid(v.ent) then self[k] = nil continue end
			render.ClearStencil()
			render.SetStencilEnable(true)
			render.SetStencilWriteMask(255)
			render.SetStencilTestMask(255)
			render.SetStencilReferenceValue(1)
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
			render.SetStencilFailOperation(STENCILOPERATION_KEEP)
			render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
			render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
			v.ent:DrawModel()
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
			local mins, maxs = GetEntityAABB(v.ent)
			cam.Start2D()
				local health    = v.ent:Health()
				local maxHealth = v.ent:GetMaxHealth()
				local mul = math.Clamp(health / maxHealth, 0, 1)
				local x = mins.x
				local y = mins.y + (maxs.y - mins.y) * mul
				local w = maxs.x - x
				local h = maxs.y - y
				surface.SetDrawColor(255, 0, 0, 32)
				surface.DrawRect(x, y, w, h)
			cam.End2D()
			render.SetStencilEnable(false)
		end
	end
	function ARC9_HaloManager:DrawHalo()
		local CT = CurTime()
		for i = 1, #_ents do
			_ents[i] = nil
		end
		for k, v in ipairs(self) do
			if (not IsValid(v.ent) or v.ent:Health() <= 0) or v.t <= CT then
				table.remove(self, k)
			else
				table.insert(_ents, v.ent)
			end
		end
		halo.Add(_ents, halo_color, 2, 2, 2, true, true )
		if #self <= 0 then
			self:Disable()
		end
	end
end