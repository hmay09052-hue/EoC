GRNArcCW = GRNArcCW or {}
local M = GRNArcCW
local C = M.Config
local L = C.ShotLog or {}

-- =========================================================
-- Schusslog für ArcCW-Waffen
-- Schüsse und Treffer werden pro Spieler und Waffe gesammelt und alle
-- L.FlushInterval Sekunden als eine Zeile geschrieben, Kills sofort.
-- Dateien: data/eoc_arccw/schusslog_JJJJ-MM-TT.txt
-- Admins: Konsole "eoc_schusslog [Name/SteamID]" oder Chat "!schusslog".
-- =========================================================
if L.Enabled == false then return end

local DIR = "eoc_arccw"
file.CreateDir(DIR)

M.ShotBuffer = M.ShotBuffer or {}   -- [sid64 .. "|" .. class] = { ... }
M.ShotRecent = M.ShotRecent or {}   -- letzte Zeilen für die Admin-Ausgabe

local function logFile()
    return DIR .. "/schusslog_" .. os.date("%Y-%m-%d") .. ".txt"
end

local function write(line)
    line = os.date("%H:%M:%S") .. "  " .. line
    file.Append(logFile(), line .. "\n")
    table.insert(M.ShotRecent, line)
    local max = L.RecentLines or 300
    while #M.ShotRecent > max do table.remove(M.ShotRecent, 1) end
    if L.PrintToConsole then print("[Schusslog] " .. line) end
end

local function who(ply)
    if not IsValid(ply) then return "?" end
    if not ply:IsPlayer() then return ply:GetClass() end
    return string.format("%s (%s)", ply:Nick(), ply:SteamID())
end

local function bucket(ply, wep)
    local key = ply:SteamID64() .. "|" .. wep:GetClass()
    local b = M.ShotBuffer[key]
    if not b then
        b = { ply = ply, class = wep:GetClass(), shots = 0, hits = 0, damage = 0, headshots = 0, since = os.time() }
        M.ShotBuffer[key] = b
    end
    return b
end

local function arccwWeapon(ent)
    if not IsValid(ent) or not ent:IsPlayer() then return nil end
    local wep = ent:GetActiveWeapon()
    if IsValid(wep) and wep.ArcCW then return wep end
end

-- Jeder Schuss (ArcCW ruft "Hook_PostFireBullets" auch als globalen Hook).
hook.Add("Hook_PostFireBullets", "EOCArcCW_ShotLog", function(wep)
    local owner = IsValid(wep) and wep:GetOwner()
    if not IsValid(owner) or not owner:IsPlayer() then return end
    local b = bucket(owner, wep)
    b.shots = b.shots + 1
end)

-- Treffer und Schaden
hook.Add("PostEntityTakeDamage", "EOCArcCW_ShotLog", function(target, dmg, took)
    if not took then return end
    local attacker = dmg:GetAttacker()
    local wep = arccwWeapon(attacker)
    if not wep or target == attacker then return end
    local b = bucket(attacker, wep)
    b.hits = b.hits + 1
    b.damage = b.damage + dmg:GetDamage()
    if target:IsPlayer() and target:LastHitGroup() == HITGROUP_HEAD then b.headshots = b.headshots + 1 end
end)

local function victimName(v)
    if v:IsPlayer() then return who(v) end
    local npc = list.Get("NPC")[v:GetClass()]
    return (npc and npc.Name) or v:GetClass()
end

local function logKill(victim, attacker)
    local wep = arccwWeapon(attacker)
    if not wep or victim == attacker then return end
    local dist = attacker:GetPos():Distance(victim:GetPos()) / 52.49
    local tk = victim:IsPlayer() and victim:Team() == attacker:Team()
    write(string.format("KILL%s  %s  ->  %s  |  %s  |  %d m",
        tk and " (TEAMKILL)" or "", who(attacker), victimName(victim), wep:GetClass(), math.Round(dist)))
end

hook.Add("PlayerDeath", "EOCArcCW_ShotLog", function(victim, _, attacker) logKill(victim, attacker) end)
hook.Add("OnNPCKilled", "EOCArcCW_ShotLog", function(npc, attacker) logKill(npc, attacker) end)

-- Gesammelte Schüsse schreiben
function M.FlushShotLog()
    for key, b in pairs(M.ShotBuffer) do
        if b.shots > 0 or b.hits > 0 then
            local acc = b.shots > 0 and math.Round(math.min(b.hits, b.shots) / b.shots * 100) or 0
            write(string.format("SCHUSS  %s  |  %s  |  %d Schuss, %d Treffer (%d %%), %d Kopf, %d Schaden",
                IsValid(b.ply) and who(b.ply) or "offline", b.class, b.shots, b.hits, acc, b.headshots, math.Round(b.damage)))
        end
        M.ShotBuffer[key] = nil
    end
end

timer.Create("EOCArcCW_ShotLogFlush", L.FlushInterval or 30, 0, M.FlushShotLog)
hook.Add("PlayerDisconnected", "EOCArcCW_ShotLog", function() timer.Simple(0, M.FlushShotLog) end)
hook.Add("ShutDown", "EOCArcCW_ShotLog", M.FlushShotLog)

-- Aufsätze an- und abbauen ebenfalls protokollieren
if L.LogAttachments ~= false then
    hook.Add("ArcCW_PlayerCanAttach", "EOCArcCW_ShotLogAtt", function(ply, wep, attName, slot, detach)
        if not SERVER or not IsValid(ply) or not IsValid(wep) then return end
        if detach == true then
            write(string.format("AUFSATZ AB  %s  |  %s  |  %s", who(ply), wep:GetClass(), tostring(attName)))
        elseif not isstring(detach) and M.IsAllowed(attName, ply) then
            write(string.format("AUFSATZ AN  %s  |  %s  |  %s", who(ply), wep:GetClass(), tostring(attName)))
        end
    end)
end

-- Admin-Ausgabe
local function isAdmin(ply)
    return not IsValid(ply) or (L.AdminGroups or {})[ply:GetUserGroup()] == true or ply:IsSuperAdmin()
end

local function show(ply, filter)
    M.FlushShotLog()
    filter = string.lower(string.Trim(filter or ""))
    local out, count = {}, 0
    for i = #M.ShotRecent, 1, -1 do
        local line = M.ShotRecent[i]
        if filter == "" or string.find(string.lower(line), filter, 1, true) then
            table.insert(out, 1, line)
            count = count + 1
            if count >= (L.ShowLines or 40) then break end
        end
    end
    local function say(s) if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, s) else print(s) end end
    say("==== Schusslog " .. (filter ~= "" and ("(" .. filter .. ") ") or "") .. "· Datei: data/" .. logFile() .. " ====")
    for _, line in ipairs(out) do say(line) end
    if #out == 0 then say("Keine Einträge.") end
end

concommand.Add("eoc_schusslog", function(ply, _, args)
    if not isAdmin(ply) then return end
    show(ply, table.concat(args or {}, " "))
end)

hook.Add("PlayerSay", "EOCArcCW_ShotLog", function(ply, text)
    local lower = string.lower(string.Trim(text))
    if lower == "!schusslog" or string.StartWith(lower, "!schusslog ") then
        if isAdmin(ply) then
            show(ply, string.sub(text, 12))
            ply:ChatPrint("Schusslog in der Konsole (^).")
        end
        return ""
    end
end)
