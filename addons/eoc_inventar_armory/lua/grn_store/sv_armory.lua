GRNStore = GRNStore or {}
local S = GRNStore
local C = S.Config
local A = C and C.Armory

if not A then return end

util.AddNetworkString("grn_armory_state")
util.AddNetworkString("grn_armory_action")
util.AddNetworkString("grn_armory_close")
util.AddNetworkString("grn_armory_notify")

-- V4: protocolo exclusivo para evitar que copias viejas del addon pisen los net.Receive.
util.AddNetworkString("grn_armory_v4_open")
util.AddNetworkString("grn_armory_v4_state")
util.AddNetworkString("grn_armory_v4_request")
util.AddNetworkString("grn_armory_v4_action")
util.AddNetworkString("grn_armory_v4_close")
util.AddNetworkString("grn_armory_v4_notify")

S.ArmoryRate = S.ArmoryRate or {}

local function armoryNotify(ply, text)
    if not IsValid(ply) then return end
    net.Start("grn_armory_v4_notify")
        net.WriteString(tostring(text or "Waffenkammer aktualisiert."))
    net.Send(ply)
end

local function rateLimit(ply, key, delay)
    if not IsValid(ply) then return false end
    local sid = ply:SteamID64() or tostring(ply:EntIndex())
    S.ArmoryRate[sid] = S.ArmoryRate[sid] or {}
    local now = CurTime()
    if (S.ArmoryRate[sid][key] or 0) > now then return false end
    S.ArmoryRate[sid][key] = now + (delay or 0.2)
    return true
end

local function inventoryDefinition(itemID, className)
    if not GRNInventory then return nil, nil end

    itemID = tostring(itemID or "")
    className = string.lower(string.Trim(tostring(className or "")))

    -- Prefer the public API when available, but do not require a modified
    -- grn_inventory. This keeps the user's original backpack/viewmodel addon
    -- completely untouched.
    if itemID ~= "" and isfunction(GRNInventory.GetItemDefinition) then
        local def = GRNInventory.GetItemDefinition(itemID)
        if istable(def) and tostring(def.Type or "") == "weapon" then
            return itemID, def
        end
    end

    if className ~= "" and isfunction(GRNInventory.FindWeaponItemByClass) then
        local id, def = GRNInventory.FindWeaponItemByClass(className)
        if id and istable(def) then return tostring(id), def end
    end

    -- Compatibility fallback for the unmodified/original inventory build.
    local items = GRNInventory.Config and GRNInventory.Config.Items or nil
    if istable(items) then
        if itemID ~= "" then
            local def = items[itemID]
            if istable(def) and tostring(def.Type or "") == "weapon" then
                return itemID, def
            end
        end

        if className ~= "" then
            for id, def in pairs(items) do
                if istable(def) and tostring(def.Type or "") == "weapon" then
                    local weaponClass = string.lower(string.Trim(tostring(def.WeaponClass or "")))
                    if weaponClass ~= "" and weaponClass == className then
                        return tostring(id), def
                    end
                end
            end
        end
    end

    return nil, nil
end

local function mergeTable(dst, src)
    if not istable(src) then return dst end
    for key, value in pairs(src) do
        if key == "Stats" and istable(value) then
            dst.Stats = dst.Stats or {}
            for statKey, statValue in pairs(value) do
                dst.Stats[statKey] = statValue
            end
        else
            dst[key] = value
        end
    end
    return dst
end

local function weaponOverride(id, className)
    local out = {}
    local all = A.WeaponOverrides or {}
    if className and className ~= "" then
        mergeTable(out, all[className])
        mergeTable(out, all[string.lower(className)])
    end
    if id and id ~= "" then
        mergeTable(out, all[id])
        mergeTable(out, all[string.lower(id)])
    end
    return out
end

-- The armory hands weapons to GRN Inventory first. If a store weapon already
-- has an item configured in grn_inventory, that original item is reused. When
-- a staff-created store weapon has no matching inventory entry, a stable
-- runtime item is generated on the server so it can still be stored, equipped,
-- dropped and persisted by grn_inventory without requiring duplicate config.
local function runtimeInventoryID(sourceID)
    local slug
    if isfunction(S.Slug) then
        slug = S.Slug(sourceID)
    else
        slug = string.lower(string.Trim(tostring(sourceID or "weapon")))
        slug = string.gsub(slug, "[^%w_%-]+", "_")
        slug = string.gsub(slug, "_+", "_")
        slug = string.gsub(slug, "^_+", "")
        slug = string.gsub(slug, "_+$", "")
        if slug == "" then slug = "weapon" end
    end
    return "grn_store_weapon_" .. tostring(slug)
end

local function normalizeInventoryRarity(value)
    value = string.lower(string.Trim(tostring(value or "")))
    if value == "common" or value == "uncommon" or value == "rare" or value == "epic" or value == "legendary" then
        return value
    end
    if value == "gold" or value == "orange" then return "legendary" end
    if value == "purple" or value == "violet" then return "epic" end
    if value == "green" then return "uncommon" end
    if value == "blue" or value == "cyan" then return "rare" end
    return "rare"
end

local function inferInventoryEquipSlot(className, cfg, invDef)
    local special = GRNInventory and GRNInventory.Config and GRNInventory.Config.SpecialWeaponClasses
    if istable(special) and special[tostring(className or "")] == true then
        return "specialized"
    end

    local requested = string.lower(string.Trim(tostring(cfg and cfg.EquipSlot or "")))
    if requested == "specialized" then return "specialized" end
    if requested == "primary" or requested == "secondary" or requested == "utility" then
        return requested
    end

    if istable(invDef) then
        local current = string.lower(string.Trim(tostring(invDef.EquipSlot or "")))
        if current == "primary" or current == "secondary" or current == "utility" then
            return current
        end
    end

    local stored = className ~= "" and weapons.GetStored(className) or nil
    local slot = stored and tonumber(stored.Slot) or nil
    -- Source/GMod slot 1 normally represents pistols/secondary weapons.
    if slot == 1 then return "secondary" end
    return "primary"
end

local function ensureInventoryDefinition(sourceID, source, cfg, product, className)
    if not GRNInventory or not GRNInventory.Config or not istable(GRNInventory.Config.Items) then
        return nil, nil
    end

    cfg = istable(cfg) and cfg or {}
    product = istable(product) and product or nil
    className = tostring(className or cfg.ClassName or (product and product.className) or "")
    if className == "" then return nil, nil end

    local requestedID = tostring(cfg.InventoryItemID or "")
    local foundID, foundDef = inventoryDefinition(requestedID, className)
    if foundID and foundDef then return foundID, foundDef end

    local id = runtimeInventoryID(sourceID)
    local items = GRNInventory.Config.Items
    local old = istable(items[id]) and items[id] or nil
    local stored = weapons.GetStored(className)

    local name = tostring(cfg.Name or (product and product.name) or (old and old.Name) or className)
    local description = tostring(cfg.Description or (product and product.description) or (old and old.Description) or "Waffe aus der persönlichen Waffenkammer.")
    local iconURL = tostring(cfg.IconURL or (old and old.IconURL) or "")
    local icon = tostring(cfg.Icon or (old and old.Icon) or "fa-gun")
    local dropModel = tostring(cfg.PreviewModel or (product and product.previewModel) or (old and old.DropModel) or (stored and stored.WorldModel) or "models/weapons/w_pistol.mdl")
    local equipSlot = inferInventoryEquipSlot(className, cfg, old)

    local sizeW = tonumber(cfg.InventorySizeW) or (old and old.Size and tonumber(old.Size.W)) or (equipSlot == "secondary" and 1 or 2)
    local sizeH = tonumber(cfg.InventorySizeH) or (old and old.Size and tonumber(old.Size.H)) or 1

    items[id] = {
        Name = name,
        Description = description,
        Type = "weapon",
        EquipSlot = equipSlot,
        WeaponClass = className,
        Icon = icon,
        IconURL = iconURL,
        Rarity = normalizeInventoryRarity(cfg.InventoryRarity or (product and product.rarity) or (old and old.Rarity)),
        Weight = math.max(0, tonumber(cfg.InventoryWeight) or tonumber(old and old.Weight) or (equipSlot == "secondary" and 2.2 or 6.0)),
        Stack = 1,
        Size = {
            W = math.max(1, math.floor(sizeW or 1)),
            H = math.max(1, math.floor(sizeH or 1)),
        },
        DropModel = dropModel,
        GiveAmmoOnEquip = math.max(0, math.floor(tonumber(cfg.GiveAmmoOnEquip) or tonumber(old and old.GiveAmmoOnEquip) or 0)),
        AmmoType = tostring(cfg.AmmoType or (old and old.AmmoType) or ""),
        GRNStoreRuntime = true,
        GRNStoreProductID = tostring(sourceID or ""),
        GRNStoreSource = tostring(source or "store"),
    }

    return id, items[id]
end

local function inferStats(className, configured)
    local stats = istable(configured) and table.Copy(configured) or {}
    local stored = className and weapons.GetStored(className) or nil
    if not stored then return stats end

    local primary = istable(stored.Primary) and stored.Primary or {}
    local function first(...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            if v ~= nil and v ~= "" then return v end
        end
    end

    stats.Damage = first(stats.Damage, stored.Damage, stored.DamageMin, primary.Damage)
    stats.Range = first(stats.Range, stored.Range, stored.RangeMin)
    stats.RPM = first(stats.RPM, stored.RPM, primary.RPM)
    stats.Magazine = first(stats.Magazine, stored.Capacity, primary.ClipSize)
    stats.Accuracy = first(stats.Accuracy, stored.AccuracyMOA, stored.HipDispersion)
    stats.Recoil = first(stats.Recoil, stored.Recoil, stored.RecoilSide)
    stats.Aim = first(stats.Aim, stored.AimDownSightsTime, stored.SightTime)
    stats.Spread = first(stats.Spread, stored.Spread, primary.Spread)
    stats.MoveSpread = first(stats.MoveSpread, stored.MoveDispersion)

    if stats.RPM == nil and tonumber(primary.Delay) and tonumber(primary.Delay) > 0 then
        stats.RPM = math.floor(60 / tonumber(primary.Delay) + 0.5)
    end

    return stats
end

local function normalizeStats(stats)
    stats = istable(stats) and stats or {}
    local function s(v, suffix)
        if v == nil or v == "" then return "-" end
        if isnumber(v) and suffix then return tostring(math.Round(v, 2)) .. suffix end
        return tostring(v)
    end

    return {
        damage = s(stats.Damage),
        range = s(stats.Range),
        rpm = s(stats.RPM),
        magazine = s(stats.Magazine),
        accuracy = s(stats.Accuracy),
        recoil = s(stats.Recoil),
        aim = s(stats.Aim),
        spread = s(stats.Spread),
        moveSpread = s(stats.MoveSpread),
    }
end

local function makeWeaponData(sourceID, source, cfg, product)
    cfg = istable(cfg) and table.Copy(cfg) or {}
    product = istable(product) and product or nil

    local function pickString(...)
        for i = 1, select("#", ...) do
            local value = select(i, ...)
            if value ~= nil then
                value = tostring(value)
                if value ~= "" then return value end
            end
        end
        return ""
    end

    local className = pickString(cfg.ClassName, product and product.className)
    local override = weaponOverride(sourceID, className)
    mergeTable(cfg, override)

    if cfg.ClassName and cfg.ClassName ~= "" then className = tostring(cfg.ClassName) end
    if className == "" then return nil end

    local inventoryItemID = pickString(cfg.InventoryItemID)
    local resolvedItemID, invDef = inventoryDefinition(inventoryItemID, className)

    if istable(override) and tostring(override.InventoryItemID or "") ~= "" then
        resolvedItemID, invDef = inventoryDefinition(tostring(override.InventoryItemID), className)
    end

    if not resolvedItemID or not invDef then
        resolvedItemID, invDef = ensureInventoryDefinition(sourceID, source, cfg, product, className)
    end

    local name = pickString(cfg.Name, product and product.name, invDef and invDef.Name, className)
    local desc = pickString(cfg.Description, product and product.description, invDef and invDef.Description, "Freigegebene Waffe aus deiner persönlichen Waffenkammer.")
    local previewModel = pickString(cfg.PreviewModel, product and product.previewModel, invDef and invDef.DropModel)
    local iconURL = pickString(cfg.IconURL, invDef and invDef.IconURL)
    local icon = pickString(cfg.Icon, invDef and invDef.Icon, "fa-gun")
    local typeLabel = pickString(cfg.TypeLabel, "Waffe · Ausrüstung")

    local stats = inferStats(className, cfg.Stats)

    local previewAngle = nil
    if isangle(cfg.PreviewAngle) then
        previewAngle = { p = cfg.PreviewAngle.p, y = cfg.PreviewAngle.y, r = cfg.PreviewAngle.r }
    elseif istable(cfg.PreviewAngle) then
        previewAngle = {
            p = tonumber(cfg.PreviewAngle.p or cfg.PreviewAngle.pitch or cfg.PreviewAngle[1]) or 0,
            y = tonumber(cfg.PreviewAngle.y or cfg.PreviewAngle.yaw or cfg.PreviewAngle[2]) or 0,
            r = tonumber(cfg.PreviewAngle.r or cfg.PreviewAngle.roll or cfg.PreviewAngle[3]) or 0,
        }
    end

    return {
        id = tostring(sourceID),
        source = tostring(source),
        sourceLabel = source == "base" and "BASIS" or (source == "job" and "JOB" or "GEKAUFT"),
        inventoryItemID = tostring(resolvedItemID or ""),
        name = name,
        typeLabel = typeLabel,
        description = desc,
        className = className,
        iconURL = iconURL,
        icon = icon,
        previewModel = previewModel,
        fov = tonumber(cfg.FOV) or tonumber(A.Preview and A.Preview.FOV) or 34,
        previewAngle = previewAngle,
        previewScale = tonumber(cfg.PreviewScale) or 1,
        stats = normalizeStats(stats),
    }
end


local function registerOwnedProductDefinition(productID, product)
    if not istable(product) or tostring(product.type or "") ~= "weapon" then return end
    productID = tostring(productID or product.id or "")
    local className = tostring(product.className or "")
    if productID == "" or className == "" then return end

    local cfg = weaponOverride(productID, className)
    cfg.ClassName = cfg.ClassName or className
    ensureInventoryDefinition(productID, "store", cfg, product, tostring(cfg.ClassName or className))
end

-- Register stable inventory definitions before players are loaded. This is
-- important because grn_inventory validates saved item IDs while loading a
-- player; without pre-registration, a custom store weapon could disappear
-- after a server restart.
function S.RefreshArmoryInventoryDefinitions()
    if not GRNInventory or not GRNInventory.Config or not istable(GRNInventory.Config.Items) then return end

    for index, base in ipairs(A.BaseWeapons or {}) do
        if istable(base) then
            local sourceID = tostring(base.ID or ("base_" .. index))
            local cfg = table.Copy(base)
            local className = tostring(cfg.FallbackClassName or cfg.ClassName or "")
            local requestedID = tostring(cfg.InventoryItemID or "")
            local _, invDef = inventoryDefinition(requestedID, className)
            if invDef then
                className = tostring(invDef.WeaponClass or className)
            end
            if className ~= "" then
                ensureInventoryDefinition(sourceID, "base", cfg, nil, className)
            end
        end
    end

    for _, product in ipairs((S.Data and S.Data.products) or {}) do
        registerOwnedProductDefinition(tostring(product and product.id or ""), product)
    end

    -- Keep owned snapshots usable even if a staff member later removes the
    -- product from store.json. Permanent ownership remains valid in inventory.json.
    for _, record in pairs(S.PlayerData or {}) do
        if istable(record) and istable(record.items) then
            for productID, owned in pairs(record.items) do
                local product = istable(owned) and istable(owned.snapshot) and owned.snapshot or nil
                if product then
                    registerOwnedProductDefinition(tostring(productID), product)
                end
            end
        end
    end
end

S.RefreshArmoryInventoryDefinitions()
hook.Add("Initialize", "GRNStoreArmory_RegisterInventoryItems", function()
    if GRNStore and isfunction(GRNStore.RefreshArmoryInventoryDefinitions) then
        GRNStore.RefreshArmoryInventoryDefinitions()
    end
end)

hook.Add("GRNStoreProductPurchased", "GRNStoreArmory_RegisterPurchasedInventoryItem", function(_, product)
    if not istable(product) or tostring(product.type or "") ~= "weapon" then return end
    registerOwnedProductDefinition(tostring(product.id or ""), product)
end)

function S.GetCurrentJobLoadout(ply)
    local jobCfg = A.JobLoadouts
    if not istable(jobCfg) or jobCfg.Enabled == false or not IsValid(ply) then return nil, "" end

    local function normalizeJobKey(value)
        value = string.lower(string.Trim(tostring(value or "")))
        value = string.gsub(value, "á", "a")
        value = string.gsub(value, "é", "e")
        value = string.gsub(value, "í", "i")
        value = string.gsub(value, "ó", "o")
        value = string.gsub(value, "ú", "u")
        value = string.gsub(value, "ü", "u")
        value = string.gsub(value, "ñ", "n")
        value = string.gsub(value, "[^%w]+", "")
        return value
    end

    local teamID = ply:Team()
    local jobData = RPExtraTeams and RPExtraTeams[teamID] or nil
    local command = istable(jobData) and tostring(jobData.command or "") or ""
    local jobName = istable(jobData) and tostring(jobData.name or "") or ""
    if jobName == "" then jobName = tostring(team.GetName(teamID) or "") end

    local byCommand = jobCfg.ByCommand or {}
    local loadout = byCommand[command]

    -- 1) Command sin importar mayúsculas, espacios o signos.
    if not istable(loadout) then
        local wanted = normalizeJobKey(command)
        if wanted ~= "" then
            loadout = (jobCfg.ByNormalizedCommand or {})[wanted]
        end
    end

    -- 2) Name visible del job. Esto cubre configuraciones donde DarkRP u
    -- otro addon altera/reemplaza el campo command después de crear el job.
    if not istable(loadout) then
        local wantedName = normalizeJobKey(jobName)
        if wantedName ~= "" then
            loadout = (jobCfg.ByName or {})[wantedName]
        end
    end

    -- 3) Model configurado en el job/current player como último fallback.
    if not istable(loadout) then
        local models = {}
        if istable(jobData) then
            if isstring(jobData.model) then
                models[#models + 1] = jobData.model
            elseif istable(jobData.model) then
                for _, mdl in ipairs(jobData.model) do
                    if isstring(mdl) then models[#models + 1] = mdl end
                end
            end
        end
        if IsValid(ply) and isstring(ply:GetModel()) then
            models[#models + 1] = ply:GetModel()
        end

        local byModel = jobCfg.ByModel or {}
        for _, mdl in ipairs(models) do
            local key = string.lower(string.Trim(tostring(mdl or "")))
            if key ~= "" and istable(byModel[key]) then
                loadout = byModel[key]
                break
            end
        end
    end

    return istable(loadout) and loadout or nil, command, jobName
end

local function makeJobEquipmentData(itemID)
    itemID = tostring(itemID or "")
    if itemID == "" or not GRNInventory then return nil end

    local function getDefinition(id)
        if isfunction(GRNInventory.GetItemDefinition) then
            local def = GRNInventory.GetItemDefinition(id)
            if istable(def) then return def end
        end
        local items = GRNInventory.Config and GRNInventory.Config.Items or nil
        return istable(items) and istable(items[id]) and items[id] or nil
    end

    local def = getDefinition(itemID)
    if not istable(def) then
        ErrorNoHalt("[GRN Store] Job item is not registered in grn_inventory: " .. itemID .. "\n")
        return nil
    end

    -- Armor pieces can be part of a job loadout as well.
    if def.Type == "armor" then
        local slotInfo = GRNInventory.ArmorSlotByID and GRNInventory.ArmorSlotByID[tostring(def.Slot or "")] or nil
        local rows = {
            { label = "Slot", value = slotInfo and tostring(slotInfo.Label) or tostring(def.Slot or "-"), accent = true },
            { label = "Rüstung", value = "+" .. tostring(tonumber(def.Armor) or 0) },
            { label = "Gesundheit", value = "+" .. tostring(tonumber(def.Health) or 0) },
            { label = "Schadensreduktion", value = tostring(math.Round((tonumber(def.DamageReduction) or 0) * 100, 1)) .. " %" },
            { label = "Tragkraft", value = "+" .. tostring(tonumber(def.CarryWeight) or 0) .. " KG" },
            { label = "Gewicht", value = tostring(tonumber(def.Weight) or 0) .. " KG" },
        }
        return {
            id = "job_" .. itemID,
            source = "job",
            sourceLabel = "RÜSTUNG",
            inventoryItemID = itemID,
            jobItemID = itemID,
            name = tostring(def.Name or itemID),
            typeLabel = "Rüstung · " .. (slotInfo and tostring(slotInfo.Label) or "Ausrüstung"),
            description = tostring(def.Description or ""),
            className = "armor:" .. itemID,
            iconURL = tostring(def.IconURL or ""),
            icon = tostring(def.Icon or "fa-shield-halved"),
            previewModel = tostring(def.Model or ""),
            fov = 30,
            previewScale = 1,
            stats = normalizeStats({}),
            statRows = rows,
            isArmor = true,
        }
    end

    local className = tostring(def.WeaponClass or "")
    if className == "" and isfunction(GRNInventory.ResolveJobEquipmentWeaponClasses) then
        GRNInventory.ResolveJobEquipmentWeaponClasses()
        def = getDefinition(itemID)
        className = istable(def) and tostring(def.WeaponClass or "") or ""
    end

    -- Solo se omite un item si realmente no hay ninguna clase que entregar.
    -- El resto del loadout sigue mostrándose aunque el SWEP todavía no haya
    -- terminado de registrarse en weapons.GetStored().
    if className == "" then
        ErrorNoHalt("[GRN Store] Item de job sin WeaponClass: " .. itemID .. "\n")
        return nil
    end

    local stored = weapons.GetStored(className)
    local data = makeWeaponData("job_" .. itemID, "job", {
        InventoryItemID = itemID,
        ClassName = className,
        Name = def.Name,
        Description = def.Description,
        Icon = def.Icon,
        IconURL = def.IconURL,
        PreviewModel = (stored and stored.WorldModel) or def.DropModel or "",
        TypeLabel = "JOB-AUSRÜSTUNG",
    }, nil)

    if data then
        data.jobItemID = itemID
        data.sourceLabel = "JOB"
    end
    return data
end

function S.BuildArmoryWeapons(ply)
    local out = {}
    local seenClass = {}
    local jobLoadout = S.GetCurrentJobLoadout(ply)

    local function append(data)
        if not istable(data) then return end
        local key = string.lower(tostring(data.className or ""))
        if key == "" or seenClass[key] then return end
        seenClass[key] = true
        out[#out + 1] = data
    end

    if jobLoadout then
        for _, itemID in ipairs(jobLoadout.Items or {}) do
            append(makeJobEquipmentData(itemID))
        end

        local jobCfg = A.JobLoadouts or {}
        if jobCfg.ExclusiveWhenMatched ~= false then
            return out
        end
    end

    local showBase = jobLoadout ~= nil or not istable(A.JobLoadouts) or A.JobLoadouts.ShowBaseWeaponsWithoutLoadout ~= false

    for index, base in ipairs(showBase and A.BaseWeapons or {}) do
        if istable(base) then
            local id = tostring(base.ID or ("base_" .. index))
            local itemID = tostring(base.InventoryItemID or "")
            local fallbackClass = tostring(base.FallbackClassName or base.ClassName or "")
            local _, invDef = inventoryDefinition(itemID, fallbackClass)
            local baseCfg = table.Copy(base)

            if invDef then
                baseCfg.Name = baseCfg.Name or invDef.Name
                baseCfg.Description = baseCfg.Description or invDef.Description
                baseCfg.ClassName = tostring(invDef.WeaponClass or fallbackClass)
                baseCfg.IconURL = baseCfg.IconURL or invDef.IconURL
                baseCfg.Icon = baseCfg.Icon or invDef.Icon
                baseCfg.PreviewModel = baseCfg.PreviewModel or invDef.DropModel
            else
                baseCfg.ClassName = fallbackClass
            end

            append(makeWeaponData(id, "base", baseCfg, nil))
        end
    end

    if isfunction(S.GetOwnedWeaponProducts) then
        for _, product in ipairs(S.GetOwnedWeaponProducts(ply)) do
            local productID = tostring(product.id or "")
            local override = weaponOverride(productID, tostring(product.className or ""))
            local cfg = {
                InventoryItemID = override.InventoryItemID,
                IconURL = override.IconURL,
                Icon = override.Icon,
                PreviewModel = override.PreviewModel,
                TypeLabel = override.TypeLabel,
                FOV = override.FOV,
                PreviewAngle = override.PreviewAngle,
                PreviewScale = override.PreviewScale,
                Stats = override.Stats,
                Name = override.Name,
                Description = override.Description,
                ClassName = override.ClassName or product.className,
            }

            append(makeWeaponData(productID, "store", cfg, product))
        end
    end

    return out
end

local function allConfiguredJobItemIDs()
    local out = {}
    local jobCfg = A.JobLoadouts or {}
    for _, loadout in pairs(jobCfg.ByCommand or {}) do
        if istable(loadout) then
            for _, itemID in ipairs(loadout.Items or {}) do
                itemID = tostring(itemID or "")
                if itemID ~= "" then out[itemID] = true end
            end
        end
    end
    return out
end

function S.CleanupUnauthorizedJobEquipment(ply)
    local jobCfg = A.JobLoadouts
    if not istable(jobCfg) or jobCfg.Enabled == false or jobCfg.RemoveUnauthorizedOnJobChange == false then return 0 end
    if not IsValid(ply) or not GRNInventory or not isfunction(GRNInventory.RemoveItem) or not isfunction(GRNInventory.HasItem) then return 0 end
    if isfunction(GRNInventory.GetState) and not GRNInventory.GetState(ply) then return 0 end

    local allowed = {}
    local loadout = S.GetCurrentJobLoadout(ply)
    if loadout then
        for _, itemID in ipairs(loadout.Items or {}) do
            allowed[tostring(itemID or "")] = true
        end
    end

    local removed = 0
    for itemID in pairs(allConfiguredJobItemIDs()) do
        if not allowed[itemID] and GRNInventory.HasItem(ply, itemID, 1) then
            removed = removed + (tonumber(GRNInventory.RemoveItem(ply, itemID, 999)) or 0)
        end
    end

    if removed > 0 and isfunction(GRNInventory.Sync) then
        GRNInventory.Sync(ply)
    end
    return removed
end

local function loadSets(ply)
    local maxSets = math.max(1, math.floor(tonumber(A.MaxSets) or 4))
    local raw = ply:GetPData(A.SetsPDataKey or "grn_armory_sets_v1", "")
    local decoded = raw ~= "" and util.JSONToTable(raw) or nil
    local sets = {}

    for i = 1, maxSets do
        sets[i] = {}
        local src = istable(decoded) and istable(decoded[i]) and decoded[i] or {}
        local seen = {}
        for _, weaponID in ipairs(src) do
            weaponID = tostring(weaponID or "")
            if weaponID ~= "" and not seen[weaponID] then
                seen[weaponID] = true
                sets[i][#sets[i] + 1] = weaponID
            end
        end
    end

    return sets
end

local function saveSets(ply, sets)
    ply:SetPData(A.SetsPDataKey or "grn_armory_sets_v1", util.TableToJSON(sets, false) or "[]")
end

local function weaponMap(ply)
    local map = {}
    local list = S.BuildArmoryWeapons(ply)
    for _, data in ipairs(list) do
        map[data.id] = data
    end
    return map, list
end

local function buildPayload(ply)
    local _, list = weaponMap(ply)
    local sets = loadSets(ply)
    local health = IsValid(ply) and math.max(0, ply:Health()) or 0
    local armor = IsValid(ply) and math.max(0, ply:Armor()) or 0
    local loadout, command, jobName = S.GetCurrentJobLoadout(ply)

    -- Mark what the player already carries, and give every entry a list of
    -- specification rows for the terminal.
    local statLabels = {
        { "damage", "Schaden", true }, { "range", "Reichweite" }, { "rpm", "Feuerrate" }, { "magazine", "Magazin" },
        { "accuracy", "Präzision" }, { "recoil", "Rückstoß" }, { "aim", "Zielzeit" }, { "spread", "Streuung" },
        { "moveSpread", "Streuung in Bewegung" },
    }
    for _, data in ipairs(list) do
        local itemID = tostring(data.inventoryItemID or "")
        data.inInventory = itemID ~= "" and GRNInventory and isfunction(GRNInventory.HasItem) and GRNInventory.HasItem(ply, itemID, 1) or false
        if not istable(data.statRows) then
            local rows = {}
            local st = istable(data.stats) and data.stats or {}
            for _, entry in ipairs(statLabels) do
                rows[#rows + 1] = { label = entry[2], value = tostring(st[entry[1]] or "-"), accent = entry[3] == true }
            end
            data.statRows = rows
        end
    end

    return {
        armoryName = tostring(A.Name or "Persönliche Waffenkammer"),
        serverName = GetHostName() or "ECHOES OF CLONES",
        weapons = list,
        sets = sets,
        jobLoadout = loadout and {
            active = true,
            name = tostring(loadout.Name or team.GetName(ply:Team()) or "JOB-AUSRÜSTUNG"),
            command = tostring(command or ""),
            jobName = tostring(jobName or ""),
            count = #(loadout.Items or {}),
        } or { active = false },
        health = health,
        armor = armor,
        date = os.date("%d / %m / %Y"),
    }
end

local function writeCompressedTable(tbl)
    local json = util.TableToJSON(tbl, false) or "{}"
    local compressed = util.Compress(json) or ""
    net.WriteUInt(#compressed, 32)
    if #compressed > 0 then net.WriteData(compressed, #compressed) end
end

function S.SendArmoryState(ply, shouldOpen)
    if not IsValid(ply) then return end

    local vendor = IsValid(ply.GRNArmoryVendor) and ply.GRNArmoryVendor or NULL

    -- En V4 la apertura y el estado viajan por mensajes distintos. De esta
    -- forma el cliente crea primero el DHTML y luego solicita/recibe los datos.
    -- También evita colisiones con versiones viejas de grn_store que usaban
    -- exactamente el mismo nombre de net.Receive.
    if shouldOpen == true then
        net.Start("grn_armory_v4_open")
            net.WriteEntity(vendor)
        net.Send(ply)
    end

    net.Start("grn_armory_v4_state")
        net.WriteEntity(vendor)
        writeCompressedTable(buildPayload(ply))
    net.Send(ply)
end

function S.OpenArmoryForPlayer(ply, vendor)
    if not A.Enabled then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if not IsValid(vendor) or vendor:GetClass() ~= tostring(A.Entity.Class or "grn_armory_terminal") then return end

    local useDistance = tonumber(A.Entity.UseDistance) or 180
    if ply:GetPos():DistToSqr(vendor:GetPos()) > useDistance * useDistance then return end

    -- The armory is a separate terminal. If the inventory backpack animation
    -- was still active, stop only that temporary viewmodel so it cannot sit in
    -- front of the armory. The backpack configuration/animation itself remains
    -- exactly the original inventory implementation.
    if GRNInventory and isfunction(GRNInventory.StopBackpackAnimation) then
        GRNInventory.StopBackpackAnimation(ply, true)
    end
    ply.GRNInventoryOpen = false

    ply.GRNArmoryVendor = vendor
    ply.GRNArmoryOpenAt = CurTime()
    S.CleanupUnauthorizedJobEquipment(ply)
    S.SendArmoryState(ply, true)
end

local function canUseArmory(ply)
    if not A.Enabled or not IsValid(ply) or not ply:Alive() then return false end
    local vendor = ply.GRNArmoryVendor
    if not IsValid(vendor) or vendor:GetClass() ~= tostring(A.Entity.Class or "grn_armory_terminal") then return false end
    local maxDistance = tonumber(A.Entity.MenuMaxDistance) or 450
    return ply:GetPos():DistToSqr(vendor:GetPos()) <= maxDistance * maxDistance
end

local function issueWeapon(ply, weaponData)
    if not IsValid(ply) or not istable(weaponData) then return false, "Ungültige Waffe.", false end
    if not GRNInventory or not isfunction(GRNInventory.AddItem) or not isfunction(GRNInventory.HasItem) then
        return false, "Das Inventar ist nicht verfügbar; die Waffe kann nicht ausgegeben werden.", false
    end

    local className = tostring(weaponData.className or "")
    if className == "" then return false, "Für diese Waffe ist keine SWEP-Klasse konfiguriert.", false end

    local itemID = tostring(weaponData.inventoryItemID or "")
    local def = itemID ~= "" and GRNInventory.GetItemDefinition and GRNInventory.GetItemDefinition(itemID) or nil
    if itemID == "" or not istable(def) then
        -- Last-resort runtime registration for weapons created/edited while the
        -- server is running and before the next refresh.
        local cfg = weaponOverride(tostring(weaponData.id or ""), className)
        cfg.ClassName = className
        cfg.Name = weaponData.name
        cfg.Description = weaponData.description
        cfg.IconURL = weaponData.iconURL
        cfg.Icon = weaponData.icon
        cfg.PreviewModel = weaponData.previewModel
        itemID, def = ensureInventoryDefinition(tostring(weaponData.id or className), tostring(weaponData.source or "store"), cfg, nil, className)
        weaponData.inventoryItemID = tostring(itemID or "")
    end

    if itemID == "" or not istable(def) then
        return false, "Inventar-Gegenstand für " .. tostring(weaponData.name or className) .. " konnte nicht erstellt werden.", false
    end

    if GRNInventory.HasItem(ply, itemID, 1) then
        return true, tostring(weaponData.name or className) .. " ist bereits in deinem Inventar.", false
    end

    local added, reason = GRNInventory.AddItem(ply, itemID, 1)
    if tonumber(added) ~= 1 then
        return false, tostring(reason or "Nicht genug Platz im Inventar."), false
    end

    ply.GRNArmoryIssuedItems = ply.GRNArmoryIssuedItems or {}
    ply.GRNArmoryIssuedItems[itemID] = (tonumber(ply.GRNArmoryIssuedItems[itemID]) or 0) + 1

    if isfunction(GRNInventory.Sync) then GRNInventory.Sync(ply) end
    return true, tostring(weaponData.name or className) .. " ins Inventar gelegt.", true
end

function S.MarkArmoryItemStored(ply, itemID, quantity)
    if not IsValid(ply) then return end
    itemID = tostring(itemID or "")
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if itemID == "" then return end

    ply.GRNArmoryIssuedItems = ply.GRNArmoryIssuedItems or {}
    local remaining = math.max(0, (tonumber(ply.GRNArmoryIssuedItems[itemID]) or 0) - quantity)
    if remaining > 0 then
        ply.GRNArmoryIssuedItems[itemID] = remaining
    else
        ply.GRNArmoryIssuedItems[itemID] = nil
    end
end

local function returnIssuedWeapons(ply)
    local issued = ply.GRNArmoryIssuedItems or {}
    local count = 0

    if GRNInventory and isfunction(GRNInventory.RemoveItem) then
        for itemID, quantity in pairs(issued) do
            itemID = tostring(itemID or "")
            quantity = math.max(0, math.floor(tonumber(quantity) or 0))
            if itemID ~= "" and quantity > 0 then
                count = count + math.max(0, tonumber(GRNInventory.RemoveItem(ply, itemID, quantity)) or 0)
            end
        end
        if isfunction(GRNInventory.Sync) then GRNInventory.Sync(ply) end
    end

    ply.GRNArmoryIssuedItems = {}
    return count
end

net.Receive("grn_armory_v4_request", function(_, ply)
    if not rateLimit(ply, "request_v4", 0.10) then return end
    if not canUseArmory(ply) then return end
    S.SendArmoryState(ply, false)
end)

local function handleArmoryAction(ply, action, weaponID, setIndex)
    if not canUseArmory(ply) then return end

    action = tostring(action or "")
    weaponID = tostring(weaponID or "")
    setIndex = math.Clamp(math.floor(tonumber(setIndex) or 1), 1, math.max(1, tonumber(A.MaxSets) or 4))
    local map, list = weaponMap(ply)

    if action == "take_weapon" then
        local data = map[weaponID]
        if not data then
            armoryNotify(ply, "Diese Waffe ist in deiner Waffenkammer nicht mehr verfügbar.")
            S.SendArmoryState(ply, false)
            return
        end

        local ok, msg = issueWeapon(ply, data)
        armoryNotify(ply, msg)
        S.SendArmoryState(ply, false)
        if not ok then return end

    elseif action == "take_job_loadout" or action == "take_all" then
        armoryNotify(ply, "Nimm die Ausrüstung einzeln aus der Waffenkammer.")

    elseif action == "return_all" then
        local count = returnIssuedWeapons(ply)
        armoryNotify(ply, count > 0 and (count .. " Gegenstand/Gegenstände in die Waffenkammer zurückgegeben.") or "Du hast keine Gegenstände aus dieser Waffenkammer.")
        S.SendArmoryState(ply, false)

    elseif action == "add_to_set" then
        if not map[weaponID] then
            armoryNotify(ply, "Wähle zuerst eine gültige Waffe aus.")
            return
        end

        local sets = loadSets(ply)
        local set = sets[setIndex] or {}
        sets[setIndex] = set
        local found
        for i, id in ipairs(set) do
            if id == weaponID then found = i break end
        end

        if found then
            table.remove(set, found)
            armoryNotify(ply, "Waffe aus Set " .. setIndex .. " entfernt.")
        else
            local maxWeapons = math.max(1, math.floor(tonumber(A.MaxWeaponsPerSet) or 8))
            if #set >= maxWeapons then
                armoryNotify(ply, "Set " .. setIndex .. " hat das Waffenlimit erreicht.")
                return
            end
            set[#set + 1] = weaponID
            armoryNotify(ply, "Waffe zu Set " .. setIndex .. " hinzugefügt.")
        end

        saveSets(ply, sets)
        S.SendArmoryState(ply, false)
        return
    end
end

net.Receive("grn_armory_v4_action", function(_, ply)
    if not rateLimit(ply, "action_v4", 0.16) then return end
    local action = tostring(net.ReadString() or "")
    local weaponID = tostring(net.ReadString() or "")
    local setIndex = net.ReadUInt(8)
    handleArmoryAction(ply, action, weaponID, setIndex)
end)

-- Compatibilidad: si queda alguna interfaz V3 abierta durante un hot-reload,
-- sigue pudiendo ejecutar acciones. La apertura normal V4 no usa este canal.
net.Receive("grn_armory_action", function(_, ply)
    if not rateLimit(ply, "action_legacy", 0.16) then return end
    local action = tostring(net.ReadString() or "")
    local weaponID = tostring(net.ReadString() or "")
    local setIndex = net.ReadUInt(8)
    handleArmoryAction(ply, action, weaponID, setIndex)
end)

local function closeArmorySession(ply)
    if not IsValid(ply) then return end
    ply.GRNArmoryVendor = nil
    ply.GRNArmoryOpenAt = nil
end

net.Receive("grn_armory_v4_close", function(_, ply)
    closeArmorySession(ply)
end)

net.Receive("grn_armory_close", function(_, ply)
    closeArmorySession(ply)
end)

hook.Add("OnPlayerChangedTeam", "GRNStoreArmory_RefreshJobLoadout", function(ply)
    timer.Simple(0.15, function()
        if not IsValid(ply) then return end
        S.CleanupUnauthorizedJobEquipment(ply)
        if IsValid(ply.GRNArmoryVendor) then
            S.SendArmoryState(ply, false)
        end
    end)
end)

hook.Add("PlayerInitialSpawn", "GRNStoreArmory_CleanupPersistedJobEquipment", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then S.CleanupUnauthorizedJobEquipment(ply) end
    end)
end)

hook.Add("PlayerDisconnected", "GRNStoreArmory_ClearSession", function(ply)
    if not IsValid(ply) then return end
    local sid = ply:SteamID64() or tostring(ply:EntIndex())
    S.ArmoryRate[sid] = nil
    ply.GRNArmoryIssuedItems = nil
end)

concommand.Add("grn_armory_debug_job", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local targets = {}
    if IsValid(ply) then
        targets[1] = ply
    else
        targets = player.GetAll()
    end

    print("========== GRN ARMORY JOB DEBUG ==========")
    for _, target in ipairs(targets) do
        if IsValid(target) then
            local teamID = target:Team()
            local job = RPExtraTeams and RPExtraTeams[teamID] or nil
            local loadout, command, jobName = S.GetCurrentJobLoadout(target)
            local weaponsList = S.BuildArmoryWeapons(target)
            print("Player:", target:Nick(), "team:", teamID, "teamName:", team.GetName(teamID))
            print("command:", command, "jobName:", jobName, "model:", target:GetModel())
            print("RPExtraTeams job:", istable(job) and "OK" or "NIL")
            print("loadout:", loadout and tostring(loadout.Name) or "NO MATCH", "items config:", loadout and #(loadout.Items or {}) or 0, "items visibles:", #weaponsList)
        end
    end
    print("==========================================")
end)

concommand.Add("grn_armory_spawn", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    if not A.Enabled then return end

    local pos = Vector(0, 0, 0)
    local ang = Angle(0, 0, 0)

    if IsValid(ply) then
        local tr = ply:GetEyeTrace()
        pos = tr.HitPos + tr.HitNormal * 2
        ang = Angle(0, ply:EyeAngles().y + 180, 0)
    end

    local ent = ents.Create(tostring(A.Entity.Class or "grn_armory_terminal"))
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
end)

-- Used by grn_inventory: items listed in any job loadout (e.g. armor pieces)
-- behave like armory equipment (cannot be dropped, can be returned).
function S.IsJobLoadoutItem(itemID)
    if not S._JobItemCache then S._JobItemCache = allConfiguredJobItemIDs() end
    return S._JobItemCache[tostring(itemID or "")] == true
end
