--[[---------------------------------------------------------------------------
DarkRP custom jobs
This file contains your custom jobs.
This file should also contain jobs from DarkRP that you edited.
Note: If you want to edit a default DarkRP job, first disable it in darkrp_config/disabled_defaults.lua
Once you've done that, copy and paste the job to this file and edit it.
The default jobs can be found here:
https://github.com/FPtje/DarkRP/blob/master/gamemode/config/jobrelated.lua
For examples and explanation please visit this wiki page:
https://darkrp.miraheze.org/wiki/DarkRP:CustomJobFields
Add your custom jobs under the following line:
---------------------------------------------------------------------------]]


-- ========================================================================
-- Ausbildungsakademie
-- ========================================================================

TEAM_TEAMF = DarkRP.createJob("Echoes of Clones Team on Duty", {
	color = Color(0, 18, 154),
	model = { "models/starwars/sky/custom_support/admin.mdl" },
	description = "Ein Mitglied des Leitungsteams im Dienst, das über die Einhaltung der republikanischen Vorschriften unter den Klonkriegern wacht und den reibungslosen Ablauf auf der Basis sicherstellt.",
	weapons = { "gar_datapad", "weapon_fists", "arccw_k_dc15s_stun", "vibrokinfe_digital", "weapon_cuff_handcuffs", "arccw_k_dc19", "weapon_binoculars" },
	command = "teamf",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_nade_detonite" },
	vehicles = {"heracles421_lfs_barc"},
	category = "Ausbildungsakademie",
	PlayerSpawn = function(ply)
		ply:SetHealth(9999)
		ply:SetMaxHealth(9999)
		ply:SetArmor(9999)
		ply:SetMaxArmor(9999)
	end,
})

TEAM_PRISONER = DarkRP.createJob("Gefangener", {
	color = Color(0, 18, 154),
	model = { "models/nevelgrad/players/clones/base_trooper.mdl" },
	description = "Ein Mitglied des Leitungsteams im Dienst, das über die Einhaltung der republikanischen Vorschriften unter den Klonkriegern wacht und den reibungslosen Ablauf auf der Basis sicherstellt.",
	weapons = { "gar_datapad", "mvp_perfecthands", },
	command = "teambutzbach",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_nade_detonite" },
	vehicles = {"heracles421_lfs_barc"},
	category = "Gefängnis",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(0)
		ply:SetMaxArmor(0)
	end,
})

TEAM_AUSBILDER = DarkRP.createJob("Ausbilder", {
	color = Color(0, 18, 154),
	model = { "models/starwars/grady/su/arc/arc_trooper.mdl" },
	description = "Ein Kadett der Ausbildungsakademie auf Kamino, der die Grundlagen der Waffenführung, Taktik und Disziplin erlernt, bevor er einer Einheit der Grand Army of the Republic zugeteilt wird.",
	weapons = { "gar_datapad", "weapon_fists", "arccw_k_dc15s_train", "weapon_cuff_handcuffs", "arccw_k_westarm5", "arccw_k_dc15a_train", "weapon_binoculars" },
	command = "ausbilder",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "weapon_fists" },
	vehicles = {},
	category = "Ausbildungsakademie",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(350)
		ply:SetMaxArmor(350)
	end,
})

TEAM_CADET = DarkRP.createJob("Cadet", {
	color = Color(0, 18, 154),
	model = { "models/starwars/grady/clone_cadet/clone_cadet_green.mdl" },
	description = "Ein Kadett der Ausbildungsakademie auf Kamino, der die Grundlagen der Waffenführung, Taktik und Disziplin erlernt, bevor er einer Einheit der Grand Army of the Republic zugeteilt wird.",
	weapons = { "weapon_fists", "arccw_k_dc15s_train", "arccw_k_dc15a_train", "weapon_binoculars" },
	command = "cadetss",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "weapon_fists" },
	vehicles = {},
	category = "Ausbildungsakademie",
	PlayerSpawn = function(ply)
		ply:SetHealth(100)
		ply:SetMaxHealth(100)
		ply:SetArmor(100)
		ply:SetMaxArmor(100)
	end,
})

TEAM_ZIVILIST = DarkRP.createJob("Zivilist", {
	color = Color(0, 18, 154, 255),
	model = {
		"models/hcn/starwars/bf/abednedo/abednedo.mdl",
		"models/hcn/starwars/bf/abednedo/abednedo_2.mdl",
		"models/hcn/starwars/bf/abednedo/abednedo_5.mdl",
		"models/hcn/starwars/bf/bossk/bossk_green.mdl",
		"models/hcn/starwars/bf/bossk/bossk_red.mdl",
		"models/hcn/starwars/bf/rodian/rodian_5.mdl",
		"models/hcn/starwars/bf/quarren/quarren_4.mdl",
		"models/npc_hcn/starwars/bf/ishitib/ishitib_4.mdl",
		"models/npc_hcn/starwars/bf/ishitib/ishitib_5.mdl",
		"models/npc_hcn/starwars/bf/quarren/quarren_2.mdl",
		"models/npc_hcn/starwars/bf/duros/duros.mdl",
		"models/npc_hcn/starwars/bf/bossk/bossk_red.mdl",
		"models/npc_hcn/starwars/bf/sullustan/sullustan.mdl",
		"models/npc_hcn/starwars/bf/sullustan/sullustan_5.mdl",
		"models/npc_hcn/starwars/bf/weequay/weequay_4.mdl",
		"models/npc_hcn/starwars/bf/zabrak/zabrak_4.mdl",
		"models/npc_hcn/starwars/bf/zabrak/zabrak_5.mdl",
	},
	description = [[Ein Mitglied des Leitungsteams im Dienst, das über die Einhaltung der republikanischen Vorschriften unter den Klonkriegern wacht und den reibungslosen Ablauf auf der Basis sicherstellt.]],
	weapons = { "weapon_fists" },
	command = "teamzivilisten",
	max = 0,
	salary = 3000,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Zivilist",
	-- Nur behalten, wenn dein Fahrzeug-Addon dieses Feld ausliest (kein Standard-DarkRP-Feld)
	vehicles = { "heracles421_lfs_barc" },
	PlayerSpawn = function(ply)
		-- Kurz warten, damit DarkRP die Werte nach dem Spawn nicht wieder überschreibt
		timer.Simple(0, function()
			if not IsValid(ply) then return end
			ply:SetMaxHealth(200)
			ply:SetHealth(200)
			ply:SetMaxArmor(0)
			ply:SetArmor(0)
		end)
	end,
})

-- ========================================================================
-- 501st Torrent Company
-- ========================================================================

TEAM_501ST_PVT = DarkRP.createJob("501st Torrent Company | Private", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein frisch der 501st Legion zugeteilter Trooper unter dem Kommando von General Skywalker, der an vorderster Front der als 'Vaders Faust' bekannten Legion kämpft.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_republicshield", "arccw_k_nade_thermal", },
	vehicles = {},
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_501ST_PFC = DarkRP.createJob("501st Torrent Company | Private First Class", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Standardsoldat der 501st Legion, bekannt für kompromisslosen Einsatz in den härtesten Schlachten der Klonkriege.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_501ST_SPC = DarkRP.createJob("501st Torrent Company | Specialist", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Standardsoldat der 501st Legion, bekannt für kompromisslosen Einsatz in den härtesten Schlachten der Klonkriege.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_501ST_LCPL = DarkRP.createJob("501st Torrent Company | Lance Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Standardsoldat der 501st Legion, bekannt für kompromisslosen Einsatz in den härtesten Schlachten der Klonkriege.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_CPL = DarkRP.createJob("501st Torrent Company | Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Unteroffizier der 501st Legion, verantwortlich für die Koordination kleinerer Trupps im Kampfgeschehen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_501ST_CCPL = DarkRP.createJob("501st Torrent Company | Chief Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Unteroffizier der 501st Legion, verantwortlich für die Koordination kleinerer Trupps im Kampfgeschehen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_501ST_FCPL = DarkRP.createJob("501st Torrent Company | First Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Unteroffizier der 501st Legion, verantwortlich für die Koordination kleinerer Trupps im Kampfgeschehen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_501ST_SGT = DarkRP.createJob("501st Torrent Company | Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Unteroffizier der 501st Legion, verantwortlich für die Koordination kleinerer Trupps im Kampfgeschehen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_501ST_FSGT = DarkRP.createJob("501st Torrent Company | First Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Unteroffizier der 501st Legion, verantwortlich für die Koordination kleinerer Trupps im Kampfgeschehen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_501ST_SGM = DarkRP.createJob("501st Torrent Company | Sergeant Major", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Unteroffizier der 501st Legion, verantwortlich für die Koordination kleinerer Trupps im Kampfgeschehen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

TEAM_501ST_LT = DarkRP.createJob("501st Torrent Company | Lieutenant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Offizier der 501st Legion, der taktische Operationen plant und Kompanien im Feld anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_lt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17ext_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(285)
		ply:SetMaxArmor(285)
	end,
})

TEAM_501ST_1LT = DarkRP.createJob("501st Torrent Company | First Lieutenant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein Offizier der 501st Legion, der taktische Operationen plant und Kompanien im Feld anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501st_1lt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17ext_akimbo", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(290)
		ply:SetMaxArmor(290)
	end,
})

TEAM_501ST_CPT = DarkRP.createJob("501st Torrent Company | Captain", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/trooper/trooper_v2/501st_trooper_v2.mdl" },
	description = "Ein hochrangiger Stabsoffizier der 501st Legion, der Captain Rex und General Skywalker bei der Planung großer Feldzüge unterstützt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501st_cpt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s_grenadier", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17sa_dual", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(300)
		ply:SetMaxArmor(300)
	end,
})

-- ========================================================================
-- 501st BARC
-- ========================================================================

TEAM_501ST_BARC_PVT = DarkRP.createJob("501st BARC | Private", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = {},
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_501ST_BARC_PFC = DarkRP.createJob("501st BARC | Private First Class", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_501ST_BARC_SPC = DarkRP.createJob("501st BARC | Specialist", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_501ST_BARC_LCPL = DarkRP.createJob("501st BARC | Lance Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_BARC_CPL = DarkRP.createJob("501st BARC | Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_501ST_BARC_CCPL = DarkRP.createJob("501st BARC | Chief Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_501ST_BARC_FCPL = DarkRP.createJob("501st BARC | First Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_501ST_BARC_SGT = DarkRP.createJob("501st BARC | Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_501ST_BARC_FSGT = DarkRP.createJob("501st BARC | First Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_501ST_BARC_SGM = DarkRP.createJob("501st BARC | Sergeant Major", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/barc/barc_v1/501st_barc_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stbarc_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_cr2c", "arccw_k_nade_smoke", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

-- ========================================================================
-- 501st Advanced Recon Force (ARF)
-- ========================================================================

TEAM_501ST_ARF_PVT = DarkRP.createJob("501st ARF | Private", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "recondroidkit", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = {},
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_501ST_ARF_PFC = DarkRP.createJob("501st ARF | Private First Class", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "recondroidkit", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_501ST_ARF_SPC = DarkRP.createJob("501st ARF | Specialist", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "recondroidkit", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_501ST_ARF_LCPL = DarkRP.createJob("501st ARF | Lance Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein Aufklärungssoldat des Advanced Recon Force der 501st Legion, ausgebildet für Spähtrupps, Infiltration und Fernaufklärung hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "recondroidkit", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_ARF_CPL = DarkRP.createJob("501st ARF | Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_501ST_ARF_CCPL = DarkRP.createJob("501st ARF | Chief Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_501ST_ARF_FCPL = DarkRP.createJob("501st ARF | First Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_501ST_ARF_SGT = DarkRP.createJob("501st ARF | Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_501ST_ARF_FSGT = DarkRP.createJob("501st ARF | First Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_501ST_ARF_SGM = DarkRP.createJob("501st ARF | Sergeant Major", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/arf/arf_v1/501st_arf_v1.mdl" },
	description = "Ein erfahrener ARF-Späher der 501st Legion mit Zusatzausbildung in Nahkampf und Gefangennahme, der kleine Aufklärungstrupps anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
		"weapon_tarnkappe",
	},
	command = "501starf_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

-- ========================================================================
-- 501st Heavy Platoon
-- ========================================================================

TEAM_501ST_HEAVY_PVT = DarkRP.createJob("501st Heavy Platoon | Private", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein schwer bewaffneter Soldat des 501st Heavy Platoon, mit Z-6-Rotationskanonen ausgerüstet, um Sturmangriffe der Legion mit Sperrfeuer zu unterstützen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = {},
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_501ST_HEAVY_PFC = DarkRP.createJob("501st Heavy Platoon | Private First Class", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein schwer bewaffneter Soldat des 501st Heavy Platoon, mit Z-6-Rotationskanonen ausgerüstet, um Sturmangriffe der Legion mit Sperrfeuer zu unterstützen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_501ST_HEAVY_SPC = DarkRP.createJob("501st Heavy Platoon | Specialist", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein schwer bewaffneter Soldat des 501st Heavy Platoon, mit Z-6-Rotationskanonen ausgerüstet, um Sturmangriffe der Legion mit Sperrfeuer zu unterstützen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_501ST_HEAVY_LCPL = DarkRP.createJob("501st Heavy Platoon | Lance Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein schwer bewaffneter Soldat des 501st Heavy Platoon, mit Z-6-Rotationskanonen ausgerüstet, um Sturmangriffe der Legion mit Sperrfeuer zu unterstützen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_HEAVY_CPL = DarkRP.createJob("501st Heavy Platoon | Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein Unteroffizier des 501st Heavy Platoon, der Schwerwaffenteams führt und eroberte Stellungen gegen Gegenangriffe sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_501ST_HEAVY_CCPL = DarkRP.createJob("501st Heavy Platoon | Chief Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein Unteroffizier des 501st Heavy Platoon, der Schwerwaffenteams führt und eroberte Stellungen gegen Gegenangriffe sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_501ST_HEAVY_FCPL = DarkRP.createJob("501st Heavy Platoon | First Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein Unteroffizier des 501st Heavy Platoon, der Schwerwaffenteams führt und eroberte Stellungen gegen Gegenangriffe sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_501ST_HEAVY_SGT = DarkRP.createJob("501st Heavy Platoon | Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein Unteroffizier des 501st Heavy Platoon, der Schwerwaffenteams führt und eroberte Stellungen gegen Gegenangriffe sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_501ST_HEAVY_FSGT = DarkRP.createJob("501st Heavy Platoon | First Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein Unteroffizier des 501st Heavy Platoon, der Schwerwaffenteams führt und eroberte Stellungen gegen Gegenangriffe sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_501ST_HEAVY_SGM = DarkRP.createJob("501st Heavy Platoon | Sergeant Major", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ht/ht_v1/501st_ht_v1.mdl" },
	description = "Ein Unteroffizier des 501st Heavy Platoon, der Schwerwaffenteams führt und eroberte Stellungen gegen Gegenangriffe sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"personal_shield",
		"weapon_binoculars",
	},
	command = "501stheavy_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", "arccw_sops_republic_z6chaingun", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

-- ========================================================================
-- 501st Airborne Platoon
-- ========================================================================

TEAM_501ST_AIRBORNE_PVT = DarkRP.createJob("501st Airborne Platoon | Private", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Luftlandesoldat des 501st Airborne Platoon, der mit Jetpack in umkämpfte Gebiete einfliegt, um überraschende Angriffe aus der Luft zu führen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dp24", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = {},
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_501ST_AIRBORNE_PFC = DarkRP.createJob("501st Airborne Platoon | Private First Class", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Luftlandesoldat des 501st Airborne Platoon, der mit Jetpack in umkämpfte Gebiete einfliegt, um überraschende Angriffe aus der Luft zu führen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dp24", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_501ST_AIRBORNE_SPC = DarkRP.createJob("501st Airborne Platoon | Specialist", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Luftlandesoldat des 501st Airborne Platoon, der mit Jetpack in umkämpfte Gebiete einfliegt, um überraschende Angriffe aus der Luft zu führen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dp24", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_501ST_AIRBORNE_LCPL = DarkRP.createJob("501st Airborne Platoon | Lance Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Luftlandesoldat des 501st Airborne Platoon, der mit Jetpack in umkämpfte Gebiete einfliegt, um überraschende Angriffe aus der Luft zu führen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dp24", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_AIRBORNE_CPL = DarkRP.createJob("501st Airborne Platoon | Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Unteroffizier des 501st Airborne Platoon, der Luftlandungen koordiniert und Sturmtrupps im Häuserkampf anleitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dp24", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_501ST_AIRBORNE_CCPL = DarkRP.createJob("501st Airborne Platoon | Chief Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Unteroffizier des 501st Airborne Platoon, der Luftlandungen koordiniert und Sturmtrupps im Häuserkampf anleitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dp24", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_501ST_AIRBORNE_FCPL = DarkRP.createJob("501st Airborne Platoon | First Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Unteroffizier des 501st Airborne Platoon, der Luftlandungen koordiniert und Sturmtrupps im Häuserkampf anleitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dp24", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_501ST_AIRBORNE_SGT = DarkRP.createJob("501st Airborne Platoon | Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Unteroffizier des 501st Airborne Platoon, der Luftlandungen koordiniert und Sturmtrupps im Häuserkampf anleitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dp24", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_501ST_AIRBORNE_FSGT = DarkRP.createJob("501st Airborne Platoon | First Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Unteroffizier des 501st Airborne Platoon, der Luftlandungen koordiniert und Sturmtrupps im Häuserkampf anleitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dp24", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_501ST_AIRBORNE_SGM = DarkRP.createJob("501st Airborne Platoon | Sergeant Major", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/ab/ab_v1/501st_ab_v1.mdl" },
	description = "Ein Unteroffizier des 501st Airborne Platoon, der Luftlandungen koordiniert und Sturmtrupps im Häuserkampf anleitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stab_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dp24", "arccw_k_dc15a", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_impact", "arccw_k_nade_thermal", "arccw_k_nade_sonar", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

-- ========================================================================
-- 501st Medical Platoon
-- ========================================================================

TEAM_501ST_MEDIC_PVT = DarkRP.createJob("501st Medical Platoon | Private", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein Sanitäter der 501st Legion, der verwundete Brüder unter Beschuss mit Bacta und Nothilfe versorgt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc15a",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"arccw_k_nade_bacta",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_501ST_MEDIC_PFC = DarkRP.createJob("501st Medical Platoon | Private First Class", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein Sanitäter der 501st Legion, der verwundete Brüder unter Beschuss mit Bacta und Nothilfe versorgt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc15a",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"arccw_k_nade_bacta",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_501ST_MEDIC_SPC = DarkRP.createJob("501st Medical Platoon | Specialist", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein Sanitäter der 501st Legion, der verwundete Brüder unter Beschuss mit Bacta und Nothilfe versorgt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc15a",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"arccw_k_nade_bacta",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_501ST_MEDIC_LCPL = DarkRP.createJob("501st Medical Platoon | Lance Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein Sanitäter der 501st Legion, der verwundete Brüder unter Beschuss mit Bacta und Nothilfe versorgt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc15a",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"arccw_k_nade_bacta",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_MEDIC_CPL = DarkRP.createJob("501st Medical Platoon | Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein erfahrener Feldarzt der 501st Legion, der mobile Verbandsplätze leitet und die Evakuierung Verwundeter organisiert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc17_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_501ST_MEDIC_CCPL = DarkRP.createJob("501st Medical Platoon | Chief Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein erfahrener Feldarzt der 501st Legion, der mobile Verbandsplätze leitet und die Evakuierung Verwundeter organisiert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc17_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_501ST_MEDIC_FCPL = DarkRP.createJob("501st Medical Platoon | First Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein erfahrener Feldarzt der 501st Legion, der mobile Verbandsplätze leitet und die Evakuierung Verwundeter organisiert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc17_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_501ST_MEDIC_SGT = DarkRP.createJob("501st Medical Platoon | Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein erfahrener Feldarzt der 501st Legion, der mobile Verbandsplätze leitet und die Evakuierung Verwundeter organisiert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc17_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_501ST_MEDIC_FSGT = DarkRP.createJob("501st Medical Platoon | First Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein erfahrener Feldarzt der 501st Legion, der mobile Verbandsplätze leitet und die Evakuierung Verwundeter organisiert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc17_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_501ST_MEDIC_SGM = DarkRP.createJob("501st Medical Platoon | Sergeant Major", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Ein erfahrener Feldarzt der 501st Legion, der mobile Verbandsplätze leitet und die Evakuierung Verwundeter organisiert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc17_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

TEAM_501ST_MEDIC_LT = DarkRP.createJob("501st Medical Platoon | Lieutenant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/medic/medic_v1/501st_medic_v1.mdl" },
	description = "Der leitende Mediziner der 501st Legion, verantwortlich für die medizinische Versorgung der gesamten Kompanie.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stmed_lt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17ext_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15se",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte", "lvs_fakehover_barc_medical" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(285)
		ply:SetMaxArmor(285)
	end,
})

-- ========================================================================
-- 501st Engineering Platoon
-- ========================================================================

TEAM_501ST_ENGINEER_PVT = DarkRP.createJob("501st Engineering Platoon | Private", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Techniker der 501st Engeneering Company, zuständig für Feldreparaturen, Sprengsätze und Bombenentschärfung im Einsatz.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_501ST_ENGINEER_PFC = DarkRP.createJob("501st Engineering Platoon | Private First Class", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Techniker der 501st Engeneering Company, zuständig für Feldreparaturen, Sprengsätze und Bombenentschärfung im Einsatz.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_501ST_ENGINEER_SPC = DarkRP.createJob("501st Engineering Platoon | Specialist", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Techniker der 501st Engeneering Company, zuständig für Feldreparaturen, Sprengsätze und Bombenentschärfung im Einsatz.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_501ST_ENGINEER_LCPL = DarkRP.createJob("501st Engineering Platoon | Lance Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Techniker der 501st Engeneering Company, zuständig für Feldreparaturen, Sprengsätze und Bombenentschärfung im Einsatz.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_ENGINEER_CPL = DarkRP.createJob("501st Engineering Platoon | Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Unteroffizier der 501st Engeneering Company, der technische Einsätze überwacht und die Sicherung wichtiger Zugangspunkte leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"cw_flamethrower",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_501ST_ENGINEER_CCPL = DarkRP.createJob("501st Engineering Platoon | Chief Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Unteroffizier der 501st Engeneering Company, der technische Einsätze überwacht und die Sicherung wichtiger Zugangspunkte leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"cw_flamethrower",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_501ST_ENGINEER_FCPL = DarkRP.createJob("501st Engineering Platoon | First Corporal", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Unteroffizier der 501st Engeneering Company, der technische Einsätze überwacht und die Sicherung wichtiger Zugangspunkte leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"cw_flamethrower",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_501ST_ENGINEER_SGT = DarkRP.createJob("501st Engineering Platoon | Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Unteroffizier der 501st Engeneering Company, der technische Einsätze überwacht und die Sicherung wichtiger Zugangspunkte leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"cw_flamethrower",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_501ST_ENGINEER_FSGT = DarkRP.createJob("501st Engineering Platoon | First Sergeant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Unteroffizier der 501st Engeneering Company, der technische Einsätze überwacht und die Sicherung wichtiger Zugangspunkte leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"cw_flamethrower",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_501ST_ENGINEER_SGM = DarkRP.createJob("501st Engineering Platoon | Sergeant Major", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Ein Unteroffizier der 501st Engeneering Company, der technische Einsätze überwacht und die Sicherung wichtiger Zugangspunkte leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"cw_flamethrower",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

TEAM_501ST_ENGINEER_LT = DarkRP.createJob("501st Engineering Platoon | Lieutenant", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/teb/teb_v1/501st_teb_v1.mdl" },
	description = "Der leitende Ingenieur der 501st Legion, der Befestigungen plant und komplexe technische Operationen im Feld koordiniert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"fort_datapad",
		"weapon_fists",
		"realistic_hook",
		"ts_fusioncutter_repairer",
		"weapon_extinguisher_infinite",
		"seal6-c4",
		"bkeypads_access_logs",
		"defuser_bomb",
		"weapon_armorkit",
		"st_loescher",
		"st_werkzeug",
		"alydus_fusioncutter",
		"weapon_binoculars",
	},
	command = "501steng_lt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"cw_flamethrower",
		"arccw_k_dc17ext_akimbo",
		"arccw_sops_republic_dlt23v",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(285)
		ply:SetMaxArmor(285)
	end,
})

-- ========================================================================
-- 501st Lorecharaktere
-- ========================================================================

TEAM_501ST_REX = DarkRP.createJob("501st | Rex", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/rex/501st_rex_p1.mdl" },
	description = "Captain Rex (CT-7567), der Kommandant der 501st Legion und einer der fähigsten und loyalsten Klonkommandanten der gesamten Grand Army of the Republic.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501strex",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "jet_mk5", "arccw_k_dc15a", "arccw_k_dc15s_grenadier", "arccw_k_launcher_smartlauncher", "arccw_k_nade_c14", "arccw_k_republicshield", "arccw_k_nade_thermal", "arccw_k_dc17sa_dual", "weapon_cuff_handcuffs", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(350)
		ply:SetMaxArmor(350)
	end,
})

TEAM_501ST_KIX = DarkRP.createJob("501st | Kix", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/kix/501st_kix_p1.mdl" },
	description = "Kix (CT-6116), der Sanitäter von Rex' Trupp, bekannt für seine unerschütterliche Ruhe selbst im dichtesten Gefecht.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stkix",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15se",
		"arccw_k_dc17_akimbo",
		"weapon_cuff_handcuffs",
		"arccw_k_dc15a",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_repulsorlift_gunship", "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_HARDCASE = DarkRP.createJob("501st | Hardcase", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/hardcase/501st_hardcase_p1.mdl" },
	description = "Hardcase (CT-5537), ein draufgängerischer Sprengstoffexperte der 501st Legion, berüchtigt für seine Vorliebe für spektakuläre Explosionen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501sthardcase",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_z6", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_decoy", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_DOGMA = DarkRP.createJob("501st | Dogma", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/dogma/501st_dogma_p1.mdl" },
	description = "Dogma (CT-5385), ein regeltreuer Soldat der 501st Legion, der bedingungslos den Befehlen der Republik folgt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stdogma",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_republicshield", "arccw_k_nade_c14", "arccw_k_nade_thermal" },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_BOOMER = DarkRP.createJob("501st | Boomer", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/boomer/501st_boomer_p1.mdl" },
	description = "Boomer, ein Aufklärungssoldat der 501st Advanced Recon Force, bekannt für seinen Mut bei riskanten Spähmissionen hinter feindlichen Linien.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stboomer",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc17_akimbo", "recondroidkit", "weapon_cuff_handcuffs", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15x", "recondroidkit", "arccw_k_nade_smoke", "arccw_k_nade_thermal", },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_APPO = DarkRP.createJob("501st | Appo", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/appo/501st_appo_p1.mdl" },
	description = "Appo (CT-7409), ein Offizier der 501st Legion, der Anakin Skywalker während der letzten Schlachten der Klonkriege begleitete.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stappo",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_republicshield", "arccw_k_nade_c14", "arccw_k_nade_thermal" },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_JESSE = DarkRP.createJob("501st | Jesse", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/jesse_trooper/501st_jesse_tr.mdl", "models/silent/501st_ph1/lore_char/jesse_arc/501st_jesse_arc15.mdl" },
	description = "Jesse (CT-5597), ein Offizier der 501st Legion und einer der loyalsten Soldaten unter Captain Rex.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stjesse",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_republicshield", "arccw_k_nade_c14", "arccw_k_nade_thermal" },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_ECHO = DarkRP.createJob("501st | Echo", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/echo_trooper/501st_echo_tr.mdl", "models/silent/501st_ph1/lore_char/echo_arc/501st_echo_arc15.mdl" },
	description = "Jesse (CT-5597), ein Offizier der 501st Legion und einer der loyalsten Soldaten unter Captain Rex.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stecho",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_republicshield", "arccw_k_nade_c14", "arccw_k_nade_thermal" },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_FIVES = DarkRP.createJob("501st | Fives", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/fives_trooper/501st_fives_tr.mdl", "models/silent/501st_ph1/lore_char/fives_arc/501st_fives_arc15.mdl" },
	description = "Jesse (CT-5597), ein Offizier der 501st Legion und einer der loyalsten Soldaten unter Captain Rex.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stfives",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_republicshield", "arccw_k_nade_c14", "arccw_k_nade_thermal" },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_KANO = DarkRP.createJob("501st | Kano", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/kano/501st_kano_p1.mdl" },
	description = "Kano, ein Elitesoldat der 501st Legion mit Jetpack-Ausrüstung für schnelle Eingreiftrupps in besonders gefährlichen Gefechten.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"jet_mk5",
		"weapon_binoculars",
	},
	command = "501stkano",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_launcher_smartlauncher", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_republicshield", "arccw_k_nade_c14", "arccw_k_nade_thermal" },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_501ST_CORIC = DarkRP.createJob("501st | Coric", {
	color = Color(0, 51, 153),
	model = { "models/silent/501st_ph1/lore_char/coric/501st_coric_p1.mdl" },
	description = "Sergeant Coric, ein erfahrener Sanitäter-Sergeant der 501st Legion, der während der Schlacht von Umbara in kritischen Momenten das Kommando übernahm.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "501stcoric",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = { "jet_mk5", "arccw_k_dc15s", "arccw_k_dc15a", "arccw_k_dc15le", "arccw_k_dc17_akimbo", "weapon_cuff_handcuffs", "arccw_k_nade_c14", "arccw_k_nade_thermal" },
	vehicles = { "lvs_atrt", "lvs_tx130_turret", "lvs_walker_atte" },
	category = "501st Elite Legion",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

-- ========================================================================
-- Schocktruppen (Coruscant Guard)
-- ========================================================================

TEAM_ST_PVT = DarkRP.createJob("Schocktruppen | Private", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Wächter der Coruscant Guard, der die Hauptstadt der Republik patrouilliert und wichtige Regierungsgebäude sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
		"lscs_shock",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_ST_PFC = DarkRP.createJob("Schocktruppen | Private First Class", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Wächter der Coruscant Guard, der die Hauptstadt der Republik patrouilliert und wichtige Regierungsgebäude sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
		"lscs_shock",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_ST_SPC = DarkRP.createJob("Schocktruppen | Specialist", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Wächter der Coruscant Guard, der die Hauptstadt der Republik patrouilliert und wichtige Regierungsgebäude sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
		"lscs_shock",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_ST_LCPL = DarkRP.createJob("Schocktruppen | Lance Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Wächter der Coruscant Guard, der die Hauptstadt der Republik patrouilliert und wichtige Regierungsgebäude sichert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
		"lscs_shock",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_ST_CPL = DarkRP.createJob("Schocktruppen | Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der Coruscant Guard, der Patrouillen anführt und die Einhaltung der militärischen Disziplin auf Coruscant durchsetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_ST_CCPL = DarkRP.createJob("Schocktruppen | Chief Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der Coruscant Guard, der Patrouillen anführt und die Einhaltung der militärischen Disziplin auf Coruscant durchsetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_ST_FCPL = DarkRP.createJob("Schocktruppen | First Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der Coruscant Guard, der Patrouillen anführt und die Einhaltung der militärischen Disziplin auf Coruscant durchsetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_ST_SGT = DarkRP.createJob("Schocktruppen | Sergeant", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der Coruscant Guard, der Patrouillen anführt und die Einhaltung der militärischen Disziplin auf Coruscant durchsetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_ST_FSGT = DarkRP.createJob("Schocktruppen | First Sergeant", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der Coruscant Guard, der Patrouillen anführt und die Einhaltung der militärischen Disziplin auf Coruscant durchsetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_ST_SGM = DarkRP.createJob("Schocktruppen | Sergeant Major", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der Coruscant Guard, der Patrouillen anführt und die Einhaltung der militärischen Disziplin auf Coruscant durchsetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

TEAM_ST_LT = DarkRP.createJob("Schocktruppen | Lieutenant", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Offizier der Coruscant Guard, verantwortlich für die Sicherheit sensibler Bereiche und die Koordination der Wachtruppen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_lt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc17ext_akimbo",
		"arccw_k_stw48",
		"arccw_k_dc15s_stun",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
		"lscs_shock",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(285)
		ply:SetMaxArmor(285)
	end,
})

TEAM_ST_FOXOFFIZIER = DarkRP.createJob("Schocktruppen | Fox", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_commander_fox.mdl" },
	description = "Commander Fox, der Kommandant der Coruscant Guard, verantwortlich für Recht und Ordnung auf der Hauptstadtwelt Coruscant.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_foxoffizier",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc17ext_akimbo",
		"arccw_k_stw48",
		"arccw_k_dc15s_stun",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
		"lscs_shock",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(300)
		ply:SetMaxArmor(300)
	end,
})

TEAM_ST_THORNOFFIZIER = DarkRP.createJob("Schocktruppen | Thorn", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Marshal Commander Thorn, ein ranghoher Offizier der Coruscant Guard, zuständig für die Überwachung der Klonkriegertruppen in der Hauptstadt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "st_thornoffizier",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc17ext_akimbo",
		"arccw_k_stw48",
		"arccw_k_dc15s_stun",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(300)
		ply:SetMaxArmor(300)
	end,
})

-- ========================================================================
-- Schocktruppen K9
-- ========================================================================

TEAM_STK9_PVT = DarkRP.createJob("Schocktruppen K9 | Private", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Angehöriger der K9-Einheit der Coruscant Guard, spezialisiert auf spürhundgestützte Fahndung und Gefangennahme flüchtiger Zielpersonen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_STK9_PFC = DarkRP.createJob("Schocktruppen K9 | Private First Class", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Angehöriger der K9-Einheit der Coruscant Guard, spezialisiert auf spürhundgestützte Fahndung und Gefangennahme flüchtiger Zielpersonen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_STK9_SPC = DarkRP.createJob("Schocktruppen K9 | Specialist", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Angehöriger der K9-Einheit der Coruscant Guard, spezialisiert auf spürhundgestützte Fahndung und Gefangennahme flüchtiger Zielpersonen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_STK9_LCPL = DarkRP.createJob("Schocktruppen K9 | Lance Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Angehöriger der K9-Einheit der Coruscant Guard, spezialisiert auf spürhundgestützte Fahndung und Gefangennahme flüchtiger Zielpersonen.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_STK9_CPL = DarkRP.createJob("Schocktruppen K9 | Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der K9-Einheit, der Festnahmeeinsätze und Fahndungen im Häusergewirr von Coruscant leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_STK9_CCPL = DarkRP.createJob("Schocktruppen K9 | Chief Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der K9-Einheit, der Festnahmeeinsätze und Fahndungen im Häusergewirr von Coruscant leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_STK9_FCPL = DarkRP.createJob("Schocktruppen K9 | First Corporal", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der K9-Einheit, der Festnahmeeinsätze und Fahndungen im Häusergewirr von Coruscant leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_STK9_SGT = DarkRP.createJob("Schocktruppen K9 | Sergeant", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der K9-Einheit, der Festnahmeeinsätze und Fahndungen im Häusergewirr von Coruscant leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_STK9_FSGT = DarkRP.createJob("Schocktruppen K9 | First Sergeant", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der K9-Einheit, der Festnahmeeinsätze und Fahndungen im Häusergewirr von Coruscant leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_STK9_SGM = DarkRP.createJob("Schocktruppen K9 | Sergeant Major", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/eoc/st/st_ph1_trooper.mdl" },
	description = "Ein Unteroffizier der K9-Einheit, der Festnahmeeinsätze und Fahndungen im Häusergewirr von Coruscant leitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

TEAM_STK9_HOUND = DarkRP.createJob("Schocktruppen K9 | Hound", {
	color = Color(153, 0, 0),
	model = { "models/starwars/grady/merlin/st/sergeant_hound.mdl" },
	description = "Sergeant Hound, ein erfahrener Spürhundeführer der Coruscant Guard K9-Einheit, unschlagbar bei der Verfolgung Flüchtiger.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_fists",
		"realistic_hook",
		"weapon_cuff_handcuffs",
		"weapon_cuff_rope",
		"weapon_binoculars",
	},
	command = "stk9_hound",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s_stun",
		"arccw_k_stw48",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc15a_stun",
		"arccw_k_coruscantguardshield",
		"arccw_k_nade_thermal",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Schocktruppen",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

-- ========================================================================
-- Republic Navy
-- ========================================================================

--[[---------------------------------------------------------------------------
	Republic Navy – alle Ränge (von unten nach oben)

	Grün   : Crewman, Petty Officer, Senior Petty Officer, Chief Petty Officer
	Gelb   : Warrant Officer, Senior Warrant Officer, Chief Warrant Officer
	Rot    : Sub Lieutenant, Lieutenant
	Lila   : Lieutenant Commander, Commander, Captain, Vize Admiral, Admiral, Fleet Admiral
---------------------------------------------------------------------------]]

local RN_MODELS = {
	"models/starwars/grady/navy/republic_navy_black.mdl",
	"models/starwars/grady/navy/republic_navy_blue_leader.mdl",
	"models/starwars/grady/navy/republic_navy_darkgrey_leader.mdl",
	"models/starwars/grady/navy/republic_navy_red_leader.mdl",
	"models/starwars/grady/navy/republic_navy_green_leader.mdl",
	"models/starwars/grady/navy/republic_navy_trooper.mdl",
}

---------------------------------------------------------------------------
-- MANNSCHAFTEN / PETTY OFFICER (grün)
---------------------------------------------------------------------------

TEAM_RN_CREWMAN = DarkRP.createJob("Republic Navy | Crewman", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein Besatzungsmitglied der Republikanischen Marine, zuständig für den reibungslosen Betrieb an Bord republikanischer Kriegsschiffe.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17sa",
		"shield_2_deployer",
	},
	vehicles = { "heracles421_lfs_barc" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(150)
		ply:SetMaxArmor(150)
	end,
})

TEAM_RN_PETTYOFFICER = DarkRP.createJob("Republic Navy | Petty Officer", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein Unteroffizier der Republikanischen Marine, der Stationen an Bord überwacht und die Besatzung im Einsatz koordiniert.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnu",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(160)
		ply:SetMaxArmor(160)
	end,
})

TEAM_RN_SENIORPETTYOFFICER = DarkRP.createJob("Republic Navy | Senior Petty Officer", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein erfahrener Unteroffizier der Republikanischen Marine, der mehrere Stationen an Bord beaufsichtigt und Petty Officers anleitet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnspo",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(170)
		ply:SetMaxArmor(170)
	end,
})

TEAM_RN_CHIEFPETTYOFFICER = DarkRP.createJob("Republic Navy | Chief Petty Officer", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Der ranghöchste Unteroffizier der Mannschaften, verantwortlich für Disziplin, Ausbildung und den Dienstbetrieb der Besatzung.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rncpo",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(175)
		ply:SetMaxArmor(175)
	end,
})

---------------------------------------------------------------------------
-- WARRANT OFFICER (gelb)
---------------------------------------------------------------------------

TEAM_RN_WARRANTOFFICER = DarkRP.createJob("Republic Navy | Warrant Officer", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein Fachoffizier der Republikanischen Marine mit Spezialwissen in Technik, Navigation oder Waffensystemen an Bord.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnwo",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(180)
		ply:SetMaxArmor(180)
	end,
})

TEAM_RN_SENIORWARRANTOFFICER = DarkRP.createJob("Republic Navy | Senior Warrant Officer", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein erfahrener Fachoffizier der Republikanischen Marine, der Fachabteilungen an Bord leitet und Warrant Officers ausbildet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnswo",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(185)
		ply:SetMaxArmor(185)
	end,
})

TEAM_RN_CHIEFWARRANTOFFICER = DarkRP.createJob("Republic Navy | Chief Warrant Officer", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Der ranghöchste Fachoffizier der Republikanischen Marine und Bindeglied zwischen Fachpersonal und Offizierskorps.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rncwo",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(190)
		ply:SetMaxArmor(190)
	end,
})

---------------------------------------------------------------------------
-- SUBALTERNOFFIZIERE (rot)
---------------------------------------------------------------------------

TEAM_RN_SUBLIEUTENANT = DarkRP.createJob("Republic Navy | Sub Lieutenant", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein junger Offizier der Republikanischen Marine, der unter Aufsicht erste Führungsaufgaben auf der Brücke übernimmt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnsl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17ext_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(195)
		ply:SetMaxArmor(195)
	end,
})

TEAM_RN_LIEUTENANT = DarkRP.createJob("Republic Navy | Lieutenant", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein Offizier der Republikanischen Marine, verantwortlich für taktische Entscheidungen an Bord der Flotteneinheiten.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rno",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17ext_akimbo",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

---------------------------------------------------------------------------
-- STABSOFFIZIERE & ADMIRALITÄT (lila)
---------------------------------------------------------------------------

TEAM_RN_LIEUTENANTCOMMANDER = DarkRP.createJob("Republic Navy | Lieutenant Commander", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein Stabsoffizier der Republikanischen Marine, der als Erster Offizier den Kommandanten unterstützt und Abteilungen an Bord führt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnlc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17sa_dual",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_RN_COMMANDER = DarkRP.createJob("Republic Navy | Commander", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein hochrangiger Stabsoffizier der Republikanischen Marine, der Flottenbewegungen und größere Raumschlachten plant.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnso",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17sa_dual",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_RN_CAPTAIN = DarkRP.createJob("Republic Navy | Captain", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Der Kommandant eines republikanischen Kriegsschiffs, der die volle Verantwortung für Schiff, Besatzung und Einsatz trägt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rncpt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17sa_dual",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_RN_VIZEADMIRAL = DarkRP.createJob("Republic Navy | Vize Admiral", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein Flaggoffizier der Republikanischen Marine, der Kampfverbände aus mehreren Schiffen führt und den Admiral vertritt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnva",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17sa_dual",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(255)
		ply:SetMaxArmor(255)
	end,
})

TEAM_RN_ADMIRAL = DarkRP.createJob("Republic Navy | Admiral", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Ein Admiral der Republikanischen Marine, der ganze Flottenverbände befehligt und die Strategie im Raumkampf bestimmt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnadm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17sa_dual",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(270)
		ply:SetMaxArmor(270)
	end,
})

TEAM_RN_FLEETADMIRAL = DarkRP.createJob("Republic Navy | Fleet Admiral", {
	color = Color(35, 55, 85),
	model = RN_MODELS,
	description = "Der Oberbefehlshaber der Republikanischen Marine, verantwortlich für sämtliche Flotten und die Seekriegsführung der Republik.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_binoculars",
	},
	command = "rnfa",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc17sa_dual",
		"arccw_k_dc17sa",
		"shield_2_deployer",
		"weapon_cuff_handcuffs",
	},
	vehicles = { "heracles421_lfs_barc", "lvs_nuclass_attack_shuttle" },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(300)
		ply:SetMaxArmor(300)
	end,
})

-- ========================================================================
-- Republic Navy AVP
-- ========================================================================

TEAM_AVP_PVT = DarkRP.createJob("Republic Navy AVP | Private", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Pilot der Republikanischen Marine-Luftstreitkräfte (AVP), der Sternjäger und Transporter im Einsatz für die Republik fliegt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_pvt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_AVP_PFC = DarkRP.createJob("Republic Navy AVP | Private First Class", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Pilot der Republikanischen Marine-Luftstreitkräfte (AVP), der Sternjäger und Transporter im Einsatz für die Republik fliegt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_pfc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(210)
		ply:SetMaxArmor(210)
	end,
})

TEAM_AVP_SPC = DarkRP.createJob("Republic Navy AVP | Specialist", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Pilot der Republikanischen Marine-Luftstreitkräfte (AVP), der Sternjäger und Transporter im Einsatz für die Republik fliegt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_spc",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(215)
		ply:SetMaxArmor(215)
	end,
})

TEAM_AVP_LCPL = DarkRP.createJob("Republic Navy AVP | Lance Corporal", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Pilot der Republikanischen Marine-Luftstreitkräfte (AVP), der Sternjäger und Transporter im Einsatz für die Republik fliegt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_lcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_AVP_CPL = DarkRP.createJob("Republic Navy AVP | Corporal", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Unteroffizier der AVP-Staffel, der kleinere Jägerformationen im Gefecht anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_cpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"weapon_cuff_handcuffs",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(235)
		ply:SetMaxArmor(235)
	end,
})

TEAM_AVP_CCPL = DarkRP.createJob("Republic Navy AVP | Chief Corporal", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Unteroffizier der AVP-Staffel, der kleinere Jägerformationen im Gefecht anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_ccpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"weapon_cuff_handcuffs",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(240)
		ply:SetMaxArmor(240)
	end,
})

TEAM_AVP_FCPL = DarkRP.createJob("Republic Navy AVP | First Corporal", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Unteroffizier der AVP-Staffel, der kleinere Jägerformationen im Gefecht anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_fcpl",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"weapon_cuff_handcuffs",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_AVP_SGT = DarkRP.createJob("Republic Navy AVP | Sergeant", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Unteroffizier der AVP-Staffel, der kleinere Jägerformationen im Gefecht anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_sgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"weapon_cuff_handcuffs",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(260)
		ply:SetMaxArmor(260)
	end,
})

TEAM_AVP_FSGT = DarkRP.createJob("Republic Navy AVP | First Sergeant", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Unteroffizier der AVP-Staffel, der kleinere Jägerformationen im Gefecht anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_fsgt",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"weapon_cuff_handcuffs",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(265)
		ply:SetMaxArmor(265)
	end,
})

TEAM_AVP_SGM = DarkRP.createJob("Republic Navy AVP | Sergeant Major", {
	color = Color(35, 55, 85),
	model = { "models/silent/501st_ph1/avp/avp_v1/501st_avp_v1.mdl", "models/starwars/grady/navy/republic_navy_black.mdl" },
	description = "Ein Unteroffizier der AVP-Staffel, der kleinere Jägerformationen im Gefecht anführt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"weapon_lvsrepair",
		"weapon_binoculars",
	},
	command = "avp_sgm",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	weaponbox = {
		"arccw_k_dc15s",
		"arccw_k_dc15a",
		"arccw_k_dp23c",
		"weapon_cuff_handcuffs",
		"arccw_k_dc17_akimbo",
		"arccw_k_nade_thermal",
	},
	vehicles = {"heracles421_lfs_barc", "lvs_space_laat", "lvs_repulsorlift_dropship", "lvs_starfighter_vwing", "lvs_starfighter_ywing", "lvs_v19", "lvs_laatle_patrolgunship_imp", "lvs_fakehover_iftx", "lvs_walker_atte", },
	category = "Republic Navy",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(275)
		ply:SetMaxArmor(275)
	end,
})

-- ========================================================================
-- Droiden (CIS)
-- ========================================================================

TEAM_B1CE = DarkRP.createJob("B1 Commando Droide", {
	color = Color(0, 18, 154),
	model = {"models/player/hydro/b1_battledroids/officer/b1_battledroid_officer.mdl"},
	description = "Ein Standard-Kampfdroide der Separatistenarmee (CIS), massenproduziert und in großer Zahl an der Front gegen die Klontruppen der Republik eingesetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"arccw_k_e5",
		"arccw_k_nade_thermal",
		"weapon_binoculars",
	},
	command = "b1ce",
	max = 0,
	salary = 100,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = true,
	category = "Droiden",
	PlayerSpawn = function(ply)
		ply:SetHealth(200)
		ply:SetMaxHealth(200)
		ply:SetArmor(200)
		ply:SetMaxArmor(200)
	end,
})

TEAM_B1DHEAVYCE = DarkRP.createJob("B1 Assault Droide", {
	color = Color(0, 18, 154),
	model = {"models/player/hydro/b1_battledroids/assault/b1_battledroid_assault.mdl"},
	description = "Ein B1-Sturmdroide der Separatistenarmee, für aggressive Frontalangriffe mit erhöhter Feuerkraft ausgerüstet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"arccw_k_e5c",
		"arccw_k_nade_thermal",
		"arccw_k_nade_smoke",
		"arccw_k_z6",
		"weapon_binoculars",
	},
	command = "b1ace",
	max = 0,
	salary = 110,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = true,
	category = "Droiden",
	PlayerSpawn = function(ply)
		ply:SetHealth(225)
		ply:SetMaxHealth(225)
		ply:SetArmor(225)
		ply:SetMaxArmor(225)
	end,
})

TEAM_B1HEAVYCE = DarkRP.createJob("B1 Heavy Droide", {
	color = Color(0, 18, 154),
	model = {"models/player/hydro/b1_battledroids/heavy/b1_battledroid_heavy.mdl"},
	description = "Ein schwerer Kampfdroide der Separatistenarmee mit verstärkter Panzerung und schweren Waffen für Unterstützungsfeuer.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"datapad_player",
		"weapon_fists",
		"arccw_k_e5c",
		"arccw_k_nade_thermal",
		"weapon_binoculars",
	},
	command = "b1hce",
	max = 0,
	salary = 125,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = true,
	category = "Droiden",
	PlayerSpawn = function(ply)
		ply:SetHealth(250)
		ply:SetMaxHealth(250)
		ply:SetArmor(250)
		ply:SetMaxArmor(250)
	end,
})

TEAM_BXE = DarkRP.createJob("BX Commando Droide", {
	color = Color(0, 18, 154),
	model = {"models/npc/bx100_commando_droid/regular/bx100_commando_droid_regular.mdl"},
	description = "Ein Elite-Kampfdroide der Separatistenarmee mit spezieller Ausbildung für Kommando-Einsätze, schneller und wendiger als Standard-Kampfdroiden.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"arccw_k_e5bx",
		"arccw_k_nade_smoke",
		"arccw_k_e5s",
		"weapon_cuff_handcuffs",
		"arccw_k_nade_thermal",
		"weapon_binoculars",
	},
	command = "bxe",
	max = 0,
	salary = 150,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = true,
	category = "Droiden",
	PlayerSpawn = function(ply)
		ply:SetHealth(250)
		ply:SetMaxHealth(250)
		ply:SetArmor(300)
		ply:SetMaxArmor(300)
	end,
})

TEAM_DROIDCOMMANDER = DarkRP.createJob("Droiden-Kommandant", {
	color = Color(0, 0, 180),
	model = {"models/player/hydro/b1_battledroids/officer/b1_battledroid_officer.mdl"},
	description = "Der kommandierende Offiziersdroide der Separatistenarmee, der die Droidentruppen koordiniert und die strategischen Befehle der CIS-Führung umsetzt.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"realistic_hook",
		"arccw_k_e5bx",
		"arccw_k_e5s",
		"arccw_k_nade_thermal",
		"weapon_cuff_handcuffs",
		"weapon_binoculars",
	},
	command = "drocom",
	max = 1,
	salary = 300,
	admin = 0,
	vote = true,
	hasLicense = false,
	candemote = false,
	category = "Droiden",
	PlayerSpawn = function(ply)
		ply:SetHealth(300)
		ply:SetMaxHealth(300)
		ply:SetArmor(300)
		ply:SetMaxArmor(300)
	end,
})

TEAM_B2CE = DarkRP.createJob("B2 Super Kampfdroide", {
	color = Color(30, 30, 160),
	model = {"models/player/hydro/b2_battledroid/b2_battledroid.mdl"},
	description = "Ein Superkampfdroide der Separatistenarmee, schwer gepanzert und mit integrierten Waffensystemen für den direkten Frontalangriff ausgestattet.",
	weapons = {
		"gar_datapad",
		"mvp_perfecthands",
		"weapon_sw_datapad",
		"weapon_fists",
		"arccw_k_e5c",
		"arccw_k_nade_thermal",
		"arccw_k_nade_smoke",
		"arccw_k_z6",
		"weapon_binoculars",
	},
	command = "b2ce",
	max = 0,
	salary = 200,
	admin = 0,
	vote = false,
	hasLicense = false,
	candemote = false,
	category = "Droiden",
	PlayerSpawn = function(ply)
		ply:SetHealth(400)
		ply:SetMaxHealth(400)
		ply:SetArmor(350)
		ply:SetMaxArmor(350)
	end,
})

--[[---------------------------------------------------------------------------
Define which team joining players spawn into and what team you change to if demoted
---------------------------------------------------------------------------]]
GAMEMODE.DefaultTeam = TEAM_CADET
