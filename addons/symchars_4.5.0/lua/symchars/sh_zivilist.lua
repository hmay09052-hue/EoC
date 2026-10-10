--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Zivilist-Job (Standard-Job fuer Charaktere ohne Einheit)
    Wird direkt vom Addon angelegt, darkrpmodification ist dafuer nicht noetig.
    Steht der Job schon in der jobs.lua (Befehl "teamzivilisten"), wird er hier nicht doppelt angelegt.
-------------------------------------------------------------------------------------------------------------]]

local function JobExists(command)
    for _, job in pairs(RPExtraTeams or {}) do
        if job.command == command then return true end
    end
    return false
end

local function EnsureCategory(name)
    if not DarkRP.createCategory then return end
    local cats = DarkRP.getCategories and DarkRP.getCategories()
    for _, cat in ipairs(cats and cats.jobs or {}) do
        if cat.name == name then return end
    end
    DarkRP.createCategory({
        name = name,
        categorises = "jobs",
        startExpanded = true,
        color = Color(0, 18, 154, 255),
        canSee = function() return true end,
        sortOrder = 1,
    })
end

local function CreateZivilist()
    if not DarkRP or not DarkRP.createJob then return end

    if not JobExists("teamzivilisten") then
        EnsureCategory("Zivilist")

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
            weapons = { "weapon_fists", "weapon_crypto_datapad" },
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
    else
        for i, job in pairs(RPExtraTeams) do
            if job.command == "teamzivilisten" then TEAM_ZIVILIST = i break end
        end
    end

    -- Zivilist ist der Standard-Job (neue Spieler spawnen als Zivilist)
    local gm = GAMEMODE or GM
    if gm and TEAM_ZIVILIST then gm.DefaultTeam = TEAM_ZIVILIST end
end

-- DarkRP ruft diesen Hook auf, sobald eigene Jobs angelegt werden duerfen
hook.Add("loadCustomDarkRPItems", "symchars_zivilist", CreateZivilist)

-- Falls DarkRP beim Laden dieses Addons schon fertig ist (z. B. nach Lua-Refresh)
if DarkRP and DarkRP.createJob and RPExtraTeams and #RPExtraTeams > 0 then
    CreateZivilist()
end
