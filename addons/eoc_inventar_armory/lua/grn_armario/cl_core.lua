GRNWeaponrio = GRNWeaponrio or {}
local C = GRNWeaponrio.Config or {}

GRNWeaponrio.UI = GRNWeaponrio.UI or {}
local UI = GRNWeaponrio.UI

local function readCompressedTable()
    local len = net.ReadUInt(32)
    if len <= 0 then return {} end
    local raw = net.ReadData(len)
    local json = util.Decompress(raw or "")
    if not json then return {} end
    return util.JSONToTable(json) or {}
end

local function jobByID(id)
    id = tonumber(id)
    for _, job in ipairs((UI.Data and UI.Data.jobs) or {}) do
        if tonumber(job.id) == id then return job end
    end
    return nil
end

local function queueJS(code)
    if IsValid(UI.HTML) and UI.HTMLReady then
        UI.HTML:QueueJavascript(code)
    end
end

local function notify(text, ok)
    queueJS("window.GRNWeaponrio&&window.GRNWeaponrio.notify(" .. string.format("%q", tostring(text or "")) .. "," .. (ok == false and "false" or "true") .. ");")
end

local function lower(s)
    return string.lower(tostring(s or ""))
end

local function findSavedModelIndex(job)
    if not job or not job.saved or not job.saved.model then return 1 end
    for index, mdl in ipairs(job.models or {}) do
        if lower(mdl) == lower(job.saved.model) then return index end
    end
    return 1
end

local function bodygroupMemory(jobID, modelIndex)
    UI.ModelBodygroups = UI.ModelBodygroups or {}
    UI.ModelBodygroups[jobID] = UI.ModelBodygroups[jobID] or {}
    UI.ModelBodygroups[jobID][modelIndex] = UI.ModelBodygroups[jobID][modelIndex] or {}
    return UI.ModelBodygroups[jobID][modelIndex]
end

local function seedSavedBodygroups(job, modelIndex)
    local memory = bodygroupMemory(tonumber(job.id), modelIndex)
    if next(memory) ~= nil then return memory end

    local mdl = (job.models or {})[modelIndex]
    if job.saved and mdl and lower(job.saved.model) == lower(mdl) then
        for id, value in pairs(job.saved.bodygroups or {}) do
            memory[tonumber(id) or id] = tonumber(value) or 0
        end
    end

    return memory
end

local function layoutPreview()
    if not IsValid(UI.ModelPanel) then return end

    local w, h = ScrW(), ScrH()
    local P = C.Preview or {}

    local pw = math.floor(w * (tonumber(P.W) or 0.24))
    local ph = math.floor(h * (tonumber(P.H) or 0.52))
    local x = math.floor(w * (tonumber(P.X) or 0.66))
    local y = math.floor(h * (tonumber(P.Y) or 0.18))

    pw = math.Clamp(pw, tonumber(P.MinW) or 300, tonumber(P.MaxW) or 620)
    ph = math.Clamp(ph, tonumber(P.MinH) or 300, tonumber(P.MaxH) or 760)

    if x + pw > w - 24 then x = w - pw - 24 end
    if y + ph > h - 64 then y = h - ph - 64 end
    if x < 0 then x = 0 end
    if y < 0 then y = 0 end

    UI.ModelPanel:SetPos(x, y)
    UI.ModelPanel:SetSize(pw, ph)
end

local function pushBodygroupsToHTML(job, modelIndex)
    if not IsValid(UI.ModelPanel) then return end
    local ent = UI.ModelPanel:GetEntity()
    if not IsValid(ent) then return end

    local memory = seedSavedBodygroups(job, modelIndex)
    local list = {}

    for _, bg in ipairs(ent:GetBodyGroups() or {}) do
        local id = tonumber(bg.id) or 0
        local count = tonumber(bg.num) or 0
        if count > 1 then
            local value = math.Clamp(tonumber(memory[id]) or 0, 0, count - 1)
            memory[id] = value
            ent:SetBodygroup(id, value)
            list[#list + 1] = {
                id = id,
                name = tostring(bg.name or ("Element " .. id)),
                max = count - 1,
                value = value
            }
        end
    end

    table.sort(list, function(a, b) return a.id < b.id end)
    local json = util.TableToJSON(list, false) or "[]"
    queueJS("window.GRNWeaponrio&&window.GRNWeaponrio.setBodygroups(" .. json .. "," .. tostring(modelIndex) .. ");")
end

local function fitPreviewCamera()
    if not IsValid(UI.ModelPanel) then return end
    local ent = UI.ModelPanel:GetEntity()
    if not IsValid(ent) then return end

    local P = C.Preview or {}
    local mins, maxs = ent:GetRenderBounds()
    local center = (mins + maxs) * 0.5
    local height = math.max(40, maxs.z - mins.z)
    local width = math.max(maxs.x - mins.x, maxs.y - mins.y)
    local dist = math.max(height * (tonumber(P.CamDistHeight) or 2.10), width * (tonumber(P.CamDistWidth) or 3.15), tonumber(P.CamDistMin) or 160)

    UI.ModelPanel:SetFOV(tonumber(P.FOV) or 16)
    UI.ModelPanel:SetLookAt(center + Vector(0, 0, height * (tonumber(P.LookAtZ) or 0.08)))
    UI.ModelPanel:SetCamPos(center + Vector(dist, 0, height * (tonumber(P.CamPosZ) or 0.10)))

    ent:SetAngles(P.Angle or Angle(0, 320, 0))
end

function GRNWeaponrio.SelectJob(id)
    local job = jobByID(id)
    if not job then return end

    UI.SelectedJob = tonumber(job.id)
    local previousIndex = UI.ModelIndex
    local sameJob = UI.LastPreviewJob == UI.SelectedJob

    if sameJob and previousIndex and (job.models or {})[previousIndex] then
        UI.ModelIndex = previousIndex
    else
        UI.ModelIndex = findSavedModelIndex(job)
    end

    UI.LastPreviewJob = UI.SelectedJob
    GRNWeaponrio.RefreshPreview()
end

function GRNWeaponrio.RefreshPreview()
    local job = jobByID(UI.SelectedJob)
    if not job or not IsValid(UI.ModelPanel) then return end

    local models = job.models or {}
    if #models <= 0 then return end

    UI.ModelIndex = math.Clamp(tonumber(UI.ModelIndex) or 1, 1, #models)
    local mdl = models[UI.ModelIndex]
    if not mdl then return end

    UI.ModelPanel:SetModel(mdl)
    fitPreviewCamera()
    pushBodygroupsToHTML(job, UI.ModelIndex)
end

function GRNWeaponrio.ChangeModel(delta)
    local job = jobByID(UI.SelectedJob)
    if not job then return end

    local total = #(job.models or {})
    if total <= 1 then return end

    local index = (tonumber(UI.ModelIndex) or 1) + (tonumber(delta) or 0)
    if index < 1 then index = total end
    if index > total then index = 1 end
    UI.ModelIndex = index
    GRNWeaponrio.RefreshPreview()
end

function GRNWeaponrio.SetPreviewBodygroup(id, value)
    local job = jobByID(UI.SelectedJob)
    if not job or not IsValid(UI.ModelPanel) then return end

    id = math.floor(tonumber(id) or -1)
    value = math.floor(tonumber(value) or 0)
    if id < 0 then return end

    local ent = UI.ModelPanel:GetEntity()
    if not IsValid(ent) then return end

    local count = ent:GetBodygroupCount(id) or 0
    if count <= 0 then return end
    value = math.Clamp(value, 0, count - 1)

    bodygroupMemory(tonumber(job.id), tonumber(UI.ModelIndex) or 1)[id] = value
    ent:SetBodygroup(id, value)
end

function GRNWeaponrio.EquipSelected()
    local job = jobByID(UI.SelectedJob)
    if not job then
        notify("Wähle einen verfügbaren Job aus.", false)
        return
    end

    local entIndex = tonumber(UI.Data and UI.Data.entity) or 0
    local locker = Entity(entIndex)
    if not IsValid(locker) then
        notify("Der Schrank ist nicht mehr verfügbar.", false)
        return
    end

    local modelIndex = math.Clamp(tonumber(UI.ModelIndex) or 1, 1, 255)
    local memory = bodygroupMemory(tonumber(job.id), modelIndex)
    local pairsList = {}

    for id, value in pairs(memory) do
        id = math.floor(tonumber(id) or -1)
        value = math.floor(tonumber(value) or 0)
        if id >= 0 and id <= 255 and #pairsList < 64 then
            pairsList[#pairsList + 1] = {id = id, value = math.Clamp(value, 0, 255)}
        end
    end

    table.sort(pairsList, function(a, b) return a.id < b.id end)

    net.Start("grn_armario_equip")
    net.WriteUInt(entIndex, 16)
    net.WriteUInt(tonumber(job.id) or 0, 16)
    net.WriteUInt(modelIndex, 8)
    net.WriteUInt(#pairsList, 8)
    for _, bg in ipairs(pairsList) do
        net.WriteUInt(bg.id, 8)
        net.WriteUInt(bg.value, 8)
    end
    net.SendToServer()
end

function GRNWeaponrio.CloseMenu(silent)
    if IsValid(UI.Frame) then UI.Frame:Remove() end
    UI.Frame = nil
    UI.HTML = nil
    UI.ModelPanel = nil
    UI.HTMLReady = false

    if not silent then
        net.Start("grn_armario_close")
        net.SendToServer()
    end
end

local function pushDataToHTML()
    if not UI.Data then return end
    local json = util.TableToJSON(UI.Data, false) or "{}"
    queueJS("window.GRNWeaponrio&&window.GRNWeaponrio.setData(" .. json .. ");")
end

local function createMenu()
    if IsValid(UI.Frame) then return end

    UI.Frame = vgui.Create("EditablePanel")
    UI.Frame:SetSize(ScrW(), ScrH())
    UI.Frame:SetPos(0, 0)
    UI.Frame:SetKeyboardInputEnabled(true)
    UI.Frame:SetMouseInputEnabled(true)
    UI.Frame:MakePopup()
    UI.Frame.Paint = function() end
    UI.Frame.OnRemove = function()
        UI.HTMLReady = false
    end

    UI.HTML = vgui.Create("DHTML", UI.Frame)
    UI.HTML:Dock(FILL)
    UI.HTML:SetZPos(1)
    UI.HTMLReady = false

    UI.HTML:AddFunction("gmod", "close", function()
        GRNWeaponrio.CloseMenu(false)
    end)

    UI.HTML:AddFunction("gmod", "selectJob", function(id)
        GRNWeaponrio.SelectJob(tonumber(id))
    end)

    UI.HTML:AddFunction("gmod", "setBodygroup", function(id, value)
        GRNWeaponrio.SetPreviewBodygroup(id, value)
    end)

    UI.HTML:AddFunction("gmod", "equip", function()
        GRNWeaponrio.EquipSelected()
    end)

    UI.HTML:AddFunction("gmod", "nextModel", function(delta)
        GRNWeaponrio.ChangeModel(tonumber(delta) or 1)
    end)

    UI.HTML.OnDocumentReady = function()
        UI.HTMLReady = true
        pushDataToHTML()
    end

    local html = GRNWeaponrio.GetHTML()
    UI.HTML:SetHTML(SYMUI and SYMUI.ThemeHTML(html, { yellows = { "255,190,50", "115,165,237", "77,128,202" }, hexes = { "#73a5ed", "#ffbe32" } }) or html)

    UI.ModelPanel = vgui.Create("DModelPanel", UI.Frame)
    UI.ModelPanel:SetZPos(8)
    UI.ModelPanel:SetMouseInputEnabled(false)
    UI.ModelPanel:SetKeyboardInputEnabled(false)
    if UI.ModelPanel.SetPaintBackground then UI.ModelPanel:SetPaintBackground(false) end
    if UI.ModelPanel.SetAmbientLight then UI.ModelPanel:SetAmbientLight(Vector(0.58, 0.62, 0.75)) end
    if UI.ModelPanel.SetDirectionalLight then
        UI.ModelPanel:SetDirectionalLight(BOX_TOP, Color(255, 255, 255))
        UI.ModelPanel:SetDirectionalLight(BOX_FRONT, Color(210, 225, 255))
        UI.ModelPanel:SetDirectionalLight(BOX_LEFT, Color(125, 145, 175))
    end
    UI.ModelPanel.LayoutEntity = function(panel, ent)
        if panel.GRNLastEntity ~= ent then
            panel.GRNLastEntity = ent
            local seq = ent:LookupSequence("idle_all_01")
            if seq and seq >= 0 then ent:ResetSequence(seq) end
            ent:SetPlaybackRate(0.55)
        end
        panel:RunAnimation()
    end

    layoutPreview()

    UI.NextRefresh = RealTime() + (C.RefreshInterval or 2)
    UI.Frame.Think = function(self)
        if self:GetWide() ~= ScrW() or self:GetTall() ~= ScrH() then
            self:SetSize(ScrW(), ScrH())
            layoutPreview()
        end

        if RealTime() >= (UI.NextRefresh or 0) then
            UI.NextRefresh = RealTime() + (C.RefreshInterval or 2)
            local entIndex = tonumber(UI.Data and UI.Data.entity) or 0
            if entIndex > 0 then
                net.Start("grn_armario_request")
                net.WriteUInt(entIndex, 16)
                net.SendToServer()
            end
        end
    end

    UI.Frame.OnKeyCodePressed = function(_, key)
        if key == KEY_ESCAPE then
            GRNWeaponrio.CloseMenu(false)
        elseif key == KEY_ENTER then
            GRNWeaponrio.EquipSelected()
        end
    end
end

local function updateData(data, shouldOpen)
    UI.Data = data or {}

    if shouldOpen and not IsValid(UI.Frame) then
        createMenu()
    end

    if not IsValid(UI.Frame) then return end

    pushDataToHTML()

    local stillValid = jobByID(UI.SelectedJob)
    if not stillValid then
        UI.SelectedJob = nil
        for _, job in ipairs(UI.Data.jobs or {}) do
            if job.current then
                UI.SelectedJob = tonumber(job.id)
                break
            end
        end
        if not UI.SelectedJob and UI.Data.jobs and UI.Data.jobs[1] then
            UI.SelectedJob = tonumber(UI.Data.jobs[1].id)
        end
    end

    if UI.SelectedJob then
        if IsValid(UI.ModelPanel) then UI.ModelPanel:SetVisible(true) end
        GRNWeaponrio.SelectJob(UI.SelectedJob)
    else
        if IsValid(UI.ModelPanel) then UI.ModelPanel:SetVisible(false) end
        queueJS("window.GRNWeaponrio&&window.GRNWeaponrio.setBodygroups([],1);")
    end
end

net.Receive("grn_armario_jobs", function()
    local shouldOpen = net.ReadBool()
    local data = readCompressedTable()
    updateData(data, shouldOpen)
end)

net.Receive("grn_armario_feedback", function()
    local ok = net.ReadBool()
    local text = net.ReadString()
    notify(text, ok)

    if ok then
        timer.Simple(0.30, function()
            if IsValid(UI.Frame) then GRNWeaponrio.CloseMenu(false) end
        end)
    end
end)

hook.Add("ShutDown", "GRNWeaponrio.CloseOnShutdown", function()
    GRNWeaponrio.CloseMenu(true)
end)
