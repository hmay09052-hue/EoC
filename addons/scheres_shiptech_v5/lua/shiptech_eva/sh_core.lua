--[[
    ShipTech EVA – gemeinsame Definitionen: Entities und Hilfsfunktionen
    Entities: Ankerpunkt (Schadensstelle), EVA-Spind (Luftschleuse), Versorgungspunkt
]]

local C = ShipTech.Config
local EC = C.EVA
local EVA = ShipTech.EVA

if SERVER then
    for _, n in ipairs({ "ShipTechEVA_State", "ShipTechEVA_Action", "ShipTechEVA_Open", "ShipTechEVA_FX" }) do
        util.AddNetworkString(n)
    end
end

EVA.State = EVA.State or { breaches = {} }

-- neuer Alarm in ShipTech
ShipTech.AlarmTypes.breach = { prio = 1, name = "HÜLLENBRUCH", protocol = "Protokoll H-1: Techniker zur Luftschleuse, Hüllenplatten mitnehmen, Schadensstelle abdichten." }

---------------------------------------------------------------------------
-- Hilfen
---------------------------------------------------------------------------
function EVA.CanEVA(ply)
    if not IsValid(ply) then return false end
    if ShipTech.IsAdmin(ply) then return true end
    if not ShipTech.IsTechnician(ply) then return false end
    return not EC.RequireQual or ShipTech.HasQual(ply, "eva")
end

function EVA.SectorName(i) return ShipTech.SectorNames[i] or ("Sektor " .. tostring(i)) end

function EVA.StageDef(stage) return EC.Stages[stage] or EC.Stages[1] end

-- Schrittfolge einer Reparatur
function EVA.Steps(b)
    local def = EVA.StageDef(b.stage)
    local steps = {}
    if def.clear then steps[#steps + 1] = "clear" end
    for _ = 1, def.plates do steps[#steps + 1] = "plate" end
    steps[#steps + 1] = "weld"
    if b.wires then steps[#steps + 1] = "wires" end
    return steps
end

EVA.StepNames = {
    clear = "Schaden freilegen",
    plate = "Hüllenplatte setzen",
    weld  = "Verschweißen",
    wires = "Leitungen prüfen",
}

---------------------------------------------------------------------------
-- Entities
---------------------------------------------------------------------------
local CATEGORY = "ShipTech – Außeneinsatz"

local function Base(t)
    t.Type = "anim"
    t.Base = "base_anim"
    t.Category = CATEGORY
    t.Spawnable = true
    t.AdminOnly = true
    t.RenderGroup = RENDERGROUP_BOTH
    t.IsShipTechEVA = true
    if SERVER then
        t.SpawnFunction = function(self, ply, tr, className)
            if not tr.Hit then return end
            local ent = ents.Create(className)
            ent:SetPos(tr.HitPos + tr.HitNormal * 4)
            ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
            ent:Spawn()
            ent:Activate()
            return ent
        end
        t.Initialize = function(self)
            self:SetModel(self.EVAModel)
            self:PhysicsInit(SOLID_VPHYSICS)
            self:SetMoveType(MOVETYPE_VPHYSICS)
            self:SetSolid(SOLID_VPHYSICS)
            self:SetUseType(SIMPLE_USE)
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then phys:EnableMotion(false) end
        end
    else
        t.Draw = function(self) self:DrawModel() end
        t.DrawTranslucent = function(self)
            if EVA.DrawEntityHolo then EVA.DrawEntityHolo(self) end
        end
        t.Initialize = function(self)
            self:SetRenderBounds(self:OBBMins() - Vector(60, 60, 60), self:OBBMaxs() + Vector(60, 60, 220))
        end
    end
    return t
end

-- Ankerpunkt an der Außenhülle: hier entstehen Hüllenbrüche
scripted_ents.Register(Base({
    PrintName = "EVA-Ankerpunkt (Außenhülle)",
    Purpose = "Mögliche Schadensstelle. Sektor per C-Menü → Edit Properties (1 Bug, 2 Steuerbord, 3 Heck, 4 Backbord).",
    EVAModel = "models/props_lab/tpplug.mdl",
    Editable = true,
    SetupDataTables = function(self)
        self:NetworkVar("Int", 0, "HullSector", { KeyName = "hullsector", Edit = { type = "Int", order = 1, min = 1, max = 4, title = "Hüllensektor (1-4)" } })
        self:NetworkVar("Int", 1, "BreachId")
        if SERVER then self:SetHullSector(1) end
    end,
    STSaveData = function(self) return { s = self:GetHullSector() } end,
    STLoadData = function(self, d) self:SetHullSector(math.Clamp(tonumber(d.s) or 1, 1, 4)) end,
}), "shiptech_eva_anchor")

-- EVA-Spind in der Luftschleuse: Schweißgerät & Hüllenplatten, Übersicht der Schadensstellen
scripted_ents.Register(Base({
    PrintName = "EVA-Spind (Luftschleuse)",
    Purpose = "Hüllenschweißgerät und Hüllenplatten ausgeben, Übersicht der Schadensstellen.",
    EVAModel = "models/props_c17/lockers001a.mdl",
    Use = SERVER and function(self, ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        if (ply.STEVA_NextUse or 0) > CurTime() then return end
        ply.STEVA_NextUse = CurTime() + 0.5
        net.Start("ShipTechEVA_Open")
        net.WriteEntity(self)
        net.Send(ply)
    end or nil,
}), "shiptech_eva_locker")

-- Versorgungspunkt an der Hülle: Hüllenplatte aufnehmen (E)
scripted_ents.Register(Base({
    PrintName = "EVA-Versorgungspunkt",
    Purpose = "Hüllenplatte aufnehmen (E) – direkt an der Außenhülle.",
    EVAModel = "models/props_c17/canister01a.mdl",
    Use = SERVER and function(self, ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        if (ply.STEVA_NextUse or 0) > CurTime() then return end
        ply.STEVA_NextUse = CurTime() + 0.4
        if EVA.TakePlate then EVA.TakePlate(ply) end
    end or nil,
}), "shiptech_eva_supply")

if SERVER and ShipTech.ExtraPersist then
    for _, cls in ipairs({ "shiptech_eva_anchor", "shiptech_eva_locker", "shiptech_eva_supply" }) do
        ShipTech.ExtraPersist[cls] = true
    end
end
