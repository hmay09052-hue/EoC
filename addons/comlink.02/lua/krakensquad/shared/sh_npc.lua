function KrakenSquad.SetupNPCEntity(ENT, opts)
    function ENT:SetupDataTables()
        self:NetworkVar("String", 0, "DisplayText")
    end

    if SERVER then
        function ENT:Initialize()
            self:RefreshFromConfig()
            self:SetUseType(SIMPLE_USE)
            KrakenSquad.QueueNPCSave()
        end

        function ENT:Use(ply)
            if not IsValid(ply) or not ply:IsPlayer() then return end
            if (self._nextUse or 0) > CurTime() then return end
            self._nextUse = CurTime() + 0.5
            if ply:GetPos():DistToSqr(self:GetPos()) > 40000 then return end
            KF.Net.Send(opts.netMessage, nil, ply)
        end

        function ENT:RefreshFromConfig()
            local mdl, txt, anim
            if opts.terminal then
                local cfg = KrakenSquad.GetConfig("npcTerminal")
                mdl, txt, anim = cfg.model, cfg.title or KrakenSquad.L(opts.titleFallback), cfg.animation
            else
                mdl  = KrakenSquad.GetConfig("npcModels")[opts.modelKey]
                txt  = KrakenSquad.GetConfig("npcTexts")[opts.titleKey] or KrakenSquad.L(opts.titleFallback)
                anim = KrakenSquad.GetConfig("npcAnimations")[opts.animKey]
            end
            util.PrecacheModel(mdl)
            self:SetModel(mdl)
            KrakenSquad.SetupNPCPhysics(self)
            self:SetDisplayText(txt)
            KrakenSquad.SetupNPCAnimation(self, anim)
        end

        ENT.SpawnFunction = KrakenSquad.NPCSpawnFunction
    end

    if CLIENT then
        function ENT:Draw() self:DrawModel() end
        function ENT:Think() KrakenSquad.ClientNPCThink(self) end
        function ENT:DrawTranslucent()
            KrakenSquad.Draw.EntityOverhead(self, KrakenSquad.L(opts.fallbackLangKey))
        end
    end
end
