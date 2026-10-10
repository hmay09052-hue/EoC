-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
GRN_NAVY = GRN_NAVY or {}
local GN = GRN_NAVY
local C = GN.Config

GN.Client = GN.Client or {
    State = {},
    RTS = {
        enabled = false,
        camPos = nil,
        yaw = 0,
        pitch = 78,
        height = (C.RTS and C.RTS.DefaultHeight) or 3000,
        selectedEnt = nil,
        bombardMode = false,
        moveMode = false,
        targetMode = nil,
        pendingTargetData = nil,
    }
}

local function sendAction(action, data)
    net.Start(GN.Net.Action)
    net.WriteString(action)
    net.WriteTable(data or {})
    net.SendToServer()
end

-- Helper: escapa el string para insertarlo dentro de un backtick JS
local function esc(str)
    str = tostring(str or "")
    str = str:gsub("\\", "\\\\")
    str = str:gsub("`",  "\\`")
    str = str:gsub("</", "<\\/")
    return str
end

local function buildMainHTML()
    return [[<!doctype html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        :root {
            --bg-color: rgba(20, 20, 20, 0.7);
            --text-color: #ffffff;
            --border-color: rgba(255, 255, 255, 0.1);
            --border-radius: 6px;
            --accent: #58b7ff;
            --danger: #ff6b6b;
        }
        
        * { box-sizing: border-box; }
        html, body { width: 100%; height: 100%; margin: 0; background: transparent; font-family: 'Tahoma', 'Arial', sans-serif; color: var(--text-color); overflow: hidden; }
        body { display: flex; justify-content: flex-end; align-items: stretch; padding: 20px; }
        
        .panel {
            width: 430px;
            height: 100%;
            background-color: var(--bg-color);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius);
            backdrop-filter: blur(5px);
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            user-select: none;
        }
        
        .header { padding: 18px; border-bottom: 1px solid var(--border-color); background: rgba(0,0,0,0.2); }
        .title { font-size: 20px; font-weight: bold; text-shadow: 1px 1px 2px rgba(0,0,0,0.8); }
        .sub { font-size: 12px; opacity: 0.8; margin-top: 4px; }
        
        .content { padding: 14px; overflow: auto; display: flex; flex-direction: column; gap: 12px; }
        .card { background: rgba(0, 0, 0, 0.3); border: 1px solid var(--border-color); border-radius: var(--border-radius); padding: 12px; }
        .card h3 { margin: 0 0 10px; font-size: 14px; text-shadow: 1px 1px 2px rgba(0,0,0,0.8); }
        
        .row { display: flex; gap: 8px; }
        .row > * { flex: 1; }
        
        select, button {
            width: 100%;
            background: rgba(0, 0, 0, 0.5);
            color: var(--text-color);
            border: 1px solid var(--border-color);
            border-radius: var(--border-radius);
            padding: 8px;
            font-family: inherit;
            outline: none;
            transition: background 0.2s;
        }
        button { cursor: pointer; font-weight: bold; text-shadow: 1px 1px 2px rgba(0,0,0,0.5); }
        button:hover { background: rgba(255, 255, 255, 0.1); }
        button.red { color: var(--danger); border-color: rgba(255, 107, 107, 0.3); }
        button.red:hover { background: rgba(255, 107, 107, 0.15); }
        
        ul { list-style: none; padding: 0; margin: 0; max-height: 160px; overflow: auto; }
        li { padding: 8px 10px; border: 1px solid var(--border-color); border-radius: var(--border-radius); background: rgba(0,0,0,0.2); margin-bottom: 6px; cursor: pointer; transition: all 0.2s;}
        li:hover { background: rgba(255, 255, 255, 0.05); }
        li.active { border-color: var(--accent); background: rgba(88, 183, 255, 0.15); }
        li small { display: block; opacity: 0.7; margin-top: 3px; font-size: 11px; }
        
        .mini { font-size: 11px; }
        .badge { display: inline-block; padding: 2px 6px; border-radius: 4px; font-size: 10px; margin-left: 6px; background: rgba(255, 255, 255, 0.1); }
        
        .footer { padding: 12px 14px; border-top: 1px solid var(--border-color); display: flex; gap: 8px; background: rgba(0,0,0,0.2); }
        .grow { flex: 1; }
        .muted { opacity: 0.6; }
        .grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
        
        /* Minimalist Scrollbar */
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: rgba(0,0,0,0.1); }
        ::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 3px; }
        ::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.4); }
    </style>
</head>
<body>
    <div class="panel">
        <div class="header">
            <div class="title">]] ..
    GRN_NAVY.T('menu_title') ..
    [[</div>
            <div class="sub" id="teamLabel">]] ..
    GRN_NAVY.T('menu_loading') ..
    [[</div>
        </div>
        <div class="content">
            <div class="card">
                <h3>]] ..
    GRN_NAVY.T('menu_available_players') ..
    [[</h3>
                <ul id="players"></ul>
            </div>
            <div class="card">
                <h3>]] ..
    GRN_NAVY.T('menu_capital_ships') ..
    [[</h3>
                <select id="capital"></select>
                <div class="row" style="margin-top:8px">
                    <button onclick="spawnCapital()">]] ..
    GRN_NAVY.T('menu_btn_deploy_capital') ..
    [[</button>
                    <button class="red" onclick="removeSelectedShip()">]] ..
    GRN_NAVY.T('menu_btn_withdraw') ..
    [[</button>
                </div>
            </div>
            <div class="card">
                <h3>]] ..
    GRN_NAVY.T('menu_fighters') ..
    [[</h3>
                <select id="fighter"></select>
                <div class="mini muted" style="margin:6px 0">]] ..
    GRN_NAVY.T('menu_fighters_hint') ..
    [[</div>
                <button onclick="spawnFighter()">]] ..
    GRN_NAVY.T('menu_btn_deploy_fighter') ..
    [[</button>
            </div>
            <div class="card">
                <h3>]] ..
    GRN_NAVY.T('menu_supplies') ..
    [[</h3>
                <select id="supply"></select>
                <div class="mini muted" style="margin:6px 0">]] ..
    GRN_NAVY.T('menu_supplies_hint') ..
    [[</div>
                <button style="margin-top:8px" onclick="spawnSupply()">]] ..
    GRN_NAVY.T('menu_btn_request_supply') ..
    [[</button>
            </div>
            <div class="card">
                <h3>]] ..
    GRN_NAVY.T('menu_escape_pods') ..
    [[</h3>
                <select id="escapepod"></select>
                <div class="mini muted" style="margin:6px 0">]] ..
    GRN_NAVY.T('menu_pods_hint') ..
    [[</div>
                <button style="margin-top:8px" onclick="spawnEscapePod()">]] ..
    GRN_NAVY.T('menu_btn_launch_pod') ..
    [[</button>
            </div>
            <div class="card">
                <h3>]] ..
    GRN_NAVY.T('menu_combat_control') ..
    [[</h3>
                <div class="grid2">
                    <button onclick="toggleBombard()">]] ..
    GRN_NAVY.T('menu_btn_bombard') ..
    [[</button>
                    <button onclick="toggleMoveMode()">]] ..
    GRN_NAVY.T('menu_btn_move') ..
    [[</button>
                </div>
                <div class="grid2" style="margin-top:8px">
                    <button onclick="refreshData()">]] ..
    GRN_NAVY.T('menu_btn_refresh') ..
    [[</button>
                    <button onclick="exitMode()">]] ..
    GRN_NAVY.T('menu_btn_exit_mode') ..
    [[</button>
                </div>
                <div class="mini muted" style="margin-top:8px">]] ..
    GRN_NAVY.T('menu_combat_hint') ..
    [[</div>
            </div>
            <div class="card">
                <h3>]] ..
    GRN_NAVY.T('menu_active_ships') ..
    [[</h3>
                <ul id="ships"></ul>
            </div>
        </div>
        <div class="footer">
            <button class="grow" onclick="closeMenu()">]] ..
    GRN_NAVY.T('menu_btn_close') ..
    [[</button>
        </div>
    </div>

    <script>
        var STATE={players:[],capitals:[],fighters:[],supplies:[],escapePods:[],ships:[],team:null};
        var LABELS={teamPrefix:'Team: ',noTeam:'No Team',hp:'HP',shield:'Shield'};
        var selectedPlayers=[]; var selectedShip=null; var bombard=false;

        function grnAction(action, data) {
            // Placeholder for the actual Lua interface function
            console.log("Action:", action, "Data:", data);
        }

        function closeMenu()       { grnAction('close','{}') }
        function refreshData()     { grnAction('refresh','{}') }
        function spawnCapital()    { grnAction('spawn_capital',  JSON.stringify({shipID:   document.getElementById('capital').value})) }
        function spawnFighter()    { grnAction('spawn_fighter',  JSON.stringify({fighterID:document.getElementById('fighter').value, playerIDs:selectedPlayers, capitalEnt:selectedShip})) }
        function spawnSupply()     { grnAction('supply_target_mode', JSON.stringify({supplyID: document.getElementById('supply').value, capitalEnt:selectedShip})) }
        function spawnEscapePod()  { grnAction('escape_pod_target_mode', JSON.stringify({podID: document.getElementById('escapepod').value, playerIDs:selectedPlayers.slice(0,5), capitalEnt:selectedShip})) }
        function removeSelectedShip(){ if(selectedShip!==null) grnAction('remove_ship', JSON.stringify({entIndex:selectedShip})) }
        function toggleBombard()   { bombard=!bombard; if(bombard){ grnAction('move_toggle', JSON.stringify({enabled:false})); } grnAction('bombard_toggle', JSON.stringify({enabled:bombard})) }
        function toggleMoveMode()  { var enabled=true; grnAction('move_toggle', JSON.stringify({enabled:enabled})) }
        function exitMode()        { bombard=false; grnAction('exit_mode', JSON.stringify({})) }

        function render(){
            document.getElementById('teamLabel').textContent = STATE.team ? (LABELS.teamPrefix+STATE.team) : LABELS.noTeam;
            var p=document.getElementById('players'); p.innerHTML='';
            for(var i=0;i<(STATE.players||[]).length;i++){
                var pl=STATE.players[i];
                var li=document.createElement('li');
                li.className=selectedPlayers.indexOf(pl.id)>=0?'active':'';
                li.innerHTML='<b>'+pl.name+'</b><small>'+pl.teamName+(pl.navyTeam?' &middot; '+pl.navyTeam:'')+'</small>';
                (function(pid){ li.onclick=function(){ var idx=selectedPlayers.indexOf(pid); if(idx>=0) selectedPlayers.splice(idx,1); else selectedPlayers.push(pid); render(); }; })(pl.id);
                p.appendChild(li);
            }
            var ships=document.getElementById('ships'); ships.innerHTML='';
            for(var i=0;i<(STATE.ships||[]).length;i++){
                var s=STATE.ships[i];
                var li=document.createElement('li');
                li.className=(selectedShip===s.entIndex)?'active':'';
                li.innerHTML='<b>'+s.name+'</b><span class="badge">'+s.team+'</span><small>'+LABELS.hp+' '+Math.floor(s.health)+' / '+LABELS.shield+' '+Math.floor(s.shield||0)+'</small>';
                (function(idx){ li.onclick=function(){ selectedShip=idx; grnAction('focus_ship',JSON.stringify({entIndex:idx})); render(); }; })(s.entIndex);
                ships.appendChild(li);
            }
            var capSel=document.getElementById('capital'),fighterSel=document.getElementById('fighter'),supplySel=document.getElementById('supply'),escapeSel=document.getElementById('escapepod');
            capSel.innerHTML=''; fighterSel.innerHTML=''; supplySel.innerHTML=''; if(escapeSel) escapeSel.innerHTML='';
            for(var i=0;i<(STATE.capitals||[]).length;i++){ var o=document.createElement('option'); o.value=STATE.capitals[i].id; o.textContent=STATE.capitals[i].name; capSel.appendChild(o); }
            for(var i=0;i<(STATE.fighters||[]).length;i++){ var o=document.createElement('option'); o.value=STATE.fighters[i].id; o.textContent=STATE.fighters[i].name; fighterSel.appendChild(o); }
            for(var i=0;i<(STATE.supplies||[]).length;i++){ var o=document.createElement('option'); o.value=STATE.supplies[i].id; o.textContent=STATE.supplies[i].name; supplySel.appendChild(o); }
            for(var i=0;i<(STATE.escapePods||[]).length;i++){ var o=document.createElement('option'); o.value=STATE.escapePods[i].id; o.textContent=STATE.escapePods[i].name; if(escapeSel) escapeSel.appendChild(o); }
        }
        function setState(raw){ STATE=JSON.parse(raw); render(); }
        function setLabels(raw){ LABELS=Object.assign(LABELS,JSON.parse(raw)); render(); }
    </script>
</body>
</html>]]
end

local function mainFrame()
    if IsValid(GN.Client.MainFrame) then return GN.Client.MainFrame end

    local fr = vgui.Create("DFrame")
    fr:SetTitle("") -- Título vacío
    fr:SetSize(460, ScrH() - 80)
    fr:SetPos(ScrW() - 460 - 20, 40)
    fr:MakePopup()
    fr:SetDraggable(false)
    fr:ShowCloseButton(false)
    
    -- ESTO HACE INVISIBLE EL PANEL DFRAME BASE
    fr.Paint = function() end 

    local dhtml = vgui.Create("DHTML", fr)
    dhtml:Dock(FILL)
    local page = buildMainHTML()
    if SYMUI then page = SYMUI.ThemeHTML(page, { css = ":root{--border-radius:0px}" }) end
    dhtml:SetHTML(page)
    fr.HTML = dhtml

    -- CORRECCIÓN PRINCIPAL: usar AddFunction en lugar de OnConsoleMessage.
    -- AddFunction registra una función Lua que el JS puede llamar directamente
    -- como  grnAction(type, dataObj)  una vez el documento esté listo.
    dhtml.OnDocumentReady = function()
        -- Registrar la función JS→Lua
        dhtml:AddFunction("window", "grnAction", function(actionType, dataJSON)
            local data = util.JSONToTable(dataJSON) or {}
            if actionType == "close" then
                net.Start(GN.Net.ToggleRTS)
                net.WriteBool(false)
                net.SendToServer()
                GN.Client.RTS.enabled = false
                if IsValid(GN.Client.MainFrame) then GN.Client.MainFrame:Remove() end
                if IsValid(GN.Client.ActionOverlay) then GN.Client.ActionOverlay:Remove() GN.Client.ActionOverlay = nil end
            elseif actionType == "refresh" then
                net.Start(GN.Net.RequestState)
                net.SendToServer()
            elseif actionType == "spawn_capital" then
                local rts = GN.Client.RTS
                sendAction("spawn_capital", {
                    shipID = data.shipID,
                    pos = rts.camPos and (rts.camPos + Angle(0, rts.yaw, 0):Forward() * 2200 + Vector(0,0,-600)) or nil
                })
            elseif actionType == "spawn_fighter" then
                sendAction("spawn_fighter", data)
            elseif actionType == "spawn_supply" then
                sendAction("spawn_supply", data)
            elseif actionType == "supply_target_mode" then
                GN.Client.RTS.targetMode = "supply"
                GN.Client.RTS.pendingTargetData = data
                GN.Client.RTS.bombardMode = false
                GN.Client.RTS.moveMode = false
                GN.Client.SyncCursorAndPanel()
            elseif actionType == "escape_pod_target_mode" then
                GN.Client.RTS.targetMode = "escape_pod"
                GN.Client.RTS.pendingTargetData = data
                GN.Client.RTS.bombardMode = false
                GN.Client.RTS.moveMode = false
                GN.Client.SyncCursorAndPanel()
            elseif actionType == "spawn_escape_pod" then
                sendAction("spawn_escape_pod", data)
            elseif actionType == "remove_ship" then
                sendAction("remove_ship", data)
            elseif actionType == "bombard_toggle" then
                GN.Client.RTS.bombardMode = (data.enabled == true)
                GN.Client.RTS.moveMode = false
                GN.Client.RTS.targetMode = nil
                GN.Client.RTS.pendingTargetData = nil
                GN.Client.SyncCursorAndPanel()
            elseif actionType == "move_toggle" then
                GN.Client.RTS.moveMode = (data.enabled == true)
                GN.Client.RTS.bombardMode = false
                GN.Client.RTS.targetMode = nil
                GN.Client.RTS.pendingTargetData = nil
                GN.Client.SyncCursorAndPanel()
            elseif actionType == "exit_mode" then
                GN.Client.RTS.moveMode = false
                GN.Client.RTS.bombardMode = false
                GN.Client.RTS.targetMode = nil
                GN.Client.RTS.pendingTargetData = nil
                GN.Client.SyncCursorAndPanel()
            elseif actionType == "focus_ship" then
                GN.Client.RTS.selectedEnt = data.entIndex
            end
        end)
        -- Inject i18n labels
        local labelsJSON = util.TableToJSON({
            teamPrefix = GRN_NAVY.T("menu_team_prefix"),
            noTeam     = GRN_NAVY.T("menu_no_team"),
            hp         = GRN_NAVY.T("menu_ship_hp"),
            shield     = GRN_NAVY.T("menu_ship_shield"),
        })
        dhtml:QueueJavascript("setLabels(`" .. esc(labelsJSON) .. "`);")
        -- Inject initial state if already available
        if GN.Client.State and next(GN.Client.State) then
            dhtml:QueueJavascript("setState(`" .. esc(util.TableToJSON(GN.Client.State)) .. "`);")
        end
    end

    GN.Client.MainFrame = fr
    return fr
end

-- Whitelist UI built entirely with native Garry's Mod panels (no DHTML)
local function whitelistFrame(data)
    if IsValid(GN.Client.WhitelistFrame) then GN.Client.WhitelistFrame:Remove() end

    local jobs     = data.jobs     or {}
    local wl       = data.whitelist or {}

    -- Colores
    local COL_BG      = Color(7,  10, 18)
    local COL_CARD    = Color(12, 16, 28)
    local COL_BORDER  = Color(80, 120, 180, 80)
    local COL_TEXT    = Color(223, 233, 255)
    local COL_DIM     = Color(150, 165, 195)
    local COL_BTN     = Color(29, 79, 121)
    local COL_BTN_HL  = Color(40, 100, 150)
    local COL_WHITE   = Color(255, 255, 255)
    if SYMUI then -- SymChars-Design
        COL_BG, COL_CARD, COL_BORDER = Color(9, 11, 14, 248), SYMUI.col.panel2, SYMUI.Accent(120)
        COL_TEXT, COL_DIM, COL_WHITE = SYMUI.col.text, SYMUI.col.dim, SYMUI.col.text
        COL_BTN, COL_BTN_HL = SYMUI.col.panel3, SYMUI.Accent(90)
    end

    local W, H = 860, 680

    -- ── Frame principal ──────────────────────────────────────────────
    local fr = vgui.Create("DFrame")
    fr:SetTitle("")
    fr:SetSize(W, H)
    fr:Center()
    fr:MakePopup()
    fr:SetDraggable(true)
    fr:ShowCloseButton(false)
    fr.Paint = function(s, w, h)
        SY_RoundedBox(14, 0, 0, w, h, COL_BG)
        surface.SetDrawColor(COL_BORDER)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        -- Header bar
        SY_RoundedBoxEx(14, 0, 0, w, 46, COL_CARD, true, true, false, false)
        surface.SetDrawColor(COL_BORDER)
        surface.DrawRect(0, 46, w, 1)
        draw.SimpleText(GRN_NAVY.T("wl_title"), (SYMUI and SYMUI.F("Trebuchet24") or "Trebuchet24"), 16, 12, COL_WHITE)
    end

    -- ── Botón cerrar (X) ────────────────────────────────────────────
    local btnX = vgui.Create("DButton", fr)
    btnX:SetSize(32, 32)
    btnX:SetPos(W - 42, 7)
    btnX:SetText("")
    btnX.Paint = function(s, w, h)
        local c = s:IsHovered() and Color(200,60,60) or Color(140,40,40)
        SY_RoundedBox(8, 0, 0, w, h, c)
        draw.SimpleText("✕", (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnX.DoClick = function() fr:Remove() end

    -- ── Cabecera de columnas ─────────────────────────────────────────
    local HDR_Y = 54
    local hdr = vgui.Create("DPanel", fr)
    hdr:SetPos(10, HDR_Y)
    hdr:SetSize(W - 20, 28)
    hdr.Paint = function(s, w, h)
        SY_RoundedBox(6, 0, 0, w, h, COL_CARD)
        draw.SimpleText(GRN_NAVY.T("wl_col_job"), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), 10,  h/2, COL_DIM, TEXT_ALIGN_LEFT,  TEXT_ALIGN_CENTER)
        draw.SimpleText(GRN_NAVY.T("wl_col_team"), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), 440, h/2, COL_DIM, TEXT_ALIGN_LEFT,  TEXT_ALIGN_CENTER)
        draw.SimpleText(GRN_NAVY.T("wl_col_enabled"), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), 660, h/2, COL_DIM, TEXT_ALIGN_LEFT,  TEXT_ALIGN_CENTER)
    end

    -- ── Scroll con filas ─────────────────────────────────────────────
    local scroll = vgui.Create("DScrollPanel", fr)
    scroll:SetPos(10, HDR_Y + 32)
    scroll:SetSize(W - 20, H - HDR_Y - 32 - 58)

    -- Guardamos referencias para leer valores al guardar
    local rowData = {}  -- { jobcmd, teamCombo, enabledCheck }

    for i, j in ipairs(jobs) do
        local entry = wl[j.command] or { team = "republic", enabled = false }

        local row = vgui.Create("DPanel", scroll)
        row:SetSize(W - 36, 44)
        row:SetPos(0, (i-1) * 48)
        row.Paint = function(s, w, h)
            local bg = (i % 2 == 0) and Color(10,14,24) or Color(14,19,30)
            SY_RoundedBox(8, 0, 0, w, h, bg)
            draw.SimpleText(j.name,    (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), 10, h/2 - 7, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(j.command, (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), 10, h/2 + 7, COL_DIM,   TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- Combo equipo
        local combo = vgui.Create("DComboBox", row)
        combo:SetPos(430, 8)
        combo:SetSize(200, 28)
        combo:AddChoice(GRN_NAVY.T("wl_team_republic"), "republic")
        combo:AddChoice(GRN_NAVY.T("wl_team_cis"), "cis")
        combo:SetValue(entry.team == "cis" and GRN_NAVY.T("wl_team_cis") or GRN_NAVY.T("wl_team_republic"))
        combo.Paint = function(s, w, h)
            SY_RoundedBox(8, 0, 0, w, h, Color(16,23,40))
            surface.SetDrawColor(COL_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            draw.SimpleText(s:GetValue(), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), 10, h/2, COL_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("▾", (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), w - 14, h/2, COL_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- Checkbox habilitado
        local chk = vgui.Create("DCheckBox", row)
        chk:SetPos(668, 12)
        chk:SetSize(20, 20)
        chk:SetValue(entry.enabled == true)
        chk.Paint = function(s, w, h)
            local bg = s:GetChecked() and Color(40,120,200) or Color(20,28,45)
            SY_RoundedBox(5, 0, 0, w, h, bg)
            surface.SetDrawColor(COL_BORDER)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            if s:GetChecked() then
                draw.SimpleText("✓", (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        rowData[#rowData+1] = { jobcmd = j.command, teamCombo = combo, enabledCheck = chk }
    end

    -- Ajustar altura del scroll canvas
    scroll:GetCanvas():SetSize(W - 36, #jobs * 48)

    -- ── Botón Guardar ────────────────────────────────────────────────
    local btnSave = vgui.Create("DButton", fr)
    btnSave:SetText("")
    btnSave:SetSize(160, 38)
    btnSave:SetPos(W - 176, H - 50)
    btnSave.Paint = function(s, w, h)
        local c = s:IsHovered() and COL_BTN_HL or COL_BTN
        SY_RoundedBox(10, 0, 0, w, h, c)
        surface.SetDrawColor(COL_BORDER)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(GRN_NAVY.T("wl_btn_save"), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), w/2, h/2, COL_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnSave.DoClick = function()
        local rows = {}
        for _, rd in ipairs(rowData) do
            local _, teamVal = rd.teamCombo:GetSelected()
            rows[#rows+1] = {
                jobcmd  = rd.jobcmd,
                team    = teamVal or "republic",
                enabled = rd.enabledCheck:GetChecked()
            }
        end
        net.Start(GN.Net.SubmitWhitelist)
        net.WriteTable(rows)
        net.SendToServer()
        fr:Remove()
    end

    GN.Client.WhitelistFrame = fr
end


local handleLeftRTSClick
local handleRightRTSClick

local function adjustRTSZoom(delta)
    if not GN.Client or not GN.Client.RTS or not GN.Client.RTS.enabled then return end
    local rts = GN.Client.RTS
    local step = ((C.RTS and C.RTS.ZoomStep) or 250) * (delta > 0 and -1 or 1)
    rts.height = math.Clamp((rts.height or ((C.RTS and C.RTS.DefaultHeight) or 3000)) + step, (C.RTS and C.RTS.MinHeight) or 900, (C.RTS and C.RTS.MaxHeight) or 12000)
    if isvector(rts.camPos) then
        local groundZ = LocalPlayer():GetPos().z
        rts.camPos = Vector(rts.camPos.x, rts.camPos.y, groundZ + rts.height)
    end
end

local function ensureActionOverlay()
    if IsValid(GN.Client.ActionOverlay) then return GN.Client.ActionOverlay end

    local pnl = vgui.Create("DPanel")
    pnl:SetSize(ScrW(), ScrH())
    pnl:SetPos(0, 0)
    pnl:SetVisible(false)
    pnl:SetMouseInputEnabled(false)
    pnl:SetKeyboardInputEnabled(false)
    pnl:SetCursor("crosshair")
    pnl.Paint = function() end

    pnl.OnMousePressed = function(_, mc)
        if not GN.Client.RTS or not GN.Client.RTS.enabled then return end
        if mc == MOUSE_LEFT then
            handleLeftRTSClick()
        elseif mc == MOUSE_RIGHT then
            handleRightRTSClick()
        end
    end

    pnl.OnKeyCodePressed = function(_, key)
        local exitKey = (C.RTS and C.RTS.ExitModeKey) or KEY_O
        if key == exitKey then
            GN.Client.RTS.bombardMode = false
            GN.Client.RTS.moveMode = false
            GN.Client.RTS.targetMode = nil
            GN.Client.RTS.pendingTargetData = nil
            GN.Client.SyncCursorAndPanel()
        end
    end

    pnl.OnMouseWheeled = function(_, delta)
        adjustRTSZoom(delta)
        return true
    end

    GN.Client.ActionOverlay = pnl
    return pnl
end

local function pushStateToUI()
    if IsValid(GN.Client.MainFrame) and IsValid(GN.Client.MainFrame.HTML) then
        GN.Client.MainFrame.HTML:QueueJavascript("setState(`" .. esc(util.TableToJSON(GN.Client.State or {})) .. "`);")
    end
end

function GN.Client.SyncCursorAndPanel()
    local fr = GN.Client.MainFrame
    local rts = GN.Client.RTS or {}
    local menuVisible = rts.enabled and not rts.moveMode and not rts.bombardMode and not rts.targetMode
    local actionMode = rts.enabled and (rts.moveMode or rts.bombardMode or rts.targetMode)
    local overlay = ensureActionOverlay()

    if IsValid(overlay) then
        overlay:SetSize(ScrW(), ScrH())
        overlay:SetPos(0, 0)
        overlay:SetVisible(actionMode)
        overlay:SetMouseInputEnabled(actionMode)
        overlay:SetKeyboardInputEnabled(actionMode)
    end

    if IsValid(fr) then
        fr:SetVisible(menuVisible)
        fr:SetMouseInputEnabled(menuVisible)
        fr:SetKeyboardInputEnabled(menuVisible)
        if menuVisible then
            fr:MakePopup()
        end
    end

    if actionMode then
        if IsValid(overlay) then
            overlay:MakePopup()
            overlay:SetCursor("crosshair")
        end
        gui.EnableScreenClicker(true)
        timer.Simple(0, function()
            if IsValid(overlay) then overlay:RequestFocus() end
        end)
    elseif menuVisible then
        gui.EnableScreenClicker(true)
    else
        gui.EnableScreenClicker(false)
    end
end

function GN.Client.SetInteractionMode(enabled)
    local rts = GN.Client.RTS or {}
    if enabled then
        rts.moveMode = rts.moveMode == true
        rts.bombardMode = rts.bombardMode == true
    end
    GN.Client.SyncCursorAndPanel()
end

net.Receive(GN.Net.OpenWhitelist, function()
    whitelistFrame(net.ReadTable() or {})
end)

net.Receive(GN.Net.PushState, function()
    GN.Client.State = net.ReadTable() or {}
    pushStateToUI()
end)

net.Receive(GN.Net.ToggleRTS, function()
    local enabled = net.ReadBool()
    GN.Client.RTS.enabled = enabled
    if enabled then
        local lp = LocalPlayer()
        GN.Client.RTS.camPos = lp:GetPos() + Vector(0,0,GN.Client.RTS.height)
        GN.Client.RTS.yaw = lp:EyeAngles().y
        GN.Client.RTS.selectedEnt = nil
        GN.Client.RTS.bombardMode = false
        GN.Client.RTS.moveMode = false
        GN.Client.RTS.targetMode = nil
        GN.Client.RTS.pendingTargetData = nil
        mainFrame()
        GN.Client.SyncCursorAndPanel()
        net.Start(GN.Net.RequestState)
        net.SendToServer()
    else
        GN.Client.RTS.bombardMode = false
        GN.Client.RTS.moveMode = false
        GN.Client.RTS.targetMode = nil
        GN.Client.RTS.pendingTargetData = nil
        gui.EnableScreenClicker(false)
        if IsValid(GN.Client.MainFrame) then GN.Client.MainFrame:Remove() end
        if IsValid(GN.Client.ActionOverlay) then GN.Client.ActionOverlay:Remove() GN.Client.ActionOverlay = nil end
    end
end)

local function getSelectedShip()
    local idx = GN.Client.RTS.selectedEnt
    if not idx then return NULL end
    local ent = Entity(idx)
    return IsValid(ent) and ent or NULL
end

local function getRTSScreenRay(mx, my)
    local rts = GN.Client.RTS
    if not isvector(rts.camPos) then return nil, nil end

    if not mx or mx <= 0 then mx = ScrW() * 0.5 end
    if not my or my <= 0 then my = ScrH() * 0.5 end

    local viewAng = Angle(rts.pitch, rts.yaw, 0)
    local forward = viewAng:Forward()
    local right = viewAng:Right()
    local up = viewAng:Up()
    local fov = 60
    local aspect = ScrW() / math.max(ScrH(), 1)
    local tanHalfFov = math.tan(math.rad(fov * 0.5))

    local sx = ((mx / ScrW()) * 2 - 1) * aspect * tanHalfFov
    local sy = (1 - (my / ScrH()) * 2) * tanHalfFov
    local dir = (forward + right * sx + up * sy):GetNormalized()

    return rts.camPos, dir
end

local function traceWorld(includeEntities)
    local mx, my = gui.MousePos()
    local startPos, dir = getRTSScreenRay(mx, my)
    if not startPos or not dir then
        return { Hit = false, HitPos = vector_origin, Entity = NULL }
    end

    local tr = util.TraceLine({
        start = startPos,
        endpos = startPos + dir * 200000,
        mask = includeEntities and MASK_SHOT or MASK_SOLID_BRUSHONLY,
        filter = function(ent)
            if not includeEntities then return true end
            if ent == LocalPlayer() then return false end
            return true
        end
    })

    if includeEntities and (not IsValid(tr.Entity) or not tr.Entity.GRN_NavyCapital) then
        tr = util.TraceLine({
            start = startPos,
            endpos = startPos + dir * 200000,
            mask = MASK_SOLID_BRUSHONLY
        })
    end

    return tr
end

hook.Add("CalcView", "GRN_Navy_CalcView", function(ply, origin, angles, fov)
    if not GN.Client.RTS.enabled then return end
    local rts = GN.Client.RTS
    return {
        origin = rts.camPos,
        angles = Angle(rts.pitch, rts.yaw, 0),
        fov = 60,
        drawhud = false,
        drawviewer = true,
        drawviewmodel = false,
    }
end)

hook.Add("HUDShouldDraw", "GRN_Navy_HideHUD", function(name)
    if GN.Client.RTS.enabled then return false end
end)

hook.Add("CreateMove", "GRN_Navy_MoveCamera", function(cmd)
    if not GN.Client.RTS.enabled then return end
    local rts = GN.Client.RTS
    local speed = C.RTS.PanSpeed
    local ang = Angle(0, rts.yaw, 0)
    local fwd, right = ang:Forward(), ang:Right()
    local pos = Vector(rts.camPos)
    if input.IsKeyDown(KEY_W) then pos = pos + fwd * speed end
    if input.IsKeyDown(KEY_S) then pos = pos - fwd * speed end
    if input.IsKeyDown(KEY_A) then pos = pos - right * speed end
    if input.IsKeyDown(KEY_D) then pos = pos + right * speed end
    if input.IsKeyDown(KEY_Q) then rts.yaw = rts.yaw - C.RTS.RotateStep end
    if input.IsKeyDown(KEY_E) then rts.yaw = rts.yaw + C.RTS.RotateStep end
    rts.camPos = pos
    cmd:ClearMovement()
    cmd:ClearButtons()
end)

hook.Add("InputMouseApply", "GRN_Navy_MouseZoom", function(cmd, x, y, ang)
    if not GN.Client.RTS.enabled then return end
    
    if input.IsMouseDown(MOUSE_MIDDLE) then
        GN.Client.RTS.yaw = GN.Client.RTS.yaw + x * 0.03
    end
    

    local wheel = (cmd.GetMouseWheel and cmd:GetMouseWheel()) or 0
    
    if wheel ~= 0 then
        adjustRTSZoom(wheel)
    end
    
    return true
end)

local function issueRTSOrder(ship, hitPos)
    if not IsValid(ship) or not isvector(hitPos) then return end
    local rts = GN.Client.RTS
    if rts.bombardMode then
        net.Start(GN.Net.Bombard)
        net.WriteUInt(ship:EntIndex(), 16)
        net.WriteVector(hitPos)
        net.SendToServer()
    else
        net.Start(GN.Net.OrderMove)
        net.WriteUInt(ship:EntIndex(), 16)
        net.WriteVector(hitPos + Vector(0,0,500))
        net.SendToServer()
    end
    rts.bombardMode = false
    rts.moveMode = false
    GN.Client.SyncCursorAndPanel()
end

handleLeftRTSClick = function()
    local rts = GN.Client.RTS
    local tr = traceWorld(true)
    if rts.targetMode then
        local worldTr = traceWorld(false)
        if worldTr.Hit then
            local payload = table.Copy(rts.pendingTargetData or {})
            payload.targetPos = worldTr.HitPos
            if rts.targetMode == "supply" then
                sendAction("spawn_supply", payload)
            elseif rts.targetMode == "escape_pod" then
                sendAction("spawn_escape_pod", payload)
            end
            rts.targetMode = nil
            rts.pendingTargetData = nil
            GN.Client.SyncCursorAndPanel()
            return true
        end
    end

    if IsValid(tr.Entity) and tr.Entity.GRN_NavyCapital and tr.Entity:GetNWString("GRN_NavyTeam", "") == (GN.Client.State and GN.Client.State.team or "") then
        rts.selectedEnt = tr.Entity:EntIndex()
        pushStateToUI()
        return true
    end

    if rts.bombardMode or rts.moveMode then
        local ship = getSelectedShip()
        if IsValid(ship) then
            local worldTr = traceWorld(false)
            if worldTr.Hit then
                issueRTSOrder(ship, worldTr.HitPos)
                return true
            end
        end
    end

    return false
end

handleRightRTSClick = function()
    local rts = GN.Client.RTS
    if not rts.moveMode and not rts.bombardMode and not rts.targetMode then return false end
    if rts.targetMode then
        local tr = traceWorld(false)
        if not tr.Hit then return false end
        local payload = table.Copy(rts.pendingTargetData or {})
        payload.targetPos = tr.HitPos
        if rts.targetMode == "supply" then
            sendAction("spawn_supply", payload)
        elseif rts.targetMode == "escape_pod" then
            sendAction("spawn_escape_pod", payload)
        end
        rts.targetMode = nil
        rts.pendingTargetData = nil
        GN.Client.SyncCursorAndPanel()
        return true
    end
    local ship = getSelectedShip()
    if not IsValid(ship) then return false end
    local tr = traceWorld(false)
    if not tr.Hit then return false end
    issueRTSOrder(ship, tr.HitPos)
    return true
end

hook.Add("Think", "GRN_Navy_MouseControls", function()
    if not GN.Client.RTS.enabled then return end
    local exitKey = (C.RTS and C.RTS.ExitModeKey) or KEY_O
    if input.WasKeyPressed(exitKey) then
        GN.Client.RTS.bombardMode = false
        GN.Client.RTS.moveMode = false
        GN.Client.RTS.targetMode = nil
        GN.Client.RTS.pendingTargetData = nil
        GN.Client.SyncCursorAndPanel()
    end
end)

hook.Add("HUDPaint", "GRN_Navy_ActionCursor", function()
    if not GN.Client.RTS.enabled then return end
    if not (GN.Client.RTS.moveMode or GN.Client.RTS.bombardMode or GN.Client.RTS.targetMode) then return end

    local x, y = gui.MousePos()
    if x <= 0 or y <= 0 then
        x, y = ScrW() * 0.5, ScrH() * 0.5
    end

    surface.SetDrawColor(255, 255, 255, 230)
    surface.DrawLine(x - 10, y, x + 10, y)
    surface.DrawLine(x, y - 10, x, y + 10)
    surface.DrawOutlinedRect(x - 14, y - 14, 28, 28, 1)

    local txt = GN.Client.RTS.targetMode == "supply" and GRN_NAVY.T("hud_mode_supply") or (GN.Client.RTS.targetMode == "escape_pod" and GRN_NAVY.T("hud_mode_pod") or (GN.Client.RTS.bombardMode and GRN_NAVY.T("hud_mode_bombard") or GRN_NAVY.T("hud_mode_move")))
    draw.SimpleText(txt .. "  |  " .. input.GetKeyName((C.RTS and C.RTS.ExitModeKey) or KEY_O):upper() .. GRN_NAVY.T("hud_exit_hint"), (SYMUI and SYMUI.F("Trebuchet24") or "Trebuchet24"), x + 20, y - 18, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)

hook.Add("PlayerBindPress", "GRN_Navy_Binds", function(ply, bind, pressed)
    if not GN.Client.RTS.enabled then return end
    bind = string.lower(bind)
    if string.find(bind, "invnext") then
        adjustRTSZoom(1)
        return true
    elseif string.find(bind, "invprev") then
        adjustRTSZoom(-1)
        return true
    elseif pressed and string.find(bind, "+attack2", 1, true) then
        if handleRightRTSClick() then return true end
    elseif pressed and string.find(bind, "+attack", 1, true) then
        if handleLeftRTSClick() then return true end
    end
end)

hook.Add("HUDPaint", "GRN_Navy_HUD", function()
    if not GN.Client.RTS.enabled then return end
    local rts = GN.Client.RTS
    local ship = getSelectedShip()
    local exitKeyName = input.GetKeyName((C.RTS and C.RTS.ExitModeKey) or KEY_O) or "o"
    draw.SimpleText("GRN Navy RTS", (SYMUI and SYMUI.F("Trebuchet24") or "Trebuchet24"), 24, 20, Color(255,255,255), 0, 0)
    draw.SimpleText(GRN_NAVY.T("hud_controls") .. string.upper(exitKeyName) .. (rts.targetMode == "supply" and GRN_NAVY.T("hud_marking_supply") or (rts.targetMode == "escape_pod" and GRN_NAVY.T("hud_marking_pod") or (rts.bombardMode and GRN_NAVY.T("hud_bombard_mode") or (rts.moveMode and GRN_NAVY.T("hud_move_mode") or "")))), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), 24, 48, Color(180,200,255), 0, 0)
    if IsValid(ship) then
        local hp = ship.Health and ship:Health() or 0
        local maxhp = ship.GetMaxHP and ship:GetMaxHP() or ship.GetMaxHealth and ship:GetMaxHealth() or math.max(hp,1)
        local sh = ship.GetShield and ship:GetShield() or 0
        local maxsh = ship.GetMaxShield and ship:GetMaxShield() or math.max(sh,1)
        local x,y,w,h = 24, 76, 320, 18
        surface.SetDrawColor(20,20,30,220) surface.DrawRect(x,y,w,h)
        surface.SetDrawColor(200,70,70,255) surface.DrawRect(x,y,w * math.Clamp(hp / math.max(maxhp,1), 0, 1), h)
        draw.SimpleText(ship:GetNWString("GRN_NavyName", ship.PrintName or ship:GetClass()) .. " " .. GRN_NAVY.T("menu_ship_hp"), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), x+6, y-1, color_white)
        y = y + 26
        surface.SetDrawColor(20,20,30,220) surface.DrawRect(x,y,w,h)
        surface.SetDrawColor(70,150,255,255) surface.DrawRect(x,y,w * math.Clamp(sh / math.max(maxsh,1), 0, 1), h)
        draw.SimpleText(GRN_NAVY.T("menu_ship_shield"), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), x+6, y-1, color_white)
    end
    local tr = traceWorld(false)
    surface.SetDrawColor(90,180,255,180)
    surface.DrawOutlinedRect(ScrW()/2 - 4, ScrH()/2 - 4, 8, 8)
    if tr and tr.Hit then
        local spos = tr.HitPos:ToScreen()
        draw.SimpleText(GRN_NAVY.T("hud_crosshair_target"), (SYMUI and SYMUI.F("Trebuchet18") or "Trebuchet18"), spos.x + 10, spos.y, Color(255,255,255), 0, 1)
    end
end)

hook.Add("PreDrawHalos", "GRN_Navy_SelHalo", function()
    if not GN.Client.RTS.enabled then return end
    local ship = getSelectedShip()
    if IsValid(ship) then
        halo.Add({ship}, Color(80,180,255), 2, 2, 2, true, true)
    end
end)