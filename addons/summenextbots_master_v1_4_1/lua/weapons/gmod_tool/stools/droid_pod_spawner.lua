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
TOOL.Name = "Droid Boarding Ship"
TOOL.Command = nil
TOOL.ConfigName = nil
 
cleanup.Register("droid_boaring_pods")

if CLIENT then
    language.Add("Tool.droid_pod_spawner.name", "Create Boarding Ship")
    language.Add("Tool.droid_pod_spawner.desc", "Spawns a boarding ship that drills through to the position and then spawns droids.")
    language.Add("Tool.droid_pod_spawner.0", "Left click: Spawns the ship")
else
    util.AddNetworkString("SummeNextbots.Spawn")

    local function isValidClass(npcClass)
        for _, v in pairs(SummeNextbots.Config.Tool) do
            if v.class == npcClass then
                return true
            end
        end
        return false
    end

    net.Receive("SummeNextbots.Spawn", function(len, ply)
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) or wep:GetClass() ~= "gmod_tool" then return end

        local pos = net.ReadVector()
        local data = net.ReadTable()
        local data_ = {}

        for k, v in pairs(data) do
            if not isValidClass(k) then print("EXPLOIT DETECTED!!! USED BY ".. ply:Name()) return end
            for i = 1, v do
                table.insert(data_, k)
            end
        end

        local pod = ents.Create("summe_boarding_pod_flying")
        pod:SetPos(pos)
        pod.TargetPos = pos
        pod.NPCList = data_
        pod:Spawn()

        undo.Create("Droid Boarding Pod")
        undo.AddEntity(pod)
        undo.SetPlayer(ply)
        undo.Finish()

    end)
end

function TOOL:LeftClick(trace)
    if not IsFirstTimePredicted() then return false end

    if CLIENT then

        local data = {}
        for k, v in SortedPairs(SummeNextbots.Config.Tool) do
            data[v.class] = cookie.GetNumber("SummeNextbots.TypePod."..tostring(k)) or 0
        end

        local pos = trace.HitPos
        if not pos then return end

        net.Start("SummeNextbots.Spawn")
        net.WriteVector(pos)
        net.WriteTable(data)
        net.SendToServer()
    end

    return true
end

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
        slider:SetValue(cookie.GetNumber("SummeNextbots.TypePod."..tostring(k)) or 0)
        slider:Dock(LEFT)
        slider:SetWide(240)
        slider:SetDark(true)
        function slider:OnValueChanged(value)
            value = math.Round(value, 0)
            cookie.Set("SummeNextbots.TypePod."..tostring(k), value)
        end
        
        self:AddItem(panel)
    end
end

if not CLIENT then return end

local mat = Material("models/wireframe")
local circleMat = Material("particle/particle_ring_wave_addnofog")

-- Renders the marker. 
hook.Add("HUDPaint", "NextBotSpawner.Render", function()
    local ply = LocalPlayer()
    local tool = ply:GetActiveWeapon()

    if IsValid(tool) and tool:GetClass() == "gmod_tool" and ply:GetTool() and ply:GetTool().Mode == "droid_pod_spawner" then
        local targetPos = ply:GetEyeTrace().HitPos
        if isvector(targetPos) then
            cam.Start3D()

                render.SetMaterial(circleMat)
                local intPol = (math.sin( CurTime() ) * 300 * 2)
                render.DrawQuadEasy(targetPos + Vector(0, 0, 0), Vector(0, 0, 1), 0 + intPol, 0 + intPol, Color(201, 201, 201, 19), 0)

                render.ModelMaterialOverride(mat)
                render.SetColorModulation(0.416,0.69,1)
                render.Model({
                    model = "models/summe/drochclass/pod.mdl",
                    pos = targetPos + Vector(0, 0, 600),
                    angle = Angle(0),
                })
            cam.End3D()
        end
    end
end)