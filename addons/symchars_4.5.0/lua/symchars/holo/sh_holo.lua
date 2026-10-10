--[[-------------------------------------------------------------------------------------------------------------
    SymChars 2 - Holo-System (Welt)

    symchars_holo_display   Holo-Anzeige: Einheit, Mitglieder online, Fortbildungen, Dokument, freier Text
    symchars_holo_projector Holo-Projektor: projiziert das Beispielmodell einer Einheit (oder ein eigenes Modell)
    symchars_terminal       Terminal: öffnet einen Bereich des Menüs (Einheiten, Verwaltung, Dokumente, ...)

    Spawnen: Q-Menü > Entities > SymChars (nur Admins). Einstellen: Rechtsklick im C-Menü > "Holo einstellen"
    oder ADMIN > HOLOGRAMME. "Dauerhaft speichern" lässt das Objekt nach Kartenwechsel wieder erscheinen.
-------------------------------------------------------------------------------------------------------------]]

symchars.holo = symchars.holo or {}
symchars.holo.configs = symchars.holo.configs or {}

local H = symchars.holo
local U = symchars.util

H.CLASSES = {
    symchars_holo_display = "Holo-Anzeige",
    symchars_holo_projector = "Holo-Projektor",
    symchars_terminal = "Einheits-Terminal",
}

H.DISPLAY_MODES = {
    { id = "unit", name = "Einheit (Info)" },
    { id = "roster", name = "Einheit (Mitglieder online)" },
    { id = "trainings", name = "Fortbildungen einer Einheit" },
    { id = "document", name = "Dokument" },
    { id = "text", name = "Freier Text" },
}

H.TERMINAL_TABS = {
    { id = "units", name = "Einheiten" },
    { id = "characters", name = "Charaktere" },
    { id = "manager", name = "Verwaltung" },
    { id = "docs", name = "Dokumente" },
}

function H.Normalize(class, raw)
    raw = istable(raw) and raw or {}
    if class == "symchars_holo_display" then
        local mode = "unit"
        for _, m in ipairs(H.DISPLAY_MODES) do if m.id == raw.mode then mode = raw.mode end end
        return {
            mode = mode,
            unit = U.ID(raw.unit),
            doc = U.Int(raw.doc, 0, 0),
            title = U.Clean(raw.title, 80),
            text = U.Clean(raw.text, 1500, true),
            width = U.Int(raw.width, 90, 30, 400),
            color = U.TableToColor(raw.color, Color(90, 190, 255)),
            flicker = raw.flicker ~= false,
            range = U.Int(raw.range, 900, 150, 4000),
        }
    elseif class == "symchars_holo_projector" then
        local model = U.Trim(raw.model)
        if model ~= "" and not string.match(string.lower(model), "^models/.+%.mdl$") then model = "" end
        return {
            unit = U.ID(raw.unit),
            model = model,
            size = U.Num(raw.size, 1, 0.1, 4),
            color = U.TableToColor(raw.color, Color(90, 190, 255)),
            spin = U.Num(raw.spin, 20, 0, 180),
            label = raw.label ~= false,
            range = U.Int(raw.range, 1500, 150, 5000),
        }
    elseif class == "symchars_terminal" then
        local tab = "units"
        if raw.tab == "trainings" then raw.tab = "manager" end -- alter Ausbildungs-Reiter -> Verwaltung
        for _, t in ipairs(H.TERMINAL_TABS) do if t.id == raw.tab then tab = raw.tab end end
        return {
            tab = tab,
            unit = U.ID(raw.unit),
            title = U.Clean(raw.title, 48),
        }
    end
    return {}
end

function H.ToSave(cfg)
    local copy = table.Copy(cfg)
    if istable(cfg.color) then copy.color = U.ColorToTable(cfg.color) end
    return copy
end

function H.GetConfig(ent)
    if not IsValid(ent) then return nil end
    local cfg = H.configs[ent:EntIndex()]
    if not cfg then
        cfg = H.Normalize(ent:GetClass(), {})
        H.configs[ent:EntIndex()] = cfg
    end
    return cfg
end

---------------------------------------------------------------------------------------------------------------
-- Entities
---------------------------------------------------------------------------------------------------------------
local function Base(class, name, model)
    local ENT = {}
    ENT.Type = "anim"
    ENT.Base = "base_anim"
    ENT.PrintName = name
    ENT.Author = "SymChars"
    ENT.Category = "SymChars"
    ENT.Spawnable = true
    ENT.AdminOnly = true
    ENT.RenderGroup = RENDERGROUP_BOTH
    ENT.SymcharsModel = model

    function ENT:SetupDataTables()
        self:NetworkVar("Int", 0, "HoloID")
        self:NetworkVar("Bool", 0, "SymSaved")
    end

    if SERVER then
        function ENT:Initialize()
            self:SetModel(self.SymcharsModel)
            self:PhysicsInit(SOLID_VPHYSICS)
            self:SetMoveType(MOVETYPE_VPHYSICS)
            self:SetSolid(SOLID_VPHYSICS)
            self:SetUseType(SIMPLE_USE)
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then phys:EnableMotion(false) end
            if H.OnSpawned then H.OnSpawned(self) end
        end

        function ENT:Use(ply)
            if H.OnUse then H.OnUse(self, ply) end
        end

        function ENT:OnRemove()
            if H.OnRemoved then H.OnRemoved(self) end
        end
    else
        function ENT:Draw()
            if H.DrawEntity then H.DrawEntity(self, false) else self:DrawModel() end
        end

        function ENT:DrawTranslucent()
            if H.DrawEntity then H.DrawEntity(self, true) end
        end
    end

    scripted_ents.Register(ENT, class)
end

Base("symchars_holo_display", "Holo-Anzeige", "models/hunter/plates/plate05x05.mdl")
Base("symchars_holo_projector", "Holo-Projektor", "models/maxofs2d/hover_rings.mdl")
Base("symchars_terminal", "Einheits-Terminal", "models/props_combine/combine_intmonitor001.mdl")

---------------------------------------------------------------------------------------------------------------
-- Eigenschaft im C-Menü
---------------------------------------------------------------------------------------------------------------
properties.Add("symchars_holo_config", {
    MenuLabel = "Holo einstellen",
    Order = 50,
    MenuIcon = "icon16/wrench.png",
    Filter = function(self, ent, ply)
        if not IsValid(ent) or not H.CLASSES[ent:GetClass()] then return false end
        return symchars.IsSuperAdmin(ply)
    end,
    Action = function(self, ent)
        if symchars.ui and symchars.ui.OpenHoloConfig then symchars.ui.OpenHoloConfig(ent) end
    end,
})

if CLIENT then
    symchars.net.Receive("holo_configs", function(data)
        for _, entry in ipairs(istable(data) and data or {}) do
            local idx = tonumber(entry.ent)
            if idx then
                if entry.removed then
                    H.configs[idx] = nil
                else
                    H.configs[idx] = H.Normalize(entry.class, entry.cfg)
                end
            end
        end
        hook.Run("symchars_holo_updated")
    end)
end
