AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = (BattleGrid and BattleGrid.L and BattleGrid:L("ENTITY_CP")) or "Command Post"
ENT.Author = "Kraken"
ENT.Category = "Battle Grid"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "CPIdentifier")
    self:NetworkVar("String", 1, "CPState")
    self:NetworkVar("String", 2, "OwnerFaction")
    self:NetworkVar("String", 3, "AttackerFaction")
    self:NetworkVar("Float",  0, "CaptureProgress")
    self:NetworkVar("Float",  1, "CaptureRadius",    { KeyName = "capture_radius",    Edit = { type = "Float",  order = 3, min = 64,  max = 4096, title = "Capture Radius" } })
    self:NetworkVar("String", 4, "CPName",            { KeyName = "cp_name",           Edit = { type = "Generic",             order = 1, title = "Name" } })
    self:NetworkVar("String", 5, "CPPrefix",          { KeyName = "cp_prefix",         Edit = { type = "Generic",             order = 2, title = "Prefix (A, B, C...)" } })
    self:NetworkVar("Float",  2, "CPTicksRequired",   { KeyName = "cp_ticks_required", Edit = { type = "Float",  order = 4, min = 1,   max = 100,  title = "Ticks to Capture" } })
    self:NetworkVar("String", 6, "CPDefaultFaction",  { KeyName = "cp_default_faction",Edit = { type = "Generic",             order = 5, title = "Default Faction ID" } })
end

if SERVER then
    function ENT:Initialize()
        local mdl = "models/kraken/bf2/misc/props/command_post.mdl"
        if not util.IsValidModel(mdl) then
            mdl = "models/props_junk/PopCan01a.mdl"
            BattleGrid:Warn("CP model not found, using fallback: " .. mdl)
        end
        self:SetModel(mdl)

        local bgs = self:GetBodyGroups()
        if bgs and bgs[2] and bgs[2].num and bgs[2].num > 4 then
            self:SetBodygroup(1, 4)
        end

        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        else
            self:SetMoveType(MOVETYPE_NONE)
            self:SetSolid(SOLID_BBOX)
            self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))
            BattleGrid:Warn("CP entity has no valid physics object, using bbox fallback")
        end

        self:SetCPState(BattleGrid.CPState.NEUTRAL)
        self:SetOwnerFaction("")
        self:SetAttackerFaction("")
        self:SetCaptureProgress(0)

        local id = self:GetCPIdentifier()
        local existing = id ~= "" and BattleGrid:GetCPByID(id) or nil
        if existing and not IsValid(existing.entity) then return end

        -- Placed by hand (or duplicated): the entity becomes a brand new persisted post.
        local cfg = BattleGrid:GetCPConfig()
        if self:GetCaptureRadius() == 0 then self:SetCaptureRadius(cfg.captureRadius) end
        if self:GetCPTicksRequired() == 0 then self:SetCPTicksRequired(cfg.ticksToCapture) end
        if self:GetCPName() == "" then self:SetCPName(BattleGrid:L("ENTITY_CP")) end
        self:SetCPIdentifier(BattleGrid:GenerateUID("CP"))

        local defaultOwner = self:GetCPDefaultFaction()
        if defaultOwner == "" then defaultOwner = cfg.defaultOwner end
        BattleGrid:AddCommandPost({
            identifier    = self:GetCPIdentifier(),
            name          = self:GetCPName(),
            prefix        = self:GetCPPrefix(),
            pos           = self:GetPos(),
            angles        = self:GetAngles(),
            radius        = self:GetCaptureRadius(),
            ticksRequired = self:GetCPTicksRequired(),
            default_owner = defaultOwner,
            entity        = self,
        })
    end

    function ENT:ApplyCPData(cp)
        self:SetCPName(cp.name or "")
        self:SetCPPrefix(cp.prefix or "")
        self:SetCaptureRadius(cp.radius or 0)
        self:SetCPTicksRequired(cp.ticksRequired or 0)
        self:SetCPDefaultFaction(cp.default_owner or "")
    end

    function ENT:SyncRecord()
        local cp = BattleGrid:GetCPByID(self:GetCPIdentifier())
        if not cp or cp.entity ~= self then return end
        cp.name = self:GetCPName()
        cp.prefix = self:GetCPPrefix()
        cp.radius = math.max(1, self:GetCaptureRadius())
        cp.ticksRequired = math.max(1, math.floor(self:GetCPTicksRequired()))
        cp.default_owner = self:GetCPDefaultFaction()
        cp.pos = self:GetPos()
        cp.angles = self:GetAngles()
        BattleGrid:SaveCommandPost(cp)
    end

    function ENT:EditValue(key, val)
        self:SetKeyValue(key, val)
        timer.Simple(0, function()
            if IsValid(self) then self:SyncRecord() end
        end)
    end

    function ENT:OnRemove()
        if self._bgRemoving then return end
        self._bgRemoving = true
        local cp = BattleGrid:GetCPByID(self:GetCPIdentifier())
        if not cp or cp.entity ~= self then return end
        if BattleGrid._cpRemoveSuppressed then
            cp.entity = nil
            return
        end
        BattleGrid:DeleteCommandPost(cp.identifier)
    end

    hook.Add("PhysgunDrop", "BattleGrid.CPPhysgunDrop", function(_, ent)
        if IsValid(ent) and ent:GetClass() == "battlegrid_commandpost" then ent:SyncRecord() end
    end)

    function ENT:Think()
        local cp = BattleGrid:GetCPByID(self:GetCPIdentifier())
        if cp and cp.entity == self then
            cp.pos = self:GetPos()

            self:SetCPState(cp.state or BattleGrid.CPState.NEUTRAL)
            self:SetOwnerFaction(cp.owner or "")
            self:SetAttackerFaction(cp.attacker or "")
            self:SetCaptureProgress(cp.ticksRequired > 0 and (cp.ticks / cp.ticksRequired) or 0)
        end

        self:NextThink(CurTime() + 0.2)
        return true
    end

    function ENT:Use(activator, caller)
        if not IsValid(caller) or not caller:IsPlayer() then return end

        local state = self:GetCPState()
        local owner = self:GetOwnerFaction()
        local name = self:GetCPName()

        local stateKey = BattleGrid:GetCPStateKey(state)

        local ownerText = ""
        if owner ~= "" then
            local faction = BattleGrid:GetFactionByID(owner)
            ownerText = faction and (" — " .. faction.name) or (" — " .. owner)
        end

        caller:ChatPrint(BattleGrid:GetPrefixText() .. name .. " [" .. BattleGrid:L(stateKey) .. "]" .. ownerText)
    end
end

if CLIENT then
    local mat_lightcone = Material("models/Jellyton/BF2/Misc/Props/Command_Post/M_LightCone_01_Hi_D")
    local mat_postbase  = Material("models/Jellyton/BF2/Misc/Props/Command_Post/M_REP_CommandPost_01")
    local mat_repinsig  = Material("models/Jellyton/BF2/Misc/Props/Command_Post/M_REP_Insignia")
    local mat_sepinsig  = Material("models/Jellyton/BF2/Misc/Props/Command_Post/M_SEP_Insignia")

    local NEUTRAL_COLOR = Vector(1, 1, 1)
    local NEUTRAL_EMISSIVE = Vector(0, 0, 0)

    local _ringCol = Color(0, 0, 0)

    local holoIconCache = {}
    local function GetHoloMaterial(path)
        if not path or path == "" then return nil end
        if not holoIconCache[path] then
            holoIconCache[path] = Material(path, "noclamp smooth")
        end
        local mat = holoIconCache[path]
        return (mat and not mat:IsError()) and mat or nil
    end

    local holoGlitch = {}

    local function HoloGlitchState(ent)
        local id = ent:EntIndex()
        if not holoGlitch[id] then
            holoGlitch[id] = { active = false, nextCheck = 0, endTime = 0, offsetX = 0, sliceY = 0, sliceH = 0 }
        end
        local g = holoGlitch[id]
        local t = CurTime()
        if g.active then
            if t > g.endTime then
                g.active = false
                g.nextCheck = t + math.Rand(3, 8)
            else
                if math.random() < 0.3 then
                    g.offsetX = math.Rand(-6, 6)
                    g.sliceY = math.Rand(-1, 0.6)
                    g.sliceH = math.Rand(0.05, 0.25)
                end
            end
        elseif t > g.nextCheck then
            if math.random() < 0.15 then
                g.active = true
                g.endTime = t + math.Rand(0.08, 0.3)
                g.offsetX = math.Rand(-6, 6)
                g.sliceY = math.Rand(-1, 0.6)
                g.sliceH = math.Rand(0.05, 0.25)
            end
            g.nextCheck = t + math.Rand(0.5, 2)
        end
        return g
    end

    local function FactionToVector(factionID)
        if not factionID or factionID == "" then return nil end
        local faction = BattleGrid:GetFactionByID(factionID)
        if not faction or not faction.color then return nil end
        return Vector(faction.color.r / 255, faction.color.g / 255, faction.color.b / 255)
    end

    local function GetFactionIcon(factionID)
        if not factionID or factionID == "" then return nil end
        local faction = BattleGrid:GetFactionByID(factionID)
        if not faction or not faction.icon or faction.icon == "" then return nil end
        return GetHoloMaterial(faction.icon)
    end

    function ENT:Draw()
        self:DrawModel()

        local state = self:GetCPState()
        local owner = self:GetOwnerFaction()
        local progress = self:GetCaptureProgress()

        local col = NEUTRAL_COLOR
        local emissive = NEUTRAL_EMISSIVE

        if state == BattleGrid.CPState.CAPTURED and owner ~= "" then
            local fc = FactionToVector(owner)
            if fc then
                col = fc
                emissive = fc * 0.8
            end
        elseif state == BattleGrid.CPState.CONTESTED then
            local pulse = 0.5 + math.sin(CurTime() * 4) * 0.5
            if owner ~= "" then
                local fc = FactionToVector(owner) or NEUTRAL_COLOR
                local ac = FactionToVector(self:GetAttackerFaction()) or Vector(1, 0.3, 0.1)
                col = LerpVector(pulse * progress, fc, ac)
                emissive = col * 0.6
            else
                col = LerpVector(pulse, NEUTRAL_COLOR, Vector(1, 0.7, 0.2))
                emissive = col * 0.4
            end
        end

        mat_lightcone:SetVector("$color2", col)
        mat_repinsig:SetVector("$color2", col)
        mat_sepinsig:SetVector("$color2", col)
        mat_postbase:SetVector("$emissiveBlendTint", emissive)

        local pos = self:GetPos() + Vector(0, 0, 15)
        render.SetMaterial(mat_lightcone)
        render.DrawBeam(pos, pos + Vector(0, 0, 130), 90, 0, 1)

        local holoMat = GetFactionIcon(owner)
        if holoMat then
            local t = CurTime()
            local holoSize = 38
            local s2 = holoSize * 2
            local holoPos = self:GetPos() + Vector(0, 0, 150)
            local yaw = t * 20
            local colR, colG, colB = col.x * 255, col.y * 255, col.z * 255
            local basePulse = 0.7 + math.sin(t * 2) * 0.3
            local flicker = 0.9 + math.sin(t * 17.3) * 0.05 + math.sin(t * 31.7) * 0.05
            local g = HoloGlitchState(self)
            local glitchAlphaMul = g.active and math.Rand(0.3, 1) or 1
            local drawAlpha = math.floor(120 * basePulse * flicker * glitchAlphaMul)
            local scanSpacing = 4
            local scanOffset = (t * 30) % scanSpacing
            local blurPasses = { {2, 0}, {-2, 0}, {0, 2}, {0, -2}, {1.4, 1.4}, {-1.4, 1.4}, {1.4, -1.4}, {-1.4, -1.4} }

            local function HoloPass(ang, alpha)
                cam.Start3D2D(holoPos, ang, 1)
                    surface.SetMaterial(holoMat)
                    surface.SetDrawColor(colR, colG, colB, math.floor(alpha * 0.15))
                    for _, off in ipairs(blurPasses) do
                        surface.DrawTexturedRect(-holoSize + off[1], -holoSize + off[2], s2, s2)
                    end
                    surface.SetDrawColor(colR, colG, colB, alpha)
                    surface.DrawTexturedRect(-holoSize, -holoSize, s2, s2)
                    surface.SetDrawColor(colR * 0.3, colG * 0.3, colB * 0.3, math.floor(alpha * 0.4))
                    for sy = -holoSize + scanOffset, holoSize, scanSpacing do
                        local uvTop = (sy + holoSize) / s2
                        surface.DrawTexturedRectUV(-holoSize, sy, s2, 1, 0, uvTop, 1, math.min(uvTop + 1 / s2, 1))
                    end
                cam.End3D2D()
            end

            HoloPass(Angle(0, yaw, 90), drawAlpha)

            cam.Start3D2D(holoPos, Angle(0, yaw, 90), 1)
                surface.SetMaterial(holoMat)
                local brightScanY = ((t * 20) % s2) - holoSize
                local buvTop = (brightScanY + holoSize) / s2
                surface.SetDrawColor(colR, colG, colB, math.floor(120 * basePulse * glitchAlphaMul))
                surface.DrawTexturedRectUV(-holoSize, brightScanY, s2, 3, 0, buvTop, 1, math.min(buvTop + 3 / s2, 1))

                if g.active then
                    local sliceUVTop = math.Clamp((g.sliceY + 1) / 2, 0, 1)
                    local sliceTop = -holoSize + g.sliceY * s2
                    local sliceH = g.sliceH * s2
                    surface.SetDrawColor(colR, colG, colB, math.floor(drawAlpha * 0.7))
                    surface.DrawTexturedRectUV(-holoSize + g.offsetX, sliceTop, s2, sliceH, 0, sliceUVTop, 1, math.Clamp(sliceUVTop + g.sliceH, 0, 1))
                    surface.SetDrawColor(math.min(255, colR * 0.5), math.min(255, colG * 1.2), math.min(255, colB * 0.8), math.floor(drawAlpha * 0.3))
                    surface.DrawTexturedRectUV(-holoSize - g.offsetX * 0.5, sliceTop + 2, s2, sliceH, 0, sliceUVTop, 1, math.Clamp(sliceUVTop + g.sliceH, 0, 1))
                end
            cam.End3D2D()

            HoloPass(Angle(0, yaw + 180, 90), math.floor(60 * basePulse * flicker * glitchAlphaMul))
        end

        if state == BattleGrid.CPState.CONTESTED and progress > 0 then
            local ringPos = self:GetPos() + Vector(0, 0, 2)
            local radius = 40
            local segments = math.floor(32 * progress)
            if segments > 0 then
                render.SetColorMaterial()
                local a = 150
                _ringCol.r = col.x * 255
                _ringCol.g = col.y * 255
                _ringCol.b = col.z * 255
                _ringCol.a = a
                for i = 0, segments do
                    local angle = (i / 32) * math.pi * 2
                    local x1 = ringPos.x + math.cos(angle) * radius
                    local y1 = ringPos.y + math.sin(angle) * radius
                    local nextAngle = ((i + 1) / 32) * math.pi * 2
                    local x2 = ringPos.x + math.cos(nextAngle) * radius
                    local y2 = ringPos.y + math.sin(nextAngle) * radius
                    render.DrawLine(Vector(x1, y1, ringPos.z), Vector(x2, y2, ringPos.z), _ringCol, false)
                end
            end
        end
    end
end
