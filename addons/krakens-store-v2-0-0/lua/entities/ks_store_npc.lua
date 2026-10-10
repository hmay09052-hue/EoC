AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Kraken's Store NPC"
ENT.Author = "Kraken"

ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "NPCConfigId")
    self:NetworkVar("String", 1, "NPCName")
    self:NetworkVar("String", 2, "FloatingText")
end

local L = KrakensStore.L

if SERVER then
    function ENT:Initialize()
        KrakensStore.NPCs.ConfigureEntity(self, "")
        self:SetUseType(SIMPLE_USE)
    end

    function ENT:Use(activator, caller)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if not KrakensStore.Utils.UseDebounce(activator, 1) then return end
        local npcConfigId = self:GetNPCConfigId()
        if not npcConfigId or npcConfigId == "" then
            activator:ChatPrint(L("err_npc_not_configured"))
            return
        end
        KrakensStore.OpenNPCStoreFor(activator, npcConfigId)
    end


    function ENT:OnDuplicated()
        KrakensStore.NPCs.ConfigureEntity(self, self:GetNPCConfigId())
    end

    hook.Add("KrakensStore_NPCUpdated", "KrakensStore_UpdateNPCEntities", function(npcId, npcData)
        KrakensStore.NPCs.ForEachEntity(function(ent)
            if ent:GetNPCConfigId() == npcId then
                KrakensStore.NPCs.ConfigureEntity(ent, npcId)
            end
        end)
    end)

    hook.Add("KrakensStore_NPCDeleted", "KrakensStore_RemoveNPCEntities", function(npcId)
        KrakensStore.NPCs.ForEachEntity(function(ent)
            if ent:GetNPCConfigId() == npcId then ent:Remove() end
        end)
    end)
end

if CLIENT then
    local function ApplyIdleAnim(ent)
        local configId = ent:GetNPCConfigId()
        local npcConfig = configId ~= "" and KrakensStore.NPCs.Get(configId)
        local anim = npcConfig and npcConfig.idleAnim
        if not anim or anim == "" then
            ent.KS_IdleSeq = nil
            return
        end
        local seq = ent:LookupSequence(anim)
        if seq and seq > 0 then
            ent.KS_IdleSeq = seq
            ent:SetSequence(seq)
            ent:SetPlaybackRate(1)
            ent:SetCycle(0)
        else
            ent.KS_IdleSeq = nil
        end
    end

    function ENT:Initialize()
        timer.Simple(0.5, function()
            if IsValid(self) then ApplyIdleAnim(self) end
        end)
    end

    function ENT:Think()
        if self.KS_IdleSeq then
            self:FrameAdvance(FrameTime())
        end
    end

    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:DrawTranslucent()
        local displayName = self:GetNPCName()
        if displayName == "" then displayName = L("npc_default_name") end
        local floatingText = self:GetFloatingText()
        KrakensStore.UI.DrawEntityLabel3D(self, displayName, floatingText ~= "" and floatingText or L("entity_press_e_open"))
    end

    hook.Add("KrakensStore_NPCUpdated", "KrakensStore_NPCAnimUpdate", function(npcId)
        KrakensStore.NPCs.ForEachEntity(function(ent)
            if ent:GetNPCConfigId() == npcId then ApplyIdleAnim(ent) end
        end)
    end)

    hook.Add("KrakensStore_NPCsSynced", "KrakensStore_NPCAnimSyncApply", function()
        KrakensStore.NPCs.ForEachEntity(ApplyIdleAnim)
    end)
end
