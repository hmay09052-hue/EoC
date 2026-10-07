if SERVER then
    AddCSLuaFile()
end

SWEP.Base = "weapon_base"
SWEP.PrintName = "Inventar-Rucksack"
SWEP.Author = "GRN Inventory / animation assets provided by the user"
SWEP.Purpose = "Internal first-person backpack animation used by grn_inventory."
SWEP.Category = "CloneFall"

SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.ShouldDropOnDie = false

SWEP.ViewModelFOV = 70
SWEP.ViewModel = "models/weapons/ais/stalker2/bpa/v_bpa.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false
SWEP.DrawWeaponInfoBox = false
SWEP.Slot = 5
SWEP.SlotPos = 99

SWEP.SwayScale = 0.15
SWEP.BobScale = 0.75

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

sound.Add({
    name = "Stalker2.BpaClose",
    channel = CHAN_WEAPON,
    volume = 0.23,
    level = 65,
    pitch = {95, 100},
    sound = {
        "weapons/stalker2/bpa/s_inventory_close_01 (sfx).ogg",
        "weapons/stalker2/bpa/s_inventory_close_02 (sfx).ogg",
        "weapons/stalker2/bpa/s_inventory_close_03 (sfx).ogg",
        "weapons/stalker2/bpa/s_inventory_close_04 (sfx).ogg"
    }
})

sound.Add({
    name = "Stalker2.BpaOpen",
    channel = CHAN_WEAPON,
    volume = 0.23,
    level = 65,
    pitch = {95, 100},
    sound = {
        "weapons/stalker2/bpa/s_inventory_open_01 (sfx).ogg",
        "weapons/stalker2/bpa/s_inventory_open_02 (sfx).ogg",
        "weapons/stalker2/bpa/s_inventory_open_03 (sfx).ogg",
        "weapons/stalker2/bpa/s_inventory_open_04 (sfx).ogg"
    }
})

function SWEP:Initialize()
    self:SetHoldType("normal")
    self.GRNIdleAt = 0
    self.GRNClosing = false
end

local function activityDuration(owner, activity, fallback)
    if not IsValid(owner) then return fallback or 1 end
    local vm = owner:GetViewModel()
    if not IsValid(vm) then return fallback or 1 end

    local duration = 0
    local sequence = vm:SelectWeightedSequence(activity)
    if isnumber(sequence) and sequence >= 0 then
        duration = tonumber(vm:SequenceDuration(sequence)) or 0
    end

    if duration <= 0 then
        duration = tonumber(vm:SequenceDuration()) or 0
    end
    if duration <= 0 then duration = fallback or 1 end
    return duration
end

function SWEP:Deploy()
    local owner = self:GetOwner()
    self.GRNClosing = false
    local duration = activityDuration(owner, ACT_VM_PULLBACK, 1.15)
    self:SendWeaponAnim(ACT_VM_PULLBACK)
    self.GRNIdleAt = CurTime() + duration
    return true
end

function SWEP:Think()
    if self.GRNClosing then return end
    if (self.GRNIdleAt or 0) > 0 and CurTime() >= self.GRNIdleAt then
        self.GRNIdleAt = 0
        self:SendWeaponAnim(ACT_VM_IDLE)
    end
end

-- Called by the inventory server controller when the UI closes.
-- Returns the actual close animation duration so the previous weapon can be
-- restored immediately after the viewmodel animation finishes.
function SWEP:GRNInventoryBeginClose()
    if self.GRNClosing then
        return activityDuration(self:GetOwner(), ACT_VM_PULLBACK_HIGH, 1.0)
    end

    self.GRNClosing = true
    local duration = activityDuration(self:GetOwner(), ACT_VM_PULLBACK_HIGH, 1.0)
    self:SendWeaponAnim(ACT_VM_PULLBACK_HIGH)
    return duration
end

function SWEP:PrimaryAttack() end
function SWEP:SecondaryAttack() end

-- ============================================================
-- OPTIONAL CUSTOM BACKPACK VISUAL
-- ============================================================
-- The original v_bpa.mdl remains the animation driver. The replacement is
-- rendered in the viewmodel pass using the animated jnt_backpack matrix.
-- This renderer intentionally does NOT rely on bonemerge: armor props often
-- use a totally different skeleton/origin than the S.T.A.L.K.E.R. viewmodel.
if CLIENT then
    local INVISIBLE_MATERIAL = "engine/occlusionproxy"
    local ZERO_VECTOR = Vector(0, 0, 0)
    local ZERO_ANGLE = Angle(0, 0, 0)

    local function replacementSettings()
        local inv = GRNInventory
        local cfg = inv and inv.Config
        local backpack = cfg and cfg.BackpackAnimation
        local rep = backpack and backpack.Replacement
        if not istable(rep) then return nil end
        return rep
    end

    local function replacementPath(rep)
        local modelPath = string.Trim(tostring(rep and rep.Model or ""))
        if modelPath == "" then return nil end
        return modelPath
    end

    local function modelAvailable(modelPath)
        if not modelPath or modelPath == "" then return false end
        -- file.Exists is useful for addon-mounted models for which
        -- util.IsValidModel can occasionally return false before precache.
        return util.IsValidModel(modelPath) or file.Exists(modelPath, "GAME")
    end

    function SWEP:GRNRestoreDriverMaterial(vm)
        vm = IsValid(vm) and vm or (IsValid(self:GetOwner()) and self:GetOwner():GetViewModel() or nil)
        if IsValid(vm) and self.GRNDriverMaterialHidden then
            vm:SetMaterial(self.GRNDriverOriginalMaterial or "")
        end
        self.GRNDriverMaterialHidden = false
        self.GRNDriverOriginalMaterial = nil
    end

    function SWEP:GRNRemoveReplacementModel()
        if IsValid(self.GRNReplacementModel) then
            self.GRNReplacementModel:Remove()
        end
        self.GRNReplacementModel = nil
        self.GRNReplacementPath = nil
        self.GRNReplacementBoundsCenter = nil
    end

    function SWEP:GRNEnsureReplacementModel(vm)
        local rep = replacementSettings()
        if not rep or rep.Enabled == false then
            self:GRNRemoveReplacementModel()
            self:GRNRestoreDriverMaterial(vm)
            return nil
        end

        local modelPath = replacementPath(rep)
        if not modelAvailable(modelPath) then
            self:GRNRemoveReplacementModel()
            self:GRNRestoreDriverMaterial(vm)

            if not self.GRNReplacementMissingWarned then
                self.GRNReplacementMissingWarned = true
                print("[grn_inventory] The custom backpack model is unavailable on this client: " .. tostring(modelPath))
                print("[grn_inventory] Make sure the addon containing that model is mounted/downloaded by the client.")
            end
            return nil
        end

        self.GRNReplacementMissingWarned = false

        if IsValid(self.GRNReplacementModel) and self.GRNReplacementPath == modelPath then
            return self.GRNReplacementModel, rep
        end

        self:GRNRemoveReplacementModel()

        local group = RENDERGROUP_VIEWMODEL or RENDERGROUP_OPAQUE
        local ent = ClientsideModel(modelPath, group)
        if not IsValid(ent) then
            if not self.GRNReplacementCreateWarned then
                self.GRNReplacementCreateWarned = true
                print("[grn_inventory] Could not create the custom backpack model: " .. tostring(modelPath))
            end
            self:GRNRestoreDriverMaterial(vm)
            return nil
        end

        ent:SetNoDraw(true)
        ent:SetSkin(math.max(0, math.floor(tonumber(rep.Skin) or 0)))

        local mins, maxs = ent:GetModelBounds()
        if mins and maxs then
            self.GRNReplacementBoundsCenter = (mins + maxs) * 0.5
        else
            self.GRNReplacementBoundsCenter = ZERO_VECTOR
        end

        self.GRNReplacementModel = ent
        self.GRNReplacementPath = modelPath
        self.GRNReplacementCreateWarned = false
        return ent, rep
    end

    local function localOffset(pos, ang, offset)
        offset = offset or ZERO_VECTOR
        return pos
            + ang:Forward() * (tonumber(offset.x) or 0)
            + ang:Right() * (tonumber(offset.y) or 0)
            + ang:Up() * (tonumber(offset.z) or 0)
    end

    local function rotatedLocalVector(ang, vec)
        return ang:Forward() * (tonumber(vec.x) or 0)
            + ang:Right() * (tonumber(vec.y) or 0)
            + ang:Up() * (tonumber(vec.z) or 0)
    end

    -- Hide only after the replacement model has actually been created. If the
    -- custom model is missing, the stock backpack stays visible instead of the
    -- player seeing nothing.
    function SWEP:PreDrawViewModel(vm)
        local ent, rep = self:GRNEnsureReplacementModel(vm)
        if not IsValid(ent) or not rep then return end

        if rep.HideOriginal ~= false then
            if not self.GRNDriverMaterialHidden then
                self.GRNDriverOriginalMaterial = vm:GetMaterial() or ""
                self.GRNDriverMaterialHidden = true
            end

            if vm:GetMaterial() ~= INVISIBLE_MATERIAL then
                vm:SetMaterial(INVISIBLE_MATERIAL)
            end
        else
            self:GRNRestoreDriverMaterial(vm)
        end
    end

    function SWEP:GRNDrawReplacement(vm)
        -- PostDrawViewModel and ViewModelDrawn can both fire depending on the
        -- base/gamemode. Draw exactly once per rendered frame.
        if self.GRNReplacementDrawFrame == FrameNumber() then return end

        local ent, rep = self:GRNEnsureReplacementModel(vm)
        if not IsValid(ent) or not rep or not IsValid(vm) then return end

        vm:SetupBones()

        local boneName = tostring(rep.Bone or "jnt_backpack")
        local bone = vm:LookupBone(boneName)
        if not bone then
            if not self.GRNMissingBoneWarned then
                self.GRNMissingBoneWarned = true
                print("[grn_inventory] Backpack animation bone not found: " .. boneName)
            end
            return
        end

        local matrix = vm:GetBoneMatrix(bone)
        if not matrix then return end
        self.GRNMissingBoneWarned = false

        local pos = matrix:GetTranslation()
        local ang = matrix:GetAngles()
        local off = rep.Position or ZERO_VECTOR
        local addAng = rep.Angles or ZERO_ANGLE
        local scale = math.max(0.01, tonumber(rep.Scale) or 1)

        pos = localOffset(pos, ang, off)

        -- User rotation is applied on the backpack bone's local axes.
        ang:RotateAroundAxis(ang:Right(), tonumber(addAng.p) or 0)
        ang:RotateAroundAxis(ang:Up(), tonumber(addAng.y) or 0)
        ang:RotateAroundAxis(ang:Forward(), tonumber(addAng.r) or 0)

        -- Many wearable armor models are authored around the PLAYER origin,
        -- not around the backpack itself. Centering the render bounds on the
        -- animated bone prevents those models from ending up 40-80 units away
        -- and completely outside the first-person camera.
        if rep.AutoCenter ~= false then
            local center = self.GRNReplacementBoundsCenter or ZERO_VECTOR
            local customCenter = rep.CenterOffset or ZERO_VECTOR
            center = Vector(
                (tonumber(center.x) or 0) + (tonumber(customCenter.x) or 0),
                (tonumber(center.y) or 0) + (tonumber(customCenter.y) or 0),
                (tonumber(center.z) or 0) + (tonumber(customCenter.z) or 0)
            )
            pos = pos - rotatedLocalVector(ang, center * scale)
        end

        ent:SetModelScale(scale, 0)
        ent:SetRenderOrigin(pos)
        ent:SetRenderAngles(ang)
        ent:SetupBones()

        -- The hidden animation driver may have already written to the
        -- viewmodel depth buffer. Ignore that depth only for this replacement
        -- draw so it cannot disappear behind an invisible mesh.
        render.SuppressEngineLighting(rep.EngineLighting == false)
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)

        local forceVisible = rep.ForceVisible ~= false
        if forceVisible then cam.IgnoreZ(true) end
        ent:DrawModel()
        if forceVisible then cam.IgnoreZ(false) end

        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        render.SuppressEngineLighting(false)

        ent:SetRenderOrigin()
        ent:SetRenderAngles()

        self.GRNReplacementDrawFrame = FrameNumber()
    end
end

function SWEP:PostDrawViewModel(vm)
    local attachment = IsValid(vm) and vm:GetAttachment(1) or nil
    if attachment then
        self.GRNViewCamera = vm:GetAngles() - attachment.Ang
    else
        self.GRNViewCamera = Angle(0, 0, 0)
    end

    if CLIENT then
        self:GRNDrawReplacement(vm)
    end
end

-- ViewModelDrawn is the most reliable dedicated SWEP callback for drawing
-- clientside models in first person. PostDrawViewModel above is kept as a
-- compatibility fallback; the FrameNumber guard prevents double rendering.
function SWEP:ViewModelDrawn(vm)
    if CLIENT then
        vm = IsValid(vm) and vm or (IsValid(self:GetOwner()) and self:GetOwner():GetViewModel() or nil)
        if IsValid(vm) then
            self:GRNDrawReplacement(vm)
        end
    end
end

function SWEP:Holster()
    if CLIENT then
        self:GRNRestoreDriverMaterial()
        self:GRNRemoveReplacementModel()
    end
    return true
end

function SWEP:OnRemove()
    if CLIENT then
        self:GRNRestoreDriverMaterial()
        self:GRNRemoveReplacementModel()
    end
end

function SWEP:CalcView(_, pos, ang, fov)
    self.GRNViewCamera = self.GRNViewCamera or Angle(0, 0, 0)
    return pos, ang + self.GRNViewCamera, fov
end

if CLIENT then
    concommand.Add("grn_inventory_backpack_debug", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local wep = ply:GetWeapon("weapon_grn_inventory_backpack")
        local cfg = GRNInventory and GRNInventory.Config and GRNInventory.Config.BackpackAnimation
        local rep = cfg and cfg.Replacement
        local path = rep and tostring(rep.Model or "") or ""

        print("========== GRN INVENTORY BACKPACK DEBUG ==========")
        print("Reemplazo activado:", rep and rep.Enabled ~= false or false)
        print("Ruta de reemplazo:", path)
        print("file.Exists(GAME):", path ~= "" and file.Exists(path, "GAME") or false)
        print("util.IsValidModel:", path ~= "" and util.IsValidModel(path) or false)
        print("SWEP valid:", IsValid(wep))

        local vm = ply:GetViewModel()
        print("Valid viewmodel:", IsValid(vm))
        if IsValid(vm) then
            local boneName = rep and tostring(rep.Bone or "jnt_backpack") or "jnt_backpack"
            print("Hueso:", boneName, "index:", vm:LookupBone(boneName))
        end
        print("==================================================")
    end)
end
