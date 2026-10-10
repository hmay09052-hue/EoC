local NPC_PATH = "krakensquad/npcs.json"

KrakenSquad.NPC_CLASSES = {
    ent_krakensquad_creator  = true,
    ent_krakensquad_list     = true,
    ent_krakensquad_terminal = true,
}
local NPC_CLASSES = KrakenSquad.NPC_CLASSES

function KrakenSquad.SetupNPCPhysics(ent)
    ent:SetMoveType(MOVETYPE_NONE)
    ent:SetSolid(SOLID_BBOX)
    ent:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    local mins, maxs = ent:GetModelBounds()
    if mins and maxs then
        ent:SetCollisionBounds(Vector(mins.x, mins.y, 0), maxs)
    end
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:EnableMotion(false) end
    timer.Simple(0, function() if IsValid(ent) then ent:DropToFloor() end end)
end

function KrakenSquad.SetupNPCAnimation(ent, anim)
    local seqName = anim and anim ~= "" and anim or ""
    ent:SetNWString("KSAnim", seqName)

    local function Apply()
        if not IsValid(ent) then return true end
        local seq = seqName ~= "" and ent:LookupSequence(seqName) or -1
        if seq < 0 then seq = ent:LookupSequence("idle_all_01") end
        if seq < 0 then seq = ent:SelectWeightedSequence(ACT_IDLE) end
        if seq < 0 then return false end
        ent:ResetSequence(seq)
        ent:SetPlaybackRate(1)
        ent:SetCycle(0)
        return true
    end
    if not Apply() then timer.Simple(0.5, Apply) end
end

function KrakenSquad.NPCSpawnFunction(self, ply, tr)
    if not tr.Hit then return end
    local ent = ents.Create(self.ClassName)
    ent:SetPos(tr.HitPos)
    ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
    ent:Spawn()
    ent:Activate()
    ent:DropToFloor()
    return ent
end

function KrakenSquad.IsNearTerminal(ply, maxDist)
    local sqr = (maxDist or 200) ^ 2
    for _, ent in ipairs(ents.FindByClass("ent_krakensquad_terminal")) do
        if ply:GetPos():DistToSqr(ent:GetPos()) <= sqr then return true end
    end
    return false
end

function KrakenSquad.GetEntityDisplayName(ent)
    if not IsValid(ent) then return KrakenSquad.L("unknown_entity") end
    if ent:IsPlayer() then return ent:Nick() end
    if ent:IsNPC() then
        local cls = ent:GetClass()
        local entry = list.Get("NPC")[cls]
        return ent.PrintName or (entry and entry.Name) or cls
    end
    return ent.PrintName or ent:GetClass()
end

function KrakenSquad.SaveNPCs()
    if not file.IsDir("krakensquad", "DATA") then file.CreateDir("krakensquad") end
    local data = {}
    for cls in pairs(NPC_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(cls)) do
            local p, a = ent:GetPos(), ent:GetAngles()
            data[#data + 1] = {
                class = cls,
                pos = { p.x, p.y, p.z },
                ang = { a.p, a.y, a.r },
            }
        end
    end
    file.Write(NPC_PATH, util.TableToJSON(data, true))
end

function KrakenSquad.LoadNPCs()
    if not file.Exists(NPC_PATH, "DATA") then return end
    local data = util.JSONToTable(file.Read(NPC_PATH, "DATA"))
    if not data then return end
    for _, e in ipairs(data) do
        if NPC_CLASSES[e.class] and e.pos and e.ang then
            local ent = ents.Create(e.class)
            ent:SetPos(Vector(e.pos[1], e.pos[2], e.pos[3]))
            ent:SetAngles(Angle(e.ang[1], e.ang[2], e.ang[3]))
            ent:Spawn(); ent:Activate()
        end
    end
end

function KrakenSquad.RefreshAllNPCs()
    for cls in pairs(NPC_CLASSES) do
        for _, ent in ipairs(ents.FindByClass(cls)) do
            if ent.RefreshFromConfig then ent:RefreshFromConfig() end
        end
    end
end

function KrakenSquad.QueueNPCSave()
    timer.Create("KS.NPCSave", 1, 1, KrakenSquad.SaveNPCs)
end

hook.Add("EntityRemoved", "KrakenSquad.NPCPersist", function(ent)
    if NPC_CLASSES[ent:GetClass()] then KrakenSquad.QueueNPCSave() end
end)
