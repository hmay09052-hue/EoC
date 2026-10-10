FCR = FCR or {}
FCR.Util = FCR.Util or {}

local Util = FCR.Util
local C = FCR.Config

function Util.Round(num, decimals)
    local factor = 10 ^ (decimals or 0)
    return math.Round((num or 0) * factor) / factor
end

function Util.IsRepairTool(wep)
    if not IsValid(wep) then return false end
    local classes = C.ToolClasses or { ["ts_fusioncutter_repairer"] = true }
    return classes[wep:GetClass()] == true
end

function Util.IsLVSVehicle(ent)
    return IsValid(ent) and ent.LVS == true and isfunction(ent.GetHP)
end

function Util.IsLFSVehicle(ent)
    if not IsValid(ent) then return false end
    if ent.LFS == true and isfunction(ent.GetHP) then return true end

    local class = string.lower(ent:GetClass() or "")
    return string.StartWith(class, "lunasflightschool_") and isfunction(ent.GetHP)
end

function Util.IsSimfphysVehicle(ent)
    if not IsValid(ent) then return false end

    if simfphys and isfunction(simfphys.IsCar) then
        local ok, result = pcall(simfphys.IsCar, ent)
        if ok and result then return true end
    end

    return string.lower(ent:GetClass() or "") == "gmod_sent_vehicle_fphysics_base"
end

function Util.ResolveRepairEntity(ent)
    if not IsValid(ent) then return NULL end
    if Util.IsLVSVehicle(ent) or Util.IsLFSVehicle(ent) or Util.IsSimfphysVehicle(ent) then return ent end

    local seen = {}
    local queue = {ent}
    local idx = 1

    while queue[idx] do
        local cur = queue[idx]
        idx = idx + 1
        if not IsValid(cur) or seen[cur] then continue end
        seen[cur] = true

        if Util.IsLVSVehicle(cur) or Util.IsLFSVehicle(cur) or Util.IsSimfphysVehicle(cur) then
            return cur
        end

        if isfunction(cur.GetBaseEnt) then
            local ok, baseEnt = pcall(cur.GetBaseEnt, cur)
            if ok and IsValid(baseEnt) and not seen[baseEnt] then
                queue[#queue + 1] = baseEnt
            end
        end

        if IsValid(cur.SPHYSBaseEnt) and not seen[cur.SPHYSBaseEnt] then
            queue[#queue + 1] = cur.SPHYSBaseEnt
        end

        if isfunction(cur.GetParent) then
            local ok, parent = pcall(cur.GetParent, cur)
            if ok and IsValid(parent) and not seen[parent] then
                queue[#queue + 1] = parent
            end
        end
    end

    return IsValid(ent) and ent or NULL
end

function Util.GetVehicleBaseId(ent)
    ent = Util.ResolveRepairEntity(ent)
    if Util.IsLVSVehicle(ent) then return "LVS" end
    if Util.IsLFSVehicle(ent) then return "LFS" end
    if Util.IsSimfphysVehicle(ent) then return "SIMFPHYS" end
    return "VEHICLE"
end

function Util.GetVehicleMaxHealth(ent)
    ent = Util.ResolveRepairEntity(ent)
    if not IsValid(ent) then return 0 end

    if isfunction(ent.GetMaxHP) then
        local max = tonumber(ent:GetMaxHP()) or 0
        if max > 0 then return max end
    end

    if isfunction(ent.GetMaxHealth) then
        local max = tonumber(ent:GetMaxHealth()) or 0
        if max > 0 then return max end
    end

    if tonumber(ent.MaxHealth) and ent.MaxHealth > 0 then
        return tonumber(ent.MaxHealth) or 0
    end

    if tonumber(ent.StartHealth) and ent.StartHealth > 0 then
        return tonumber(ent.StartHealth) or 0
    end

    return 0
end

function Util.GetVehicleHealth(ent)
    ent = Util.ResolveRepairEntity(ent)
    if not IsValid(ent) then return 0, 0 end

    local current = 0
    if isfunction(ent.GetHP) then
        current = tonumber(ent:GetHP()) or 0
    elseif isfunction(ent.GetCurHealth) then
        current = tonumber(ent:GetCurHealth()) or 0
    elseif isfunction(ent.Health) then
        current = tonumber(ent:Health()) or 0
    end

    return math.max(0, current), math.max(0, Util.GetVehicleMaxHealth(ent))
end

function Util.SetVehicleHealth(ent, value)
    ent = Util.ResolveRepairEntity(ent)
    if not IsValid(ent) then return false end

    local max = Util.GetVehicleMaxHealth(ent)
    if max <= 0 then return false end

    value = math.Clamp(math.floor(value), 0, max)

    if isfunction(ent.SetHP) then
        ent:SetHP(value)
    elseif isfunction(ent.SetCurHealth) then
        ent:SetCurHealth(value)
    else
        return false
    end

    if isfunction(ent.SetOnFire) then
        ent:SetOnFire(false)
    end

    if isfunction(ent.SetOnSmoke) then
        ent:SetOnSmoke(false)
    end

    if Util.IsSimfphysVehicle(ent) then
        if value >= max then
            if isfunction(ent.OnRepaired) then
                pcall(ent.OnRepaired, ent)
            end
            if hook and isfunction(hook.Run) then
                hook.Run("simfphysOnRepaired", ent)
            end
            if istable(ent.Wheels) then
                for _, wheel in pairs(ent.Wheels) do
                    if IsValid(wheel) and isfunction(wheel.SetDamaged) then
                        wheel:SetDamaged(false)
                    end
                end
            end
        end
    end

    return true
end

function Util.IsSupportedVehicle(ent)
    ent = Util.ResolveRepairEntity(ent)
    return Util.IsLVSVehicle(ent) or Util.IsLFSVehicle(ent) or Util.IsSimfphysVehicle(ent)
end

function Util.IsRepairTarget(ent)
    ent = Util.ResolveRepairEntity(ent)
    if not Util.IsSupportedVehicle(ent) then return false end
    local current, max = Util.GetVehicleHealth(ent)
    return max > 0 and current < (max - 0.001)
end

function Util.GetVehicleLabel(ent)
    ent = Util.ResolveRepairEntity(ent)
    if not IsValid(ent) then return "NO TARGET" end

    if isstring(ent.PrintName) and ent.PrintName ~= "" then
        return string.upper(ent.PrintName)
    end

    if isfunction(ent.GetName) then
        local name = ent:GetName()
        if isstring(name) and name ~= "" then
            return string.upper(name)
        end
    end

    return string.upper(ent:GetClass())
end

local function getTraceBounds()
    local half = tonumber(C.TraceHullHalfSize) or 10
    half = math.max(0, half)
    return Vector(-half, -half, -half), Vector(half, half, half)
end

function Util.GetTargetTrace(ply, distance)
    distance = distance or C.RepairDistance
    local shootPos = ply:GetShootPos()
    local endPos = shootPos + ply:GetAimVector() * distance
    local mins, maxs = getTraceBounds()

    local hull = util.TraceHull({
        start = shootPos,
        endpos = endPos,
        mins = mins,
        maxs = maxs,
        filter = ply,
        mask = MASK_SHOT
    })

    if IsValid(hull.Entity) and hull.Entity ~= ply then
        return hull
    end

    return util.TraceLine({
        start = shootPos,
        endpos = endPos,
        filter = ply,
        mask = MASK_SHOT
    })
end

function Util.GetEntityInteractionPoint(ent, fromPos)
    if not IsValid(ent) then return nil end
    fromPos = fromPos or ent:GetPos()

    if C.UseNearestPointRange ~= false and isfunction(ent.NearestPoint) then
        local ok, point = pcall(ent.NearestPoint, ent, fromPos)
        if ok and isvector(point) then
            return point
        end
    end

    if isfunction(ent.WorldSpaceCenter) then
        local ok, point = pcall(ent.WorldSpaceCenter, ent)
        if ok and isvector(point) then
            return point
        end
    end

    return ent:GetPos()
end

function Util.GetRepairDistanceToEntity(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return math.huge, nil end
    local origin = ply:GetShootPos()
    local point = Util.GetEntityInteractionPoint(ent, origin)
    if not isvector(point) then
        return math.huge, nil
    end
    return origin:Distance(point), point
end

function Util.IsWithinRepairRange(ply, ent, distance, grace)
    local maxDist = (distance or C.RepairDistance) + (grace or C.RepairRangeGrace or 0)
    local dist, point = Util.GetRepairDistanceToEntity(ply, ent)
    return dist <= maxDist, dist, point, maxDist
end

function Util.HasJobAccess(ply)
    if not istable(C.AllowedJobs) or table.IsEmpty(C.AllowedJobs) then
        return true
    end

    if not DarkRP or not RPExtraTeams then
        return true
    end

    local teamData = RPExtraTeams[ply:Team()]
    if not teamData then return false end

    local command = string.lower(teamData.command or "")
    for _, allowed in ipairs(C.AllowedJobs) do
        if command == string.lower(allowed) then
            return true
        end
    end

    return false
end

function Util.HasUsergroupAccess(ply)
    if not istable(C.AllowedUsergroups) or table.IsEmpty(C.AllowedUsergroups) then
        return true
    end

    local group = string.lower(ply:GetUserGroup() or "")
    for _, allowed in ipairs(C.AllowedUsergroups) do
        if group == string.lower(allowed) then
            return true
        end
    end

    return false
end

function Util.CanPlayerUse(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false, "invalid_player" end
    if not C.AllowSpectators and not ply:Alive() then return false, "dead_player" end
    if not Util.HasUsergroupAccess(ply) then return false, "group_blocked" end
    if not Util.HasJobAccess(ply) then return false, "job_blocked" end
    return true
end

function Util.SessionStillValid(session)
    if not session then return false, "no_session" end
    if not IsValid(session.ply) or not session.ply:Alive() then return false, "player_invalid" end
    if not IsValid(session.vehicle) then return false, "vehicle_invalid" end
    if not Util.IsSupportedVehicle(session.vehicle) then return false, "target_invalid" end

    if C.CancelIfWeaponSwitched then
        local wep = session.ply:GetActiveWeapon()
        if not IsValid(wep) or wep ~= session.weapon then
            return false, "weapon_lost"
        end
    end

    local inRange = Util.IsWithinRepairRange(session.ply, session.vehicle, C.RepairDistance, C.RepairRangeGrace or 24)
    if not inRange then
        return false, "lost_distance"
    end

    if C.RequireAimLock then
        local tr = Util.GetTargetTrace(session.ply, (C.RepairDistance or 0) + (C.RepairRangeGrace or 24))
        local aimEnt = Util.ResolveRepairEntity(tr.Entity)
        if aimEnt ~= session.vehicle then
            return false, "target_invalid"
        end
    end

    local current, max = Util.GetVehicleHealth(session.vehicle)
    if max <= 0 then return false, "target_invalid" end
    if current >= max then return false, "already_repaired" end

    return true
end
