GRN_NAVY = GRN_NAVY or {}
local GN = GRN_NAVY

GN.Net = {
    OpenMenu = "GRN_Navy_OpenMenu",
    OpenWhitelist = "GRN_Navy_OpenWhitelist",
    SubmitWhitelist = "GRN_Navy_SubmitWhitelist",
    RequestState = "GRN_Navy_RequestState",
    PushState = "GRN_Navy_PushState",
    ToggleRTS = "GRN_Navy_ToggleRTS",
    Action = "GRN_Navy_Action",
    OrderMove = "GRN_Navy_OrderMove",
    Bombard = "GRN_Navy_Bombard",
}

function GN:IsDarkRP()
    return istable(RPExtraTeams)
end

function GN:IsStaff(ply)
    if not IsValid(ply) then return false end
    local cfg = self.Config and self.Config.StaffGroups or {}
    return cfg[string.lower(ply:GetUserGroup() or "")] or cfg[ply:GetUserGroup() or ""] or false
end

function GN:GetJobs()
    local jobs = {}
    if istable(RPExtraTeams) then
        for teamID, data in pairs(RPExtraTeams) do
            jobs[#jobs + 1] = {
                team = teamID,
                command = data.command or ("team_" .. tostring(teamID)),
                name = data.name or team.GetName(teamID) or ("Team " .. tostring(teamID))
            }
        end
    else
        for teamID, data in pairs(team.GetAllTeams()) do
            if teamID ~= TEAM_CONNECTING and data and data.Name then
                jobs[#jobs + 1] = {
                    team = teamID,
                    command = "team_" .. tostring(teamID),
                    name = data.Name
                }
            end
        end
    end
    table.sort(jobs, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    return jobs
end

function GN:GetPlayerJobCommand(ply)
    if not IsValid(ply) then return nil end
    local tid = ply:Team()
    if istable(RPExtraTeams) and RPExtraTeams[tid] then
        return RPExtraTeams[tid].command or ("team_" .. tostring(tid))
    end
    return "team_" .. tostring(tid)
end

function GN:FindDef(list, id)
    for _, def in ipairs(list or {}) do
        if def.id == id then return def end
    end
end

function GN:GetCapitalDef(teamKey, id)
    return self:FindDef(self.Config.CapitalShips[teamKey] or {}, id)
end
function GN:GetFighterDef(teamKey, id)
    return self:FindDef(self.Config.Fighters[teamKey] or {}, id)
end
function GN:GetSupplyDef(teamKey, id)
    return self:FindDef(self.Config.Supplies[teamKey] or {}, id)
end
function GN:GetEscapePodDef(teamKey, id)
    return self:FindDef(self.Config.EscapePods[teamKey] or {}, id)
end

function GN:IsCapitalShip(ent)
    return IsValid(ent) and ent.GRN_NavyCapital == true
end

function GN:IsRTSAllowed(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false, "Jugador invalido" end
    local jobCmd = self:GetPlayerJobCommand(ply)
    local wl = self.Whitelist and self.Whitelist[jobCmd]
    if not wl or not wl.enabled then
        return false, "Tu trabajo no esta habilitado para el Navy RTS"
    end
    return true, wl.team
end
