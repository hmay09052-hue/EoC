--[[
   _____ _    _ __  __ __  __ ______                   
  / ____| |  | |  \/  |  \/  |  ____|                  
 | (___ | |  | | \  / | \  / | |__                     
  \___ \| |  | | |\/| | |\/| |  __|                    
  ____) | |__| | |  | | |  | | |____                   
 |_____/_\____/|_| _|_|_|__|_|______|___ _______ _____ 
 | \ | |  ____\ \ / /__   __|  _ \ / __ \__   __/ ____|
 |  \| | |__   \ V /   | |  | |_) | |  | | | | | (___  
 | . ` |  __|   > <    | |  |  _ <| |  | | | |  \___ \ 
 | |\  | |____ / . \   | |  | |_) | |__| | | |  ____) |
 |_| \_|______/_/ \_\  |_|  |____/ \____/  |_| |_____/ 
                                                       
    Created by Summe: https://steamcommunity.com/id/DerSumme/ 
    Purchased content: https://discord.gg/k6YdMwj9w2
]]--

TOOL.Category = "Summe Nextbots"
TOOL.Name = "Droid Dispenser"
TOOL.Command = nil
TOOL.ConfigName = nil
 
if CLIENT then
    language.Add("Tool.droid_dispenser_spawner.name", "Create Droid Dispenser")
    language.Add("Tool.droid_dispenser_spawner.desc", "Spawns a droid container with droids inside, which are spawned one by one.")
    language.Add("Tool.droid_dispenser_spawner.0", "Left click: Spawns the dispenser")
else
    util.AddNetworkString("SummeNextbots.SpawnDispenser")

    local function isValidClass(npcClass)
        for _, v in pairs(SummeNextbots.Config.Tool) do
            if v.class == npcClass then
                return true
            end
        end
        return false
    end

    net.Receive("SummeNextbots.SpawnDispenser", function(len, ply)
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end

        local pos = net.ReadVector()
        local data = net.ReadTable()
        local model = net.ReadString()
        local hp = net.ReadUInt(15)
        local shouldFall = net.ReadBool()
        local data_ = {}

        for k, v in pairs(data) do
            if not isValidClass(k) then print("EXPLOIT DETECTED!!! USED BY ".. ply:Name()) return end
            for i = 1, v do
                table.insert(data_, k)
            end
        end

        if shouldFall then
            local pod = ents.Create("summe_dispenser_flying")
            pod:SetPos(pos + Vector(0, 0, 600))
            pod.TargetPos = pos
            pod.NPCList = data_
            pod:Spawn()
            pod:SetModel(model)
            pod:SetMaxHealth(hp)
            pod:SetHealth(hp)

            local phys = pod:GetPhysicsObject()
            if IsValid(phys) then
                phys:Wake()
            end
        else
            local pod = ents.Create("summe_dispenser_landed")
            pod:SetPos(pos)
            pod.TargetPos = pos
            pod.NPCList = data_
            pod:Spawn()
            pod:SetModel(model)
            pod:SetMaxHealth(hp)
            pod:SetHealth(hp)

            undo.Create("Droid Dispenser Pod")
            undo.AddEntity(pod)
            undo.SetPlayer(ply)
            undo.Finish()
        end

    end)
end

function TOOL:LeftClick(trace)
    if not IsFirstTimePredicted() then return false end

    if CLIENT then

        local data = {}
        for k, v in SortedPairs(SummeNextbots.Config.Tool) do
            data[v.class] = cookie.GetNumber("SummeNextbots.Type."..tostring(k)) or 0
        end

        local pos = trace.HitPos
        if not pos then return end

        local model = GetConVarString("droid_dispenser_spawner_model")
        if model == nil then
            model = "models/dav0r/thruster.mdl"
        end

        net.Start("SummeNextbots.SpawnDispenser")
        net.WriteVector(pos)
        net.WriteTable(data)
        net.WriteString(model)
        net.WriteUInt(cookie.GetNumber("SummeNextbots.DispenserHealth") or 1000, 15)
        net.WriteBool(tobool(cookie.GetString("SummeNextbots.DropDispenser") or "false"))
        net.SendToServer()
    end

    return true
end
 
function TOOL:RightClick(trace)
    if not IsFirstTimePredicted() then return false end

    return true
end


local ConVarsDefault = TOOL:BuildConVarList()
 
function TOOL:BuildCPanel()
    if SERVER then return end

    self:AddControl("Header", {
        Text = "Droid Boarding Pod",
        Description = "With this tool you spawn a boarding pod from which droids come out."
    })

    self:AddControl("Label", {
        Text = "The number of droids in the container:",
    })

    for k, v in SortedPairs(SummeNextbots.Config.Tool) do
        local panel = vgui.Create("DPanel")
        panel:SetTall(ScrH() * .05)

        local spawnIcon = vgui.Create("SpawnIcon", panel)
        spawnIcon:SetModel(v.previewModel or "models/Gibs/HGIBS.mdl")
        spawnIcon:Dock(LEFT)

        local slider = vgui.Create("DNumSlider", panel)
        slider:SetText(v.name)
        slider:SetMinMax(0, 10)
        slider:SetDecimals(0)
        slider:SetValue(cookie.GetNumber("SummeNextbots.Type."..tostring(k)) or 0)
        slider:Dock(LEFT)
        slider:SetWide(240)
        slider:SetDark(true)
        function slider:OnValueChanged(value)
            value = math.Round(value, 0)
            cookie.Set("SummeNextbots.Type."..tostring(k), value)
        end
        
        self:AddItem(panel)
    end

    self:AddControl("Label", {
        Text = "Settings:",
    })

    self:AddControl("PropSelect", { Label = "Select model", ConVar = "droid_dispenser_spawner_model", Height = 0, Models = list.Get("SummeNextbots.DispenserModels")})

    local HPSlider = vgui.Create("DNumSlider")
    HPSlider:SetText("Dispenser Health")
    HPSlider:SetMinMax(0, 10000)
    HPSlider:SetDecimals(0)
    HPSlider:SetValue(cookie.GetNumber("SummeNextbots.DispenserHealth", 1000))
    HPSlider:SetDark(true)
    function HPSlider:OnValueChanged(value)
        value = math.Round(value, 0)
        cookie.Set("SummeNextbots.DispenserHealth", value)
    end

    self:AddItem(HPSlider)

    local checkbox = vgui.Create("DCheckBoxLabel")
    checkbox:SetText("Fall from sky")
    checkbox:SetValue(tobool(cookie.GetString("SummeNextbots.DropDispenser", "false")))
    function checkbox:OnChange(value)
        cookie.Set("SummeNextbots.DropDispenser", tostring(value))
    end

    self:AddItem(checkbox)
end

if not CLIENT then return end

CreateClientConVar("droid_dispenser_spawner_model", "models/props/starwars/vehicles/sbd_dispenser.mdl", true, false)

list.Set("SummeNextbots.DispenserModels", "models/props/starwars/vehicles/sbd_dispenser.mdl", {})
list.Set("SummeNextbots.DispenserModels", "models/props/starwars/vehicles/droideka_dispenser.mdl", {})
list.Set("SummeNextbots.DispenserModels", "models/props/starwars/vehicles/bd_dispenser.mdl", {})

local mat = Material("models/wireframe")
local circleMat = Material("particle/particle_ring_wave_addnofog")

-- Renders the marker. 
hook.Add("HUDPaint", "NextBotSpawner.DispenserRender", function()
    local ply = LocalPlayer()
    local tool = ply:GetActiveWeapon()

    if IsValid(tool) and tool:GetClass() == "gmod_tool" and ply:GetTool() and ply:GetTool().Mode == "droid_dispenser_spawner" then
        local targetPos = ply:GetEyeTrace().HitPos
        if isvector(targetPos) then
            cam.Start3D()

            render.SetMaterial(circleMat)
            render.DrawQuadEasy(targetPos + Vector(0, 0, 0), Vector(0, 0, 1), 250, 250, Color(201, 201, 201, 19), 0)

            render.DrawQuadEasy(targetPos + Vector(0, 0, 0), Vector(0, 0, 1), 600, 600, Color(201, 201, 201, 19), 0)

                render.ModelMaterialOverride(mat)
                render.SetColorModulation(0.902,0.416,1)
                render.Model({
                    model = GetConVarString("droid_dispenser_spawner_model"),
                    pos = targetPos,
                    angle = Angle(0),
                    size = 3,
                })
            cam.End3D()
        end
    end
end)