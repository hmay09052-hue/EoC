--[[
	No Door Buying - DarkRP Addon
	Verhindert, dass Spieler Türen (und optional Fahrzeuge) kaufen können.
]]

local Config = {
	-- Nachricht, die der Spieler bekommt, wenn er versucht eine Tür zu kaufen
	Message = "Türen können auf diesem Server nicht gekauft werden.",

	-- Zusätzlich alle Türen auf der Map als "nicht kaufbar" markieren.
	-- Wirkt auch dann, wenn ein anderes Addon den Kauf-Hook überschreibt.
	-- (Wird nicht in der Datenbank gespeichert, nur bis zum Neustart / Map-Wechsel.)
	MarkDoorsUnownable = true,

	-- Sollen Fahrzeuge ebenfalls nicht mehr gekauft werden können?
	BlockVehicles = false,
	VehicleMessage = "Fahrzeuge können auf diesem Server nicht gekauft werden.",

	-- Usergroups, die trotzdem Türen kaufen dürfen (leer lassen = niemand)
	-- Beispiel: { ["superadmin"] = true, ["admin"] = true }
	AllowedGroups = {},
}

local function isAllowed(ply)
	return IsValid(ply) and Config.AllowedGroups[ply:GetUserGroup()] == true
end

-- Wird von DarkRP aufgerufen, bevor ein Spieler eine Tür kauft (F2 / /toggleown)
-- Rückgabe: darf kaufen, Grund, Nachricht unterdrücken
hook.Add("playerBuyDoor", "NoDoorBuying_BlockDoors", function(ply, ent)
	if isAllowed(ply) then return end
	return false, Config.Message, false
end)

-- Wird von DarkRP aufgerufen, bevor ein Spieler ein Fahrzeug kauft
hook.Add("playerBuyVehicle", "NoDoorBuying_BlockVehicles", function(ply, ent)
	if not Config.BlockVehicles or isAllowed(ply) then return end
	return false, Config.VehicleMessage, false
end)

-- Alle Türen auf der Map als nicht kaufbar markieren
local function markAllDoors()
	if not Config.MarkDoorsUnownable then return end

	local count = 0
	for _, ent in ipairs(ents.GetAll()) do
		if IsValid(ent) and ent.isDoor and ent:isDoor() and ent.setKeysNonOwnable
			and not ent:getKeysNonOwnable() and not ent:isKeysOwned() then
			ent:setKeysNonOwnable(true)
			count = count + 1
		end
	end

	print("[No Door Buying] " .. count .. " Türen als nicht kaufbar markiert.")
end

-- DarkRP lädt die Türdaten erst nach InitPostEntity, daher etwas warten
hook.Add("InitPostEntity", "NoDoorBuying_MarkDoors", function()
	timer.Simple(10, markAllDoors)
	timer.Simple(60, markAllDoors)
end)

hook.Add("PostCleanupMap", "NoDoorBuying_MarkDoors", function()
	timer.Simple(1, markAllDoors)
end)

-- Bei einem Lua-Refresh (Datei-Änderung zur Laufzeit) direkt ausführen
if GAMEMODE then
	timer.Simple(1, markAllDoors)
end

-- Prüfen, ob DarkRP läuft (erst nach dem Laden des Gamemodes möglich)
hook.Add("Initialize", "NoDoorBuying_CheckDarkRP", function()
	if not DarkRP then
		print("[No Door Buying] WARNUNG: DarkRP wurde nicht gefunden. Das Addon funktioniert nur mit DarkRP!")
	end
end)

print("[No Door Buying] Geladen - Türen können nicht mehr gekauft werden.")
