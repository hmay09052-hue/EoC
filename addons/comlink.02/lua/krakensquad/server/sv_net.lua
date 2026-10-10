local SyncSquadListTo, ApplyPresetComms, TryAutoAssign

local Net = KrakenSquad.Net
local ML  = KrakenSquad.MAX_LENGTHS

local function IsLocked(squad)
    if not squad:IsPreset() or squad:IsUnitSquad() then return false end
    for _, p in ipairs(KrakenSquad.GetConfig("presetSquads") or {}) do
        if p.name == squad:GetTitle() and p.lockMembers then return true end
    end
    return false
end

-- Vor dem Wechsel in einen anderen Squad den aktuellen verlassen (Einheits-Squad oder eigener Squad).
-- Wer danach seinen neuen Squad verlässt, kommt automatisch zurück in den Einheits-Squad.
local function LeaveCurrentFor(ply)
    local cur = ply:GetKSSquad()
    if cur then
        if IsLocked(cur) then return false end
        cur:RemoveMember(ply)
    end
    ply._ksUnitOptOut = nil
    return true
end
KrakenSquad.LeaveCurrentFor = LeaveCurrentFor

Net.Receive("KS.RequestCreate", function(_, ply)
    local title    = net.ReadString():Trim():sub(1, ML.squadName)
    local isPublic = net.ReadBool()
    if #title < ML.squadNameMin then return end
    if not LeaveCurrentFor(ply) then return end
    KrakenSquad.CreateSquad(title, ply, isPublic)
end, { rateKey = "create" })

Net.Receive("KS.RequestLeave", function(_, ply)
    local squad = ply:GetKSSquad()
    if not squad then return end
    if IsLocked(squad) then return end

    if squad:IsUnitSquad() then
        -- bewusst aus dem Einheits-Squad ausgetreten: nicht automatisch zurückholen
        -- (bis zum Charakterwechsel oder "Einheits-Squad beitreten")
        ply._ksUnitOptOut = ply.GetCharacterID and ply:GetCharacterID() or true
    else
        ply._ksUnitOptOut = nil
    end

    squad:RemoveMember(ply)
end)

Net.Receive("KS.RequestJoinUnit", function(_, ply)
    if KrakenSquad.UnitSquadOf and KrakenSquad.UnitSquadOf(ply) == ply:GetKSSquad() then return end
    local cur = ply:GetKSSquad()
    if cur and IsLocked(cur) then return end
    if cur then cur:RemoveMember(ply) end
    ply._ksUnitOptOut = nil
    if KrakenSquad.SyncUnitSquad then KrakenSquad.SyncUnitSquad(ply) end
end, { rateKey = "create" })

Net.Receive("KS.RequestKick", function(_, ply)
    if not ply:KSIsLeader() then return end
    local target = net.ReadEntity()
    local squad  = ply:GetKSSquad()
    if not (squad and IsValid(target) and target:KSInSquad(squad:GetID())) then return end
    if squad:IsUnitSquad() then return end -- aus dem Einheits-Squad entlässt nur die Einheit
    squad:RemoveMember(target)
end)

Net.Receive("KS.RequestPosChange", function(_, ply)
    if not ply:KSIsLeader() then return end
    local target = net.ReadEntity()
    local pos    = net.ReadUInt(8)
    if not IsValid(target) or target == ply or not KrakenSquad.GetPositions()[pos] then return end
    local squad = ply:GetKSSquad()
    if not (squad and target:KSInSquad(squad:GetID())) then return end
    squad:ChangePosition(target, pos)
end)

Net.Receive("KS.RequestComm", function(_, ply)
    ply:KSCommunicate(net.ReadString():sub(1, ML.commID))
end, { rateKey = "communicate" })

Net.Receive("KS.RequestCommand", function(_, ply)
    ply:KSCommand(net.ReadString():sub(1, ML.cmdID))
end, { rateKey = "command" })

Net.Receive("KS.RequestJoinPublic", function(_, ply)
    local squad = KrakenSquad.GetSquad(net.ReadUInt(16))
    if not squad or not squad:IsPublic() or ply:GetKSSquad() == squad then return end
    if squad:GetMemberCount() >= squad:GetMaxMembers() then return end
    if not LeaveCurrentFor(ply) then return end
    squad:AddMember(ply)
end)

Net.Receive("KS.RequestSwitchPreset", function(_, ply)
    local targetName = net.ReadString():sub(1, ML.squadName)
    if targetName == "" then return end

    local current = ply:GetKSSquad()
    if not current or not current:IsPreset() or current:GetTitle() == targetName then return end

    local preset
    for _, p in ipairs(KrakenSquad.GetConfig("presetSquads") or {}) do
        if p.name == targetName then preset = p break end
    end
    if not preset or not preset.filters then return end
    if not KrakenSquad.PlayerMatchesFilters(ply, preset.filters) then return end

    local squad
    for _, s in pairs(KrakenSquad.Cache) do
        if s:IsPreset() and s:GetTitle() == targetName then squad = s break end
    end
    if not squad then return end

    current:RemoveMember(ply)
    squad:AddMember(ply)

    local lf = preset.leaderFilter
    if lf and lf.type and lf.value and KF.Integrations.MatchesFilter(ply, lf.type, lf.value) then
        squad:ChangePosition(ply, 1)
    end
    if preset.roleAssignments then
        for _, ra in ipairs(preset.roleAssignments) do
            if ra.filter and ra.position and KF.Integrations.MatchesFilter(ply, ra.filter.type, ra.filter.value) then
                squad:ChangePosition(ply, ra.position)
                break
            end
        end
    end
    ApplyPresetComms(ply, preset)
end, { rateKey = "switch_preset" })

Net.Receive("KS.RequestSquads", function(_, ply) SyncSquadListTo(ply) end)

Net.Receive("KS.InvitePlayer", function(_, ply)
    if not ply:KSIsLeader() then return end
    local target = net.ReadEntity()
    if IsValid(target) and target:IsPlayer() then target:KSInviteToSquad(ply) end
end, { rateKey = "invite" })

Net.Receive("KS.InviteDecision", function(_, ply)
    local accepted = net.ReadBool()
    local squadID  = ply:GetNWInt("KS.InvitedTo", -1)
    ply:SetNWInt("KS.InvitedTo", -1)
    if not accepted or squadID == -1 then return end
    local squad = KrakenSquad.GetSquad(squadID)
    if not squad or ply:GetKSSquad() == squad then return end
    if squad:GetMemberCount() >= squad:GetMaxMembers() then return end
    if LeaveCurrentFor(ply) then squad:AddMember(ply) end
end)

Net.Receive("KS.AdminConfigUpdate", function(_, ply)
    local tbl = KF.Net.ReadJSON(65536)
    if not tbl then return end
    for k, v in pairs(tbl) do
        if KrakenSquad.Defaults[k] ~= nil and type(v) == type(KrakenSquad.Defaults[k]) then
            KrakenSquad.Config[k] = v
        end
    end
    KrakenSquad.SaveConfig()
    KrakenSquad.SyncConfigToAll()

    if tbl.language    then KrakenSquad.SetLang(tbl.language) end
    if tbl.blockDamage ~= nil then KrakenSquad.ApplyFFHook() end
    if tbl.xpRewards   then KrakenSquad.RestartXPTimer() end
    if tbl.npcModels or tbl.npcTexts or tbl.npcAnimations or tbl.npcTerminal then
        KrakenSquad.RefreshAllNPCs()
    end
end, { admin = true, rateKey = "admin" })

Net.Receive("KS.AdminPresetCreate", function(_, ply)
    local preset = KF.Net.ReadJSON(8192)
    if not preset or not preset.name then return end
    preset.name = preset.name:Trim():sub(1, ML.squadName)
    if #preset.name < ML.squadNameMin then return end

    local presets = KrakenSquad.GetConfig("presetSquads") or {}
    table.insert(presets, preset)
    KrakenSquad.SetConfig("presetSquads", presets)
    KrakenSquad.SaveConfig()
    KrakenSquad.CreateSquadInternal(preset.name, preset.public or false, true)
    KrakenSquad.SyncConfigToAll()
end, { admin = true, rateKey = "admin" })

Net.Receive("KS.AdminPresetUpdate", function(_, ply)
    local payload = KF.Net.ReadJSON(8192)
    if not payload or not payload.preset then return end
    local idx, preset = tonumber(payload.index), payload.preset
    if not idx or not preset.name then return end
    preset.name = preset.name:Trim():sub(1, ML.squadName)
    if #preset.name < ML.squadNameMin then return end

    local presets = KrakenSquad.GetConfig("presetSquads") or {}
    if not presets[idx] then return end
    local oldName = presets[idx].name
    presets[idx] = preset
    KrakenSquad.SetConfig("presetSquads", presets)
    KrakenSquad.SaveConfig()

    for _, s in pairs(KrakenSquad.Cache) do
        if s:IsPreset() and s:GetTitle() == oldName then
            s.name, s.public = preset.name, preset.public or false
            break
        end
    end
    KrakenSquad.SyncConfigToAll()
end, { admin = true, rateKey = "admin" })

Net.Receive("KS.AdminPresetDelete", function(_, ply)
    local idx = net.ReadUInt(16)
    local presets = KrakenSquad.GetConfig("presetSquads") or {}
    if not presets[idx] then return end
    local name = presets[idx].name
    table.remove(presets, idx)
    KrakenSquad.SetConfig("presetSquads", presets)
    KrakenSquad.SaveConfig()

    for _, s in pairs(KrakenSquad.Cache) do
        if s:IsPreset() and s:GetTitle() == name then s:Remove() break end
    end
    KrakenSquad.SyncConfigToAll()
end, { admin = true })

Net.Receive("KS.LayoutSync", function(_, ply)
    KF.Net.SendJSON("KS.LayoutSync", KrakenSquad.GetConfig("layout") or {}, ply)
end)

Net.Receive("KS.LayoutUpdate", function(_, ply)
    local layout = KF.Net.ReadJSON(8192)
    if not layout then return end
    KrakenSquad.SetConfig("layout", layout)
    KrakenSquad.SaveConfig()
    KrakenSquad.SyncConfigToAll()
end, { admin = true, rateKey = "layout" })

Net.Receive("KS.RemoveNPC", function(_, ply)
    local ent = net.ReadEntity()
    if IsValid(ent) and KrakenSquad.NPC_CLASSES[ent:GetClass()] then ent:Remove() end
end, { admin = true, rateKey = "admin" })

Net.Receive("KS.RemoveAllNPCs", function(_, ply)
    for _, ent in ipairs(ents.GetAll()) do
        if KrakenSquad.NPC_CLASSES[ent:GetClass()] then ent:Remove() end
    end
end, { admin = true, rateKey = "admin" })

ApplyPresetComms = function(ply, preset)
    if not KComms or not preset.commsChannels then return end
    local pos = ply:GetKSPosition()
    local ch = preset.commsChannels[tostring(pos)] or preset.commsChannels[pos]
    if not ch then return end
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        if ch.active   and ch.active   ~= "" then ply:KCSetActive(ch.active) end
        if ch.passive1 and ch.passive1 ~= "" then ply:KCSetPassive(1, ch.passive1) end
        if ch.passive2 and ch.passive2 ~= "" then ply:KCSetPassive(2, ch.passive2) end
    end)
end

local function MatchesAnyFilter(ply, filters)
    for _, f in ipairs(filters) do
        if KF.Integrations.MatchesFilter(ply, f.type, f.value) then return true end
    end
end

local function ApplyPresetRoles(ply, squad, preset)
    local lf = preset.leaderFilter
    if lf and lf.type and lf.value and KF.Integrations.MatchesFilter(ply, lf.type, lf.value) then
        squad:ChangePosition(ply, 1)
    end
    for _, ra in ipairs(preset.roleAssignments or {}) do
        if ra.filter and ra.position and KF.Integrations.MatchesFilter(ply, ra.filter.type, ra.filter.value) then
            if ply:GetKSPosition() ~= ra.position then squad:ChangePosition(ply, ra.position) end
            return
        end
    end
end

TryAutoAssign = function(ply)
    if not IsValid(ply) then return end
    local presets = KrakenSquad.GetConfig("presetSquads") or {}
    local current = ply:GetKSSquad()

    if current and current:IsPreset() then
        for _, preset in ipairs(presets) do
            if preset.autoAssign and preset.name == current:GetTitle() and preset.filters then
                if MatchesAnyFilter(ply, preset.filters) then
                    ApplyPresetRoles(ply, current, preset)
                    ApplyPresetComms(ply, preset)
                    return
                end
                current:RemoveMember(ply)
                break
            end
        end
    end

    if ply:KSInSquad() then return end
    for _, preset in ipairs(presets) do
        if preset.autoAssign and preset.filters and MatchesAnyFilter(ply, preset.filters) then
            for _, s in pairs(KrakenSquad.Cache) do
                if s:IsPreset() and s:GetTitle() == preset.name then
                    s:AddMember(ply)
                    ApplyPresetRoles(ply, s, preset)
                    ApplyPresetComms(ply, preset)
                    return
                end
            end
        end
    end
end

SyncSquadListTo = function(ply)
    local data = {}
    for _, s in pairs(KrakenSquad.Cache) do
        data[#data + 1] = {
            id = s:GetID(), name = s:GetTitle(),
            public = s:IsPublic(), preset = s:IsPreset(),
            members = s:GetMemberCount(),
        }
    end
    KF.Net.SendJSON("KS.RequestSquads", data, ply)

    for _, s in pairs(KrakenSquad.Cache) do
        local members = s:GetMembers()
        if #members > 0 then
            KF.Net.Send("KS.MembersUpdated", function()
                net.WriteUInt(s:GetID(), 16)
                net.WriteUInt(#members, 8)
                for _, m in ipairs(members) do
                    net.WriteUInt(math.max(m:UserID(), 0), 16)
                end
            end, ply)
        end
    end
end

hook.Add("PlayerInitialSpawn", "KrakenSquad.InitSpawn", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        KrakenSquad.SyncConfigToPlayer(ply)
        SyncSquadListTo(ply)
        KrakenSquad.SyncOrdersTo(ply)
        timer.Simple(0.5, function()
            if not IsValid(ply) then return end
            ply._KSLastTeam = ply:Team()
            TryAutoAssign(ply)
        end)
    end)
end)

local function HandleClassChange(ply)
    if not IsValid(ply) then return end
    ply._KSLastTeam = ply:Team()
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        TryAutoAssign(ply)
        KrakenSquad.RespawnHandleSquadChange(ply)
    end)
end

hook.Add("OnPlayerChangedTeam", "KrakenSquad.TeamChange",       HandleClassChange)
hook.Add("PlayerJoinedClass",   "KrakenSquad.HelixClassChange", HandleClassChange)
hook.Add("OnPlayerJoinClass",   "KrakenSquad.NutClassChange",   HandleClassChange)

hook.Add("OnCharVarChanged", "KrakenSquad.NutCharVar", function(character, key)
    if key ~= "faction" then return end
    HandleClassChange(character.getPlayer and character:getPlayer())
end)
