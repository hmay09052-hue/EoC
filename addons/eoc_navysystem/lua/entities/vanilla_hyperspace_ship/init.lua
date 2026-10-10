AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:Initialize()
	self:SetName("Hyperspace")
	self.OriginalPos = self:GetPos()
	self.JumpDistance = tonumber(self.JumpDistanceValue or 15800) or 15800
	self.JumpStep = tonumber(self.JumpStepValue or 450) or 450
	self.TargetPos = self.OriginalPos

	if self.RetreatValue == 1 then
		local dir = (self.FlipValue == 1) and -1 or 1
		self.TargetPos = self.OriginalPos + self:GetForward() * self.JumpDistance * dir
	else
		local startOffset = -self.JumpDistance
		if self.FlipValue == 1 then
			startOffset = self.JumpDistance
		end
		self:SetPos(self.OriginalPos + self:GetForward() * startOffset)
		self.TargetPos = self.OriginalPos
	end

	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_FLY )
	self:SetSolid(SOLID_NONE)
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
	end

	self.afterjump = false
	self.jump = true
	if self.ShakeValue == 1 then
		util.ScreenShake(self:GetPos(),100000,5,2,100000)
	end

	self.VanillaTimer = tostring(self:EntIndex() .. self:GetName())
	self.StopTimer = self.VanillaTimer .. "Stop"

	timer.Create(self.VanillaTimer, 0, 0, function()
		if not IsValid(self) then return end
		local delta = self.TargetPos - self:GetPos()
		local dist = delta:Length()
		if dist <= self.JumpStep then
			self:SetPos(self.TargetPos)
			self.jump = false
			self.afterjump = true
			self:Remove()
			return
		end
		self:SetPos(self:GetPos() + delta:GetNormalized() * self.JumpStep)
	end)

	timer.Create(self.StopTimer, 0, 0, function()
		if not IsValid(self) then return end
		if self:GetPos():IsEqualTol(self.TargetPos,500) then
			timer.Remove(self.VanillaTimer)
			self.jump = false
			self.afterjump = true
			self:Remove()
		end
	end)
end

function ENT:KeyValue( key, value )
	if ( key == "SpawnModel" ) then
		self.SpawnModelValue = tonumber(value)
	end

	if ( key == "ActualModel" ) then
		self.ActualModelValue = value
		self.SpawnModelPath = value
		if self.SpawnModelValue == 1 then
			if not util.IsValidModel(value) then self:Remove() end
		end
	end

	if ( key == "AI") then
		self.AIValue = tonumber(value)
	end

	if ( key == "Freeze" ) then
		self.FreezeValue = tonumber(value)
	end

	if (key == "Flip" ) then
		self.FlipValue = tonumber(value)
	end

	if (key == "Retreat" ) then
		self.RetreatValue = tonumber(value)
	end

	if (key == "NoSpawnOnRemove" ) then
		self.NoSpawnOnRemoveValue = tonumber(value)
	end

	if (key == "JumpDistance" ) then
		self.JumpDistanceValue = tonumber(value)
	end

	if (key == "JumpStep" ) then
		self.JumpStepValue = tonumber(value)
	end

	if (key == "Shake") then
		self.ShakeValue = tonumber(value)
	end

	if (key == "Owner") then
		self.OwnerValue = value
	end

	if (key == "Sound") then
		self:SetPlaySound(value)
	end

	if ( key == "Entity" ) then
		if self.SpawnModelValue == 0 then
			self.VANILLAENTITY = value
			local stored = scripted_ents.GetStored(self.VANILLAENTITY)
			local sent = stored and stored.t or nil
			local mdl = istable(sent) and (sent.Model or sent.WorldModel or sent.VehicleModel or sent.ShipModel or sent.MDL or sent.mdl) or nil
			if isstring(mdl) and mdl ~= "" then
				self:SetModel(mdl)
			end
		else
			self:SetModel(self.ActualModelValue)
			self.VANILLAENTITY = "vanilla_modelship"
		end
	end
end

function ENT:Think()
end

function ENT:OnRemove()
	local spawnedEnt = nil
	if self.afterjump == true and self.RetreatValue ~= 1 and self.NoSpawnOnRemoveValue ~= 1 then
		local afterjump = ents.Create(self.VANILLAENTITY)
		if IsValid(afterjump) then
			afterjump:SetPos(self:GetPos())
			afterjump:SetAngles(self:GetAngles())
			local resolvedModel = self.ActualModelValue or self:GetModel()
			if self.VANILLAENTITY == "vanilla_modelship" then
				if isstring(resolvedModel) and resolvedModel ~= "" then
					afterjump:SetKeyValue("Model", resolvedModel)
				elseif isstring(self.SpawnModelPath) and self.SpawnModelPath ~= "" then
					afterjump:SetKeyValue("Model", self.SpawnModelPath)
				end
			end
			afterjump:Spawn()
			if (not isstring(resolvedModel) or resolvedModel == "") and IsValid(afterjump) then
				resolvedModel = afterjump:GetModel()
			end
			if self.VANILLAENTITY ~= "vanilla_modelship" and isstring(resolvedModel) and resolvedModel ~= "" and afterjump.SetModel then
				afterjump:SetModel(resolvedModel)
			end
			if self.AIValue == 1 and simfphys and simfphys.LFS and simfphys.LFS.PlanesGetAll then
				for _, v in pairs(simfphys.LFS:PlanesGetAll()) do
					if v == afterjump and afterjump.SetAI then
						afterjump:SetAI(true)
					end
				end
			end
			if self.FreezeValue == 1 then
				afterjump:SetMoveType(MOVETYPE_FLY)
			end
			spawnedEnt = afterjump
			self.GRN_SpawnedEntity = afterjump
			undo.Create( "Ship" )
				undo.AddEntity( afterjump )
				undo.SetPlayer( self:GetOwner() )
				undo.SetCustomUndoText("Undone Ship")
			undo.Finish()
		end
	end
	hook.Run("GRN_Navy_HyperspaceFinished", self, spawnedEnt)
	timer.Remove(self.VanillaTimer)
	timer.Remove(self.StopTimer)
end
