local CONFIG_PATH = "krakensquad/config.json"

function KrakenSquad.SaveConfig()
    if not file.IsDir("krakensquad", "DATA") then file.CreateDir("krakensquad") end
    file.Write(CONFIG_PATH, util.TableToJSON(KrakenSquad.Config, true))
end

function KrakenSquad.LoadConfig()
    if not file.IsDir("krakensquad", "DATA") then file.CreateDir("krakensquad") end
    if not file.Exists(CONFIG_PATH, "DATA") then
        KrakenSquad.Config = {}
        KrakenSquad.SaveConfig()
        return
    end
    KrakenSquad.Config = util.JSONToTable(file.Read(CONFIG_PATH, "DATA")) or {}

    -- Umstieg: System einmalig auf Deutsch stellen
    if not KrakenSquad.Config._langDe then
        KrakenSquad.Config._langDe = true
        KrakenSquad.Config.language = "de"
        KrakenSquad.SaveConfig()
    end

    -- Umstieg: altes Limit (8 bzw. max. 20) einmalig auf 100 anheben
    if not KrakenSquad.Config._limit100 then
        KrakenSquad.Config._limit100 = true
        if tonumber(KrakenSquad.Config.maxMembers or 0) < 100 then KrakenSquad.Config.maxMembers = nil end
        KrakenSquad.SaveConfig()
    end
end

function KrakenSquad.SyncConfigToPlayer(ply)
    KF.Net.SendJSON("KS.AdminConfigSync", KrakenSquad.Config, ply)
end

function KrakenSquad.SyncConfigToAll()
    KF.Net.SendJSON("KS.AdminConfigSync", KrakenSquad.Config)
end

KrakenSquad.LoadConfig()

local Squad = KrakenSquad.SquadObj
local nextSquadID = 1

function KrakenSquad.CreateSquadInternal(name, isPublic, isPreset)
    local id = nextSquadID
    nextSquadID = nextSquadID + 1
    local squad = setmetatable({
        id = id, name = name,
        public = isPublic or false, preset = isPreset or false,
        _members = {},
    }, Squad)
    KrakenSquad.Cache[id] = squad
    KF.Net.Broadcast("KS.SquadCreated", function()
        net.WriteUInt(id, 16)
        net.WriteString(name)
        net.WriteBool(squad.public)
        net.WriteBool(squad.preset)
    end)
    return squad
end

function KrakenSquad.CreateSquad(name, leader, isPublic)
    local squad = KrakenSquad.CreateSquadInternal(name, isPublic, false)
    squad:AddMember(leader)
    squad:ChangePosition(leader, 1)
    KrakenSquad.Notify(leader, "success", KrakenSquad.L("squad_created"))
    return squad
end

local function SyncMembers(squad)
    local members = squad:GetMembers()
    if #members == 0 then return end
    KF.Net.Send("KS.MembersUpdated", function()
        net.WriteUInt(squad:GetID(), 16)
        net.WriteUInt(#members, 8)
        for _, m in ipairs(members) do
            net.WriteUInt(math.max(m:UserID(), 0), 16)
        end
    end, members)
end

function Squad:AddMember(ply)
    if not IsValid(ply) or ply:KSInSquad() then return self end
    if self:GetMemberCount() >= self:GetMaxMembers() then return self end

    ply:SetNWInt("KS.SquadID", self:GetID())
    ply:SetNWInt("KS.Position", #KrakenSquad.GetPositions())
    table.insert(self._members, ply)

    SyncMembers(self)
    -- Einheits-Squads: kein Chat-Spam bei jedem Beitritt (bis zu 100 Leute)
    if not self:IsUnitSquad() then
        self:BroadcastMsg(KrakenSquad.L("player_joined", KF.Integrations.GetPlayerName(ply)), "member_event")
        KrakenSquad.Notify(ply, "success", KrakenSquad.L("joined_squad", self:GetTitle()))
    end
    return self
end

function Squad:RemoveMember(ply)
    if not ply:KSInSquad(self:GetID()) then return self end
    local wasLeader = ply:KSIsLeader()

    if not self:IsUnitSquad() then
        self:BroadcastMsg(KrakenSquad.L("player_left", KF.Integrations.GetPlayerName(ply)), "member_event")
    end
    ply:SetNWInt("KS.SquadID",  -1)
    ply:SetNWInt("KS.Position", -1)

    for i = #self._members, 1, -1 do
        if self._members[i] == ply then table.remove(self._members, i) break end
    end

    if #self._members == 0 and not self:IsPreset() then
        self:Remove()
        return self
    end

    SyncMembers(self)
    -- Im Einheits-Squad bestimmt der SymChars-Rang den Squadführer, nicht die Reihenfolge
    if wasLeader and not self:IsUnitSquad() then
        local m = self:GetMembers()
        if m[1] then self:ChangePosition(m[1], 1) end
    end
    return self
end

function Squad:ChangePosition(ply, pos)
    ply:SetNWInt("KS.Position", pos)
    local data = KrakenSquad.GetPositions()[pos]
    if data and not self:IsUnitSquad() then
        self:BroadcastMsg(KrakenSquad.L("position_changed",
            KF.Integrations.GetPlayerName(ply), data.name), "member_event")
    end
    return self
end

function Squad:Remove()
    local id = self:GetID()
    for _, p in ipairs(self:GetMembers()) do
        p:SetNWInt("KS.SquadID",  -1)
        p:SetNWInt("KS.Position", -1)
    end
    self._members = {}
    self:BroadcastMsg(KrakenSquad.L("squad_removed"))
    KF.Net.Broadcast("KS.SquadRemoved", function() net.WriteUInt(id, 16) end)
    if self.unit then
        SetGlobal2String("KS.SquadUnit_" .. id, "")
        if KrakenSquad.UnitSquads then KrakenSquad.UnitSquads[self.unit] = nil end
    end
    KrakenSquad.Cache[id] = nil
    KrakenSquad._SquadMarks[id] = nil
end

function Squad:BroadcastMsg(msg, msgType)
    local members = self:GetMembers()
    if #members == 0 then return end
    KF.Net.Send("KS.Broadcast", function()
        net.WriteUInt(self:GetID(), 16)
        net.WriteString(msg)
        net.WriteString(msgType or "")
    end, members)
end

function KrakenSquad.Notify(ply, ntype, msg)
    if not IsValid(ply) then return end
    if BF2HUD and BF2HUD.Notify then
        BF2HUD.Notify(ntype, "Squads", msg, ply)
    elseif DarkRP and ply.PrintMessage then
        ply:PrintMessage(HUD_PRINTTALK, KrakenSquad.L("chat_prefix") .. msg)
    else
        ply:ChatPrint(KrakenSquad.L("chat_prefix") .. msg)
    end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:KSInviteToSquad(inviter)
    local squad = inviter:GetKSSquad()
    if not squad or not inviter:KSIsLeader() then return end
    if squad:IsUnitSquad() then return end -- in den Einheits-Squad kommt man über die Einheit
    if self:GetKSSquad() == squad then return end
    if self:GetNWInt("KS.InvitedTo", -1) ~= -1 then
        KrakenSquad.Notify(inviter, "warning", KrakenSquad.L("invite_pending", self:Nick()))
        return
    end
    self:SetNWInt("KS.InvitedTo", squad:GetID())
    KF.Net.Send("KS.InvitePlayer", function()
        net.WriteEntity(inviter)
        net.WriteString(squad:GetTitle())
    end, self)
    KrakenSquad.Notify(inviter, "success", KrakenSquad.L("invite_sent", self:Nick()))
end

KrakenSquad._SquadMarks = KrakenSquad._SquadMarks or {}

function PLAYER:KSCommunicate(commID)
    local squad = self:GetKSSquad()
    if not squad then return end
    local data = KrakenSquad.GetCommunicationByID(commID)
    if not data then return end

    squad:BroadcastMsg(KrakenSquad.FormatText(KrakenSquad.ChatText(data), self))
    local members = squad:GetMembers()

    if data.triggerPing then
        local pd = self:GetKSPositionData()
        local eyeEnt = self:GetEyeTrace().Entity
        if pd and pd.isMarksman and IsValid(eyeEnt) then
            local marks = KrakenSquad._SquadMarks[squad:GetID()] or {}
            KrakenSquad._SquadMarks[squad:GetID()] = marks
            local idx = eyeEnt:EntIndex()
            if not marks[idx] or marks[idx] <= CurTime() then
                marks[idx] = CurTime() + 60
                KF.Net.Send("KS.MarkSync", function()
                    net.WriteEntity(eyeEnt)
                    net.WriteString(data.triggerPing == "enemy" and "enemy" or "mark")
                    net.WriteString(KrakenSquad.GetEntityDisplayName(eyeEnt))
                    net.WriteEntity(self)
                end, members)
            end
        else
            self:KSPing(data.triggerPing)
        end
    end

    KF.Net.Send("KS.Communications", function()
        net.WriteString(commID)
        net.WriteEntity(self)
    end, members)

    for _, m in ipairs(members) do
        if m == self then continue end
        local pd = m:GetKSPositionData()
        if not pd or not pd.isMedic then continue end
        for _, cid in ipairs(pd.medicComms or {}) do
            if cid == commID then
                KF.Net.Send("KS.MedicAlert", function()
                    net.WriteEntity(self)
                    net.WriteUInt(math.max(self:Health(), 0), 16)
                    net.WriteUInt(math.max(self:GetMaxHealth(), 1), 16)
                end, m)
                break
            end
        end
    end
end

function PLAYER:KSPing(pingType)
    local squad = self:GetKSSquad()
    if not squad then return end
    KF.Net.Send("KS.CommsPing", function()
        net.WriteVector(self:GetEyeTrace().HitPos)
        net.WriteEntity(self)
        net.WriteString(pingType or "normal")
    end, squad:GetMembers())
end

function PLAYER:KSCommand(cmdID)
    local squad = self:GetKSSquad()
    if not squad or not self:KSIsLeader() then return end
    local data = KrakenSquad.GetCommandByID(cmdID)
    if not data then return end
    squad:BroadcastMsg(KrakenSquad.FormatText(KrakenSquad.ChatText(data), self))
    KF.Net.Send("KS.RequestCommand", function()
        net.WriteString(cmdID)
        net.WriteEntity(self)
    end, squad:GetMembers())
end

hook.Add("PlayerDisconnected", "KrakenSquad.Disconnect", function(ply)
    local squad = ply:GetKSSquad()
    if squad then squad:RemoveMember(ply) end
end)

hook.Add("PlayerSay", "KrakenSquad.ChatCommands", function(ply, text)
    if not KrakenSquad.Net.CheckRate(ply, "chat_cmd") then return end
    local cmds  = KrakenSquad.GetConfig("chatCommands")
    local lower = text:Trim():lower()

    if lower == cmds.create:lower() then
        if ply:KSInSquad() then
            KrakenSquad.Notify(ply, "warning", KrakenSquad.L("already_in_squad"))
        else
            KF.Net.Send("KS.NPCCreator", nil, ply)
        end
        return ""
    end

    if lower == cmds.squads:lower() then
        KF.Net.Send("KS.OpenPublicList", nil, ply)
        return ""
    end

    if lower == cmds.admin:lower() then
        if KrakenSquad.IsAdmin(ply) then KF.Net.Send("KS.OpenAdminMenu", nil, ply) end
        return ""
    end

    local kick = cmds.kick:lower()
    if lower == kick or lower:sub(1, #kick + 1) == kick .. " " then
        if not ply:KSIsLeader() then
            KrakenSquad.Notify(ply, "warning", KrakenSquad.L("kick_not_leader"))
            return ""
        end
        local target = text:sub(#cmds.kick + 2):Trim()
        if target == "" then
            KrakenSquad.Notify(ply, "info", KrakenSquad.L("kick_usage"):format(cmds.kick))
            return ""
        end
        local squad = ply:GetKSSquad()
        if not squad then return "" end
        local lt = target:lower()
        for _, t in ipairs(squad:GetMembers()) do
            if t ~= ply and t:Nick():lower():find(lt, 1, true) then
                squad:RemoveMember(t)
                KrakenSquad.Notify(ply, "success", KrakenSquad.L("kick_success"):format(t:Nick()))
                return ""
            end
        end
        KrakenSquad.Notify(ply, "warning", KrakenSquad.L("kick_not_found"))
        return ""
    end

    local invite = cmds.invite:lower()
    if lower:sub(1, #invite + 1) == invite .. " " then
        if not ply:KSIsLeader() then return "" end
        local target = text:sub(#cmds.invite + 2):Trim()
        if target == "" then return "" end
        local lt = target:lower()
        for _, t in ipairs(player.GetAll()) do
            if t ~= ply and (not t:KSInSquad() or t:GetKSSquad():IsUnitSquad()) and t:Nick():lower():find(lt, 1, true) then
                t:KSInviteToSquad(ply)
                return ""
            end
        end
        return ""
    end
end)

function KrakenSquad.ApplyFFHook()
    if KrakenSquad.GetConfig("blockDamage") then
        hook.Add("PlayerShouldTakeDamage", "KrakenSquad.FF", function(victim, attacker)
            if not (IsValid(attacker) and attacker:IsPlayer()) then return end
            local squad = victim:GetKSSquad()
            if squad and squad == attacker:GetKSSquad() then return false end
        end)
    else
        hook.Remove("PlayerShouldTakeDamage", "KrakenSquad.FF")
    end
end
KrakenSquad.ApplyFFHook()

hook.Add("InitPostEntity", "KrakenSquad.Init", function()
    timer.Simple(2, function()
        for _, p in ipairs(KrakenSquad.GetConfig("presetSquads") or {}) do
            KrakenSquad.CreateSquadInternal(p.name, p.public or false, true)
        end
        KrakenSquad.LoadNPCs()
    end)
end)
