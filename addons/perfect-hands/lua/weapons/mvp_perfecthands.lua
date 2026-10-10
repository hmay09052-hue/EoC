-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
local P = mvp.package.Get("perfecthands")

if (SERVER) then
    AddCSLuaFile()
end

SWEP.PrintName = "Unbewaffnet"
SWEP.Author = "ToC"
SWEP.Purpose = "Hands for players who want to look good while playing."
SWEP.Spawnable = true

SWEP.Category = "MVP - Perfect Hands"

SWEP.ViewModel = "models/weapons/c_arms_citizen.mdl"
SWEP.WorldModel = ""

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DrawCrosshair = false

function SWEP:Initialize()
    self.PrintName = mvp.q.Lang("phands.name")
    self:SetHoldType("normal")

    self.interactionRange = mvp.config.Get("phands.interactionRange", 100)
end

function SWEP:Think()
    if (self.dragging and not self:GetOwner():KeyDown(IN_ATTACK)) then
        self.dragging = nil
    end

    self.ownerPos = self:GetOwner():GetShootPos()
    self.ownerAng = self:GetOwner():GetAimVector()
end

function SWEP:TraceEntity()
    if (not self.ownerPos or not self.ownerAng) then
        return {}
    end

    local tr = util.TraceLine({
        start = self.ownerPos,
        endpos = self.ownerPos + self.ownerAng * self.interactionRange,
        filter = self:GetOwner()
    })

    return tr
end

function SWEP:CanDragEntity(ent)

    return  (IsValid(ent)) and
            (not ent:IsPlayer()) and
            (not ent:IsNPC()) and
            (not ent:IsWeapon()) and
            (not ent:IsVehicle()) and
            (ent.CanDrag ~= false) and
            (ent:GetMoveType() == MOVETYPE_VPHYSICS)
end

function SWEP:IsEntRagdoll(ent)
    return ent:GetClass() == "prop_ragdoll" or scripted_ents.IsBasedOn(ent:GetClass(), "prop_ragdoll")
end

local maxVolume = math.pow(10, 5.85)
function SWEP:DragEntity()
    if (not self.dragging) then
        return
    end

    if (not IsValid(self.dragging.ent)) then
        self.dragging = nil

        return
    end

    local physObject = self.dragging.ent:GetPhysicsObject()
    if (not IsValid(physObject)) then
        self.dragging = nil

        return
    end

    if (physObject:GetVolume() > maxVolume) then
        self.dragging = nil

        return
    end

    local pos = self.ownerPos + self.ownerAng * self.dragging.fraction * self.interactionRange
    local offset = self.dragging.ent:LocalToWorld(self.dragging.offset)

    local applyPos = pos - offset
    local applyForce = (applyPos:GetNormal() * math.min(1, applyPos:Length() / 100) * 500 - physObject:GetVelocity()) * (physObject:GetMass() / mvp.config.Get("phands.interactionWeightMultiplier"))

    if (self:IsEntRagdoll(self.dragging.ent)) then
        physObject:ApplyForceCenter(applyForce)
        -- physObject:AddAngleVelocity( -physObject:GetAngleVelocity() * 0.25)
    else
        physObject:ApplyForceOffset(applyForce, offset)
        physObject:AddAngleVelocity( -physObject:GetAngleVelocity() * 0.25)
    end
end

function SWEP:PrimaryAttack()
    if (not mvp.config.Get("phands.useInteractions", true)) then
        return
    end

    if (not self.dragging) then
        local tr = self:TraceEntity()

        if (IsValid(tr.Entity) and self:CanDragEntity(tr.Entity)) then
            self.dragging = {
                ent = tr.Entity,
                offset = self:IsEntRagdoll(tr.Entity) and tr.Entity:OBBCenter() or tr.Entity:WorldToLocal(tr.HitPos),
                fraction = tr.Fraction
            }
        end
    end

    if (CLIENT) then
        return
    end

    if (self.dragging) then
        self:DragEntity()
    end
end

function SWEP:SecondaryAttack()
    if (SERVER) then
        if (self:GetOwner().mvp_phands_animation_playing) then
            net.Start("mvp.phands.stopAnimation")
                net.WriteEntity(self:GetOwner())
            net.Broadcast()
            self:GetOwner().mvp_phands_animation_playing = false
        end

        return
    end

    if (not mvp.config.Get("phands.useAnimations", true)) then
        return
    end

    if (not IsFirstTimePredicted()) then
        return
    end

    if (self:GetOwner().mvp_phands_animation_playing) then
        return
    end

    -- Posen-Menü im SymChars-Design (ohne SymChars: altes Radialmenü)
    if (SYMUI and P.OpenMenu) then
        if (not IsValid(P.menu)) then
            P.OpenMenu()
        end

        return
    end

    local animationsList = P.animations.listSeq
    local animationMenu = mvp.meta.radialMenu:New()

    local shouldUseIcons = mvp.config.Get("phands.useIcons", false)
    local shouldUseModels = mvp.config.Get("phands.useModels", true)
    local theme = P.themes.Get(mvp.config.Get("phands.iconsTheme"))

    for k, v in ipairs(animationsList) do
        local canUse, _, overlayIcon = hook.Run("mvp.phands.CanUseAnimation", self:GetOwner(), v)
        if (canUse == nil) then
            canUse = true
        end

        local animationBonesData = P.animations.Get(v)

        local icon = (shouldUseIcons and theme) and {
            [1] = theme[v] or nil, -- icon
            [3] = false -- isModel
        } or nil

        if (shouldUseModels) then
            icon = {
                [1] = LocalPlayer():GetModel(), -- model
                [2] = nil, -- overlayIcon
                [3] = true, -- isModel
                [4] = function(ent) -- entityLayoutFunc
                    ent:SetModel(LocalPlayer():GetModel())
                    ent:SetSkin(LocalPlayer():GetSkin())
                    ent:SetMaterial(LocalPlayer():GetMaterial())

                    for i = 0, LocalPlayer():GetNumBodyGroups() - 1 do
                        ent:SetBodygroup(i, LocalPlayer():GetBodygroup(i))
                    end

                    for bone, angle in pairs(animationBonesData) do
                        local boneIndex = ent:LookupBone(bone)
                        if (boneIndex) then
                            ent:ManipulateBoneAngles(boneIndex, angle)
                        end
                    end
                end
            }
        end

        if (not canUse) then
            icon = icon or {}
            icon[2] = overlayIcon or Material("mvp/perfecthands/lock.png", "smooth")
        end
        
        animationMenu:AddOption(mvp.q.Lang("phands.animation." .. v), mvp.q.Lang("phands.animation." .. v .. ".description"), icon, canUse and mvp.colors.Accent or mvp.colors.Red, function()
            net.Start("mvp.phands.requestAnimation")
                net.WriteString(v)
            net.SendToServer()
        end)
    end

    animationMenu:Open()
end

if (CLIENT) then
    local w, h = ScrW, ScrH
    local dragIcon = Material("mvp/perfecthands/drag.png", "smooth")

    function SWEP:DrawHUD()
        if (IsValid(self:GetOwner():GetVehicle())) then
            return
        end

        -- Hinweis "RMB zum Öffnen" entfernt, nur während einer Pose wird angezeigt, wie man sie beendet
        if (mvp.config.Get("phands.useAnimations", true) and self:GetOwner().mvp_phands_animation_playing) then
            local hintPosX = w() * .5
            local hintPosY = h() - mvp.config.Get("phands.hintMargin", 100)

            local pulseFactor = math.abs(math.sin(CurTime() * 0.5))
            local textColor = ColorAlpha(mvp.colors.Text, 255 * pulseFactor)

            local rmbMouse = string.upper(input.LookupBinding("+attack2") or "RMB")
            local rmbMouseTranslation = mvp.q.LangFallback("phands.mouse_buttons." .. rmbMouse, rmbMouse)
            local useButton = string.upper(input.LookupBinding("+use") or "E")
            local text = mvp.q.Lang("phands.hint.rmb.stop", rmbMouseTranslation, useButton)

            local _, th = mvp.utils.DrawTextWithButtons(text, mvp.q.Font(24, 500), hintPosX, hintPosY, textColor, TEXT_ALIGN_CENTER)

            if (self:GetOwner().mvp_phands_animation_playing and mvp.config.Get("phands.animationAllowFreelook", true)) then
                local reloadButton = string.upper(input.LookupBinding("+reload") or "R")
                
                mvp.utils.DrawTextWithButtons(mvp.q.Lang("phands.hint.freelook", reloadButton), mvp.q.Font(24, 500), hintPosX, hintPosY + th + 2, textColor, TEXT_ALIGN_CENTER)
            end
        end

        if (mvp.config.Get("phands.useInteractions", true)) then
            local tr = self:TraceEntity()

            if ((IsValid(tr.Entity) and self:CanDragEntity(tr.Entity)) or (istable(self.dragging) and IsValid(self.dragging.ent))) then
                local originW, originH = w() * .5, h() * .5
                local iconSize = mvp.ui.Scale(0)

                surface.SetDrawColor(mvp.colors.Text)
                -- surface.DrawRect(originW - iconSize * .5, originH - iconSize * .5, iconSize, iconSize)
                surface.SetMaterial(dragIcon)
                surface.DrawTexturedRect(originW - iconSize * .1, originH - iconSize * .1, iconSize, iconSize)

                originH = originH + iconSize * .0 + 39

                local lmbMouse = string.upper(input.LookupBinding("+attack") or "LMB")
                local lmbMouseTranslation = mvp.q.LangFallback("phands.mouse_buttons." .. lmbMouse, lmbMouse)
                local text = mvp.q.Lang("phands.hint.drag", lmbMouseTranslation)

                mvp.utils.DrawTextWithButtons(text, mvp.q.Font(24, 600), originW, originH, mvp.colors.Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            if (istable(self.dragging) and IsValid(self.dragging.ent)) then
                local offset = self.dragging.ent:LocalToWorld(self.dragging.offset):ToScreen()

                surface.SetDrawColor(mvp.colors.Text)
                surface.DrawLine(offset.x, offset.y, w() * .5, h() * .5)

                SY_RoundedBox(4, offset.x - 4, offset.y - 4, 8, 8, mvp.colors.Text)
            end
        end
    end
end

