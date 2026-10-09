TOOL.Category = "EoC Droiden"
TOOL.Name = "#tool.eoc_droid_pod.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.Information = {
    { name = "left" },
}

TOOL.ClientConVar = {}
for _, entry in ipairs(EOCDroids.Config.Spawnlist) do
    TOOL.ClientConVar["n_" .. entry.key] = entry.key == "b1" and "4" or "0"
end

local POD_MODEL = "models/summe/drochclass/pod.mdl"

if CLIENT then
    language.Add("tool.eoc_droid_pod.name", "Droiden-Boarding-Pod")
    language.Add("tool.eoc_droid_pod.desc", "Ein Boarding-Pod bohrt sich durch Decken bis zur Zielposition und setzt Droiden ab.")
    language.Add("tool.eoc_droid_pod.left", "Pod an der Zielposition landen lassen")
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end

    local ply = self:GetOwner()
    if not EOCDroids.CheckToolUse(ply) then return false end

    local queue = EOCDroids.BuildQueue(self, "n_")
    if #queue == 0 then
        EOCDroids.Message(ply, "Waehle zuerst im Tool-Menue aus, welche Droiden im Pod sind.", 2)
        return false
    end

    local pod = ents.Create("eoc_droid_pod")
    if not IsValid(pod) then return false end

    pod:SetPos(trace.HitPos)
    pod:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
    pod.Queue = queue
    pod.Drop = true
    pod.Creator = ply
    pod:Spawn()
    pod:Activate()

    undo.Create("EoC Boarding-Pod")
        undo.AddEntity(pod)
        undo.SetPlayer(ply)
    undo.Finish()
    cleanup.Add(ply, "npcs", pod)

    return true
end

function TOOL:Think()
    local mdl = EOCDroids.PickModel(POD_MODEL, "models/props_c17/oildrum001_explosive.mdl")
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
    panel:Help("#tool.eoc_droid_pod.desc")
    panel:Help("Anzahl der Droiden im Pod (max. " .. EOCDroids.Config.MaxPerDeployer .. " insgesamt):")

    for _, entry in ipairs(EOCDroids.Config.Spawnlist) do
        EOCDroids.AddDroidSlider(panel, entry, "eoc_droid_pod_n_" .. entry.key)
    end
end
