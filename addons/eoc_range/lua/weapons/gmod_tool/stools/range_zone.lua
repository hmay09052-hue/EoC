--[[
    EoC Range – Toolgun für Bahn-, Start- und Zielzonen
    Linksklick auf eine Zone: auswählen. Linksklick auf den Boden: erste Ecke.
    Rechtsklick: zweite Ecke -> Zone wird auf das Rechteck gesetzt (Höhe bleibt, außer die Ecken liegen höher).
]]

TOOL.Category = "EoC Range"
TOOL.Name = "#tool.range_zone.name"
TOOL.Information = {
    { name = "left" },
    { name = "right" },
    { name = "reload" },
}

if CLIENT then
    language.Add("tool.range_zone.name", "EoC Range – Zone")
    language.Add("tool.range_zone.desc", "Größe von Bahn-, Start- und Zielzonen festlegen")
    language.Add("tool.range_zone.left", "Zone anklicken = auswählen, danach Boden anklicken = erste Ecke")
    language.Add("tool.range_zone.right", "Zweite Ecke setzen und Zone anpassen")
    language.Add("tool.range_zone.reload", "Auswahl aufheben")
end

local function Tell(ply, text)
    if EoCRange and EoCRange.Notify then EoCRange.Notify(ply, text, 0) else ply:ChatPrint(text) end
end

local function Allowed(ply)
    return IsValid(ply) and EoCRange and EoCRange.IsAdmin(ply)
end

function TOOL:LeftClick(tr)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not Allowed(ply) then return false end

    local ent = tr.Entity
    if IsValid(ent) and ent.IsRangeZone then
        self.Zone = ent
        self.CornerA = nil
        Tell(ply, ent.PrintName .. " (Bahn " .. ent:GetLane() .. ") ausgewählt. Jetzt die erste Ecke anklicken.")
        return true
    end

    if not IsValid(self.Zone) then
        Tell(ply, "Zuerst eine Zone anklicken.")
        return false
    end
    self.CornerA = tr.HitPos
    Tell(ply, "Erste Ecke gesetzt. Rechtsklick auf die gegenüberliegende Ecke.")
    return true
end

function TOOL:RightClick(tr)
    if CLIENT then return true end
    local ply = self:GetOwner()
    if not Allowed(ply) then return false end
    local zone = self.Zone
    if not IsValid(zone) or not self.CornerA then
        Tell(ply, "Zuerst Zone auswählen und erste Ecke setzen.")
        return false
    end

    -- beide Ecken in das gedrehte System der Zone (nur Gier) umrechnen
    local yaw = Angle(0, zone:GetAngles().y, 0)
    local inv = Angle(0, -yaw.y, 0)
    local a, b = Vector(self.CornerA), Vector(tr.HitPos)
    a:Rotate(inv)
    b:Rotate(inv)

    local minX, maxX = math.min(a.x, b.x), math.max(a.x, b.x)
    local minY, maxY = math.min(a.y, b.y), math.max(a.y, b.y)
    local minZ, maxZ = math.min(a.z, b.z), math.max(a.z, b.z)

    local center = Vector((minX + maxX) / 2, (minY + maxY) / 2, minZ)
    center:Rotate(yaw)

    zone:SetPos(center)
    zone:SetAngles(yaw)
    zone:SetSizeX(math.max(maxX - minX, 16))
    zone:SetSizeY(math.max(maxY - minY, 16))
    if maxZ - minZ > zone:GetSizeZ() then zone:SetSizeZ(maxZ - minZ) end

    self.CornerA = nil
    Tell(ply, string.format("Zone angepasst: %d x %d x %d", zone:GetSizeX(), zone:GetSizeY(), zone:GetSizeZ()))
    return true
end

function TOOL:Reload()
    if CLIENT then return true end
    self.Zone = nil
    self.CornerA = nil
    return true
end

function TOOL.BuildCPanel(panel)
    panel:AddControl("Header", { Description = "Links: Zone wählen / erste Ecke. Rechts: zweite Ecke. R: Auswahl aufheben.\nZonen sind nur mit Physgun oder Toolgun in der Hand sichtbar." })
end
