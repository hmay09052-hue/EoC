AddCSLuaFile()

SWEP.PrintName = (FCR and FCR.L and FCR.L("weapon_printname")) or "Fusion Cutter"
SWEP.Author = "Tscripts"
SWEP.Instructions = (FCR and FCR.L and FCR.L("weapon_instructions")) or "LMB: start vehicle repair protocol"
SWEP.Category = "[Tscripts] Sweps"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.UseHands = true
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.HoldType = "slam"
SWEP.ViewModel = "models/weapons/c_grenade.mdl"
SWEP.WorldModel = "models/weapons/w_grenade.mdl"
SWEP.ShowViewModel = false
SWEP.DrawViewModel = false
SWEP.ShowWorldModel = false
SWEP.DrawCrosshair = false
SWEP.DrawAmmo = false
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Primary.Delay = 0.45
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Delay = 0.45
SWEP.ViewModelBoneMods = {
    ["ValveBiped.Grenade_body"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
    ["ValveBiped.Pin"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) },
    ["ValveBiped.Bip01"] = { scale = Vector(1, 1, 1), pos = Vector(0, -1.297, 0), angle = Angle(0, 0, 0) }
}
SWEP.VElements = {
    ["fusioncutter"] = { type = "Model", model = "models/cosmo/starwarscutter.mdl", bone = "ValveBiped.Grenade_body", rel = "", pos = Vector(-0.519, 0.518, 1.557), angle = Angle(162.468, -180, 24.545), size = Vector(0.82, 0.82, 0.82), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["core_glow"] = { type = "Sprite", sprite = "sprites/animglow02", bone = "ValveBiped.Grenade_body", rel = "fusioncutter", pos = Vector(9.869, -0.519, 16.104), size = { x = 9, y = 9 }, color = Color(255, 88, 88, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false },
    ["tip_glow"] = { type = "Sprite", sprite = "sprites/animglow02", bone = "ValveBiped.Grenade_body", rel = "fusioncutter", pos = Vector(-1.558, -0.119, 9.67), size = { x = 2, y = 2 }, color = Color(255, 174, 72, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false }
}
SWEP.WElements = {
    ["fusioncutter"] = { type = "Model", model = "models/cosmo/starwarscutter.mdl", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(2.596, 4.675, 3.635), angle = Angle(-8.183, -17.532, -146.105), size = Vector(0.885, 0.885, 0.885), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 0, bodygroup = {} },
    ["world_glow"] = { type = "Sprite", sprite = "sprites/animglow02", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(16.104, -1.558, -12.988), size = { x = 9, y = 9 }, color = Color(255, 92, 92, 255), nocull = true, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false }
}

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)

    if CLIENT then
        self.VElements = table.FullCopy(self.VElements)
        self.WElements = table.FullCopy(self.WElements)
        self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)
        self:CreateModels(self.VElements)
        self:CreateModels(self.WElements)
        if IsValid(self.Owner) then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                self:ResetBonePositions(vm)
                vm:SetColor(Color(255, 255, 255, 1))
                vm:SetMaterial("")
            end
        end
    end
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    local ply = self:GetOwner()
    if not IsValid(ply) then return end
    if FCR and FCR.Session and FCR.Session.TryBegin then
        FCR.Session.TryBegin(ply, self)
    end
end

function SWEP:SecondaryAttack()
    return false
end

function SWEP:Holster()
    if CLIENT and IsValid(self.Owner) then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            self:ResetBonePositions(vm)
        end
    end
    return true
end

function SWEP:OnRemove()
    self:Holster()
end

if CLIENT then
    SWEP.vRenderOrder = nil
    function SWEP:ViewModelDrawn()
        local vm = self.Owner:GetViewModel()
        if not IsValid(vm) or not self.VElements then return end
        self:UpdateBonePositions(vm)
        if not self.vRenderOrder then
            self.vRenderOrder = {}
            for k, v in pairs(self.VElements) do
                if v.type == "Model" then table.insert(self.vRenderOrder, 1, k) elseif v.type == "Sprite" or v.type == "Quad" then table.insert(self.vRenderOrder, k) end
            end
        end
        for _, name in ipairs(self.vRenderOrder) do
            local v = self.VElements[name]
            if not v or v.hide then continue end
            local model = v.modelEnt
            local sprite = v.spriteMaterial
            if not v.bone then continue end
            local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
            if not pos then continue end
            if v.type == "Model" and IsValid(model) then
                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)
                model:SetAngles(ang)
                local matrix = Matrix(); matrix:Scale(v.size); model:EnableMatrix("RenderMultiply", matrix); model:SetMaterial(v.material or ""); model:SetSkin(v.skin or 0)
                render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255); render.SetBlend(v.color.a / 255); model:DrawModel(); render.SetBlend(1); render.SetColorModulation(1,1,1)
            elseif v.type == "Sprite" and sprite then
                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                local pulse = 0.55 + math.abs(math.sin(CurTime() * 1.8)) * 0.45
                render.SetMaterial(sprite)
                render.DrawSprite(drawpos, v.size.x, v.size.y, Color(v.color.r, v.color.g, v.color.b, 160 + 90 * pulse))
            end
        end
    end

    SWEP.wRenderOrder = nil
    function SWEP:DrawWorldModel()
        if self.ShowWorldModel then self:DrawModel() end
        if not self.WElements then return end
        if not self.wRenderOrder then
            self.wRenderOrder = {}
            for k, v in pairs(self.WElements) do
                if v.type == "Model" then table.insert(self.wRenderOrder, 1, k) elseif v.type == "Sprite" or v.type == "Quad" then table.insert(self.wRenderOrder, k) end
            end
        end
        local boneEnt = IsValid(self.Owner) and self.Owner or self
        for _, name in pairs(self.wRenderOrder) do
            local v = self.WElements[name]
            if not v or v.hide then continue end
            local pos, ang = self:GetBoneOrientation(self.WElements, v, boneEnt, v.bone or "ValveBiped.Bip01_R_Hand")
            if not pos then continue end
            local model = v.modelEnt
            local sprite = v.spriteMaterial
            if v.type == "Model" and IsValid(model) then
                model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
                ang:RotateAroundAxis(ang:Up(), v.angle.y)
                ang:RotateAroundAxis(ang:Right(), v.angle.p)
                ang:RotateAroundAxis(ang:Forward(), v.angle.r)
                model:SetAngles(ang)
                local matrix = Matrix(); matrix:Scale(v.size); model:EnableMatrix("RenderMultiply", matrix); model:SetMaterial(v.material or "")
                render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255); render.SetBlend(v.color.a / 255); model:DrawModel(); render.SetBlend(1); render.SetColorModulation(1,1,1)
            elseif v.type == "Sprite" and sprite then
                local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
                render.SetMaterial(sprite)
                render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
            end
        end
    end

    function SWEP:GetBoneOrientation(baseTable, tab, ent, boneOverride)
        local bone, pos, ang
        if tab.rel and tab.rel ~= "" then
            local rel = baseTable[tab.rel]
            if not rel then return end
            pos, ang = self:GetBoneOrientation(baseTable, rel, ent)
            if not pos then return end
            pos = pos + ang:Forward() * rel.pos.x + ang:Right() * rel.pos.y + ang:Up() * rel.pos.z
            ang:RotateAroundAxis(ang:Up(), rel.angle.y); ang:RotateAroundAxis(ang:Right(), rel.angle.p); ang:RotateAroundAxis(ang:Forward(), rel.angle.r)
        else
            bone = ent:LookupBone(boneOverride or tab.bone)
            if not bone then return end
            local matrix = ent:GetBoneMatrix(bone)
            pos, ang = Vector(0,0,0), Angle(0,0,0)
            if matrix then pos, ang = matrix:GetTranslation(), matrix:GetAngles() end
            if IsValid(self.Owner) and self.Owner:IsPlayer() and ent == self.Owner:GetViewModel() and self.ViewModelFlip then ang.r = -ang.r end
        end
        return pos, ang
    end

    function SWEP:CreateModels(tab)
        if not tab then return end
        for _, v in pairs(tab) do
            if v.type == "Model" and v.model and v.model ~= "" and (not IsValid(v.modelEnt) or v.createdModel ~= v.model) and string.find(v.model, ".mdl") and file.Exists(v.model, "GAME") then
                v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
                if IsValid(v.modelEnt) then v.modelEnt:SetPos(self:GetPos()); v.modelEnt:SetAngles(self:GetAngles()); v.modelEnt:SetParent(self); v.modelEnt:SetNoDraw(true); v.createdModel = v.model else v.modelEnt = nil end
            elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" and (not v.spriteMaterial or v.createdSprite ~= v.sprite) and file.Exists("materials/" .. v.sprite .. ".vmt", "GAME") then
                local name = v.sprite .. "-"
                local params = { ["$basetexture"] = v.sprite }
                for _, j in ipairs({ "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }) do
                    if v[j] then params["$" .. j] = 1; name = name .. "1" else name = name .. "0" end
                end
                v.createdSprite = v.sprite
                v.spriteMaterial = CreateMaterial(name, "UnlitGeneric", params)
            end
        end
    end

    local allBones
    local hasFixed = false
    function SWEP:UpdateBonePositions(vm)
        if not self.ViewModelBoneMods then self:ResetBonePositions(vm) return end
        if not vm:GetBoneCount() then return end
        local loopThrough = self.ViewModelBoneMods
        if not hasFixed then
            allBones = {}
            for i=0, vm:GetBoneCount() do
                local boneName = vm:GetBoneName(i)
                allBones[boneName] = self.ViewModelBoneMods[boneName] or { scale = Vector(1,1,1), pos = Vector(0,0,0), angle = Angle(0,0,0) }
            end
            loopThrough = allBones
        end
        for boneName, mod in pairs(loopThrough) do
            local bone = vm:LookupBone(boneName)
            if not bone then continue end
            local scale = Vector(mod.scale.x, mod.scale.y, mod.scale.z)
            local pos = Vector(mod.pos.x, mod.pos.y, mod.pos.z)
            local ms = Vector(1,1,1)
            if not hasFixed then
                local cur = vm:GetBoneParent(bone)
                while cur >= 0 do local pScale = loopThrough[vm:GetBoneName(cur)].scale; ms = ms * pScale; cur = vm:GetBoneParent(cur) end
            end
            scale = scale * ms
            if vm:GetManipulateBoneScale(bone) ~= scale then vm:ManipulateBoneScale(bone, scale) end
            if vm:GetManipulateBoneAngles(bone) ~= mod.angle then vm:ManipulateBoneAngles(bone, mod.angle) end
            if vm:GetManipulateBonePosition(bone) ~= pos then vm:ManipulateBonePosition(bone, pos) end
        end
    end

    function SWEP:ResetBonePositions(vm)
        if not vm:GetBoneCount() then return end
        for i=0, vm:GetBoneCount() do
            vm:ManipulateBoneScale(i, Vector(1,1,1)); vm:ManipulateBoneAngles(i, Angle(0,0,0)); vm:ManipulateBonePosition(i, Vector(0,0,0))
        end
    end

    function table.FullCopy(tab)
        if not tab then return nil end
        local res = {}
        for k, v in pairs(tab) do
            if type(v) == "table" then res[k] = table.FullCopy(v) elseif type(v) == "Vector" then res[k] = Vector(v.x, v.y, v.z) elseif type(v) == "Angle" then res[k] = Angle(v.p, v.y, v.r) else res[k] = v end
        end
        return res
    end
end
