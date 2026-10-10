if not CLIENT then return end

GRN_DEFCON = GRN_DEFCON or {}

local C = GRN_DEFCON.Config
local PANEL_HOOK_ID = "GRN_Defcon_FunctionalHUD"
local NET_SYNC = "GRN_Defcon_Sync"
local NET_REQUEST = "GRN_Defcon_Request"
local NET_OPEN_SETTINGS = "GRN_Defcon_OpenSettings"
local SETTINGS_FILE = "grn_defcon/client_settings.json"

local currentLevel = math.max(1, math.floor(tonumber(C.DefaultLevel) or 5))
GRN_DEFCON.ClientLevels = GRN_DEFCON.ClientLevels or table.Copy(C.Levels or {})
local documentReady = false
local defconPanel
local dragOverlay
local settingsFrame
local editingSettings
local activeSoundChannel
local lastGlobalSyncRequest = 0

local HTML = [=[
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">

    <style>
        :root {
            --defcon-color: #55e18f;
            --defcon-rgb: 85, 225, 143;
            --text-main: #f7f8fb;
            --text-soft: rgba(240, 244, 248, .80);
            --text-dim: rgba(230, 235, 242, .56);
            --title-font: "Bebas Neue", Impact, sans-serif;
            --body-font: "Montserrat", Arial, sans-serif;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            -webkit-user-select: none;
            user-select: none;
        }

        html,
        body {
            width: 100%;
            height: 100%;
            overflow: hidden;
            background: transparent !important;
        }

        body {
            color: var(--text-main);
            font-family: var(--body-font);
            pointer-events: none;
            -webkit-font-smoothing: antialiased;
        }

        .hud {
            position: relative;
            width: 100%;
            height: 100%;
            display: grid;
            grid-template-columns: clamp(52px, 16%, 88px) minmax(0, 1fr);
            align-items: center;
            overflow: hidden;
            background: transparent;
            opacity: 1;
        }

        /* Only the lower separator remains. There is no line above the directive. */
        .hud::after {
            content: "";
            position: absolute;
            left: clamp(50px, 15%, 84px);
            right: 1.5%;
            bottom: 5%;
            height: 1px;
            background: linear-gradient(
                90deg,
                rgba(255, 255, 255, 0),
                rgba(255, 255, 255, .18),
                rgba(255, 255, 255, 0)
            );
            pointer-events: none;
        }

        .icon-zone {
            position: relative;
            width: 100%;
            height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            padding-bottom: 8%;
        }

        .icon-glow {
            position: absolute;
            width: clamp(34px, 72%, 62px);
            height: clamp(34px, 72%, 62px);
            border-radius: 50%;
            background: radial-gradient(
                circle,
                rgba(var(--defcon-rgb), .24) 0%,
                rgba(var(--defcon-rgb), .08) 44%,
                rgba(var(--defcon-rgb), 0) 74%
            );
            animation: glowPulse 2.2s ease-in-out infinite;
            will-change: transform, opacity;
        }

        .alert-icon {
            position: relative;
            z-index: 2;
            color: var(--defcon-color);
            font-family: "Font Awesome 6 Free", "Font Awesome 5 Free", sans-serif;
            font-weight: 900;
            font-size: clamp(26px, 30vh, 46px);
            line-height: 1;
            text-shadow:
                0 0 8px rgba(var(--defcon-rgb), .48),
                0 0 17px rgba(var(--defcon-rgb), .25);
            animation: iconAlert 1.8s ease-in-out infinite;
            will-change: transform, opacity;
        }

        /* Font Awesome fallback while the external stylesheet is loading. */
        .alert-icon::before {
            content: "\f071";
        }

        .text-zone {
            min-width: 0;
            padding: 5% 2.5% 8% 0;
        }

        .eyebrow {
            margin-bottom: clamp(3px, 1.4%, 6px);
            overflow: hidden;
            color: rgba(255, 255, 255, .82);
            font-family: var(--title-font);
            font-size: clamp(8px, 8vh, 13px);
            line-height: 1;
            letter-spacing: .18em;
            text-transform: uppercase;
            white-space: nowrap;
            text-overflow: ellipsis;
            text-shadow: 0 0 8px rgba(0, 0, 0, .30);
        }

        .title {
            overflow: hidden;
            color: var(--text-main);
            font-family: var(--title-font);
            font-size: clamp(15px, 20vh, 31px);
            line-height: 1;
            letter-spacing: .035em;
            text-transform: uppercase;
            white-space: nowrap;
            text-overflow: ellipsis;
            text-shadow: 0 0 10px rgba(0, 0, 0, .32);
        }

        .title strong {
            color: var(--defcon-color);
            font-weight: 400;
            text-shadow:
                0 0 8px rgba(var(--defcon-rgb), .38),
                0 0 16px rgba(var(--defcon-rgb), .18);
        }

        .description {
            display: -webkit-box;
            margin-top: clamp(4px, 1.5%, 7px);
            overflow: hidden;
            color: var(--text-soft);
            font-size: clamp(7px, 8vh, 12px);
            font-weight: 700;
            line-height: 1.34;
            letter-spacing: .01em;
            text-shadow: 0 0 8px rgba(0, 0, 0, .28);
            -webkit-box-orient: vertical;
            -webkit-line-clamp: 2;
        }

        .status-row {
            display: flex;
            align-items: center;
            gap: 7px;
            min-width: 0;
            margin-top: clamp(5px, 2%, 9px);
        }

        .status-dot {
            flex: 0 0 auto;
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: var(--defcon-color);
            box-shadow: 0 0 8px rgba(var(--defcon-rgb), .82);
            animation: dotBlink 1.5s ease-in-out infinite;
            will-change: opacity;
        }

        .status-text {
            min-width: 0;
            overflow: hidden;
            color: var(--text-dim);
            font-family: var(--title-font);
            font-size: clamp(7px, 7vh, 11px);
            line-height: 1;
            letter-spacing: .17em;
            text-transform: uppercase;
            white-space: nowrap;
            text-overflow: ellipsis;
        }

        .hud.change {
            animation: hudChange .35s ease-out;
        }

        @keyframes glowPulse {
            0%, 100% { transform: scale(.82); opacity: .42; }
            50% { transform: scale(1); opacity: .95; }
        }

        @keyframes iconAlert {
            0%, 100% { transform: translate3d(0, 0, 0) scale(1); opacity: 1; }
            50% { transform: translate3d(0, -1px, 0) scale(1.06); opacity: .88; }
        }

        @keyframes dotBlink {
            0%, 100% { opacity: .55; }
            50% { opacity: 1; }
        }

        @keyframes hudChange {
            0% { opacity: .28; transform: translate3d(-10px, 0, 0); }
            100% { opacity: 1; transform: translate3d(0, 0, 0); }
        }

        @media (max-height: 115px) {
            .text-zone { padding-top: 2%; padding-bottom: 4%; }
            .description { -webkit-line-clamp: 1; }
            .status-row { margin-top: 5px; }
        }

        @media (prefers-reduced-motion: reduce) {
            *, *::before, *::after {
                animation-duration: .01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: .01ms !important;
            }
        }
    </style>
</head>
<body>
    <section class="hud" id="defconHud">
        <div class="icon-zone" aria-hidden="true">
            <div class="icon-glow"></div>
            <i class="fa-solid fa-triangle-exclamation alert-icon"></i>
        </div>

        <div class="text-zone">
            <div class="eyebrow" id="eyebrow">NORMAL OPERATIONS</div>
            <div class="title" id="title">DEFCON <strong>5</strong> — PEACEKEEPER</div>
            <div class="description" id="description">Base operations are normal. Maintain your post and report anomalies.</div>

            <div class="status-row">
                <div class="status-dot"></div>
                <div class="status-text" id="status">NO CRITICAL THREATS</div>
            </div>
        </div>
    </section>

    <script>
        (function() {
            "use strict";

            var root = document.documentElement;
            var hud = document.getElementById("defconHud");
            var eyebrow = document.getElementById("eyebrow");
            var title = document.getElementById("title");
            var description = document.getElementById("description");
            var status = document.getElementById("status");

            function escapeHTML(value) {
                return String(value == null ? "" : value)
                    .replace(/&/g, "&amp;")
                    .replace(/</g, "&lt;")
                    .replace(/>/g, "&gt;")
                    .replace(/"/g, "&quot;")
                    .replace(/'/g, "&#039;");
            }

            function normalizeHex(value) {
                var hex = String(value || "#55e18f").trim();
                if (!/^#[0-9a-fA-F]{6}$/.test(hex)) return "#55e18f";
                return hex;
            }

            function hexToRGB(hex) {
                hex = normalizeHex(hex).substring(1);
                return [
                    parseInt(hex.substring(0, 2), 16),
                    parseInt(hex.substring(2, 4), 16),
                    parseInt(hex.substring(4, 6), 16)
                ].join(",");
            }

            function animateChange() {
                hud.classList.remove("change");
                void hud.offsetWidth;
                hud.classList.add("change");
            }

            window.setDefconData = function(data) {
                if (!data) return;

                var color = normalizeHex(data.color);
                root.style.setProperty("--defcon-color", color);
                root.style.setProperty("--defcon-rgb", hexToRGB(color));

                var level = escapeHTML(data.level || 5);
                var name = escapeHTML(data.name || "UNKNOWN");

                eyebrow.textContent = data.state || "OPERATIONAL STATUS";
                title.innerHTML = "DEFCON <strong>" + level + "</strong> — " + name;
                description.textContent = data.description || "";
                status.textContent = data.short || "";

                animateChange();
            };
        })();
    </script>
</body>
</html>
]=]

local SETTINGS_HTML = [=[
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=Montserrat:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.2/css/all.min.css" rel="stylesheet">
    <style>
        :root {
            --accent: #55b8ff;
            --bg: rgba(7, 9, 13, .985);
            --panel: rgba(16, 20, 27, .98);
            --line: rgba(255,255,255,.15);
            --text: #f5f7fb;
            --muted: #99a3b2;
        }

        * { box-sizing: border-box; user-select: none; }
        html, body { width: 100%; height: 100%; margin: 0; overflow: hidden; background: transparent; }
        body { color: var(--text); font-family: "Montserrat", Arial, sans-serif; }

        .window {
            width: 100%;
            height: 100%;
            padding: clamp(18px, 4vw, 28px);
            background:
                radial-gradient(circle at 12% 0%, rgba(85,184,255,.20), transparent 36%),
                linear-gradient(145deg, var(--panel), var(--bg));
            border: 1px solid rgba(255,255,255,.34);
            box-shadow: inset 0 0 45px rgba(0,0,0,.45);
        }

        .eyebrow {
            color: var(--accent);
            font-size: 10px;
            font-weight: 900;
            letter-spacing: .20em;
        }

        h1 {
            margin: 4px 0 3px;
            font-family: "Bebas Neue", Impact, sans-serif;
            font-size: clamp(34px, 7vw, 52px);
            line-height: .95;
            letter-spacing: .045em;
        }

        .sub {
            color: var(--muted);
            font-size: clamp(10px, 2vw, 13px);
            line-height: 1.55;
        }

        .card {
            margin-top: clamp(18px, 4vh, 28px);
            padding: clamp(15px, 3vw, 20px);
            border: 1px solid var(--line);
            background: rgba(255,255,255,.035);
        }

        .row {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
        }

        .label {
            font-family: "Bebas Neue", Impact, sans-serif;
            font-size: 22px;
            letter-spacing: .08em;
        }

        .value {
            color: var(--accent);
            font-size: 12px;
            font-weight: 900;
            letter-spacing: .12em;
        }

        input[type="range"] {
            width: 100%;
            margin: 18px 0 8px;
            accent-color: var(--accent);
        }

        .hint {
            margin-top: 14px;
            padding: 12px 13px;
            display: flex;
            gap: 10px;
            align-items: flex-start;
            color: #c8d0dc;
            font-size: 11px;
            line-height: 1.5;
            border-left: 2px solid var(--accent);
            background: rgba(85,184,255,.07);
        }

        .hint i { color: var(--accent); margin-top: 2px; }

        .buttons {
            position: absolute;
            left: clamp(18px, 4vw, 28px);
            right: clamp(18px, 4vw, 28px);
            bottom: clamp(18px, 4vw, 28px);
            display: grid;
            grid-template-columns: 1fr 1fr 1.25fr;
            gap: 9px;
        }

        button {
            min-height: 42px;
            border: 1px solid rgba(255,255,255,.18);
            background: rgba(255,255,255,.055);
            color: #dce2eb;
            font-family: "Bebas Neue", Impact, sans-serif;
            font-size: 17px;
            letter-spacing: .10em;
            cursor: pointer;
        }

        button:hover { border-color: rgba(255,255,255,.46); background: rgba(255,255,255,.10); }
        button.primary { color: #061018; border-color: var(--accent); background: var(--accent); }
    </style>
</head>
<body>
    <section class="window">
        <div class="eyebrow">GALACTIC REPUBLIC // PERSONAL HUD</div>
        <h1>DEFCON SETTINGS</h1>
        <div class="sub">Adjust the HUD size, then drag the highlighted DEFCON panel anywhere on your screen.</div>

        <div class="card">
            <div class="row">
                <div class="label">HUD SIZE</div>
                <div class="value" id="scaleValue">100%</div>
            </div>
            <input id="scale" type="range" min="55" max="165" step="1" value="100">
            <div class="hint">
                <i class="fa-solid fa-up-down-left-right"></i>
                <span>Hold the left mouse button over the DEFCON panel and move it freely. Settings are stored separately for each player.</span>
            </div>
        </div>

        <div class="buttons">
            <button onclick="settings.cancel()">CANCEL</button>
            <button onclick="settings.reset()">RESET</button>
            <button class="primary" onclick="settings.save()">SAVE CHANGES</button>
        </div>
    </section>

    <script>
        var slider = document.getElementById('scale');
        var value = document.getElementById('scaleValue');

        function updateScaleLabel() {
            value.textContent = Math.round(Number(slider.value)) + '%';
        }

        slider.addEventListener('input', function() {
            updateScaleLabel();
            settings.previewScale(Number(slider.value) / 100);
        });

        window.setSettingsData = function(data) {
            if (!data) return;
            if (data.minScale) slider.min = Math.round(Number(data.minScale) * 100);
            if (data.maxScale) slider.max = Math.round(Number(data.maxScale) * 100);
            slider.value = Math.round(Number(data.scale || 1) * 100);
            updateScaleLabel();
        };

        updateScaleLabel();
    </script>
</body>
</html>
]=]

local function GetLevelData(level)
    return GRN_DEFCON.ClientLevels[level] or C.Levels[level] or C.Levels[5] or {}
end

local function DefaultSettings()
    return {
        x = tonumber(C.PositionX) or 0.018,
        y = tonumber(C.PositionY) or 0.045,
        scale = 1
    }
end

local function SanitizeSettings(settings)
    local defaults = DefaultSettings()
    settings = istable(settings) and settings or {}

    return {
        x = math.Clamp(tonumber(settings.x) or defaults.x, 0, 1),
        y = math.Clamp(tonumber(settings.y) or defaults.y, 0, 1),
        scale = math.Clamp(
            tonumber(settings.scale) or defaults.scale,
            tonumber(C.UserMinimumScale) or 0.55,
            tonumber(C.UserMaximumScale) or 1.65
        )
    }
end

local function LoadClientSettings()
    if not C.AllowPlayerHUDCustomization or not file.Exists(SETTINGS_FILE, "DATA") then
        return DefaultSettings()
    end

    local decoded = util.JSONToTable(file.Read(SETTINGS_FILE, "DATA") or "")
    return SanitizeSettings(decoded)
end

local hudSettings = LoadClientSettings()

local function SaveClientSettings(settings)
    hudSettings = SanitizeSettings(settings)
    file.CreateDir("grn_defcon")
    file.Write(SETTINGS_FILE, util.TableToJSON(hudSettings, true))
end

local function GetLayoutSettings()
    if editingSettings then
        return editingSettings
    end

    return hudSettings
end

local function LayoutPanel(panel)
    if not IsValid(panel) then return end

    local screenWidth, screenHeight = ScrW(), ScrH()
    local settings = SanitizeSettings(GetLayoutSettings())
    local baseWidth = math.Clamp(
        math.floor(screenWidth * (tonumber(C.WidthScale) or 0.32)),
        tonumber(C.MinimumWidth) or 420,
        tonumber(C.MaximumWidth) or 620
    )
    local baseHeight = math.Clamp(
        math.floor(screenHeight * (tonumber(C.HeightScale) or 0.19)),
        tonumber(C.MinimumHeight) or 165,
        tonumber(C.MaximumHeight) or 220
    )
    local width = math.max(180, math.floor(baseWidth * settings.scale))
    local height = math.max(90, math.floor(baseHeight * settings.scale))
    local x = math.Clamp(math.floor(screenWidth * settings.x), 0, math.max(0, screenWidth - width))
    local y = math.Clamp(math.floor(screenHeight * settings.y), 0, math.max(0, screenHeight - height))

    panel:SetPos(x, y)
    panel:SetSize(width, height)

    if IsValid(dragOverlay) then
        dragOverlay:SetPos(x, y)
        dragOverlay:SetSize(width, height)
    end
end

local function PushCurrentData()
    if not IsValid(defconPanel) or not documentReady then return end

    local data = GetLevelData(currentLevel)
    local payload = {
        level = currentLevel,
        name = data.Name or "UNKNOWN",
        state = data.State or "",
        short = data.Short or "",
        description = data.Description or "",
        color = data.Color or "#55e18f",
        glow = data.Glow or "rgba(85,225,143,.28)",
        systemLabel = C.SecurityNetworkLabel or "",
        onlineLabel = C.OnlineLabel or "ONLINE",
        directiveLabel = C.DirectiveLabel or "BASE DIRECTIVE ACTIVE",
        codePrefix = C.SecurityCodePrefix or ""
    }

    defconPanel:RunJavascript("window.setDefconData(" .. util.TableToJSON(payload) .. ");")
end

local function SetDisplayedLevel(level)
    currentLevel = math.max(1, math.floor(tonumber(level) or 5))
    PushCurrentData()
end

local function CreateDragOverlay()
    if IsValid(dragOverlay) then
        dragOverlay:Remove()
    end

    dragOverlay = vgui.Create("DPanel")
    dragOverlay:SetVisible(false)
    dragOverlay:SetCursor("sizeall")
    dragOverlay:SetZPos(32760)

    dragOverlay.Paint = function(_, width, height)
        local acc = SYMUI and SYMUI.Accent() or Color(85, 184, 255)
        surface.SetDrawColor(acc.r, acc.g, acc.b, 28)
        surface.DrawRect(0, 0, width, height)
        surface.SetDrawColor(acc.r, acc.g, acc.b, 255)
        surface.DrawOutlinedRect(0, 0, width, height, 2)
        draw.SimpleText("DRAG TO MOVE", SYMUI and "symchars.small.bold" or "DermaDefaultBold", 10, 8, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    dragOverlay.OnMousePressed = function(panel, mouseCode)
        if mouseCode ~= MOUSE_LEFT or not editingSettings then return end

        local mouseX, mouseY = gui.MousePos()
        local panelX, panelY = panel:GetPos()
        panel.Dragging = true
        panel.DragOffsetX = mouseX - panelX
        panel.DragOffsetY = mouseY - panelY
        panel:MouseCapture(true)
    end

    dragOverlay.OnMouseReleased = function(panel, mouseCode)
        if mouseCode ~= MOUSE_LEFT then return end
        panel.Dragging = false
        panel:MouseCapture(false)
    end

    dragOverlay.Think = function(panel)
        if not panel.Dragging or not editingSettings then return end

        if not input.IsMouseDown(MOUSE_LEFT) then
            panel.Dragging = false
            panel:MouseCapture(false)
            return
        end

        local mouseX, mouseY = gui.MousePos()
        local width, height = panel:GetSize()
        local x = math.Clamp(mouseX - (panel.DragOffsetX or 0), 0, math.max(0, ScrW() - width))
        local y = math.Clamp(mouseY - (panel.DragOffsetY or 0), 0, math.max(0, ScrH() - height))

        editingSettings.x = ScrW() > 0 and (x / ScrW()) or 0
        editingSettings.y = ScrH() > 0 and (y / ScrH()) or 0

        if IsValid(defconPanel) then
            defconPanel:SetPos(x, y)
        end

        panel:SetPos(x, y)
    end
end

local function CreatePanel()
    if IsValid(defconPanel) then
        defconPanel:Remove()
    end

    documentReady = false

    if not C.Enabled then return end

    defconPanel = vgui.Create("DHTML")
    defconPanel:SetHTML(SYMUI and SYMUI.ThemeHTML(HTML) or HTML)
    defconPanel:SetMouseInputEnabled(false)
    defconPanel:SetKeyboardInputEnabled(false)
    defconPanel:SetAlpha(0)
    defconPanel:SetZPos(10)

    LayoutPanel(defconPanel)

    defconPanel.OnDocumentReady = function(panel)
        if not IsValid(panel) then return end

        documentReady = true
        panel:AlphaTo(255, 0.18, 0)
        PushCurrentData()
    end

    CreateDragOverlay()
    LayoutPanel(defconPanel)
end

local function RequestServerState()
    net.Start(NET_REQUEST)
    net.SendToServer()
end

-- Networked global fallback: keeps every HUD and 3D terminal synchronized even if a net packet is missed.
timer.Create("GRN_Defcon_GlobalStateFallback", 0.35, 0, function()
    local globalLevel = math.floor(tonumber(GetGlobalInt("GRN_Defcon_CurrentLevel", currentLevel)) or currentLevel)
    if globalLevel < 1 or globalLevel == currentLevel then return end

    SetDisplayedLevel(globalLevel)
    hook.Run("GRN_Defcon_ClientLevelChanged", globalLevel, GetLevelData(globalLevel), false, "")

    if lastGlobalSyncRequest <= CurTime() then
        lastGlobalSyncRequest = CurTime() + 1
        RequestServerState()
    end
end)

local function UpdateSettingsHTML()
    if not IsValid(settingsFrame) or not IsValid(settingsFrame.HTML) or not editingSettings then return end

    settingsFrame.HTML:RunJavascript(
        "window.setSettingsData(" .. util.TableToJSON({
            scale = editingSettings.scale,
            minScale = tonumber(C.UserMinimumScale) or 0.55,
            maxScale = tonumber(C.UserMaximumScale) or 1.65
        }) .. ");"
    )
end

local function CloseSettings(saveChanges)
    if saveChanges and editingSettings then
        SaveClientSettings(editingSettings)
    end

    editingSettings = nil

    if IsValid(settingsFrame) then
        settingsFrame:Remove()
    end

    settingsFrame = nil

    if IsValid(dragOverlay) then
        dragOverlay:SetVisible(false)
        dragOverlay.Dragging = false
        dragOverlay:MouseCapture(false)
    end

    LayoutPanel(defconPanel)
end

local function OpenSettings()
    if not C.AllowPlayerHUDCustomization then
        notification.AddLegacy("DEFCON HUD customization is disabled.", NOTIFY_ERROR, 4)
        return
    end

    if IsValid(settingsFrame) then
        settingsFrame:MakePopup()
        settingsFrame:MoveToFront()
        return
    end

    editingSettings = table.Copy(hudSettings)
    LayoutPanel(defconPanel)

    if IsValid(dragOverlay) then
        dragOverlay:SetVisible(true)
        dragOverlay:MakePopup()
    end

    local width = math.Clamp(math.floor(ScrW() * 0.34), 470, 650)
    local height = math.Clamp(math.floor(ScrH() * 0.48), 390, 520)

    settingsFrame = vgui.Create("DFrame")
    settingsFrame:SetSize(width, height)
    settingsFrame:Center()
    settingsFrame:SetTitle("")
    settingsFrame:ShowCloseButton(false)
    settingsFrame:SetDraggable(true)
    settingsFrame:SetSizable(false)
    settingsFrame:SetDeleteOnClose(true)
    settingsFrame:SetZPos(32767)
    settingsFrame:MakePopup()
    settingsFrame.Paint = nil

    settingsFrame.OnKeyCodePressed = function(_, keyCode)
        if keyCode == KEY_ESCAPE then
            CloseSettings(false)
        end
    end

    local html = vgui.Create("DHTML", settingsFrame)
    html:Dock(FILL)
    html:SetMouseInputEnabled(true)
    html:SetKeyboardInputEnabled(true)
    settingsFrame.HTML = html

    html:AddFunction("settings", "previewScale", function(value)
        if not editingSettings then return end
        editingSettings.scale = math.Clamp(
            tonumber(value) or 1,
            tonumber(C.UserMinimumScale) or 0.55,
            tonumber(C.UserMaximumScale) or 1.65
        )
        LayoutPanel(defconPanel)
    end)

    html:AddFunction("settings", "reset", function()
        editingSettings = DefaultSettings()
        LayoutPanel(defconPanel)
        UpdateSettingsHTML()
    end)

    html:AddFunction("settings", "save", function()
        CloseSettings(true)
        notification.AddLegacy("DEFCON HUD settings saved.", NOTIFY_GENERIC, 4)
    end)

    html:AddFunction("settings", "cancel", function()
        CloseSettings(false)
    end)

    html.OnDocumentReady = function()
        UpdateSettingsHTML()
    end

    html:SetHTML(SYMUI and SYMUI.ThemeHTML(SETTINGS_HTML) or SETTINGS_HTML)
    settingsFrame:MoveToFront()
end

local function PlayChangeSound()
    local source = tostring(C.ChangeSound or C.NotificationSound or "")
    if source == "" then return end

    local volume = math.Clamp(tonumber(C.ChangeSoundVolume) or 1, 0, 1)
    local lowered = string.lower(source)
    local isRemote = string.StartWith(lowered, "http://") or string.StartWith(lowered, "https://")

    if not isRemote then
        surface.PlaySound(source)
        return
    end

    if IsValid(activeSoundChannel) then
        activeSoundChannel:Stop()
        activeSoundChannel = nil
    end

    sound.PlayURL(source, "noplay noblock", function(channel)
        if not IsValid(channel) then return end

        activeSoundChannel = channel
        channel:SetVolume(volume)
        channel:Play()
    end)
end

hook.Add("InitPostEntity", PANEL_HOOK_ID, function()
    timer.Simple(0.35, function()
        CreatePanel()
        RequestServerState()
    end)
end)

hook.Add("OnScreenSizeChanged", PANEL_HOOK_ID, function()
    timer.Simple(0, function()
        LayoutPanel(defconPanel)

        if IsValid(settingsFrame) then
            settingsFrame:Center()
        end
    end)
end)

net.Receive(NET_SYNC, function()
    local level = net.ReadUInt(16)
    local announce = net.ReadBool()
    local actorName = net.ReadString()
    local decoded = util.JSONToTable(net.ReadString() or "")

    if istable(decoded) then
        GRN_DEFCON.ClientLevels[level] = decoded
    end

    SetDisplayedLevel(level)
    hook.Run("GRN_Defcon_ClientLevelChanged", level, decoded, announce, actorName)

    if not announce then return end

    PlayChangeSound()

    if not C.ShowPopupNotification then return end

    local data = GetLevelData(level)
    local message = string.format("DEFCON %d - %s", level, data.Name or "UNKNOWN")

    if C.ShowChangedBy and actorName ~= "" then
        message = message .. " | SET BY " .. actorName
    end

    notification.AddLegacy(message, NOTIFY_HINT, tonumber(C.NotificationDuration) or 6)
end)

net.Receive(NET_OPEN_SETTINGS, function()
    OpenSettings()
end)

concommand.Add(C.SettingsConsoleCommand or "defconsettings", function()
    OpenSettings()
end)

if C.AllowClientPreviewCommand then
    concommand.Add("grn_defcon_preview", function(_, _, arguments)
        SetDisplayedLevel(arguments and arguments[1] or 5)
    end)
end

GRN_DEFCON.GetClientLevel = function()
    return currentLevel
end

GRN_DEFCON.GetClientLevelData = function(level)
    return GetLevelData(level or currentLevel)
end

GRN_DEFCON.GetClientLevels = function()
    return GRN_DEFCON.ClientLevels
end

GRN_DEFCON.OpenSettings = OpenSettings
