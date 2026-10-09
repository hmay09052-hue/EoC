local C = EOCDroids.Config

util.AddNetworkString("EOCDroids.Message")
util.AddNetworkString("EOCDroids.AquaZap")

-- ============================================================
-- NACHRICHTEN (ersetzt SummeLibrary:Chat / :Notify)
-- ============================================================
function EOCDroids.Message(target, text, kind)
    net.Start("EOCDroids.Message")
    net.WriteString(text)
    net.WriteUInt(kind or 0, 2) -- 0 = Info, 1 = Erfolg, 2 = Warnung
    if target == nil then
        net.Broadcast()
    else
        net.Send(target)
    end
end

function EOCDroids.MessageAdmins(text, kind)
    local admins = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsAdmin() then admins[#admins + 1] = ply end
    end
    if #admins > 0 then EOCDroids.Message(admins, text, kind) end
end

-- ============================================================
-- REGISTER ALLER AKTIVEN DROIDEN (statt teurer ents.FindInSphere-Suchen)
-- ============================================================
EOCDroids.Active = EOCDroids.Active or {}

function EOCDroids.Register(ent)
    EOCDroids.Active[ent] = true
end

function EOCDroids.Unregister(ent)
    EOCDroids.Active[ent] = nil
end

function EOCDroids.Count()
    local count = 0
    for ent in pairs(EOCDroids.Active) do
        if IsValid(ent) then
            count = count + 1
        else
            EOCDroids.Active[ent] = nil
        end
    end
    return count
end

-- Ruft fn fuer jeden Droiden im Radius auf
function EOCDroids.ForEachNear(pos, radius, fn)
    local radiusSqr = radius * radius
    for ent in pairs(EOCDroids.Active) do
        if not IsValid(ent) then
            EOCDroids.Active[ent] = nil
        elseif ent:GetPos():DistToSqr(pos) <= radiusSqr then
            fn(ent)
        end
    end
end

-- Teilt ein Ziel mit Verbuendeten in der Naehe (Trupp-Verhalten)
function EOCDroids.AlertAllies(source, enemy, radius)
    if not IsValid(enemy) then return end
    EOCDroids.ForEachNear(source:GetPos(), radius or C.AlertRadius, function(droid)
        if droid == source or droid:HasEnemy() then return end
        if not droid:IsValidTarget(enemy) then return end
        droid:SetEnemy(enemy)
        droid.LastSeenTime = CurTime()
        droid.LastKnownPos = enemy:GetPos()
    end)
end

-- ============================================================
-- NPC-ZIELE (globaler Cache, einmal pro Sekunde statt pro Droide)
-- ============================================================
EOCDroids.NPCTargets = {}

timer.Create("EOCDroids.NPCTargetCache", 1, 0, function()
    local list = {}
    if C.TargetNPCs and next(EOCDroids.Active) ~= nil then
        for _, ent in ipairs(ents.GetAll()) do
            if (ent:IsNPC() or ent:IsNextBot()) and not ent.IsEOCDroid and ent:Health() > 0
                and not C.FriendlyNPCClasses[ent:GetClass()] then
                list[#list + 1] = ent
            end
        end
    end
    EOCDroids.NPCTargets = list
end)

-- ============================================================
-- SPRACHAUSGABE-LIMIT (verhindert Sound-Spam bei grossen Schlachten)
-- ============================================================
local voiceSecond, voiceCount = 0, 0

function EOCDroids.TakeVoiceSlot()
    local now = math.floor(CurTime())
    if now ~= voiceSecond then
        voiceSecond, voiceCount = now, 0
    end
    if voiceCount >= C.GlobalVoicesPerSecond then return false end
    voiceCount = voiceCount + 1
    return true
end

-- ============================================================
-- SCHADEN
-- ============================================================
hook.Add("EntityTakeDamage", "EOCDroids.Damage", function(target, dmg)
    if not target.IsEOCDroid then return end

    if not C.FriendlyFire then
        local attacker, inflictor = dmg:GetAttacker(), dmg:GetInflictor()
        if IsValid(attacker) and attacker.IsEOCDroid then return true end
        if IsValid(inflictor) and inflictor.EOCDroidProjectile then return true end
    end

    if target.ScaleIncomingDamage then
        target:ScaleIncomingDamage(dmg)
    end

    if dmg:GetDamage() <= 0 then return true end
end)

-- Droiden-Waffen liegen nicht als Entity herum, aber zur Sicherheit:
hook.Add("PlayerCanPickupWeapon", "EOCDroids.NoPickup", function(ply, wep)
    if wep.IsEOCDroidWeapon then return false end
end)

-- Gepackte Spieler beim Tod freigeben
hook.Add("PlayerDeath", "EOCDroids.ReleaseGrab", function(ply)
    local grabber = ply:GetNW2Entity("EOCGrabber")
    if IsValid(grabber) and grabber.ReleaseGrab then
        grabber:ReleaseGrab(false)
    end
    ply:SetNW2Entity("EOCGrabber", NULL)
end)

hook.Add("PlayerSpawn", "EOCDroids.ResetGrab", function(ply)
    ply:SetNW2Entity("EOCGrabber", NULL)
end)

-- ============================================================
-- NAVMESH
-- ============================================================
function EOCDroids.HasNavmesh()
    return navmesh.IsLoaded()
end

hook.Add("InitPostEntity", "EOCDroids.NavmeshCheck", function()
    timer.Simple(10, function()
        if navmesh.IsLoaded() then
            MsgC(Color(80, 255, 80), "[EoC Droids] ", color_white, "Navmesh gefunden, Droiden koennen laufen.\n")
        else
            MsgC(Color(255, 170, 0), "[EoC Droids] ", color_white, "Kein Navmesh fuer " .. game.GetMap() .. ". Droiden laufen direkt auf Ziele zu (nav_generate empfohlen).\n")
        end
    end)
end)

-- ============================================================
-- TOOLS: Warteschlange aus den Client-ConVars des Tools bauen
-- ============================================================
function EOCDroids.BuildQueue(tool, prefix)
    local queue = {}

    for _, entry in ipairs(C.Spawnlist) do
        local count = math.Clamp(math.floor(tool:GetClientNumber(prefix .. entry.key, 0)), 0, C.MaxPerType)
        for _ = 1, count do
            if #queue >= C.MaxPerDeployer then break end
            queue[#queue + 1] = entry.class
        end
    end

    -- mischen, damit die Typen gemischt aussteigen
    for i = #queue, 2, -1 do
        local j = math.random(i)
        queue[i], queue[j] = queue[j], queue[i]
    end

    return queue
end

local toolCooldown = {}

function EOCDroids.CheckToolUse(ply)
    if not C.CanUseTools(ply) then
        EOCDroids.Message(ply, "Du darfst dieses Tool nicht benutzen.", 2)
        return false
    end
    if (toolCooldown[ply] or 0) > CurTime() then return false end
    toolCooldown[ply] = CurTime() + 1
    return true
end

-- ============================================================
-- KONSOLENBEFEHLE
-- ============================================================
concommand.Add("eoc_droids_clear", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end

    local removed = 0
    for ent in pairs(EOCDroids.Active) do
        if IsValid(ent) then
            ent:Remove()
            removed = removed + 1
        end
    end
    for _, ent in ipairs(ents.FindByClass("eoc_droid_*")) do
        ent:Remove()
    end
    EOCDroids.Active = {}

    local text = removed .. " Droiden entfernt."
    if IsValid(ply) then EOCDroids.Message(ply, text, 1) else print("[EoC Droids] " .. text) end
end)

concommand.Add("eoc_droids_count", function(ply)
    local text = "Aktive Droiden: " .. EOCDroids.Count() .. " / " .. C.MaxDroids
    if IsValid(ply) then EOCDroids.Message(ply, text, 0) else print("[EoC Droids] " .. text) end
end)
