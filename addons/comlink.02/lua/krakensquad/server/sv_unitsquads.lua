--[[-------------------------------------------------------------------------------------------------------------
    Einheits-Squads (SymChars)
    Jede Haupteinheit bekommt automatisch einen Squad mit ihrem Namen. Jeder Spieler, dessen aktiver Charakter
    in der Einheit oder einer ihrer Untereinheiten ist, kommt automatisch hinein (bis zu 100 Personen).
    Squadführer wird, wer in seiner Einheit eines der Rechte aus "unitSquadLeaderFlags" hat (Standard: Befördern,
    also ab Sergeant bzw. Einheitsleitung). Wer einen eigenen Squad erstellt oder einem beitritt, verlässt den
    Einheits-Squad dafür; verlässt er den eigenen Squad wieder, kommt er automatisch zurück.
    Ausschalten: Config "unitSquads" = false.
-------------------------------------------------------------------------------------------------------------]]

KrakenSquad.UnitSquads = KrakenSquad.UnitSquads or {}

local function Enabled()
    return KrakenSquad.GetConfig("unitSquads") ~= false and symchars ~= nil and symchars.factions ~= nil
end

local function CharOf(ply)
    if not ply.GetCharacter then return end
    local ok, char = pcall(ply.GetCharacter, ply)
    if ok then return char end
end

local function RootOf(char)
    local faction = char and char.GetFaction and char:GetFaction()
    if not faction then return end
    return faction.GetRoot and faction:GetRoot() or faction, faction
end

local function IsUnitLeader(char, faction)
    local A = symchars.authority
    for _, flag in ipairs(KrakenSquad.GetConfig("unitSquadLeaderFlags") or {}) do
        if A and A.HasFlag then
            if A.HasFlag(char, faction:GetID(), flag) then return true end
        elseif char.HasRankFlag and (char:HasRankFlag(flag) or char:HasRankFlag("admin")) then
            return true
        end
    end
    return false
end

local function GetUnitSquad(root)
    local id = root:GetID()
    local squad = KrakenSquad.UnitSquads[id]
    if squad and KrakenSquad.Cache[squad:GetID()] == squad then return squad end

    squad = KrakenSquad.CreateSquadInternal(root:GetName(), false, true)
    squad.unit = id
    SetGlobal2String("KS.SquadUnit_" .. squad:GetID(), id)
    KrakenSquad.UnitSquads[id] = squad
    return squad
end

-- Einheits-Squad eines Spielers (oder nil)
function KrakenSquad.UnitSquadOf(ply)
    if not Enabled() then return end
    local root = RootOf(CharOf(ply))
    return root and GetUnitSquad(root) or nil
end

function KrakenSquad.SyncUnitSquad(ply)
    if not Enabled() or not IsValid(ply) or not ply:IsPlayer() then return end

    local char = CharOf(ply)
    local root, faction = RootOf(char)
    local cur = ply:GetKSSquad()

    if not root then
        if cur and cur:IsUnitSquad() then cur:RemoveMember(ply) end
        return
    end

    local target = GetUnitSquad(root)

    -- selbst ausgetreten: draußen lassen, bis der Charakter wechselt oder er wieder beitritt
    if ply._ksUnitOptOut ~= nil and not cur then
        local charID = ply.GetCharacterID and ply:GetCharacterID() or true
        if ply._ksUnitOptOut == charID then return end
        ply._ksUnitOptOut = nil
    end

    if cur ~= target then
        if cur and not cur:IsUnitSquad() then return end -- ist in einem anderen Squad
        if cur then cur:RemoveMember(ply) end
        if target:GetMemberCount() >= target:GetMaxMembers() then return end
        target:AddMember(ply)
        ply._ksUnitLeader = nil
    end

    if not ply:KSInSquad(target:GetID()) then return end

    local leader = IsUnitLeader(char, faction)
    local pos = ply:GetNWInt("KS.Position", -1)

    if leader and pos ~= 1 then
        ply._ksUnitLeader = true
        target:ChangePosition(ply, 1)
    elseif not leader and pos == 1 then
        ply._ksUnitLeader = nil
        target:ChangePosition(ply, #KrakenSquad.GetPositions())
    end
end

function KrakenSquad.SyncAllUnitSquads()
    if not Enabled() then return end
    for _, ply in ipairs(player.GetAll()) do
        local ok, err = pcall(KrakenSquad.SyncUnitSquad, ply)
        if not ok then ErrorNoHalt("[KrakenSquad] Einheits-Squad (" .. tostring(ply) .. "): " .. tostring(err) .. "\n") end
    end
end

-- Regelmäßig abgleichen (Einheit/Rang/Charakter gewechselt, eigenen Squad verlassen ...)
timer.Create("KrakenSquad.UnitSquads", 3, 0, KrakenSquad.SyncAllUnitSquads)

local function Soon(ply)
    timer.Simple(1, function()
        if IsValid(ply) then KrakenSquad.SyncUnitSquad(ply) end
    end)
end

hook.Add("symchars_selectedcharacter", "KrakenSquad.UnitSquads", Soon)
hook.Add("PlayerSpawn", "KrakenSquad.UnitSquads", Soon)

-- Eigener Squad aufgelöst/verlassen -> der Timer oben holt den Spieler zurück in den Einheits-Squad
