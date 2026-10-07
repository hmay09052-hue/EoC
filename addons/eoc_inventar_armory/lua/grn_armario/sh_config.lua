GRNWeaponrio = GRNWeaponrio or {}
GRNWeaponrio.Config = GRNWeaponrio.Config or {}

local C = GRNWeaponrio.Config

C.Debug = false
C.MenuTitle = "UNIFORM"
C.MenuFooter = "Echoes of Clones · Uniformsystem"

-- Entity del armario
C.EntityModel = "models/eemyscifipack/props/furniture/scifi_locker.mdl"
C.EntityFallbackModel = "models/props_c17/Lockers001a.mdl"
C.EntityImageMaterial = "grn_armario/armario_icono.png"
C.EntityImageURL = "https://r2.fivemanage.com/CAL8kaFVELoEmru99DXu6/armarioicono.png"
C.EntityImageCacheName = "armarioicono.png"
C.EntityUseDistance = 180
C.EntityUseCooldown = 0.75

-- IDs de Workshop necesarios para el modelo/otros contenidos del servidor.
-- Ejemplo: C.WorkshopIDs = { "1234567890", "0987654321" }
-- Si el modelo del armario ya está en tu colección principal, podés dejarlo vacío.
C.WorkshopIDs = {}

-- Cartel 3D2D / icono sobre la entidad
C.DrawWorldIcon = true
C.WorldIconBillboard = true
C.WorldIconOffset = Vector(0, 0, 125)
C.WorldIconAutoHeight = true       -- nunca deja el icono metido dentro del modelo
C.WorldIconHeightPadding = 24     -- separación sobre el punto más alto del locker
C.WorldIconIgnoreZ = false        -- IMPORTANTE: false = respeta paredes/profundidad (no atraviesa muros)
C.WorldIconAngle = Angle(0, 90, 90) -- usado sólo si WorldIconBillboard = false
-- Render HTML 3D2D. La imagen se carga directamente por URL dentro de DHTML.
C.WorldIconScale = 0.075
C.WorldIconHTMLSize = 256
C.WorldIconHTMLTextHeight = 44
C.WorldIconHTMLFallback = "asset://garrysmod/materials/grn_armario/armario_icono.png"
C.WorldIconMaxDistance = 700      -- sólo se dibuja cerca del jugador
C.WorldIconOcclusionCheck = true  -- oculta el icono si hay una pared/prop sólido entre jugador y armario
C.WorldIconVisibilityCheckInterval = 0.12 -- segundos entre trazas LOS por armario (optimización)
C.WorldIconEntityRefreshInterval = 1.0    -- refresco de la lista de armarios; evita FindByClass cada frame
C.WorldIconText = "SPIND"

-- Compatibilidad con configuraciones antiguas; ya no se usa para renderizar.
C.WorldIconSize = 180
C.WorldIconTextOffset = 98

-- Menú y refresco de whitelist
C.RefreshInterval = 2
C.SessionTimeout = 90
C.SpawnAfterEquip = true
C.ApplyDelay = 0.20
C.ApplyAgainDelay = 0.85

-- Si un job requiere votación, por defecto no aparece en el armario.
C.AllowVoteJobs = false

-- Ranks que pueden ver cualquier job sin whitelist.
C.BypassGroups = {
    -- ["superadmin"] = true,
}

-- Permite ocultar jobs completos por command, por ejemplo:
-- C.HiddenJobCommands = { ["citizen"] = true }
C.HiddenJobCommands = {}

-- Regla adicional opcional. La whitelist de Lucid/Luctus se comprueba primero.
-- Retorná false para bloquear un job ya whitelisteado, true para permitirlo
-- después de la whitelist, o nil para no agregar otra restricción.
C.CustomWhitelistCheck = function(ply, teamID, job)
    return nil
end

-- Hook adicional disponible para integraciones externas:
-- hook.Add("GRNWeaponrioCanUseJob", "MiWhitelist", function(ply, teamID, job)
--     return true  -- permitido
--     -- return false -- bloqueado
--     -- return nil   -- dejar que continúe el chequeo normal
-- end)

-- Si querés una clave distinta para persistencia (por personaje, por ejemplo),
-- podés retornar otra string. Por defecto se usa SteamID64.
C.PersistenceOwnerKey = function(ply)
    return IsValid(ply) and ply:SteamID64() or "0"
end

-- Límites anti-abuso para bodygroups recibidos desde el cliente.
C.MaxBodygroupIndex = 63
C.MaxBodygroupValue = 63


-- Preview 3D del modelo dentro del menú.
-- Ajustes pensados para dejarlo más chico, más alejado y corrido al lado derecho.
C.Preview = {
    X = 0.63,          -- posición horizontal del panel (porcentaje de pantalla)
    Y = 0.18,          -- posición vertical del panel
    W = 0.22,          -- ancho del panel
    H = 0.50,          -- alto del panel
    MinW = 320,
    MinH = 320,
    MaxW = 620,
    MaxH = 760,

    FOV = 16,
    CamDistHeight = 2.35,
    CamDistWidth = 3.55,
    CamDistMin = 190,
    LookAtZ = 0.08,
    CamPosZ = 0.10,
    Angle = Angle(0, 320, 0)
}

-- Logos del menú por job o por categoría de DarkRP.
-- Prioridad: JobIcons -> CategoryIcons -> DefaultMenuIcon -> abreviación.
C.DefaultMenuIcon = ""

C.JobIcons = {
    -- ["jedi_padawan"] = "https://r2.fivemanage.com/.../padawan.png",
}

C.CategoryIcons = {
    -- ["Orden Jedi"] = "https://r2.fivemanage.com/.../jedi_logo.png",
    -- ["Galactic Republic"] = "https://r2.fivemanage.com/.../republica_lgo.png",
}
