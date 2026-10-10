if CLIENT then
    include("autorun/adv_dropship_lang.lua")
    include("autorun/client/adv_dropship_profiles.lua")

    language.Add("tool.adv_dropship.name", "Advanced Dropship Spawner")
    language.Add("tool.adv_dropship.desc", "By: Biology Boy")
    language.Add("tool.adv_dropship.0", "Left click to spawn. Right click to remove.")
end

TOOL.Category = "Dropship Tools"
TOOL.Name = "Advanced Dropship Spawner"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar = {
    model = "models/props_c17/oildrum001.mdl",
    speed = "300",
    arrival_height = "500",
    landing_height = "100",
    ground_time = "5",
    npc_class = "npc_combine_s",
    npc_count = "50",
    entities_per_wave = "4",
    max_total_npcs = "20",
    npc_repeat = "0",
    npc_interval = "1",
    npc_aligned = "1",
    has_health = "0",
    max_health = "1000",
    collision = "1",
    arrival_sound = "",
    departure_sound = "",
    hover_sound = "",
    spawn_effect = "cball_explode",
    flight_wobble_amp = "2",
    flight_wobble_freq = "4",
    ground_wobble_amp = "1",
    ground_wobble_freq = "2",
    exit_height = "300",
    exit_speed = "600",
    weapon = "weapon_smg1",
    lang = "en",
}

local ghostEnt

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    local pos = trace.HitPos
    local ang = Angle(0, ply:EyeAngles().y, 0)
    local model = self:GetClientInfo("model")
    if not util.IsValidModel(model) then return false end

    local ent = ents.Create("adv_dropship")
    if not IsValid(ent) then return false end

    local offset = ang:Forward() * -1000 + Vector(0, 0, tonumber(self:GetClientInfo("arrival_height")) or 300)
    ent:SetModel(model)
    ent:SetPos(pos + offset)
    ent:SetAngles(ang)
    ent.TargetLandingPos = pos + Vector(0, 0, tonumber(self:GetClientInfo("landing_height")) or 100)

    ent.SpawnerData = {
        Speed = tonumber(self:GetClientInfo("speed")) or 300,
        LandingHeight = tonumber(self:GetClientInfo("landing_height")) or 100,
        GroundTime = tonumber(self:GetClientInfo("ground_time")) or 5,
        NPCClass = self:GetClientInfo("npc_class"),
        NPCCount = tonumber(self:GetClientInfo("npc_count")) or 50,
        EntitiesPerWave = tonumber(self:GetClientInfo("entities_per_wave")) or 4,
        MaxTotalNPCs = tonumber(self:GetClientInfo("max_total_npcs")) or 20,
        Repeat = self:GetClientNumber("npc_repeat") == 1,
        Interval = tonumber(self:GetClientInfo("npc_interval")) or 1,
        Aligned = self:GetClientNumber("npc_aligned") == 1,
        HasHealth = self:GetClientNumber("has_health") == 1,
        MaxHealth = tonumber(self:GetClientInfo("max_health")) or 1000,
        Collision = self:GetClientNumber("collision") == 1,
        Weapon = self:GetClientInfo("weapon"),
        Sounds = {
            Arrival = self:GetClientInfo("arrival_sound"),
            Departure = self:GetClientInfo("departure_sound"),
            Hover = self:GetClientInfo("hover_sound")
        },
        SpawnEffect = self:GetClientInfo("spawn_effect"),
        FlightWobbleAmp = tonumber(self:GetClientInfo("flight_wobble_amp")) or 2,
        FlightWobbleFreq = tonumber(self:GetClientInfo("flight_wobble_freq")) or 4,
        GroundWobbleAmp = tonumber(self:GetClientInfo("ground_wobble_amp")) or 1,
        GroundWobbleFreq = tonumber(self:GetClientInfo("ground_wobble_freq")) or 2,
        ExitHeight = tonumber(self:GetClientInfo("exit_height")) or 300,
        ExitSpeed = tonumber(self:GetClientInfo("exit_speed")) or 600,
        Owner = ply,
    }

    ent:Spawn()
    ent:Activate()

    undo.Create("Advanced Dropship")
        undo.AddEntity(ent)
        undo.SetPlayer(ply)
    undo.Finish()

    return true
end

function TOOL:RightClick(trace)
    if SERVER then
        local ent = trace.Entity
        if IsValid(ent) and ent:GetClass() == "adv_dropship" then
            ent:Remove()
            return true
        end
    end
    return false
end

function TOOL:Think()
    if CLIENT then
        local model = self:GetClientInfo("model")
        if not util.IsValidModel(model) then
            if IsValid(ghostEnt) then ghostEnt:Remove() end
            ghostEnt = nil
            return
        end

        if not IsValid(ghostEnt) or ghostEnt:GetModel() ~= model then
            if IsValid(ghostEnt) then ghostEnt:Remove() end
            ghostEnt = ClientsideModel(model, RENDERGROUP_TRANSLUCENT)
            if not IsValid(ghostEnt) then return end
            ghostEnt:SetRenderMode(RENDERMODE_TRANSALPHA)
            ghostEnt:SetColor(Color(255, 255, 255, 150))
            ghostEnt:SetNoDraw(false)
        end

        local trace = self:GetOwner():GetEyeTrace()
        if IsValid(ghostEnt) and trace.Hit then
            ghostEnt:SetPos(trace.HitPos + Vector(0, 0, 1))
            ghostEnt:SetAngles(Angle(0, self:GetOwner():EyeAngles().y, 0))
        end
    end
end

function TOOL:Holster()
    if CLIENT and IsValid(ghostEnt) then
        ghostEnt:Remove()
        ghostEnt = nil
    end
end

function TOOL.BuildCPanel(panel)
    local lang = LocalPlayer():GetInfo("adv_dropship_lang") or "pt"
    local L = ADV_DROPSHIP_LANG[lang] or ADV_DROPSHIP_LANG["pt"]

    local function AddSlider(lblKey, cmd, min, max, typ)
        panel:AddControl("Slider", {
            Label = L[lblKey],
            Type = typ or "Float",
            Min = min,
            Max = max,
            Command = "adv_dropship_" .. cmd
        })
    end

    panel:AddControl("Header", { Text = L.header, Description = L.description })

    panel:AddControl("ComboBox", {
        Label = L.lang,
        MenuButton = 0,
        Options = {
            ["Português"] = { adv_dropship_lang = "pt" },
            ["English"] = { adv_dropship_lang = "en" },
            ["Francais"] = { adv_dropship_lang = "fr" }
        }
    })

    panel:AddControl("Label", { Text = L.manage_profiles })

    local combo = vgui.Create("DComboBox", panel)
    combo:SetSortItems(true)
    combo:SetValue("...")
    for _, name in ipairs(ADV_DROPSHIP_PROFILES.List()) do
        combo:AddChoice(name)
    end
    panel:AddItem(combo)

    local txtName = vgui.Create("DTextEntry", panel)
    txtName:SetPlaceholderText(L.profile_placeholder)
    panel:AddItem(txtName)

    local btnSave = vgui.Create("DButton", panel)
    btnSave:SetText(L.save_profile)
    btnSave.DoClick = function()
        local name = txtName:GetValue()
        if name == "" then return end

        local data = {}
        local vars = {
            "model", "speed", "arrival_height", "landing_height", "ground_time",
            "npc_class", "npc_count", "entities_per_wave", "max_total_npcs",
            "npc_repeat", "npc_interval", "npc_aligned", "has_health", "max_health",
            "collision", "weapon", "arrival_sound", "departure_sound", "hover_sound",
            "spawn_effect", "flight_wobble_amp", "flight_wobble_freq",
            "ground_wobble_amp", "ground_wobble_freq", "exit_height",
            "exit_speed", "lang"
        }

        for _, k in ipairs(vars) do
            data[k] = GetConVar("adv_dropship_" .. k):GetString()
        end

        if ADV_DROPSHIP_PROFILES.Save(name, data) then
            combo:AddChoice(name)
        end
    end
    panel:AddItem(btnSave)

    local btnLoad = vgui.Create("DButton", panel)
    btnLoad:SetText(L.load_profile)
    btnLoad.DoClick = function()
        local name = combo:GetValue()
        if name == "" then return end
        local data = ADV_DROPSHIP_PROFILES.Load(name)
        if not data then return end
        for k, v in pairs(data) do
            RunConsoleCommand("adv_dropship_" .. k, v)
        end
    end
    panel:AddItem(btnLoad)

    local btnDelete = vgui.Create("DButton", panel)
    btnDelete:SetText(L.delete_profile)
    btnDelete.DoClick = function()
        local name = combo:GetValue()
        if name == "" then return end
        if ADV_DROPSHIP_PROFILES.Delete(name) then
            combo:Clear()
            for _, prof in ipairs(ADV_DROPSHIP_PROFILES.List()) do
                combo:AddChoice(prof)
            end
        end
    end
    panel:AddItem(btnDelete)

    panel:AddControl("Textbox", { Label = L.model, Command = "adv_dropship_model" })
    AddSlider("speed", "speed", 100, 2000)
    AddSlider("arrival_height", "arrival_height", 100, 5000)
    AddSlider("landing_height", "landing_height", 10, 1000)
    AddSlider("ground_time", "ground_time", 1, 60)
    panel:AddControl("Textbox", { Label = L.npc_class, Command = "adv_dropship_npc_class" })
    panel:AddControl("Textbox", { Label = L.weapon, Command = "adv_dropship_weapon" })
    AddSlider("npc_count", "npc_count", 1, 500, "Integer")
    AddSlider("entities_per_wave", "entities_per_wave", 1, 50, "Integer")
    AddSlider("max_total_npcs", "max_total_npcs", 1, 100, "Integer")
    panel:AddControl("CheckBox", { Label = L.npc_repeat, Command = "adv_dropship_npc_repeat" })
    AddSlider("npc_interval", "npc_interval", 0.1, 10)
    panel:AddControl("CheckBox", { Label = L.npc_aligned, Command = "adv_dropship_npc_aligned" })
    panel:AddControl("CheckBox", { Label = L.has_health, Command = "adv_dropship_has_health" })
    AddSlider("max_health", "max_health", 100, 10000, "Integer")
    panel:AddControl("CheckBox", { Label = L.collision, Command = "adv_dropship_collision" })
    panel:AddControl("Textbox", { Label = L.arrival_sound, Command = "adv_dropship_arrival_sound" })
    panel:AddControl("Textbox", { Label = L.departure_sound, Command = "adv_dropship_departure_sound" })
    panel:AddControl("Textbox", { Label = L.hover_sound, Command = "adv_dropship_hover_sound" })
    panel:AddControl("Textbox", { Label = "Spawn Effect", Command = "adv_dropship_spawn_effect" })
    AddSlider("flight_wobble_amp", "flight_wobble_amp", 0, 10)
    AddSlider("flight_wobble_freq", "flight_wobble_freq", 0, 10)
    AddSlider("ground_wobble_amp", "ground_wobble_amp", 0, 10)
    AddSlider("ground_wobble_freq", "ground_wobble_freq", 0, 10)
    AddSlider("exit_height", "exit_height", 0, 5000)
    AddSlider("exit_speed", "exit_speed", 100, 3000)
end