-- Echoes of Clones // Aussehen-System (Bodygroups, Skins, Modelle)
-- Basierend auf bodyGroupr von Arizard, neu aufgebaut für Echoes of Clones.

BODYMAN = BODYMAN or {}

if SERVER then
	AddCSLuaFile("bodyman/bodyman_config.lua")
	AddCSLuaFile("bodyman/bodyman_shared.lua")
	AddCSLuaFile("bodyman/bodyman_ui.lua")
	AddCSLuaFile("bodyman/bodyman_client.lua")

	include("bodyman/bodyman_config.lua")
	include("bodyman/bodyman_shared.lua")
	include("bodyman/bodyman_server.lua")
	include("bodyman/bodyman_server_hooks.lua")
else
	include("bodyman/bodyman_config.lua")
	include("bodyman/bodyman_shared.lua")
	include("bodyman/bodyman_ui.lua")
	include("bodyman/bodyman_client.lua")
end

MsgC(BODYMAN.Theme.Yellow, "[" .. BODYMAN.ServerName .. "] ", color_white, "Aussehen-System geladen.\n")
