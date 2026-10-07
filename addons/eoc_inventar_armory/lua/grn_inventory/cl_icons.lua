--[[
    GRN Inventory - model icon renderer

    Renders any .mdl into a small transparent PNG (once), caches it in
    data/grn_inventory/icons/ and exposes it as a data: URI that the DHTML
    inventory and armory can show directly in an <img>.

    INV.RequestModelIcon(model, key, opts, callback)
        callback(dataURI) is called once the icon is ready.
]]

local INV = GRNInventory
local C = INV.Config

INV.ModelIcons = INV.ModelIcons or {}       -- cacheKey -> data URI
INV.ModelIconWaiters = INV.ModelIconWaiters or {}
INV.ModelIconQueue = INV.ModelIconQueue or {}

local ICON_DIR = "grn_inventory/icons"

local function iconSize()
    return math.Clamp(math.floor(tonumber(C.Armor and C.Armor.IconSize) or 128), 32, 256)
end

local function cacheKey(model, opts)
    local v = tostring((C.Armor and C.Armor.IconVersion) or 1)
    local extra = ""
    if istable(opts) then
        extra = tostring(opts.kind or "") .. tostring(opts.camDir or "") .. tostring(opts.zoom or "")
            .. tostring(opts.bone or "") .. tostring(opts.radius or "")
            .. (istable(opts.override) and (util.TableToJSON(opts.override) or "") or "")
    end
    return util.CRC(string.lower(model) .. "|" .. extra .. "|" .. v .. "|" .. iconSize())
end

local function toURI(png)
    if not png or png == "" then return nil end
    local b64 = util.Base64Encode(png, true)
    if not b64 or b64 == "" then return nil end
    return "data:image/png;base64," .. b64
end

local function deliver(key, uri)
    INV.ModelIcons[key] = uri or false
    local waiters = INV.ModelIconWaiters[key]
    INV.ModelIconWaiters[key] = nil
    if not waiters or not uri then return end
    for _, cb in ipairs(waiters) do
        pcall(cb, uri)
    end
end

function INV.RequestModelIcon(model, opts, callback)
    if not isstring(model) or model == "" then return end
    model = string.Replace(model, "\\", "/")
    if not string.EndsWith(string.lower(model), ".mdl") then return end

    local key = cacheKey(model, opts)
    local known = INV.ModelIcons[key]
    if known then
        if callback then callback(known) end
        return known
    end
    if known == false then return end -- failed before

    if callback then
        INV.ModelIconWaiters[key] = INV.ModelIconWaiters[key] or {}
        table.insert(INV.ModelIconWaiters[key], callback)
    end

    -- Disk cache from an earlier session.
    local path = ICON_DIR .. "/" .. key .. ".png"
    if file.Exists(path, "DATA") then
        local uri = toURI(file.Read(path, "DATA"))
        if uri then
            deliver(key, uri)
            return uri
        end
    end

    for _, job in ipairs(INV.ModelIconQueue) do
        if job.key == key then return end
    end
    INV.ModelIconQueue[#INV.ModelIconQueue + 1] = { key = key, model = model, opts = opts or {} }
end

local rt
local function getRT(size)
    if rt then return rt end
    rt = GetRenderTargetEx("grn_inventory_icon_rt_" .. size, size, size,
        RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_SEPARATE, bit.bor(4, 8, 256, 512), 0,
        IMAGE_FORMAT_RGBA8888 or 0)
    return rt
end

local function renderJob(job)
    local size = iconSize()
    if not util.IsValidModel(job.model) then return nil end

    local ent = ClientsideModel(job.model, RENDERGROUP_OPAQUE)
    if not IsValid(ent) then return nil end
    ent:SetNoDraw(true)
    ent:SetPos(vector_origin)
    ent:SetAngles(angle_zero)

    -- Armor pictures from a job model: idle pose, every armor bodygroup on.
    if job.opts.bone then
        local seq = ent:LookupSequence("idle_all_01")
        if seq and seq >= 0 then ent:ResetSequence(seq) ent:SetCycle(0) end
        local override = istable(job.opts.override) and job.opts.override or {}
        for key, group in pairs(isfunction(INV.ResolveArmorBodygroups) and INV.ResolveArmorBodygroups(ent) or {}) do
            ent:SetBodygroup(group.index, tonumber(override[key]) or group.on)
        end
    end
    ent:SetupBones()

    local mins, maxs
    if ent.GetModelRenderBounds then mins, maxs = ent:GetModelRenderBounds() end
    if not mins then mins, maxs = ent:GetRenderBounds() end
    local center = (mins + maxs) * 0.5
    local extent = maxs - mins
    local radius = math.max(2, extent:Length() * 0.5)

    if job.opts.bone then
        local boneID = ent:LookupBone(job.opts.bone)
        local matrix = boneID and ent:GetBoneMatrix(boneID) or nil
        if matrix then
            center = matrix:GetTranslation()
            radius = math.max(2, tonumber(job.opts.radius) or 12)
        end
    end

    -- Camera direction: armor is seen from the front-right, weapons from the
    -- side perpendicular to their longest axis.
    local dir = job.opts.camDir
    if not isvector(dir) then
        if job.opts.kind == "weapon" then
            if extent.x >= extent.y then
                dir = Vector(0.12, -1, 0.18)
            else
                dir = Vector(1, 0.12, 0.18)
            end
        else
            dir = Vector(1, 0.42, 0.18)
        end
    end
    dir = dir:GetNormalized()

    local fov = 30
    local zoom = tonumber(job.opts.zoom) or 1
    local dist = (radius / math.sin(math.rad(fov * 0.5))) / zoom
    local camPos = center + dir * dist
    local camAng = (center - camPos):Angle()

    local target = getRT(size)
    render.PushRenderTarget(target)
    render.OverrideAlphaWriteEnable(true, true)
    render.SetWriteDepthToDestAlpha(false)
    render.Clear(0, 0, 0, 0, true, true)

    cam.Start3D(camPos, camAng, fov, 0, 0, size, size, 1, dist + radius * 4)
        render.SuppressEngineLighting(true)
        render.SetLightingOrigin(center)
        render.ResetModelLighting(0.32, 0.34, 0.38)
        render.SetModelLighting(BOX_FRONT, 1.0, 1.0, 1.0)
        render.SetModelLighting(BOX_TOP, 0.9, 0.9, 0.92)
        render.SetModelLighting(BOX_RIGHT, 0.55, 0.58, 0.62)
        render.SetModelLighting(BOX_LEFT, 0.45, 0.47, 0.52)
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        ent:DrawModel()
        render.SuppressEngineLighting(false)
    cam.End3D()

    local png = render.Capture({ format = "png", x = 0, y = 0, w = size, h = size, alpha = true })
    render.SetWriteDepthToDestAlpha(true)
    render.OverrideAlphaWriteEnable(false)
    render.PopRenderTarget()
    ent:Remove()

    return png
end

hook.Add("PostRender", "GRNInventory_ModelIconRenderer", function()
    local job = table.remove(INV.ModelIconQueue, 1)
    if not job then return end

    local ok, png = pcall(renderJob, job)
    if not ok or not png then
        if not ok then ErrorNoHalt("[GRN Inventory] Icon render failed for " .. job.model .. ": " .. tostring(png) .. "\n") end
        deliver(job.key, nil)
        return
    end

    file.CreateDir(ICON_DIR)
    file.Write(ICON_DIR .. "/" .. job.key .. ".png", png)
    deliver(job.key, toURI(png))
end)

-- Icon for an inventory item definition (armor model, or weapon world model).
function INV.RequestItemIcon(itemID, callback)
    local def = INV.GetItemDefinition(itemID)
    if not def then return end
    if isstring(def.IconURL) and def.IconURL ~= "" then return end
    if def.Type == "weapon" and C.Armor and C.Armor.RenderWeaponIcons == false then return end

    local model = INV.GetIconModel(def)

    -- Armor: the piece's own (Nevelgrad) model when it is installed, otherwise
    -- the job model, zoomed onto the body part of its slot.
    local camera
    if def.Type == "armor" then
        if isstring(def.Model) and def.Model ~= "" and util.IsValidModel(def.Model) then
            model = def.Model
        else
            camera = C.Armor and istable(C.Armor.IconCamera) and C.Armor.IconCamera[tostring(def.Slot or "")] or nil
            if camera and not (model and INV.GetArmorBodygroupProfile(model)) then camera = nil end
        end
    end
    if not model then return end

    return INV.RequestModelIcon(model, {
        kind = def.Type == "weapon" and "weapon" or "armor",
        camDir = def.IconCamDir or (camera and camera.Dir),
        zoom = def.IconZoom,
        bone = camera and camera.Bone or nil,
        override = camera and istable(def.PlayerBodygroups) and def.PlayerBodygroups or nil,
        radius = camera and camera.Radius or nil,
    }, callback)
end

concommand.Add("grn_inventory_clear_icons", function()
    for _, name in ipairs(file.Find(ICON_DIR .. "/*.png", "DATA") or {}) do
        file.Delete(ICON_DIR .. "/" .. name)
    end
    INV.ModelIcons = {}
    print("[GRN Inventory] Icon cache cleared.")
end)

-- Warm the cache for every armor item a few seconds after joining, so the
-- armor slots already have pictures the first time the inventory opens.
hook.Add("InitPostEntity", "GRNInventory_PrerenderArmorIcons", function()
    timer.Simple(5, function()
        for id, def in pairs(C.Items or {}) do
            if istable(def) and def.Type == "armor" then
                INV.RequestItemIcon(id)
            end
        end
    end)
end)

-- -------------------------------------------------------------------------
-- UI sounds (shared by inventory and armory)
-- -------------------------------------------------------------------------
local resolvedSounds = {}
local lastHover = 0

local function resolveSound(kind)
    if resolvedSounds[kind] ~= nil then return resolvedSounds[kind] end
    local cfg = C.UISounds or {}
    local list = cfg[kind]
    if isstring(list) then list = { list } end
    local found = false
    for _, path in ipairs(istable(list) and list or {}) do
        if file.Exists("sound/" .. path, "GAME") then
            found = path
            break
        end
    end
    resolvedSounds[kind] = found
    return found
end

function INV.PlayUISound(kind)
    local cfg = C.UISounds or {}
    if cfg.Enabled == false then return end
    kind = tostring(kind or "")
    kind = string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2)
    if kind == "Hover" then
        local now = RealTime()
        if now - lastHover < (tonumber(cfg.HoverCooldown) or 0.06) then return end
        lastHover = now
    end
    local path = resolveSound(kind)
    if path then surface.PlaySound(path) end
end
