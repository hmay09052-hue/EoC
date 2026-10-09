TOOL.Category = "EoC Droiden"
TOOL.Name = "#tool.eoc_droid_dispenser.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.Information = {
    { name = "left" },
}

TOOL.ClientConVar = {
    model = EOCDroids.Config.DispenserModels[1] or "models/props_borealis/bluebarrel001.mdl",
    health = tostring(EOCDroids.Config.DeployerHealth),
    drop = "0",
}
for _, entry in ipairs(EOCDroids.Config.Spawnlist) do
    TOOL.ClientConVar["n_" .. entry.key] = entry.key == "b1" and "4" or "0"
end

if CLIENT then
    language.Add("tool.eoc_droid_dispenser.name", "Droiden-Dispenser")
    language.Add("tool.eoc_droid_dispenser.desc", "Stellt einen Droiden-Container auf, aus dem die Droiden nacheinander aussteigen.")
    language.Add("tool.eoc_droid_dispenser.left", "Dispenser platzieren")
end

local function GetDispenserModel(mdl)
    if table.HasValue(EOCDroids.Config.DispenserModels, mdl) and EOCDroids.IsValidModel(mdl) then
        return mdl
    end
    return EOCDroids.PickModel(EOCDroids.Config.DispenserModels, "models/props_borealis/bluebarrel001.mdl")
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not EOCDroids.CheckToolUse(ply) then return false end

    local queue = EOCDroids.BuildQueue(self, "n_")
    if #queue == 0 then
        EOCDroids.Message(ply, "Waehle zuerst im Tool-Menue aus, welche Droiden im Dispenser sind.", 2)
        return false
    end

    local dispenser = ents.Create("eoc_droid_dispenser")
    if not IsValid(dispenser) then return false end

    dispenser:SetModel(GetDispenserModel(self:GetClientInfo("model")))
    dispenser:SetPos(trace.HitPos)
    dispenser:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
    dispenser.Queue = queue
    dispenser.Drop = self:GetClientNumber("drop", 0) == 1
    dispenser.DeployHealth = math.Clamp(math.floor(self:GetClientNumber("health", 1500)), 100, 20000)
    dispenser.Creator = ply
    dispenser:Spawn()
    dispenser:Activate()

    undo.Create("EoC Droiden-Dispenser")
        undo.AddEntity(dispenser)
        undo.SetPlayer(ply)
    undo.Finish()
    cleanup.Add(ply, "npcs", dispenser)

    return true
end

function TOOL:Think()
    local mdl = GetDispenserModel(self:GetClientInfo("model"))
    if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= mdl then
        self:MakeGhostEntity(mdl, vector_origin, angle_zero)
    end

    if IsValid(self.GhostEntity) then
        local ply = self:GetOwner()
        local tr = ply:GetEyeTrace()
        self.GhostEntity:SetPos(tr.HitPos)
        self.GhostEntity:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
    end
end

function TOOL.BuildCPanel(panel)
    panel:Help("#tool.eoc_droid_dispenser.desc")

    local models = {}
    for _, mdl in ipairs(EOCDroids.Config.DispenserModels) do
        if EOCDroids.IsValidModel(mdl) then models[mdl] = {} end
    end
    if next(models) then
        panel:AddControl("PropSelect", { Label = "Modell", ConVar = "eoc_droid_dispenser_model", Height = 0, Models = models })
    end

    panel:NumSlider("Lebenspunkte", "eoc_droid_dispenser_health", 100, 20000, 0)
    panel:CheckBox("Vom Himmel fallen lassen", "eoc_droid_dispenser_drop")

    panel:Help("Anzahl der Droiden im Dispenser (max. " .. EOCDroids.Config.MaxPerDeployer .. " insgesamt):")
    for _, entry in ipairs(EOCDroids.Config.Spawnlist) do
        EOCDroids.AddDroidSlider(panel, entry, "eoc_droid_dispenser_n_" .. entry.key)
    end
end
