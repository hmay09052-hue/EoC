GRNStore = GRNStore or {}
local S = GRNStore
local C = S.Config

S.ClientState = S.ClientState or {
    categories = {},
    products = {},
    inventory = {},
    money = 0,
    isStaff = false,
}

S.MenuFrame = S.MenuFrame or nil
S.MenuHTML = S.MenuHTML or nil
S.PreviewPanels = S.PreviewPanels or {}
S.CurrentVendor = S.CurrentVendor or nil
S.HTMLReady = false
S.ClosingMenu = false

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

local function sendSimpleNet(name, value)
    net.Start(name)
    if value ~= nil then net.WriteString(tostring(value)) end
    net.SendToServer()
end

local function pushStateToHTML()
    if not IsValid(S.MenuHTML) or not S.HTMLReady then return end
    local json = util.TableToJSON(S.ClientState or {}, false) or "{}"
    S.MenuHTML:QueueJavascript("if(window.CloneFallStore){window.CloneFallStore.setData(" .. json .. ");}")
end

local function productFromID(id)
    id = tostring(id or "")

    for _, product in ipairs(S.ClientState.products or {}) do
        if product.id == id then return product end
    end

    for _, item in ipairs(S.ClientState.inventory or {}) do
        if item.productID == id then
            return {
                id = item.productID,
                name = item.name,
                category = item.category,
                type = item.type,
                className = item.className,
                previewModel = item.previewModel,
                spawnModel = item.spawnModel,
                rarity = item.rarity,
                purchaseType = item.purchaseType,
                description = item.description,
            }
        end
    end

    return nil
end

local function normalizeModelPath(path)
    if not isstring(path) then return nil end

    path = string.Trim(path)
    path = string.Replace(path, "\\", "/")

    if path == "" then return nil end
    if not string.StartWith(string.lower(path), "models/") then return nil end
    if not string.EndsWith(string.lower(path), ".mdl") then return nil end

    return path
end

-- util.IsValidModel por si solo puede devolver falsos negativos con ciertos
-- modelos montados/VPK. Tambien probamos file.Exists y una variante lowercase.
local function validateModelCandidate(path)
    path = normalizeModelPath(path)
    if not path then return nil end

    local function isErrorModel(p)
        return string.lower(p or "") == "models/error.mdl"
    end

    local function test(p)
        if not p or p == "" or isErrorModel(p) then return false end

        local okValid, valid = pcall(util.IsValidModel, p)
        if okValid and valid then return true end

        local okFile, exists = pcall(file.Exists, p, "GAME")
        if okFile and exists then return true end

        return false
    end

    if test(path) then
        return path
    end

    -- Los assets default de Source/GMod suelen estar normalizados en lowercase.
    -- Esto corrige rutas como models/Humans/... en clientes Linux.
    local lower = string.lower(path)
    if lower ~= path and test(lower) then
        return lower
    end

    return nil
end

local function getTypeFallback(productType)
    local configured = C.Preview.TypeFallbacks or {}
    local candidate = validateModelCandidate(configured[productType or ""])
    if candidate then return candidate end

    local generic = validateModelCandidate(C.Preview.FallbackModel)
    if generic then return generic end

    -- Fallbacks incluidos con GMod/HL2. Nunca mandamos models/error.mdl.
    local guaranteed = {
        "models/player/kleiner.mdl",
        "models/weapons/w_pistol.mdl",
        "models/props_junk/wood_crate001a.mdl",
        "models/items/battery.mdl",
    }

    for _, path in ipairs(guaranteed) do
        local valid = validateModelCandidate(path)
        if valid then return valid end
    end

    return nil
end

local function resolvePreviewModel(product)
    if not istable(product) then
        return getTypeFallback("other")
    end

    -- 1) Model de preview configurado explicitamente.
    local model = validateModelCandidate(product.previewModel)
    if model then return model end

    -- 2) Model de spawn (muy util para prop_physics y entidades genericas).
    model = validateModelCandidate(product.spawnModel)
    if model then return model end

    -- 3) Si className ya es una ruta .mdl.
    model = validateModelCandidate(product.className)
    if model then return model end

    -- 4) Player model registrado por nombre.
    if product.type == "model" and isstring(product.className) and product.className ~= "" then
        local ok, translated = pcall(player_manager.TranslatePlayerModel, product.className)
        if ok then
            model = validateModelCandidate(translated)
            if model then return model end
        end
    end

    -- 5) WorldModel real de una SWEP.
    if product.type == "weapon" and product.className and product.className ~= "" then
        local stored = weapons.GetStored(product.className)
        if stored then
            model = validateModelCandidate(stored.WorldModel)
                or validateModelCandidate(stored.WM)
                or validateModelCandidate(stored.ViewModel)

            if model then return model end
        end
    end

    -- 6) Model registrado por scripted entity.
    if product.className and product.className ~= "" then
        local storedEnt = scripted_ents.GetStored(product.className)
        if storedEnt and storedEnt.t then
            local entTable = storedEnt.t

            model = validateModelCandidate(entTable.Model)
                or validateModelCandidate(entTable.WorldModel)
                or validateModelCandidate(entTable.Mdl)
                or validateModelCandidate(entTable.MDL)

            if model then return model end
        end

        -- 7) Vehiculos Sandbox/LVS/LFS que se registran en list.Get("Vehicles").
        local vehicles = list.Get("Vehicles")
        local vehicle = vehicles and vehicles[product.className]

        if vehicle then
            model = validateModelCandidate(vehicle.Model)

            if not model and istable(vehicle.Members) then
                model = validateModelCandidate(vehicle.Members.Model)
                    or validateModelCandidate(vehicle.Members.MDL)
                    or validateModelCandidate(vehicle.Members.Mdl)
            end

            if model then return model end
        end
    end

    return getTypeFallback(product.type)
end

local function setPanelModelSafe(panel, product)
    if not IsValid(panel) then return false end

    local requested = resolvePreviewModel(product)
    local fallback = getTypeFallback(istable(product) and product.type or "other")

    local function apply(path)
        path = validateModelCandidate(path)
        if not path then return false end

        pcall(util.PrecacheModel, path)
        panel:SetModel(path)

        if not IsValid(panel.Entity) then
            return false
        end

        local actual = string.lower(tostring(panel.Entity:GetModel() or ""))
        if actual == "" or actual == "models/error.mdl" then
            return false
        end

        panel.GRNResolvedModel = path
        return true
    end

    if apply(requested) then
        return true
    end

    if fallback ~= requested and apply(fallback) then
        return true
    end

    return false
end

local function fitModelPanel(panel)
    if not IsValid(panel) or not IsValid(panel.Entity) then return end

    local ent = panel.Entity
    local mins, maxs = ent:GetRenderBounds()
    if not mins or not maxs then return end

    local center = (mins + maxs) * 0.5
    local extent = maxs - mins
    local size = math.max(extent.x, extent.y, extent.z)
    if size <= 0 then size = 72 end

    panel:SetFOV(C.Preview.FOV or 34)
    panel:SetLookAt(center)

    -- Camara diagonal para que armas, props y playermodels entren bien
    -- en el espacio visual de cada tarjeta.
    panel:SetCamPos(center + Vector(size * 1.18, size * 1.18, size * 0.34))
end

local function removePreviewPanel(key)
    local pnl = S.PreviewPanels and S.PreviewPanels[key]
    if IsValid(pnl) then pnl:Remove() end
    if S.PreviewPanels then S.PreviewPanels[key] = nil end
end

function S.ClearPreviews()
    S.PreviewPanels = S.PreviewPanels or {}
    for key, pnl in pairs(S.PreviewPanels) do
        if IsValid(pnl) then pnl:Remove() end
        S.PreviewPanels[key] = nil
    end
end

local function createCardModelPanel(key, productID)
    if not C.Preview.Enabled or not IsValid(S.MenuFrame) then return nil end

    local product = productFromID(productID)
    if not product then return nil end

    local panel = vgui.Create("DModelPanel", S.MenuFrame)
    panel:SetMouseInputEnabled(false)
    panel:SetKeyboardInputEnabled(false)
    if panel.SetPaintBackground then panel:SetPaintBackground(false) end
    panel:SetFOV(C.Preview.FOV or 34)
    panel:SetAmbientLight(Color(78, 102, 113))
    panel:SetDirectionalLight(BOX_FRONT, Color(235, 248, 255))
    panel:SetDirectionalLight(BOX_RIGHT, Color(62, 173, 205))
    panel:SetDirectionalLight(BOX_TOP, Color(148, 211, 227))
    panel:SetZPos(25)
    panel.GRNStoreKey = key
    panel.GRNStoreProductID = tostring(productID or "")

    panel.LayoutEntity = function(self, ent)
        if not IsValid(ent) then return end
        if C.Preview.Spin then
            ent:SetAngles(Angle(0, (RealTime() * (C.Preview.SpinSpeed or 10)) % 360, 0))
        end
        self:RunAnimation()
    end

    if not setPanelModelSafe(panel, product) then
        panel:Remove()
        return nil
    end

    if IsValid(panel.Entity) then
        panel.Entity:SetAngles(Angle(0, 0, 0))
    end

    fitModelPanel(panel)

    -- Algunos modelos montados terminan de resolverse un frame despues.
    -- Si Source los reemplaza por ERROR, reintentamos con un fallback seguro.
    timer.Simple(0, function()
        if not IsValid(panel) then return end

        local ent = panel.Entity
        local actual = IsValid(ent) and string.lower(tostring(ent:GetModel() or "")) or ""

        if actual == "" or actual == "models/error.mdl" then
            if not setPanelModelSafe(panel, product) then
                panel:Remove()
                if S.PreviewPanels then
                    S.PreviewPanels[key] = nil
                end
                return
            end

            fitModelPanel(panel)
        end
    end)

    S.PreviewPanels[key] = panel
    return panel
end

local function ensureCardModelPanel(key, productID)
    S.PreviewPanels = S.PreviewPanels or {}

    local panel = S.PreviewPanels[key]
    if IsValid(panel) and panel.GRNStoreProductID == tostring(productID or "") then
        return panel
    end

    if IsValid(panel) then panel:Remove() end
    S.PreviewPanels[key] = nil
    return createCardModelPanel(key, productID)
end

function S.SyncPreviewSlots(payloadJSON)
    if not C.Preview.Enabled or not IsValid(S.MenuFrame) or not IsValid(S.MenuHTML) then
        S.ClearPreviews()
        return
    end

    local payload = util.JSONToTable(tostring(payloadJSON or ""))
    if not istable(payload) then
        S.ClearPreviews()
        return
    end

    local slots = istable(payload.slots) and payload.slots or {}
    local viewportW = math.max(1, tonumber(payload.viewportW) or S.MenuHTML:GetWide())
    local viewportH = math.max(1, tonumber(payload.viewportH) or S.MenuHTML:GetTall())
    local htmlW, htmlH = S.MenuHTML:GetWide(), S.MenuHTML:GetTall()
    local scaleX = htmlW / viewportW
    local scaleY = htmlH / viewportH
    local htmlX, htmlY = S.MenuHTML:GetPos()
    local active = {}
    local visibleCount = 0
    local maxVisible = math.max(1, tonumber(C.Preview.MaxVisiblePanels) or 24)

    for _, slot in ipairs(slots) do
        if visibleCount >= maxVisible then break end
        if istable(slot) then
            local key = tostring(slot.key or "")
            local productID = tostring(slot.id or "")
            local x = tonumber(slot.x)
            local y = tonumber(slot.y)
            local w = tonumber(slot.w)
            local h = tonumber(slot.h)

            if key ~= "" and productID ~= "" and x and y and w and h and w >= 24 and h >= 24 then
                local px = math.floor(htmlX + x * scaleX + 0.5)
                local py = math.floor(htmlY + y * scaleY + 0.5)
                local pw = math.max(24, math.floor(w * scaleX + 0.5))
                local ph = math.max(24, math.floor(h * scaleY + 0.5))

                -- No crear previews que esten completamente fuera del DHTML.
                if px < htmlX + htmlW and py < htmlY + htmlH and px + pw > htmlX and py + ph > htmlY then
                    active[key] = true
                    visibleCount = visibleCount + 1
                    local panel = ensureCardModelPanel(key, productID)
                    if IsValid(panel) then
                        panel:SetPos(px, py)
                        panel:SetSize(pw, ph)
                        panel:SetVisible(true)
                        panel:MoveToFront()
                    end
                end
            end
        end
    end

    for key, panel in pairs(S.PreviewPanels or {}) do
        if not active[key] then
            removePreviewPanel(key)
        elseif IsValid(panel) then
            panel:MoveToFront()
        end
    end
end

-- Compatibilidad con versiones anteriores del HTML. El nuevo diseño usa
-- SyncPreviewSlots para tener un modelo 3D dentro de CADA tarjeta.
function S.HidePreview()
    S.ClearPreviews()
end

function S.ShowPreview(productID)
    -- Ya no se usa un panel lateral flotante. Se conserva como no-op
    -- por compatibilidad con clientes que tengan el HTML anterior cacheado.
end

local function bindHTMLFunctions(html)
    html:AddFunction("grnStore", "buy", function(id)
        if not IsValid(S.MenuFrame) then return end
        sendSimpleNet("grn_store_buy", id)
    end)

    html:AddFunction("grnStore", "useItem", function(id)
        if not IsValid(S.MenuFrame) then return end
        sendSimpleNet("grn_store_use_item", id)
    end)

    html:AddFunction("grnStore", "syncPreviews", function(json)
        S.SyncPreviewSlots(json)
    end)

    html:AddFunction("grnStore", "clearPreviews", function()
        S.ClearPreviews()
    end)

    -- Compatibilidad con HTML viejo.
    html:AddFunction("grnStore", "preview", function(id)
        S.ShowPreview(id)
    end)

    html:AddFunction("grnStore", "hidePreview", function()
        S.HidePreview()
    end)

    html:AddFunction("grnStore", "saveCategory", function(json)
        if not S.ClientState.isStaff then return end
        net.Start("grn_store_staff_category_save")
            net.WriteString(tostring(json or "{}"))
        net.SendToServer()
    end)

    html:AddFunction("grnStore", "deleteCategory", function(id)
        if not S.ClientState.isStaff then return end
        sendSimpleNet("grn_store_staff_category_delete", id)
    end)

    html:AddFunction("grnStore", "saveProduct", function(json)
        if not S.ClientState.isStaff then return end
        net.Start("grn_store_staff_product_save")
            net.WriteString(tostring(json or "{}"))
        net.SendToServer()
    end)

    html:AddFunction("grnStore", "deleteProduct", function(id)
        if not S.ClientState.isStaff then return end
        sendSimpleNet("grn_store_staff_product_delete", id)
    end)

    html:AddFunction("grnStore", "close", function()
        S.CloseMenu()
    end)
end

function S.OpenMenu()
    if IsValid(S.ArmoryFrame) and isfunction(S.CloseArmoryMenu) then
        S.CloseArmoryMenu()
    end

    if IsValid(S.MenuFrame) then
        S.MenuFrame:Remove()
    end

    S.ClosingMenu = false
    S.HTMLReady = false

    -- EditablePanel no agrega barra de titulo, bordes ni padding interno.
    -- De esta forma el DHTML realmente cubre ScrW() x ScrH().
    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    -- EditablePanel no implementa SetPaintBackground en todas las builds de GMod.
    -- La comprobacion evita el error y mantiene compatibilidad.
    if frame.SetPaintBackground then frame:SetPaintBackground(false) end
    frame:SetKeyboardInputEnabled(true)
    frame:SetMouseInputEnabled(true)
    frame:MakePopup()

    local html = vgui.Create("DHTML", frame)
    html:Dock(FILL)
    html:SetPos(0, 0)
    html:SetMouseInputEnabled(true)
    html:SetKeyboardInputEnabled(true)
    bindHTMLFunctions(html)

    html.OnDocumentReady = function()
        S.HTMLReady = true
        timer.Simple(0, function()
            if IsValid(html) then pushStateToHTML() end
        end)
    end

    local page = S.HTML or "<html><body style='background:#000;color:#fff'>Shop konnte nicht geladen werden.</body></html>"
    html:SetHTML(SYMUI and SYMUI.ThemeHTML(page) or page)

    S.MenuFrame = frame
    S.MenuHTML = html


    frame.OnRemove = function()
        S.ClearPreviews()
        S.MenuFrame = nil
        S.MenuHTML = nil
        S.HTMLReady = false

        if not S.ClosingMenu then
            net.Start("grn_store_close")
            net.SendToServer()
        end
    end

    timer.Simple(0.15, function()
        if IsValid(frame) then
            pushStateToHTML()
        end
    end)
end

function S.CloseMenu()
    if not IsValid(S.MenuFrame) then return end

    S.ClosingMenu = true
    net.Start("grn_store_close")
    net.SendToServer()

    S.ClearPreviews()
    S.MenuFrame:Remove()
    S.CurrentVendor = nil
    S.ClosingMenu = false
end

net.Receive("grn_store_state", function()
    local shouldOpen = net.ReadBool()
    local vendor = net.ReadEntity()
    local data = readCompressedTable()

    S.ClientState = data
    if IsValid(vendor) then S.CurrentVendor = vendor end

    if shouldOpen then
        S.OpenMenu()
    else
        pushStateToHTML()
    end
end)

net.Receive("grn_store_staff_ack", function()
    local kind = net.ReadString()
    if IsValid(S.MenuHTML) and S.HTMLReady then
        local json = util.TableToJSON({ kind = tostring(kind or "") }, false) or '{"kind":""}'
        S.MenuHTML:QueueJavascript("if(window.CloneFallStore&&window.CloneFallStore.staffSaved){window.CloneFallStore.staffSaved((" .. json .. ").kind);}")
    end
end)

net.Receive("grn_store_notify", function()
    local message = net.ReadString()
    if IsValid(S.MenuHTML) and S.HTMLReady then
        local json = util.TableToJSON({ message = tostring(message or "") }, false) or '{"message":""}'
        S.MenuHTML:QueueJavascript("if(window.CloneFallStore){window.CloneFallStore.notify((" .. json .. ").message);}")
    end
end)

hook.Add("Think", "GRNStore_MenuDistance", function()
    if not IsValid(S.MenuFrame) then return end

    if IsValid(S.CurrentVendor) and IsValid(LocalPlayer()) then
        local maxDist = tonumber(C.Entity.MenuMaxDistance) or 450
        if LocalPlayer():GetPos():DistToSqr(S.CurrentVendor:GetPos()) > maxDist * maxDist then
            S.CloseMenu()
        end
    end
end)

hook.Add("OnScreenSizeChanged", "GRNStore_ResizeMenu", function()
    timer.Simple(0, function()
        if IsValid(S.MenuFrame) then
            S.MenuFrame:SetSize(ScrW(), ScrH())
            S.MenuFrame:SetPos(0, 0)
            S.ClearPreviews()
            if IsValid(S.MenuHTML) and S.HTMLReady then
                S.MenuHTML:QueueJavascript("if(window.CloneFallStore&&window.CloneFallStore.syncPreviews){window.CloneFallStore.syncPreviews();}")
            end
        end
    end)
end)
