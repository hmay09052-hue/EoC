AddCSLuaFile('shared.lua')
include('shared.lua')

function ENT:Initialize()
    self:SetModel('models/props_c17/oildrum001a.mdl')
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    self.BombData = {name='Bomb', type='explosive', timer=60, radius=300, damage=500, force=800, visible=true, beep=true, glow=false}
    self.SpawnedAt = CurTime()
    self.Exploded = false
    self.Defused = false
    self.NextUse = 0
end

function ENT:SetBombData(data, owner)
    self.BombData = table.Copy(data or {})
    self.OwnerPly = owner
    if util.IsValidModel(self.BombData.model or '') then
        self:SetModel(self.BombData.model)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then phys:Wake() end
    end
    self:SetNoDraw(not self.BombData.visible)
    self:SetNWString('GRN_BombName', self.BombData.name or 'Bomb')
    self:SetNWString('GRN_BombType', self.BombData.type or 'explosive')
    self:SetNWBool('GRN_BombGlow', self.BombData.glow == true)
    self:SetNWFloat('GRN_BombEndTime', CurTime() + (tonumber(self.BombData.timer) or 60))
    self.SpawnedAt = CurTime()
    self.ArmTime = CurTime() + 1
    if self.BombData.beep then
        timer.Create('grn_bombs_beep_' .. self:EntIndex(), 1, 0, function()
            if not IsValid(self) or self.Exploded or self.Defused then return end
            self:EmitSound(GRN_Bombs.Config.BeepSound, 65, 100)
        end)
    end
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self.Exploded or self.Defused then return end
    if self.NextUse > CurTime() then return end
    self.NextUse = CurTime() + 0.5

    local data = self.BombData or {}
    if data.reqWeapon and data.weaponClass ~= '' then
        local wep = activator:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= data.weaponClass then
            GRN_Bombs.Notify(activator, 'need_weapon', data.weaponMsg ~= '' and data.weaponMsg or data.weaponClass)
            return
        end
    end

    GRN_Bombs.OpenMinigame(activator, self, data)
end

function ENT:ReceiveMinigameResult(ply, success)
    if self.Exploded or self.Defused then return end
    if success then
        self.Defused = true
        timer.Remove('grn_bombs_beep_' .. self:EntIndex())
        if (self.BombData.rewardMoney or false) and tonumber(self.BombData.moneyAmt or 0) > 0 then
            local amt = math.floor(self.BombData.moneyAmt)
            if DarkRP and ply.addMoney then
                ply:addMoney(amt)
            end
            GRN_Bombs.Notify(ply, 'reward', string.Comma(amt))
        else
            GRN_Bombs.Notify(ply, 'defused')
        end
        local fx = EffectData()
        fx:SetOrigin(self:GetPos())
        util.Effect('cball_explode', fx, true, true)
        SafeRemoveEntityDelayed(self, 0)
    else
        GRN_Bombs.Notify(ply, 'failed')
        self:Explode()
    end
end

function ENT:Think()
    if self.Exploded or self.Defused then return end
    local endTime = self:GetNWFloat('GRN_BombEndTime', 0)
    if endTime > 0 and CurTime() >= endTime then
        self:Explode()
        return
    end
    self:NextThink(CurTime() + 0.25)
    return true
end

local function spawnEffectEntity(class, pos)
    local ent = ents.Create(class)
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:Spawn()
    ent:Fire('StartFire', '', 0)
    ent:Fire('Explode', '', 0)
    ent:Fire('TurnOn', '', 0)
    SafeRemoveEntityDelayed(ent, 2)
end

function ENT:Explode()
    if self.Exploded or self.Defused then return end
    self.Exploded = true
    timer.Remove('grn_bombs_beep_' .. self:EntIndex())

    local pos = self:GetPos()
    local data = self.BombData or {}
    local radius = tonumber(data.radius) or 300
    local damage = tonumber(data.damage) or 500
    local force = tonumber(data.force) or 800

    self:EmitSound(GRN_Bombs.Config.ExplodeSound, 95, 100)

    if data.type == 'gas' then
        for _, ent in ipairs(ents.FindInSphere(pos, GRN_Bombs.Config.GasRadius)) do
            if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) then
                local dmg = DamageInfo()
                dmg:SetDamage(math.max(1, damage * 0.1))
                dmg:SetDamageType(DMG_NERVEGAS)
                dmg:SetAttacker(IsValid(self.OwnerPly) and self.OwnerPly or self)
                dmg:SetInflictor(self)
                ent:TakeDamageInfo(dmg)
            end
        end
        local fx = EffectData()
        fx:SetOrigin(pos)
        util.Effect('HelicopterMegaBomb', fx, true, true)
    else
        util.BlastDamage(self, IsValid(self.OwnerPly) and self.OwnerPly or self, pos, radius, damage)
        local effect = EffectData()
        effect:SetOrigin(pos)
        effect:SetScale(force)
        util.Effect('Explosion', effect, true, true)
    end

    if istable(data.effects) then
        for _, class in ipairs(data.effects) do
            if isstring(class) and class ~= '' then
                spawnEffectEntity(class, pos)
            end
        end
    end

    if isstring(data.particles) and data.particles ~= '' and data.particles ~= 'none' then
        local fx = EffectData()
        fx:SetOrigin(pos)
        util.Effect(data.particles, fx, true, true)
    end

    SafeRemoveEntityDelayed(self, 0)
end

function ENT:OnRemove()
    timer.Remove('grn_bombs_beep_' .. self:EntIndex())
end
