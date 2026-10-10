KrakenSquad.Cache = KrakenSquad.Cache or {}

local Squad = KrakenSquad.SquadObj or {}
Squad.__index = Squad
KrakenSquad.SquadObj = Squad

function Squad:GetID()         return self.id   or -1 end
function Squad:GetTitle()      return self.name or KrakenSquad.L("unknown_squad") end
function Squad:IsPublic()      return self.public or false end
function Squad:IsPreset()      return self.preset or false end
function Squad:GetMaxMembers()
    local max = self:IsUnitSquad() and KrakenSquad.GetConfig("unitSquadMaxMembers") or KrakenSquad.GetConfig("maxMembers")
    return math.Clamp(tonumber(max) or 100, 1, KrakenSquad.MAX_LENGTHS.maxMembers)
end

-- Einheits-Squad (SymChars): ID der Haupteinheit, sonst ""
function Squad:GetUnitID()
    if SERVER and self.unit then return self.unit end
    return GetGlobal2String("KS.SquadUnit_" .. self:GetID(), "")
end

function Squad:IsUnitSquad() return self:GetUnitID() ~= "" end

function Squad:GetMembers()
    local out = {}
    if SERVER then
        for _, p in ipairs(self._members or {}) do
            if IsValid(p) then out[#out + 1] = p end
        end
    else
        for _, uid in ipairs(self._memberUserIDs or {}) do
            local p = Player(uid)
            if IsValid(p) then out[#out + 1] = p end
        end
    end
    return out
end

function Squad:GetMemberCount() return #self:GetMembers() end

function Squad:GetOwner()
    for _, p in ipairs(self:GetMembers()) do
        if p:GetNWInt("KS.Position", -1) == 1 then return p end
    end
end

local PLAYER = FindMetaTable("Player")

function PLAYER:GetKSSquadID() return self:GetNWInt("KS.SquadID", -1) end

function PLAYER:GetKSSquad()
    return KrakenSquad.Cache[self:GetKSSquadID()]
end

function PLAYER:KSInSquad(id)
    local cur = self:GetKSSquadID()
    if cur == -1 then return false end
    return id == nil or id == cur
end

function PLAYER:GetKSPosition()
    local pos = self:GetNWInt("KS.Position", -1)
    local positions = KrakenSquad.GetPositions()
    if pos == -1 or pos > #positions then return #positions end
    return pos
end

function PLAYER:GetKSPositionData()
    local p = KrakenSquad.GetPositions()
    return p[self:GetKSPosition()] or p[#p]
end

-- Squadführer: Rolle mit "Ist Offizier" ODER Rolle 1 (auch wenn die Rolle in der Config anders heißt,
-- z.B. "Truppführer" ohne Offiziers-Haken)
function PLAYER:KSIsLeader()
    if not self:KSInSquad() then return false end
    if self:GetNWInt("KS.Position", -1) == 1 then return true end
    local d = self:GetKSPositionData()
    return d and d.isOfficer == true
end

function KrakenSquad.GetSquad(id) return KrakenSquad.Cache[id] end
