--[[
_______   ___   ________   ___        ________   ________       ___    ___ 
|\   __  \ |\  \ |\   __  \ |\  \      |\   __  \ |\   ____\     |\  \  /  /|
\ \  \|\ /_\ \  \\ \  \|\  \\ \  \     \ \  \|\  \\ \  \___|     \ \  \/  / /
 \ \   __  \\ \  \\ \  \\\  \\ \  \     \ \  \\\  \\ \  \  ___    \ \    / / 
  \ \  \|\  \\ \  \\ \  \\\  \\ \  \____ \ \  \\\  \\ \  \|\  \    \/  /  /  
   \ \_______\\ \__\\ \_______\\ \_______\\ \_______\\ \_______\ __/  / /    
 ___\|_______|_\|__| \|_______| \|_______| \|_______| \|_______||\___/ /     
|\   __  \ |\   __  \     |\  \  /  /|                          \|___|/      
\ \  \|\ /_\ \  \|\  \    \ \  \/  / /                                       
 \ \   __  \\ \  \\\  \    \ \    / /                                        
  \ \  \|\  \\ \  \\\  \    \/  /  /                                         
   \ \_______\\ \_______\ __/  / /                                           
    \|_______| \|_______||\___/ /                                            
                         \|___|/                                             
    Created by Biology Boy: https://steamcommunity.com/id/ninguemph/ 
    Purchased content: https://discord.gg/UDXKJjdrkT
]]--
AddCSLuaFile()
DEFINE_BASECLASS("base_anim")

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Advanced Dropship"
ENT.Spawnable = false
ENT.AdminSpawnable = false

function ENT:Initialize()
    if not self.SpawnerData then return end

    self:SetModel(self:GetModel())
    self:PhysicsInit(self.SpawnerData.Collision and SOLID_VPHYSICS or SOLID_NONE)
    self:SetMoveType(MOVETYPE_FLY)
    self:SetSolid(self.SpawnerData.Collision and SOLID_VPHYSICS or SOLID_NONE)

    if self.SpawnerData.HasHealth then
        self:SetHealth(self.SpawnerData.MaxHealth or 1000)
    end

    if self.SpawnerData.Sounds.Arrival ~= "" then
        self:EmitSound(self.SpawnerData.Sounds.Arrival)
    end

    self.landed = false
    self.departed = false
    self.waveStartTime = CurTime()
    self.SpawnedNPCs = {}
    self.TotalNPCsSpawned = 0
    self.HoverSoundLoop = nil
    self:NextThink(CurTime())
end

function ENT:IsAlive(ent)
    return IsValid(ent) and (not ent:IsNPC() or ent:Health() > 0)
end

function ENT:Think()
    if not self.TargetLandingPos then return end

    local pos = self:GetPos()
    local target = self.TargetLandingPos
    local speed = self.SpawnerData.Speed or 300
    local direction = (target - pos):GetNormalized()

    if not self.landed then
        self:SetPos(LerpVector(FrameTime() * 2, pos, pos + direction * speed))

        local wave = math.sin((CurTime() - self.waveStartTime) * (self.SpawnerData.FlightWobbleFreq or 4)) * (self.SpawnerData.FlightWobbleAmp or 2)
        local pitch = self.SpawnerData.EntryPitch or -10
        local ang = self:GetAngles()
        self:SetAngles(LerpAngle(FrameTime() * 2, ang, Angle(pitch + wave, ang.y, 0)))
        if (pos:Distance(target) <= 10) then
            self.landed = true
            self:SetPos(target)
            self:BeginLanding()
        end
    else
        self:MaintainHover()
        if self.SpawnerData.Repeat then
            if not self._nextWave or CurTime() >= self._nextWave then
                self._nextWave = CurTime() + (self.SpawnerData.Interval or 1)
                self:WaveCheck()
            end
        end
    end

    self:NextThink(CurTime())
    return true
end

function ENT:BeginLanding()
    local yaw = self:GetAngles().y
    for i = 1, 10 do
        timer.Simple(i * 0.02, function()
            if IsValid(self) then
                self:SetAngles(LerpAngle(i / 10, self:GetAngles(), Angle(0, yaw, 0)))
            end
        end)
    end

    if self.SpawnerData.Sounds.Hover ~= "" then
        self.HoverSoundLoop = CreateSound(self, self.SpawnerData.Sounds.Hover)
        if self.HoverSoundLoop then
            self.HoverSoundLoop:Play()
            self.HoverSoundLoop:SetSoundLevel(75)
        end
    end

    if self.SpawnerData.Repeat then
        self._nextWave = CurTime() + (self.SpawnerData.Interval or 1)
    else
        timer.Simple(self.SpawnerData.Interval or 1, function()
            if IsValid(self) then
                local totalLimit = self.SpawnerData.NPCCount or 50
                local aliveLimit = self.SpawnerData.MaxTotalNPCs or 20
                local toSpawn = math.min(totalLimit, aliveLimit, self.SpawnerData.EntitiesPerWave or 1)
                self:SpawnNPCs(toSpawn)
            end
        end)
    end

    if not self.SpawnerData.Repeat then
        timer.Simple(self.SpawnerData.GroundTime, function()
            if IsValid(self) then self:Depart() end
        end)
    end
end

function ENT:MaintainHover()
    local wave = math.sin((CurTime() - self.waveStartTime) * (self.SpawnerData.GroundWobbleFreq or 2)) * (self.SpawnerData.GroundWobbleAmp or 1)
    local ang = self:GetAngles()
    self:SetAngles(LerpAngle(FrameTime() * 2, ang, Angle(wave, ang.y, 0)))
end

function ENT:WaveCheck()
    local live = 0
    for i = #self.SpawnedNPCs, 1, -1 do
        if not self:IsAlive(self.SpawnedNPCs[i]) then
            table.remove(self.SpawnedNPCs, i)
        else
            live = live + 1
        end
    end

    local totalLimit = self.SpawnerData.NPCCount or 50
    local aliveLimit = self.SpawnerData.MaxTotalNPCs or 20
    local perWave = self.SpawnerData.EntitiesPerWave or 1
    local leftToSpawn = totalLimit - self.TotalNPCsSpawned

    local allowed = math.min(leftToSpawn, perWave, aliveLimit - live)
    if allowed > 0 then
        self:SpawnNPCs(allowed)
    end
end

function ENT:SpawnNPCs(count)
    count = math.floor(count)
    if count <= 0 or not self.SpawnerData or not self.SpawnerData.NPCClass then return end

    local class = self.SpawnerData.NPCClass
    local weapon = self.SpawnerData.Weapon or "weapon_smg1"
    local aligned = self.SpawnerData.Aligned
    local shipForward = self:GetForward()
    local shipRight = self:GetRight()
    local spawn_center_pos = self.TargetLandingPos or self:GetPos()

    if aligned then
        local spacing = 90
        local row_spacing = 90
        local max_npcs_per_row = 10
        
        local num_rows = math.ceil(count / max_npcs_per_row)
        if num_rows == 0 then return end
        local row_distribution = {}
        local base_npcs_per_row = math.floor(count / num_rows)
        local remainder = count % num_rows

        for i = 1, num_rows do
            local npcs_in_this_row = base_npcs_per_row
            if i <= remainder then
                npcs_in_this_row = npcs_in_this_row + 1
            end
            table.insert(row_distribution, npcs_in_this_row)
        end
        
        local total_depth = (num_rows - 1) * row_spacing
        local start_offset_y = -total_depth / 2

        for r = 1, num_rows do
            local npcs_in_this_row = row_distribution[r]
            if npcs_in_this_row == 0 then continue end
            
            local row_width = (npcs_in_this_row - 1) * spacing
            local start_offset_x = -row_width / 2

            for c = 1, npcs_in_this_row do
                local offsetX = start_offset_x + (c - 1) * spacing
                local offsetY = start_offset_y + (r - 1) * row_spacing
                local horizontal_offset = (shipRight * offsetX) - (shipForward * offsetY)
                local target_xy_pos = spawn_center_pos + horizontal_offset
                local trace_start = Vector(target_xy_pos.x, target_xy_pos.y, spawn_center_pos.z + 200)
                local trace_end = Vector(target_xy_pos.x, target_xy_pos.y, spawn_center_pos.z - 10000)
                
                local ground_trace = util.TraceLine({
                    start = trace_start,
                    endpos = trace_end,
                    mask = MASK_SOLID,
                    filter = self
                })

                if ground_trace.Hit then
                    local final_pos = ground_trace.HitPos + ground_trace.HitNormal * 5
                    self:SpawnNPC(class, final_pos, self:GetAngles(), weapon)
                end
            end
        end

    else
        for i = 1, count do
            local a = math.rad(math.random(0, 360))
            local r = math.random(100, 200)
            local target_xy_pos = spawn_center_pos + Vector(math.cos(a), math.sin(a), 0) * r
            local trace_start = Vector(target_xy_pos.x, target_xy_pos.y, spawn_center_pos.z + 200)
            local trace_end = Vector(target_xy_pos.x, target_xy_pos.y, spawn_center_pos.z - 10000)
            local ground_trace = util.TraceLine({
                start = trace_start, 
                endpos = trace_end, 
                mask = MASK_SOLID,
                filter = self
            })

            if ground_trace.Hit then
                local final_pos = ground_trace.HitPos + ground_trace.HitNormal * 5
                self:SpawnNPC(class, final_pos, self:GetAngles(), weapon)
            end
        end
    end
end

function ENT:SpawnNPC(class, pos, ang, weapon)

    local ent = ents.Create(class)
    if not IsValid(ent) then return end

    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()

    if ent:IsNPC() then
        if weapon then
            ent:SetKeyValue("additionalequipment", weapon)
            ent:Give(weapon)
        end
    end

    if self.SpawnerData.SpawnEffect and self.SpawnerData.SpawnEffect ~= "" then
        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetScale(1)
        util.Effect(self.SpawnerData.SpawnEffect, ed)
    end

    if self.SpawnerData.SpawnSound and self.SpawnerData.SpawnSound ~= "" then
        ent:EmitSound(self.SpawnerData.SpawnSound, 120, 120, 1, CHAN_AUTO)
    end

    table.insert(self.SpawnedNPCs, ent)
    self.TotalNPCsSpawned = self.TotalNPCsSpawned + 1
end


function ENT:SpawnEntity(class, pos, ang)
  
    if not scripted_ents.GetList()[class] then
        print("Erro: Classe de entidade inválida ou não registrada -", class)
        return
    end

    local ent = ents.Create(class)
    if not IsValid(ent) then return end

    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()

    if self.SpawnerData.SpawnEffect and self.SpawnerData.SpawnEffect ~= "" then
        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetScale(1)
        util.Effect(self.SpawnerData.SpawnEffect, ed)
    end

    if self.SpawnerData.SpawnSound and self.SpawnerData.SpawnSound ~= "" then
        ent:EmitSound(self.SpawnerData.SpawnSound, 120, 120, 1, CHAN_AUTO)
    end

    table.insert(self.SpawnedEntities, ent)
    self.TotalEntitiesSpawned = self.TotalEntitiesSpawned + 1
end


function ENT:Depart()
    if self.departed then return end
    self.departed = true
    self:StopAllSounds()

    if self.SpawnerData.Sounds.Departure ~= "" then
        self:EmitSound(self.SpawnerData.Sounds.Departure)
    end

    local forward = self:GetForward()
    local start = self:GetPos()
    local endPos = start + forward * 2000 + Vector(0, 0, self.SpawnerData.ExitHeight or 300)
    local speed = self.SpawnerData.ExitSpeed or 600
    local dur = 2000 / speed
    local steps = math.ceil(dur / 0.05)
    local startAng = self:GetAngles()
    local targetPitch = self.SpawnerData.ExitPitch or 15

    for i = 1, steps do
        timer.Simple(i * 0.05, function()
            if not IsValid(self) then return end
            self:SetPos(LerpVector(i / steps, start, endPos))
            local wave = math.sin(CurTime() * (self.SpawnerData.FlightWobbleFreq or 4) + i) * (self.SpawnerData.FlightWobbleAmp or 2)
            self:SetAngles(LerpAngle(i / steps, startAng, Angle(targetPitch + wave, startAng.y, 0)))
        end)
    end

    timer.Simple(dur + 0.5, function()
        if IsValid(self) then self:Remove() end
    end)
end

function ENT:OnTakeDamage(dmg)
    if not self.SpawnerData.HasHealth then return end
    local newHealth = self:Health() - dmg:GetDamage()
    self:SetHealth(newHealth)

    if not self._isBurning and newHealth <= (self.SpawnerData.MaxHealth or 1000) * 0.4 then
        self._isBurning = true

        self:Ignite(9999, 0)
        self:EmitSound("ambient/fire/ignite.wav", 75, 100)
        self:SetColor(Color(173, 173, 173, 183))
    end

    if newHealth <= 0 then
        self:Explode()
    end
end

function ENT:Explode()
    self:StopAllSounds()

    local attacker = self
    local effectdata = EffectData()
    effectdata:SetOrigin(self:GetPos())
    util.Effect("vanilla_ship_explosion", effectdata)

    if SERVER then
        local wreck = ents.Create("prop_physics")
        wreck:SetModel(self:GetModel())
        wreck:SetPos(self:GetPos())
        wreck:SetAngles(self:GetAngles())
        wreck:Spawn()
        wreck:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        wreck:SetColor(Color(82, 82, 82, 183))
        wreck:SetMaterial("models/props_wasteland/rockcliff01b")
        wreck:SetVelocity(self:GetVelocity() + VectorRand() * 100)
        wreck:Ignite(10, 20)
        wreck:EmitSound("vanilla/vanilla_final_explosion.wav", 90, 100, 1)
        wreck:AddCallback("PhysicsCollide", function(ent, data)
            if ent._hasExploded then return end
            ent._hasExploded = true

            local ed = EffectData()
            ed:SetOrigin(ent:GetPos())
            util.Effect("Explosion", ed)

            util.BlastDamage(ent, IsValid(attacker) and attacker or ent, ent:GetPos(), 300, 200)
            ent:EmitSound("BaseExplosionEffect.Sound")
            ent:Remove()
        end)

        timer.Simple(20, function()
            if IsValid(wreck) then wreck:Remove() end
        end)
    end
    timer.Simple(0, function()
        if IsValid(self) then self:Remove() end
    end)
end


function ENT:StopAllSounds()
    if self.HoverSoundLoop then
        self.HoverSoundLoop:Stop()
        self.HoverSoundLoop = nil
    end
end

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "Model")
end

duplicator.RegisterEntityClass("adv_dropship", function(ply, data)
    local ent = ents.Create("adv_dropship")
    if not IsValid(ent) then return end
    ent:SetPos(data.Pos)
    ent:SetAngles(data.Angle)
    ent:SetModel(data.Model)
    ent.SpawnerData = data.SpawnerData or {}
    ent.SpawnerData.Owner = ply
    ent.TargetLandingPos = data.Pos
    ent:Spawn()
    ent:Activate()
    return ent
end, {"Pos", "Angle", "Model", "SpawnerData"})

hook.Add("OnUndo", "AdvDropship_Undo", function(name, tbl)
    if name == "Advanced Dropship" and tbl and IsValid(tbl[1]) and tbl[1]:GetClass() == "adv_dropship" then
        tbl[1]:StopAllSounds()
        tbl[1]:Remove()
    end
end)
