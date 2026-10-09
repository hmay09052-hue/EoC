TOOL.Category = "EoC Droiden"
TOOL.Name = "#tool.eoc_droid_notarget.name"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.eoc_droid_notarget.name", "Droiden: No-Target")
    language.Add("tool.eoc_droid_notarget.desc", "Macht Spieler fuer Droiden und NPCs unsichtbar.")
    language.Add("tool.eoc_droid_notarget.left", "Spieler wird unsichtbar fuer Droiden")
    language.Add("tool.eoc_droid_notarget.right", "Spieler wird wieder sichtbar")
    language.Add("tool.eoc_droid_notarget.reload", "Fuer dich selbst umschalten")
end

local function SetNoTarget(admin, target, state)
    target:SetNoTarget(state)

    if state then
        EOCDroids.Message(target, "Du bist jetzt fuer Droiden unsichtbar (No-Target).", 1)
        if admin ~= target then EOCDroids.Message(admin, target:Nick() .. " ist jetzt fuer Droiden unsichtbar.", 1) end
    else
        EOCDroids.Message(target, "Droiden koennen dich wieder sehen.", 2)
        if admin ~= target then EOCDroids.Message(admin, target:Nick() .. " ist wieder sichtbar.", 2) end
    end
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not IsValid(trace.Entity) or not trace.Entity:IsPlayer() then return false end
    if not EOCDroids.CheckToolUse(ply) then return false end
    SetNoTarget(ply, trace.Entity, true)
    return true
end

function TOOL:RightClick(trace)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not IsValid(trace.Entity) or not trace.Entity:IsPlayer() then return false end
    if not EOCDroids.CheckToolUse(ply) then return false end
    SetNoTarget(ply, trace.Entity, false)
    return true
end

function TOOL:Reload()
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not EOCDroids.CheckToolUse(ply) then return false end
    SetNoTarget(ply, ply, not ply:IsFlagSet(FL_NOTARGET))
    return true
end

function TOOL.BuildCPanel(panel)
    panel:Help("#tool.eoc_droid_notarget.desc")
end
