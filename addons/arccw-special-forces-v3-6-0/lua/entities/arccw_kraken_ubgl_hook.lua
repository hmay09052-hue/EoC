AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Kraken UBGL Grappling Hook"
ENT.Spawnable = false
ENT.AdminSpawnable = true

ENT.Model = "models/props_c17/TrapPropeller_Lever.mdl"
ENT.HitSound = Sound("physics/metal/metal_barrel_impact_hard7.wav")

local ServerConvarFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE}
if not ConVarExists("kraken_grapple_hookplayers") then
    CreateConVar("kraken_grapple_hookplayers", "1", ServerConvarFlags, "Allows the Grappling Hook to grab players")
    CreateConVar("kraken_grapple_physics",     "1", ServerConvarFlags, "Grappling hook is launched as a projectile")
    CreateConVar("kraken_grapple_speed",       "1000", ServerConvarFlags, "Launch velocity of the grappling hook (Max range for non-physics hooks)")
    CreateConVar("kraken_grapple_breakpower",  "3", ServerConvarFlags, "Strength of each breakout attempt")
    CreateConVar("kraken_grapple_breakregen",  "1", ServerConvarFlags, "Breakout depletion rate")
    CreateConVar("kraken_grapple_ammo",        "-1", ServerConvarFlags, "Number of uses each grappling hook has. -1 is infinite.")
end

function ENT:SetupDataTables()
    self:NetworkVar("Bool",   0, "HasHit")
    self:NetworkVar("Entity", 0, "Wep")
    self:NetworkVar("Entity", 1, "TargetEnt")
    self:NetworkVar("Int",    0, "Dist")
    self:NetworkVar("Int",    1, "Durability")
    self:NetworkVar("Int",    2, "FollowBone")
    self:NetworkVar("Vector", 1, "FollowOffset")
    self:NetworkVar("Angle",  0, "FollowAngle")
    self:NetworkVar("Vector", 0, "ShootDir")
end

function ENT:Initialize()
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    if not cvars.Bool("kraken_grapple_hookplayers") then
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    end

    self:PhysWake()
    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        if SERVER then
            self:SetShootDir(self.Owner:GetAimVector() * cvars.Number("kraken_grapple_speed"))
        end
        phys:SetVelocity(self:GetShootDir())
    end

    self.HookHealth = 100

    hook.Add("AllowPlayerPickup", self, self.AllowPlayerPickup)
    if CLIENT then hook.Add("HUDPaint", self, self.HUDPaint) end

    if SERVER then
        local timerName = tostring(self) .. " Hook Durability Restore"
        timer.Create(timerName, 0.1, 0, function()
            if not IsValid(self) then timer.Destroy(timerName) return end
            self:SetDurability(math.Approach(self:GetDurability(), 0, cvars.Number("kraken_grapple_breakregen")))
        end)
        hook.Add("KeyPress", self, self.PlayerKeyPress)
    end
end

function ENT:Destroyed(NoCooldown)
    if CLIENT then return end

    local ef = EffectData()
    ef:SetStart(self:GetPos())
    ef:SetOrigin(self:GetPos())
    ef:SetScale(1)
    ef:SetRadius(1)
    ef:SetMagnitude(1)
    ef:SetNormal(self:GetRight())

    util.Effect("Sparks", ef, true, true)
    sound.Play(self.HitSound, self:GetPos(), 75, 100)

    if IsValid(self:GetWep()) and self:GetWep().SetCooldown then
        self:GetWep():SetCooldown(NoCooldown and self:GetWep():GetCooldown() + 10 or 100)
    end

    self:Remove()
end

function ENT:OnTakeDamage(DmgInfo)
    self.HookHealth = (self.HookHealth or 0) - DmgInfo:GetDamage()
    if self.HookHealth <= 0 then
        self:Destroyed()
    end
end

function ENT:DoParent(target, obj)
    if IsValid(target) and target ~= self and target ~= self.Owner and (not (target:IsWeapon() and target:GetOwner() == self.Owner)) then
        self:SetParent(target)

        if target:GetClass():sub(1, 5) ~= "func_" then
            for i = 0, target:GetPhysicsObjectCount() - 1 do
                local p = target:GetPhysicsObjectNum(i)
                if p == obj then
                    self:SetFollowBone(target:TranslatePhysBoneToBone(i))
                    local pos, ang = target:GetBonePosition(self:GetFollowBone())
                    if pos and ang then
                        self:SetFollowOffset(self:GetPos() - pos)
                        self:SetFollowAngle(self:GetAngles() - ang)
                    end
                    break
                end
            end
        end

        self:SetTargetEnt(target)
    end
end

local NoHitEnts = {
    ["func_breakable_surf"]    = true,
    ["arccw_kraken_ubgl_hook"] = true,
    ["ent_realistic_hook"]     = true,
}

function ENT:PhysicsCollide(data, phys)
    if self:GetHasHit() then return end

    if IsValid(data.HitEntity) and NoHitEnts[data.HitEntity:GetClass()] then
        self:Destroyed(true)
        return
    end
    if not IsValid(self:GetWep()) and IsValid(self:GetWep().Owner) and self:GetWep().Owner:IsPlayer() then self:Destroyed(true) return end

    local tr = util.TraceLine({start = (data.HitPos - (data.HitNormal * 10)), endpos = (data.HitPos + data.HitNormal * 10), filter = self})
    if tr.HitSky then return end

    timer.Simple(0, function()
        if not IsValid(self) then return end
        if not (IsValid(self:GetWep()) and IsValid(self:GetWep().Owner)) then self:Destroyed(true) return end

        self:SetCollisionGroup(COLLISION_GROUP_WORLD)

        self:SetPos(data.HitPos)
        local ang = data.HitNormal:Angle()
        ang:RotateAroundAxis(ang:Up(), 90)
        self:SetAngles(ang)
        self:SetMoveType(MOVETYPE_NONE)

        self:SetDist(data.HitPos:Distance(self:GetWep().Owner:GetShootPos()))
        self:DoParent(data.HitEntity, data.HitObject)
    end)

    self:SetDist(data.HitPos:Distance(self:GetWep().Owner:GetShootPos()))

    local ef = EffectData()
    ef:SetOrigin(data.HitPos)
    ef:SetNormal(data.HitNormal)
    ef:SetStart(data.HitPos)
    ef:SetMagnitude(2)
    ef:SetScale(1)
    ef:SetRadius(1)

    util.Effect("Sparks", ef, true, true)
    sound.Play(self.HitSound, data.HitPos, 75, 100)

    self:SetHasHit(true)
end

function ENT:Think()
    if SERVER and (not (IsValid(self:GetWep()) and self:GetWep() == self.Owner:GetActiveWeapon())) then self:Remove() return end

    local phys = self:GetPhysicsObject()
    if IsValid(phys) and self:GetHasHit() then
        phys:EnableMotion(false)
        phys:SetPos(self:GetPos())
        phys:SetAngles(self:GetAngles())
    end
end

function ENT:AllowPlayerPickup(ply, ent)
    if ply == self.Owner then return false end
end

local HookCable = Material("cable/physbeam")

local function GetMuzzlePos(wep)
    if not IsValid(wep) then return nil end
    local owner = wep:GetOwner()

    if IsValid(owner) and owner == LocalPlayer() and not hook.Call("ShouldDrawLocalPlayer", GAMEMODE, owner) then
        local vm = owner:GetViewModel()
        if IsValid(vm) then
            local idx = vm:LookupAttachment("muzzle") or vm:LookupAttachment("1") or 1
            local att = vm:GetAttachment(idx or 1)
            if att and att.Pos then return att.Pos end
        end
    end

    local idx = wep:LookupAttachment("muzzle") or wep:LookupAttachment("1") or 1
    local att = wep:GetAttachment(idx or 1)
    if att and att.Pos then return att.Pos end

    if IsValid(owner) then return owner:GetShootPos() end
    return nil
end

function ENT:Draw()
    if IsValid(self:GetTargetEnt()) then
        local bpos, bang = self:GetTargetEnt():GetBonePosition(self:GetFollowBone())
        local npos, nang = self:GetFollowOffset(), self:GetFollowAngle()
        if npos and nang and bpos and bang then
            npos:Rotate(nang)
            nang = nang + bang
            npos = bpos + npos
            self:SetPos(npos)
            self:SetAngles(nang)
        end
    end

    self:DrawModel()

    if not IsValid(self:GetWep()) then return end
    if self.Owner == LocalPlayer() and not hook.Call("ShouldDrawLocalPlayer", GAMEMODE, self.Owner) then return end

    if IsValid(self.Owner) then
        local pos = GetMuzzlePos(self:GetWep()) or self:GetWep():GetPos()
        render.SetMaterial(HookCable)
        render.DrawBeam(self:GetPos(), pos, 2, 0, 1, Color(255, 255, 255, 255))
    end
end

if CLIENT then
    surface.CreateFont("arccw_kraken_grapple_small", {
        font = SYMUI and SYMUI.FontFace("body") or "Roboto",
        size = 17,
        weight = 500,
        antialias = true,
        extended = true,
    })
    surface.CreateFont("arccw_kraken_grapple_label", {
        font = SYMUI and SYMUI.FontFace("body") or "Roboto",
        size = 14,
        weight = 400,
        antialias = true,
        extended = true,
    })
    surface.CreateFont("arccw_kraken_grapple_large", {
        font = SYMUI and SYMUI.FontFace("body") or "Roboto",
        size = 22,
        weight = 600,
        antialias = true,
        extended = true,
    })
end

local HUD_TextCol  = Color(235, 245, 255)
local HUD_DimCol   = Color(170, 195, 220)
local HUD_DangerCol = Color(255, 90, 90)

local function DrawMinimalBar(xpos, ypos, width, charge, col)
    charge = math.Clamp(charge or 0, 0, 100)
    col = col or HUD_DangerCol
    surface.SetDrawColor(255, 255, 255, 22)
    surface.DrawRect(xpos, ypos, width, 2)
    surface.SetDrawColor(col.r, col.g, col.b, 220)
    surface.DrawRect(xpos, ypos, width * (charge / 100), 2)
end

local function ShadowText(txt, font, x, y, col)
    col = col or HUD_TextCol
    draw.DrawText(txt, font, x + 1, y + 1, Color(0, 0, 0, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    draw.DrawText(txt, font, x, y, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end

function ENT:HUDPaint()
    if not (LocalPlayer() == self:GetTargetEnt()) then return end

    local cx = ScrW() / 2
    local hintsY = ScrH() - 87

    ShadowText("YOU HAVE BEEN HOOKED", "arccw_kraken_grapple_label", cx, hintsY - 40, HUD_DangerCol)
    ShadowText("ROPE LENGTH  " .. tostring(self:GetDist()), "arccw_kraken_grapple_label", cx, hintsY - 22, HUD_DimCol)
    DrawMinimalBar(cx - 80, hintsY - 4, 160, self:GetDurability(), HUD_DangerCol)
    ShadowText("E  -  Break free", "arccw_kraken_grapple_small", cx, hintsY + 8)
end

if SERVER then
    function ENT:PlayerKeyPress(ply, key)
        if (ply ~= self:GetTargetEnt() or key ~= IN_USE) then return end

        self:SetDurability(self:GetDurability() + cvars.Number("kraken_grapple_breakpower"))
        if self:GetDurability() >= 100 then self:Destroyed() end
    end
end
