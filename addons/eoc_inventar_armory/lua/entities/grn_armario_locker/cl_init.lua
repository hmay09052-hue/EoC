include("shared.lua")

--[[
    GRN Weaponrio - icono HTML 3D2D

    El icono ya no se renderiza con Material()/surface.DrawTexturedRect.
    Se crea un DHTML transparente, se carga la imagen directamente desde
    EntityImageURL y el panel se pinta manualmente dentro de un contexto 3D2D.

    Si la URL falla o tarda demasiado, el HTML cambia automáticamente al PNG
    local distribuido con el addon mediante asset://.
]]

local htmlPanel
local htmlKey
local nextHTMLRetry = 0

-- Optimización del cartel 3D2D:
--  * la lista de armarios se cachea y no usa ents.FindByClass cada frame;
--  * la visibilidad por paredes se comprueba a intervalos cortos;
--  * la distancia se calcula con DistToSqr (sin raíz cuadrada).
local lockerCache = {}
local nextLockerRefresh = 0
local visibilityCache = setmetatable({}, { __mode = "k" })

local function DebugPrint(...)
    local cfg = GRNWeaponrio and GRNWeaponrio.Config or {}
    if cfg.Debug ~= true then return end

    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end

    MsgC(Color(80, 190, 255), "[GRN Wardrobe] ", color_white, table.concat(parts, " "), "\n")
end

local function EscapeHTML(value)
    value = tostring(value or "")
    value = string.gsub(value, "&", "&amp;")
    value = string.gsub(value, "<", "&lt;")
    value = string.gsub(value, ">", "&gt;")
    value = string.gsub(value, '"', "&quot;")
    value = string.gsub(value, "'", "&#39;")
    return value
end

local function RemoveWorldHTML()
    if IsValid(htmlPanel) then
        htmlPanel:Remove()
    end

    htmlPanel = nil
    htmlKey = nil
end

local function CreateWorldHTML(cfg)
    if not vgui or not vgui.Create then return nil end

    local url = tostring(cfg.EntityImageURL or "")
    local localAsset = tostring(cfg.WorldIconHTMLFallback or "asset://garrysmod/materials/grn_armario/armario_icono.png")
    local iconSize = math.max(32, math.floor(tonumber(cfg.WorldIconHTMLSize) or 256))
    local text = tostring(cfg.WorldIconText or "")
    local textHeight = text ~= "" and math.max(0, math.floor(tonumber(cfg.WorldIconHTMLTextHeight) or 44)) or 0
    local panelW = iconSize
    local panelH = iconSize + textHeight

    if url == "" then
        url = localAsset
    end

    local key = table.concat({url, localAsset, tostring(iconSize), tostring(textHeight), text}, "|")
    if IsValid(htmlPanel) and htmlKey == key then
        return htmlPanel
    end

    RemoveWorldHTML()

    local pnl = vgui.Create("DHTML")
    if not IsValid(pnl) then
        nextHTMLRetry = RealTime() + 5
        return nil
    end

    htmlPanel = pnl
    htmlKey = key

    pnl:SetSize(panelW, panelH)
    pnl:SetPos(0, 0)
    pnl:SetMouseInputEnabled(false)
    pnl:SetKeyboardInputEnabled(false)
    pnl:SetPaintedManually(true)
    pnl:SetPaintBackgroundEnabled(false)
    pnl:SetPaintBorderEnabled(false)
    pnl:SetAllowLua(true)
    pnl.GRNIconReady = false
    pnl.GRNIconFailed = false
    pnl.GRNIconWidth = 0
    pnl.GRNIconHeight = 0

    pnl.OnDocumentReady = function(panel)
        if not IsValid(panel) then return end

        panel:AddFunction("grn", "iconReady", function(w, h)
            if not IsValid(panel) then return end
            panel.GRNIconReady = true
            panel.GRNIconFailed = false
            panel.GRNIconWidth = tonumber(w) or 0
            panel.GRNIconHeight = tonumber(h) or 0
            DebugPrint("DHTML 3D icon ready:", panel.GRNIconWidth, "x", panel.GRNIconHeight)
        end)

        panel:AddFunction("grn", "iconFailed", function()
            if not IsValid(panel) then return end
            panel.GRNIconReady = false
            panel.GRNIconFailed = true
            nextHTMLRetry = RealTime() + 5
            DebugPrint("DHTML 3D icon failed to load both remote and local fallback")
        end)

        panel:QueueJavascript([[
            (function(){
                var img = document.getElementById('grn-armario-world-icon');
                if (!img) return;

                function reportReady(){
                    if (window.grn && typeof window.grn.iconReady === 'function' && img.naturalWidth > 0) {
                        window.grn.iconReady(img.naturalWidth, img.naturalHeight);
                    }
                }

                if (img.complete && img.naturalWidth > 0) {
                    reportReady();
                }
            })();
        ]])
    end

    local remoteURL = EscapeHTML(url)
    local fallbackURL = EscapeHTML(localAsset)
    local label = EscapeHTML(text)

    local html = string.format([[
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<style>
    html, body {
        margin: 0;
        padding: 0;
        width: 100%%;
        height: 100%%;
        overflow: hidden;
        background: rgba(0,0,0,0) !important;
    }

    body {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: flex-start;
        pointer-events: none;
        user-select: none;
        -webkit-user-select: none;
    }

    #grn-armario-world-icon {
        display: block;
        width: %dpx;
        height: %dpx;
        object-fit: contain;
        object-position: center center;
        border: 0;
        outline: 0;
        margin: 0;
        padding: 0;
        background: rgba(0,0,0,0) !important;
    }

    #grn-armario-world-label {
        width: 100%%;
        height: %dpx;
        display: %s;
        align-items: center;
        justify-content: center;
        box-sizing: border-box;
        color: #f4f7fb;
        font-family: SymHead, BigNoodleTitling, "Bebas Neue", Arial, sans-serif;
        font-size: 22px;
        font-weight: 800;
        line-height: 1;
        letter-spacing: 2px;
        text-align: center;
        text-shadow: 0 2px 7px rgba(0,0,0,.85);
        background: rgba(0,0,0,0) !important;
    }
</style>
</head>
<body>
    <img id="grn-armario-world-icon" alt="" src="%s">
    <div id="grn-armario-world-label">%s</div>

<script>
(function(){
    var img = document.getElementById('grn-armario-world-icon');
    var fallback = "%s";
    var fallbackUsed = (img.getAttribute('src') === fallback);
    var readyReported = false;

    function notifyReady(){
        if (!img || img.naturalWidth <= 0) return false;
        if (window.grn && typeof window.grn.iconReady === 'function') {
            window.grn.iconReady(img.naturalWidth, img.naturalHeight);
            readyReported = true;
            return true;
        }
        return false;
    }

    function retryNotify(count){
        if (notifyReady()) return;
        if (count <= 0) return;
        setTimeout(function(){ retryNotify(count - 1); }, 100);
    }

    function useFallback(){
        if (fallbackUsed) {
            if (window.grn && typeof window.grn.iconFailed === 'function') {
                window.grn.iconFailed();
            }
            return;
        }

        fallbackUsed = true;
        readyReported = false;
        img.src = fallback;
    }

    img.addEventListener('load', function(){
        retryNotify(30);
    });

    img.addEventListener('error', function(){
        useFallback();
    });

    if (img.complete) {
        if (img.naturalWidth > 0) {
            retryNotify(30);
        } else {
            useFallback();
        }
    }

    setTimeout(function(){
        if (!readyReported && (!img.complete || img.naturalWidth <= 0)) {
            useFallback();
        }
    }, 3000);
})();
</script>
</body>
</html>
]],
        iconSize,
        iconSize,
        textHeight,
        textHeight > 0 and "flex" or "none",
        remoteURL,
        label,
        fallbackURL
    )

    pnl:SetHTML(SYMUI and SYMUI.ThemeHTML(html, { noLiteral = true }) or html)
    DebugPrint("Created transparent DHTML world icon. URL:", url)

    return pnl
end

local function GetWorldHTML(cfg)
    if IsValid(htmlPanel) then
        local url = tostring(cfg.EntityImageURL or "")
        local localAsset = tostring(cfg.WorldIconHTMLFallback or "asset://garrysmod/materials/grn_armario/armario_icono.png")
        local iconSize = math.max(32, math.floor(tonumber(cfg.WorldIconHTMLSize) or 256))
        local text = tostring(cfg.WorldIconText or "")
        local textHeight = text ~= "" and math.max(0, math.floor(tonumber(cfg.WorldIconHTMLTextHeight) or 44)) or 0
        local wantedURL = url ~= "" and url or localAsset
        local wantedKey = table.concat({wantedURL, localAsset, tostring(iconSize), tostring(textHeight), text}, "|")

        if htmlKey == wantedKey then
            return htmlPanel
        end
    end

    if RealTime() < nextHTMLRetry then return nil end
    return CreateWorldHTML(cfg)
end

local function GetWorldIconCenter(ent, cfg)
    local offset = cfg.WorldIconOffset or Vector(0, 0, 125)
    local x = tonumber(offset.x) or 0
    local y = tonumber(offset.y) or 0
    local z = tonumber(offset.z) or 125

    if cfg.WorldIconAutoHeight ~= false then
        local top = ent:OBBMaxs().z
        local padding = tonumber(cfg.WorldIconHeightPadding) or 24
        z = math.max(z, top + padding)
    end

    return ent:LocalToWorld(Vector(x, y, z))
end

local function GetWorldIconAngle(ent, center, cfg)
    if cfg.WorldIconBillboard == false then
        return ent:LocalToWorldAngles(cfg.WorldIconAngle or Angle(0, 90, 90))
    end

    -- PaintManual + 3D2D debe usar la dirección cámara -> panel. Usar la
    -- dirección inversa deja el DHTML mirando hacia atrás y por eso no aparece.
    local forwardAngle = (center - EyePos()):Angle()
    return Angle(0, forwardAngle.y - 90, forwardAngle.r + 90)
end

local function GetTopLeftOrigin(center, ang, scale, panelW, panelH)
    -- cam.Start3D2D usa el origen como esquina superior izquierda. Calculamos
    -- esa esquina a partir de un centro en mundo para que el billboard rote
    -- siempre exactamente alrededor del centro del icono.
    local halfW = panelW * 0.5 * scale
    local halfH = panelH * 0.5 * scale

    return center - ang:Forward() * halfW + ang:Right() * halfH
end

local function RefreshLockerCache(cfg, force)
    local now = RealTime()
    if not force and now < nextLockerRefresh then return lockerCache end

    lockerCache = ents.FindByClass("grn_armario_locker") or {}
    local interval = math.max(0.25, tonumber(cfg.WorldIconEntityRefreshInterval) or 1.0)
    nextLockerRefresh = now + interval

    return lockerCache
end

local function IsWorldIconVisible(ent, center, cfg, eyePos)
    if not IsValid(ent) then return false end

    local maxDist = math.max(0, tonumber(cfg.WorldIconMaxDistance) or 700)
    if maxDist > 0 and eyePos:DistToSqr(center) > (maxDist * maxDist) then
        return false
    end

    -- Aunque el TraceLine esté desactivado, el render 3D2D sigue respetando Z
    -- porque WorldIconIgnoreZ ahora es false. Este chequeo extra evita siquiera
    -- pintar el DHTML cuando el armario está tapado por una pared/prop.
    if cfg.WorldIconOcclusionCheck == false then
        return true
    end

    local now = RealTime()
    local cached = visibilityCache[ent]
    if cached and now < cached.nextCheck then
        return cached.visible == true
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    -- MASK_SHOT detecta mundo y props sólidos de forma fiable. Ignoramos jugadores,
    -- NPCs y el propio armario para que sólo la geometría/props del mapa ocluyan.
    local tr = util.TraceLine({
        start = eyePos,
        endpos = center,
        mask = MASK_SHOT,
        filter = function(hit)
            if hit == ply or hit == ent then return false end
            if IsValid(hit) and (hit:IsPlayer() or hit:IsNPC()) then return false end
            return true
        end
    })

    local visible = not tr.Hit or tr.Fraction >= 0.995
    local interval = math.max(0.05, tonumber(cfg.WorldIconVisibilityCheckInterval) or 0.12)

    visibilityCache[ent] = {
        visible = visible,
        nextCheck = now + interval
    }

    return visible
end

local function DrawEntityWorldHTML(ent, cfg, eyePos)
    if not IsValid(ent) then return end
    if cfg.DrawWorldIcon == false then return end

    -- Corte barato antes de calcular OBB/LocalToWorld o hacer una traza.
    local maxDist = math.max(0, tonumber(cfg.WorldIconMaxDistance) or 700)
    if maxDist > 0 and eyePos:DistToSqr(ent:GetPos()) > (maxDist * maxDist) then
        return
    end

    local center = GetWorldIconCenter(ent, cfg)
    if not IsWorldIconVisible(ent, center, cfg, eyePos) then
        return
    end

    local pnl = GetWorldHTML(cfg)
    if not IsValid(pnl) or pnl.GRNIconReady ~= true then
        return
    end

    local ang = GetWorldIconAngle(ent, center, cfg)
    local scale = math.max(0.001, tonumber(cfg.WorldIconScale) or 0.075)
    local panelW, panelH = pnl:GetSize()
    local origin = GetTopLeftOrigin(center, ang, scale, panelW, panelH)

    -- NO usar cam.IgnoreZ(true): hacerlo fuerza el cartel a atravesar paredes.
    -- Mantener depth test normal hace que Source también lo oculte inmediatamente,
    -- incluso entre una comprobación TraceLine y la siguiente.
    cam.Start3D2D(origin, ang, scale)
        pnl:PaintManual(true)
    cam.End3D2D()
end

function ENT:Initialize()
    -- Bounds ampliados por seguridad. El cartel se renderiza desde un hook global.
    self:SetRenderBounds(Vector(-180, -180, -100), Vector(180, 180, 340))
    nextLockerRefresh = 0
end

function ENT:Draw()
    self:DrawModel()
end

function ENT:DrawTranslucent()
    -- El modelo ya se dibuja en Draw(). El cartel HTML se dibuja desde el hook global.
end

-- Render global del DHTML 3D2D. La lista de armarios está cacheada para evitar
-- ents.FindByClass cada frame, y cada armario hace TraceLine sólo cada intervalo.
hook.Add("PostDrawTranslucentRenderables", "GRNWeaponrio_DrawHTML3DIcon", function(drawingDepth, drawingSkybox)
    if drawingDepth or drawingSkybox then return end

    local cfg = GRNWeaponrio and GRNWeaponrio.Config or {}
    if cfg.DrawWorldIcon == false then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local eyePos = EyePos()
    local lockers = RefreshLockerCache(cfg, false)

    for i = #lockers, 1, -1 do
        local ent = lockers[i]
        if not IsValid(ent) then
            table.remove(lockers, i)
        else
            DrawEntityWorldHTML(ent, cfg, eyePos)
        end
    end
end)

hook.Add("OnEntityCreated", "GRNWeaponrio_RefreshHTML3DIconCache", function(ent)
    if not IsValid(ent) then return end
    if ent:GetClass() ~= "grn_armario_locker" then return end

    -- La entidad puede terminar de inicializarse al tick siguiente.
    timer.Simple(0, function()
        if not IsValid(ent) then return end
        for i = 1, #lockerCache do
            if lockerCache[i] == ent then return end
        end
        lockerCache[#lockerCache + 1] = ent
    end)
end)

hook.Add("EntityRemoved", "GRNWeaponrio_ClearHTML3DIconVisibility", function(ent)
    visibilityCache[ent] = nil
    nextLockerRefresh = 0
end)

hook.Add("ShutDown", "GRNWeaponrio_RemoveHTML3DIcon", function()
    RemoveWorldHTML()
end)
