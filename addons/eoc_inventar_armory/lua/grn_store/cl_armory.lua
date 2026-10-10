GRNStore = GRNStore or {}
local S = GRNStore
local C = S.Config
local A = C and C.Armory

if not A then return end

S.ArmoryClientState = S.ArmoryClientState or { weapons = {}, sets = {} }
S.ArmoryFrame = S.ArmoryFrame or nil
S.ArmoryHTMLPanel = S.ArmoryHTMLPanel or nil
S.ArmoryPreview = S.ArmoryPreview or nil
S.ArmoryVendor = S.ArmoryVendor or nil
S.ArmorySelectedWeaponID = S.ArmorySelectedWeaponID or ""
S.ArmoryHTMLReady = false
S.ArmoryHTMLStateApplied = false
S.ArmoryHTMLStateCount = 0
S.ArmoryClosing = false
S.ArmoryV4OpenSeen = false
S.ArmoryV4StateSeen = false
S.ArmoryV4LastOpen = 0
S.ArmoryV4LastState = 0
S.ArmoryV4Requests = 0

local function readCompressedTable()
    local len = net.ReadUInt(32)
    if len <= 0 then return {} end
    local raw = net.ReadData(len)
    if not raw then return {} end
    local json = util.Decompress(raw)
    if not json then return {} end
    local data = util.JSONToTable(json)
    return istable(data) and data or {}
end

local function weaponByID(id)
    id = tostring(id or "")
    for _, data in ipairs(S.ArmoryClientState.weapons or {}) do
        if tostring(data.id or "") == id then return data end
    end
end

local function firstWeaponID()
    local first = S.ArmoryClientState.weapons and S.ArmoryClientState.weapons[1]
    return first and tostring(first.id or "") or ""
end

local function normalizeModelPath(path)
    if not isstring(path) then return nil end
    path = string.Trim(string.Replace(path, "\\", "/"))
    if path == "" then return nil end
    local lower = string.lower(path)
    if not string.StartWith(lower, "models/") then return nil end
    if not string.EndsWith(lower, ".mdl") then return nil end
    return path
end

local function validModel(path)
    path = normalizeModelPath(path)
    if not path then return nil end

    local function test(candidate)
        if not candidate or string.lower(candidate) == "models/error.mdl" then return false end

        local okValid, result = pcall(util.IsValidModel, candidate)
        if okValid and result then return true end

        local okFile, exists = pcall(file.Exists, candidate, "GAME")
        return okFile and exists or false
    end

    if test(path) then return path end

    local lower = string.lower(path)
    if lower ~= path and test(lower) then return lower end
    return nil
end

local function resolvePreviewModel(data)
    local previewCfg = A.Preview or {}

    if istable(data) then
        local configured = validModel(data.previewModel)
        if configured then return configured end

        local className = tostring(data.className or "")
        if className ~= "" then
            local stored = weapons.GetStored(className)
            if stored then
                local candidate = validModel(stored.WorldModel)
                    or validModel(stored.WM)
                    or validModel(stored.ViewModel)
                if candidate then return candidate end
            end
        end
    end

    return validModel(previewCfg.FallbackModel) or "models/weapons/w_pistol.mdl"
end

local function angleFromData(data)
    local fallback = Angle(0, 0, 0)
    if not istable(data) then return fallback end

    local a = data.previewAngle
    if isangle(a) then return Angle(a.p, a.y, a.r) end
    if not istable(a) then return fallback end

    return Angle(
        tonumber(a.p or a.pitch or a[1]) or 0,
        tonumber(a.y or a.yaw or a[2]) or 0,
        tonumber(a.r or a.roll or a[3]) or 0
    )
end

local function previewFallbackBounds(panel)
    if not IsValid(panel) or not IsValid(S.ArmoryHTMLPanel) then return end

    local w = math.max(1, S.ArmoryHTMLPanel:GetWide())
    local h = math.max(1, S.ArmoryHTMLPanel:GetTall())

    -- This is deliberately the right/centre side of the main content: to the
    -- right of the weapon description and before the characteristics column.
    local x = math.floor(w * 0.47)
    local y = math.floor(h * 0.30)
    local pw = math.floor(w * 0.32)
    local ph = math.floor(h * 0.46)

    panel:SetPos(x, y)
    panel:SetSize(math.max(180, pw), math.max(180, ph))
end

local function fitPreview(panel, data)
    if not IsValid(panel) or not IsValid(panel.Entity) then return end

    local ent = panel.Entity
    local mins, maxs = ent:GetRenderBounds()
    if not mins or not maxs then
        mins, maxs = ent:GetModelBounds()
    end
    if not mins or not maxs then return end

    local center = (mins + maxs) * 0.5
    local extent = maxs - mins
    local radius = math.max(12, extent:Length() * 0.52)
    local fov = math.Clamp(tonumber(data and data.fov) or tonumber((A.Preview or {}).FOV) or 34, 12, 90)
    local distance = radius / math.tan(math.rad(fov * 0.5))

    -- A diagonal camera works reliably for both pistols and long blasters.
    local direction = Vector(1.0, 1.0, 0.28)
    direction:Normalize()

    panel:SetFOV(fov)
    panel:SetLookAt(center)
    panel:SetCamPos(center + direction * math.max(42, distance * 1.16))
end

local function removePreview()
    if IsValid(S.ArmoryPreview) then S.ArmoryPreview:Remove() end
    S.ArmoryPreview = nil
end

local function ensurePreview()
    local previewCfg = A.Preview or {}
    if previewCfg.Enabled == false or not IsValid(S.ArmoryHTMLPanel) then return nil end
    if IsValid(S.ArmoryPreview) then return S.ArmoryPreview end

    -- Parent the model panel directly to DHTML. DHTML can otherwise win the
    -- sibling paint order on some Garry's Mod/CEF builds and hide the model.
    -- As a child, the model is always painted over the transparent HTML area.
    local panel = vgui.Create("DModelPanel", S.ArmoryHTMLPanel)
    panel:SetMouseInputEnabled(false)
    panel:SetKeyboardInputEnabled(false)
    if panel.SetPaintBackground then panel:SetPaintBackground(false) end
    panel:SetAmbientLight(previewCfg.AmbientLight or Color(90, 105, 125))
    panel:SetDirectionalLight(BOX_FRONT, Color(255, 255, 255))
    panel:SetDirectionalLight(BOX_BACK, Color(95, 125, 165))
    panel:SetDirectionalLight(BOX_RIGHT, Color(105, 170, 235))
    panel:SetDirectionalLight(BOX_LEFT, Color(62, 86, 120))
    panel:SetDirectionalLight(BOX_TOP, Color(180, 215, 245))
    panel:SetZPos(32767)
    panel:SetVisible(false)
    panel.GRNArmoryWeaponID = ""
    panel.GRNBaseAngle = Angle(0, 0, 0)

    panel.LayoutEntity = function(self, ent)
        if not IsValid(ent) then return end

        local base = self.GRNBaseAngle or Angle(0, 0, 0)
        if previewCfg.Spin then
            ent:SetAngles(Angle(
                base.p,
                base.y + (RealTime() * (tonumber(previewCfg.SpinSpeed) or 9)) % 360,
                base.r
            ))
        else
            ent:SetAngles(base)
        end

        self:RunAnimation()
    end

    previewFallbackBounds(panel)
    S.ArmoryPreview = panel
    return panel
end

local function setPreviewWeapon(id, force)
    id = tostring(id or "")
    local panel = ensurePreview()
    if not IsValid(panel) then return end

    local data = weaponByID(id)
    if not data then
        panel:SetVisible(false)
        panel.GRNArmoryWeaponID = ""
        return
    end

    S.ArmorySelectedWeaponID = id
    previewFallbackBounds(panel)

    if not force and panel.GRNArmoryWeaponID == id and IsValid(panel.Entity) then
        panel:SetVisible(true)
        panel:MoveToFront()
        return
    end

    local model = resolvePreviewModel(data)
    if not model then
        panel:SetVisible(false)
        return
    end

    pcall(util.PrecacheModel, model)
    panel:SetModel(model)

    if not IsValid(panel.Entity) or string.lower(tostring(panel.Entity:GetModel() or "")) == "models/error.mdl" then
        local fallback = validModel((A.Preview or {}).FallbackModel) or "models/weapons/w_pistol.mdl"
        panel:SetModel(fallback)
        model = fallback
    end

    if not IsValid(panel.Entity) then
        panel:SetVisible(false)
        return
    end

    panel.Entity:SetColor(color_white)
    panel.Entity:SetMaterial("")
    panel.Entity:SetModelScale(math.max(0.01, tonumber(data.previewScale) or 1), 0)
    panel.GRNBaseAngle = angleFromData(data)
    panel.Entity:SetAngles(panel.GRNBaseAngle)

    panel.GRNArmoryWeaponID = id
    fitPreview(panel, data)
    panel:SetVisible(true)
    panel:SetZPos(32767)
    panel:MoveToFront()
end

function S.SyncArmoryViewport(rawJSON)
    if not IsValid(S.ArmoryFrame) or not IsValid(S.ArmoryHTMLPanel) then return end

    local payload = util.JSONToTable(tostring(rawJSON or ""))
    if not istable(payload) then return end

    local id = tostring(payload.id or "")
    local x, y = tonumber(payload.x), tonumber(payload.y)
    local w, h = tonumber(payload.w), tonumber(payload.h)
    if id == "" or not x or not y or not w or not h or w < 24 or h < 24 then return end

    setPreviewWeapon(id)
    local panel = ensurePreview()
    if not IsValid(panel) then return end

    local viewportW = math.max(1, tonumber(payload.viewportW) or S.ArmoryHTMLPanel:GetWide())
    local viewportH = math.max(1, tonumber(payload.viewportH) or S.ArmoryHTMLPanel:GetTall())
    local htmlW, htmlH = S.ArmoryHTMLPanel:GetWide(), S.ArmoryHTMLPanel:GetTall()
    local scaleX, scaleY = htmlW / viewportW, htmlH / viewportH

    -- Panel is a CHILD of the DHTML, therefore the coordinates are local to the
    -- browser panel. Adding the DHTML's screen position here would offset the
    -- weapon outside its intended viewport.
    panel:SetPos(
        math.floor(x * scaleX + 0.5),
        math.floor(y * scaleY + 0.5)
    )
    panel:SetSize(
        math.max(24, math.floor(w * scaleX + 0.5)),
        math.max(24, math.floor(h * scaleY + 0.5))
    )
    panel:SetVisible(true)
    panel:SetZPos(32767)
    panel:MoveToFront()
end

local function stateJSON()
    return util.TableToJSON(S.ArmoryClientState or {}, false) or "{}"
end

local function pushState(force)
    if not IsValid(S.ArmoryHTMLPanel) then return end
    if not force and not S.ArmoryHTMLReady then return end

    local json = stateJSON()
    S.ArmoryHTMLPanel:QueueJavascript([[
        (function(){
            try {
                if (window.GRNArmoryUI && window.GRNArmoryUI.setData) {
                    window.GRNArmoryUI.setData(]] .. json .. [[);
                }
            } catch (e) {
                try { if (window.grnArmory && grnArmory.jsError) grnArmory.jsError(String(e && e.stack || e)); } catch (_) {}
            }
        })();
    ]])

    -- Rendered item pictures for the cards (same renderer as the inventory).
    if GRNInventory and isfunction(GRNInventory.RequestModelIcon) then
        for _, data in ipairs(S.ArmoryClientState.weapons or {}) do
            if istable(data) and (data.iconURL or "") == "" then
                local weaponID = tostring(data.id or "")
                local model = resolvePreviewModel(data)
                if weaponID ~= "" and model and not string.find(model, "w_pistol.mdl", 1, true) then
                    GRNInventory.RequestModelIcon(model, { kind = data.isArmor and "armor" or "weapon" }, function(uri)
                        if not IsValid(S.ArmoryHTMLPanel) then return end
                        local map = util.TableToJSON({ [weaponID] = uri }, false)
                        if map then
                            S.ArmoryHTMLPanel:QueueJavascript("if(window.GRNArmoryUI&&GRNArmoryUI.setIcons){GRNArmoryUI.setIcons(" .. map .. ");}")
                        end
                    end)
                end
            end
        end
    end

    local id = S.ArmorySelectedWeaponID
    if id == "" or not weaponByID(id) then id = firstWeaponID() end
    if id ~= "" then
        timer.Simple(0, function()
            if IsValid(S.ArmoryFrame) then setPreviewWeapon(id) end
        end)
    end
end

local function htmlWithBootState()
    local base = S.ArmoryHTML or "<html><body style='background:#08101a;color:#fff'>Waffenkammer konnte nicht geladen werden.</body></html>"
    local json = stateJSON()
    local encoded = util.Base64Encode(json or "{}", true) or ""
    local boot = [[
<script>
(function(){
  try {
    var raw = atob("]] .. encoded .. [[");
    var data = JSON.parse(raw || "{}");
    if (window.GRNArmoryUI && window.GRNArmoryUI.setData) {
      window.GRNArmoryUI.setData(data);
    }
    if (window.grnArmory && grnArmory.ready) grnArmory.ready();
  } catch (e) {
    try { if (window.grnArmory && grnArmory.jsError) grnArmory.jsError(String(e && e.stack || e)); } catch (_) {}
  }
})();
</script>
]]

    local replaced, count = string.gsub(base, "</body>", boot .. "</body>", 1)
    if count == 0 then return base .. boot end
    return replaced
end

local function sendAction(action, weaponID, setIndex)
    net.Start("grn_armory_v4_action")
        net.WriteString(tostring(action or ""))
        net.WriteString(tostring(weaponID or ""))
        net.WriteUInt(math.Clamp(math.floor(tonumber(setIndex) or 1), 1, 255), 8)
    net.SendToServer()
end

local function requestState()
    if not IsValid(S.ArmoryFrame) then return end
    S.ArmoryV4Requests = (tonumber(S.ArmoryV4Requests) or 0) + 1
    net.Start("grn_armory_v4_request")
    net.SendToServer()
end

local function bindHTML(html)
    html:AddFunction("grnArmory", "action", function(action, weaponID, setIndex)
        if not IsValid(S.ArmoryFrame) then return end
        sendAction(action, weaponID, setIndex)
    end)

    html:AddFunction("grnArmory", "syncViewport", function(json)
        S.SyncArmoryViewport(json)
    end)

    html:AddFunction("grnArmory", "selectWeapon", function(weaponID)
        if not IsValid(S.ArmoryFrame) then return end
        setPreviewWeapon(tostring(weaponID or ""), false)
    end)

    html:AddFunction("grnArmory", "ready", function()
        if not IsValid(S.ArmoryHTMLPanel) then return end
        S.ArmoryHTMLReady = true
        pushState(true)
    end)

    html:AddFunction("grnArmory", "stateApplied", function(count, active)
        S.ArmoryHTMLStateApplied = true
        S.ArmoryHTMLStateCount = tonumber(count) or 0
        if GetConVar("developer") and GetConVar("developer"):GetInt() > 0 then
            print(string.format("[GRN Armory] HTML recibio %d item(s). Loadout job: %s", S.ArmoryHTMLStateCount, tostring(active)))
        end
    end)

    html:AddFunction("grnArmory", "jsError", function(message)
        ErrorNoHalt("[GRN Armory HTML] " .. tostring(message or "error JS desconocido") .. "\n")
    end)

    html:AddFunction("grnArmory", "uiSound", function(kind)
        if GRNInventory and isfunction(GRNInventory.PlayUISound) then GRNInventory.PlayUISound(kind) end
    end)

    html:AddFunction("grnArmory", "close", function()
        S.CloseArmoryMenu()
    end)
end

function S.OpenArmoryMenu()
    if IsValid(S.MenuFrame) and isfunction(S.CloseMenu) then
        S.CloseMenu()
    end

    -- Do not let the inventory's temporary backpack viewmodel remain in front
    -- of this separate terminal. This does not alter any backpack positions,
    -- bones, model or animation settings.
    if GRNInventory and isfunction(GRNInventory.CloseUI) then
        GRNInventory.CloseUI()
    end

    if not IsValid(S.ArmoryFrame) and GRNInventory and isfunction(GRNInventory.PlayUISound) then GRNInventory.PlayUISound("Open") end
    if IsValid(S.ArmoryFrame) then S.ArmoryFrame:Remove() end

    S.ArmoryClosing = false
    S.ArmoryHTMLReady = false
    S.ArmoryHTMLStateApplied = false
    S.ArmoryHTMLStateCount = 0
    removePreview()

    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    if frame.SetPaintBackground then frame:SetPaintBackground(false) end
    frame:SetKeyboardInputEnabled(true)
    frame:SetMouseInputEnabled(true)
    frame:MakePopup()

    local html = vgui.Create("DHTML", frame)
    html:Dock(FILL)
    html:SetMouseInputEnabled(true)
    html:SetKeyboardInputEnabled(true)
    bindHTML(html)

    S.ArmoryFrame = frame
    S.ArmoryHTMLPanel = html

    -- Create the overlay immediately. Even if the HTML->Lua viewport callback
    -- is late, the selected weapon is visible in the fallback right-side area.
    local preview = ensurePreview()
    if IsValid(preview) then previewFallbackBounds(preview) end

    html.OnDocumentReady = function()
        if not IsValid(html) then return end
        S.ArmoryHTMLReady = true
        timer.Simple(0, function()
            if IsValid(html) then pushState(true) end
        end)
    end

    -- Important: the first state is embedded directly after GRNArmoryUI is
    -- defined. Some GMod/CEF builds can fire OnDocumentReady before the inline
    -- page script is callable from QueueJavascript, which used to leave the
    -- interface permanently empty even though the server sent valid items.
    local page = htmlWithBootState()
    html:SetHTML(SYMUI and SYMUI.ThemeHTML(page) or page)

    -- V4: no marcamos HTMLReady artificialmente. Preguntamos al propio JS si
    -- la API ya existe; cuando existe, JS llama a grnArmory.ready() y recién
    -- ahí se empuja el estado. Esto evita falsos "ready" de CEF.
    local retryName = "GRNStoreArmory_StateBootstrap_" .. tostring(html)
    local tries = 0
    timer.Create(retryName, 0.20, 30, function()
        tries = tries + 1
        if not IsValid(html) or not IsValid(S.ArmoryFrame) then
            timer.Remove(retryName)
            return
        end

        html:QueueJavascript([[
            (function(){
                try {
                    if (window.GRNArmoryUI && window.GRNArmoryUI.setData) {
                        if (window.grnArmory && grnArmory.ready) grnArmory.ready();
                    }
                } catch(e) {}
            })();
        ]])

        if S.ArmoryHTMLReady then
            pushState(true)
        end

        if S.ArmoryHTMLStateApplied then
            timer.Remove(retryName)
            return
        end

        -- Si todavía no llegó el payload del servidor, volver a pedirlo.
        if tries == 2 or tries == 6 or tries == 12 then
            requestState()
        end

        if tries >= 30 and not S.ArmoryHTMLStateApplied then
            ErrorNoHalt("[GRN Armory V4] El HTML no confirmo el estado. Ejecuta grn_armory_debug_client.\n")
        end
    end)

    local initial = S.ArmorySelectedWeaponID
    if initial == "" or not weaponByID(initial) then initial = firstWeaponID() end
    if initial ~= "" then
        timer.Simple(0.08, function()
            if IsValid(frame) then setPreviewWeapon(initial, true) end
        end)
    end

    frame.OnRemove = function()
        removePreview()
        S.ArmoryFrame = nil
        S.ArmoryHTMLPanel = nil
        S.ArmoryHTMLReady = false
        S.ArmoryHTMLStateApplied = false

        if not S.ArmoryClosing then
            net.Start("grn_armory_v4_close")
            net.SendToServer()
        end
    end
end

function S.CloseArmoryMenu()
    if not IsValid(S.ArmoryFrame) then return end
    if GRNInventory and isfunction(GRNInventory.PlayUISound) then GRNInventory.PlayUISound("Close") end
    S.ArmoryClosing = true
    net.Start("grn_armory_v4_close")
    net.SendToServer()
    removePreview()
    S.ArmoryFrame:Remove()
    S.ArmoryVendor = nil
    S.ArmoryClosing = false
end

local function applyArmoryState(vendor, data)
    S.ArmoryClientState = istable(data) and data or { weapons = {}, sets = {}, jobLoadout = {active = false} }
    if IsValid(vendor) then S.ArmoryVendor = vendor end

    local current = tostring(S.ArmorySelectedWeaponID or "")
    if current == "" or not weaponByID(current) then
        S.ArmorySelectedWeaponID = firstWeaponID()
    end

    -- Si por algún motivo llegó el estado antes que el mensaje OPEN, el mismo
    -- estado abre el menú. Esto hace el protocolo tolerante al orden de red.
    if not IsValid(S.ArmoryFrame) then
        S.OpenArmoryMenu()
    end

    if S.ArmoryHTMLReady then
        pushState(true)
    end

    if S.ArmorySelectedWeaponID ~= "" then
        timer.Simple(0, function()
            if IsValid(S.ArmoryFrame) then setPreviewWeapon(S.ArmorySelectedWeaponID) end
        end)
    end
end

net.Receive("grn_armory_v4_open", function()
    local vendor = net.ReadEntity()
    S.ArmoryV4OpenSeen = true
    S.ArmoryV4LastOpen = RealTime()
    if IsValid(vendor) then S.ArmoryVendor = vendor end

    if not IsValid(S.ArmoryFrame) then
        S.OpenArmoryMenu()
    end

    timer.Simple(0, function()
        if IsValid(S.ArmoryFrame) then requestState() end
    end)
end)

net.Receive("grn_armory_v4_state", function()
    local vendor = net.ReadEntity()
    local data = readCompressedTable()
    S.ArmoryV4StateSeen = true
    S.ArmoryV4LastState = RealTime()
    applyArmoryState(vendor, data)
end)

-- Compatibilidad con una sesión antigua que haya quedado abierta en hot-reload.
net.Receive("grn_armory_state", function()
    local shouldOpen = net.ReadBool()
    local vendor = net.ReadEntity()
    local data = readCompressedTable()
    if shouldOpen or IsValid(S.ArmoryFrame) then
        applyArmoryState(vendor, data)
    end
end)

net.Receive("grn_armory_v4_notify", function()
    local message = net.ReadString()
    if IsValid(S.ArmoryHTMLPanel) and S.ArmoryHTMLReady then
        local wrapped = util.TableToJSON({ tostring(message or "") }, false) or "[\"\"]"
        S.ArmoryHTMLPanel:QueueJavascript("if(window.GRNArmoryUI){window.GRNArmoryUI.toast((" .. wrapped .. ")[0]);}")
    else
        chat.AddText(Color(252, 178, 73), "[Waffenkammer] ", Color(220, 228, 238), tostring(message or ""))
    end
end)

concommand.Add("grn_armory_debug_client", function()
    local state = S.ArmoryClientState or {}
    local weaponsList = istable(state.weapons) and state.weapons or {}
    print("========== GRN ARMORY CLIENT DEBUG ==========")
    print("V4 open recibido:", tostring(S.ArmoryV4OpenSeen), "V4 state recibido:", tostring(S.ArmoryV4StateSeen), "requests:", tonumber(S.ArmoryV4Requests) or 0)
    print("frame valido:", IsValid(S.ArmoryFrame), "DHTML valido:", IsValid(S.ArmoryHTMLPanel), "vendor valido:", IsValid(S.ArmoryVendor), IsValid(S.ArmoryVendor) and S.ArmoryVendor:GetClass() or "nil")
    print("HTML ready:", tostring(S.ArmoryHTMLReady), "HTML confirmo:", tostring(S.ArmoryHTMLStateApplied))
    print("items recibidos:", #weaponsList, "items confirmados por HTML:", tonumber(S.ArmoryHTMLStateCount) or 0)
    print("job activo:", tostring(istable(state.jobLoadout) and state.jobLoadout.active or false), "job:", tostring(istable(state.jobLoadout) and state.jobLoadout.name or ""))
    for i, w in ipairs(weaponsList) do
        print(string.format("[%d] %s | %s | %s", i, tostring(w.name or "?"), tostring(w.className or "?"), tostring(w.inventoryItemID or "?")))
    end
    print("=============================================")
end)

hook.Add("Think", "GRNStoreArmory_MenuDistance", function()
    if not IsValid(S.ArmoryFrame) then return end

    if IsValid(S.ArmoryVendor) and IsValid(LocalPlayer()) then
        local maxDist = tonumber(A.Entity.MenuMaxDistance) or 450
        if LocalPlayer():GetPos():DistToSqr(S.ArmoryVendor:GetPos()) > maxDist * maxDist then
            S.CloseArmoryMenu()
            return
        end
    end

    -- Keep the overlay above CEF; some Chromium refreshes can reorder children.
    if IsValid(S.ArmoryPreview) and S.ArmoryPreview:IsVisible() then
        S.ArmoryPreview:SetZPos(32767)
    end
end)

hook.Add("OnScreenSizeChanged", "GRNStoreArmory_Resize", function()
    timer.Simple(0, function()
        if not IsValid(S.ArmoryFrame) then return end

        S.ArmoryFrame:SetSize(ScrW(), ScrH())
        S.ArmoryFrame:SetPos(0, 0)

        local panel = ensurePreview()
        if IsValid(panel) then
            previewFallbackBounds(panel)
            if S.ArmorySelectedWeaponID ~= "" then
                setPreviewWeapon(S.ArmorySelectedWeaponID, true)
            end
        end

        if IsValid(S.ArmoryHTMLPanel) and S.ArmoryHTMLReady then
            S.ArmoryHTMLPanel:QueueJavascript("if(window.GRNArmoryUI){window.GRNArmoryUI.syncViewport();}")
        end
    end)
end)

concommand.Add("grn_armory_preview_debug", function()
    local data = weaponByID(S.ArmorySelectedWeaponID)
    local panel = S.ArmoryPreview
    print("========== GRN ARMORY PREVIEW ==========")
    print("selected:", tostring(S.ArmorySelectedWeaponID))
    print("data:", data and tostring(data.name) or "nil")
    print("configured model:", data and tostring(data.previewModel or "") or "nil")
    print("resolved model:", data and tostring(resolvePreviewModel(data)) or "nil")
    print("panel valid:", IsValid(panel), "visible:", IsValid(panel) and panel:IsVisible() or false)
    print("entity valid:", IsValid(panel) and IsValid(panel.Entity) or false)
    if IsValid(panel) then
        local x, y = panel:GetPos()
        print("panel bounds:", x, y, panel:GetWide(), panel:GetTall())
    end
    print("========================================")
end)
