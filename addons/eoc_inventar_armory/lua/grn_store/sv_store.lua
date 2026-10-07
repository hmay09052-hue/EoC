GRNStore = GRNStore or {}
local S = GRNStore
local C = S.Config

util.AddNetworkString("grn_store_state")
util.AddNetworkString("grn_store_buy")
util.AddNetworkString("grn_store_use_item")
util.AddNetworkString("grn_store_close")
util.AddNetworkString("grn_store_staff_category_save")
util.AddNetworkString("grn_store_staff_category_delete")
util.AddNetworkString("grn_store_staff_product_save")
util.AddNetworkString("grn_store_staff_product_delete")
util.AddNetworkString("grn_store_notify")
util.AddNetworkString("grn_store_staff_ack")

local STORE_DIR = "grn_store"
local STORE_FILE = STORE_DIR .. "/store.json"
local INVENTORY_FILE = STORE_DIR .. "/inventory.json"

S.Data = S.Data or { categories = {}, products = {} }
S.PlayerData = S.PlayerData or {}
S.Rate = S.Rate or {}

file.CreateDir(STORE_DIR)

local function isBaseCategory(id)
    for _, cat in ipairs(C.DefaultCategories or {}) do
        if cat.id == id then return true end
    end
    return false
end

local function findCategory(id)
    for index, cat in ipairs(S.Data.categories or {}) do
        if cat.id == id then return cat, index end
    end
end

local function findProduct(id)
    for index, product in ipairs(S.Data.products or {}) do
        if product.id == id then return product, index end
    end
end

local function saveStore()
    file.Write(STORE_FILE, util.TableToJSON(S.Data, true) or "{}")
end

local function saveInventory()
    file.Write(INVENTORY_FILE, util.TableToJSON(S.PlayerData, true) or "{}")
end

local function loadStore()
    local loaded
    if file.Exists(STORE_FILE, "DATA") then
        loaded = util.JSONToTable(file.Read(STORE_FILE, "DATA") or "")
    end

    if not istable(loaded) then
        loaded = {
            categories = table.Copy(C.DefaultCategories or {}),
            products = table.Copy(C.DefaultProducts or {}),
        }
    end

    loaded.categories = istable(loaded.categories) and loaded.categories or {}
    loaded.products = istable(loaded.products) and loaded.products or {}

    -- Remove legacy/unused store content from existing installations too.
    -- This is intentionally performed before restoring the active base categories.
    local removedCategoryIDs = C.RemovedCategoryIDs or {}
    local removedCategoryNames = C.RemovedCategoryNames or {}
    local removedProductIDs = C.RemovedProductIDs or {}
    local removedProductNames = C.RemovedProductNames or {}

    local function normalized(value)
        return string.Trim(string.lower(tostring(value or "")))
    end

    for i = #loaded.categories, 1, -1 do
        local cat = loaded.categories[i]
        local id = normalized(cat and cat.id)
        local name = normalized(cat and cat.name)
        if removedCategoryIDs[id] or removedCategoryNames[name] then
            table.remove(loaded.categories, i)
        end
    end

    for i = #loaded.products, 1, -1 do
        local product = loaded.products[i]
        local id = normalized(product and product.id)
        local name = normalized(product and product.name)
        local category = normalized(product and product.category)
        local productType = normalized(product and product.type)

        -- Weapon products are no longer sold through the store. Job weapons remain
        -- available through the separate Personal Armory/loadout system.
        if removedProductIDs[id]
            or removedProductNames[name]
            or removedCategoryIDs[category]
            or productType == "weapon"
            or productType == "vehicle"
            or productType == "entity"
            or productType == "pet"
            or productType == "rank" then
            table.remove(loaded.products, i)
        end
    end

    -- Si faltan categorias base, se restauran para evitar referencias rotas.
    for _, baseCat in ipairs(C.DefaultCategories or {}) do
        local exists = false
        for _, cat in ipairs(loaded.categories) do
            if cat.id == baseCat.id then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(loaded.categories, table.Copy(baseCat))
        end
    end


    -- Registra/migra productos requeridos por otras integraciones.
    -- Esto permite actualizar el addon sin borrar store.json.
    for _, required in ipairs(C.RequiredProducts or {}) do
        local existing = nil

        for _, product in ipairs(loaded.products) do
            if product.id == required.id then
                existing = product
                break
            end
        end

        if not existing then
            local copy = table.Copy(required)
            copy.forceFields = nil
            table.insert(loaded.products, copy)
        else
            for _, fieldName in ipairs(required.forceFields or {}) do
                existing[fieldName] = required[fieldName]
            end
        end
    end

    S.Data = loaded
    saveStore()
end

local function loadInventory()
    if not file.Exists(INVENTORY_FILE, "DATA") then
        S.PlayerData = {}
        return
    end

    local loaded = util.JSONToTable(file.Read(INVENTORY_FILE, "DATA") or "")
    S.PlayerData = istable(loaded) and loaded or {}
end

loadStore()
loadInventory()

function S.IsStaff(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if C.SuperAdminAlwaysStaff and ply:IsSuperAdmin() then return true end
    local group = string.lower(tostring(ply:GetUserGroup() or ""))
    return C.StaffGroups[group] == true
end

local function rateLimit(ply, key, delay)
    if not IsValid(ply) then return false end
    local sid = ply:SteamID64() or tostring(ply:EntIndex())
    S.Rate[sid] = S.Rate[sid] or {}
    local now = CurTime()
    if (S.Rate[sid][key] or 0) > now then return false end
    S.Rate[sid][key] = now + (delay or 0.25)
    return true
end

function S.GetMoney(ply)
    if not IsValid(ply) then return 0 end

    if C.Economy.UseDarkRP and isfunction(ply.getDarkRPVar) then
        local value = tonumber(ply:getDarkRPVar("money"))
        if value then return value end
    end

    if C.Economy.AllowFallbackNWInt then
        return ply:GetNWInt(C.Economy.FallbackNWInt, 0)
    end

    return 0
end

function S.TakeMoney(ply, amount)
    amount = math.max(0, math.floor(tonumber(amount) or 0))
    if amount <= 0 then return true end

    if S.GetMoney(ply) < amount then return false end

    if C.Economy.UseDarkRP and isfunction(ply.addMoney) and isfunction(ply.getDarkRPVar) then
        ply:addMoney(-amount)
        return true
    end

    if C.Economy.AllowFallbackNWInt then
        ply:SetNWInt(C.Economy.FallbackNWInt, math.max(0, S.GetMoney(ply) - amount))
        return true
    end

    return false
end

local function playerRecord(ply)
    local sid = ply:SteamID64()
    if not sid or sid == "0" then return nil end

    S.PlayerData[sid] = S.PlayerData[sid] or {
        items = {},
        equippedModel = "",
    }

    S.PlayerData[sid].items = istable(S.PlayerData[sid].items) and S.PlayerData[sid].items or {}
    return S.PlayerData[sid]
end

local function snapshotProduct(product)
    return {
        id = product.id,
        name = product.name,
        category = product.category,
        type = product.type,
        price = product.price,
        className = product.className,
        previewModel = product.previewModel,
        spawnModel = product.spawnModel,
        rarity = product.rarity,
        purchaseType = product.purchaseType,
        duration = product.duration,
        description = product.description,
    }
end

local function cleanupExpired(ply)
    local record = playerRecord(ply)
    if not record then return false end

    local changed = false
    local now = os.time()

    for productID, owned in pairs(record.items) do
        if istable(owned) and (tonumber(owned.expires) or 0) > 0 and tonumber(owned.expires) <= now then
            record.items[productID] = nil
            if record.equippedModel == productID then record.equippedModel = "" end
            changed = true
        end
    end

    if changed then saveInventory() end
    return changed
end

local function ownershipEntry(ply, productID)
    cleanupExpired(ply)
    local record = playerRecord(ply)
    return record and record.items[productID] or nil
end

local function hasOwnership(ply, productID)
    return ownershipEntry(ply, productID) ~= nil
end


-- API publica para integraciones externas.
-- Ejemplo: GRNStore.PlayerOwnsProduct(ply, "vision_nocturna")
function S.PlayerOwnsProduct(ply, productID)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    return hasOwnership(ply, S.Slug(productID)) == true
end

local function productForOwned(productID, owned)
    local current = findProduct(productID)
    if current then return current end
    if istable(owned) and istable(owned.snapshot) then return owned.snapshot end
    return nil
end

-- Public read-only API used by the Personal Armory. Ownership remains stored
-- only in data/grn_store/inventory.json, so there is no duplicated database.
function S.GetProduct(productID)
    local product = findProduct(S.Slug(productID))
    return product and table.Copy(product) or nil
end

function S.GetOwnedWeaponProducts(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return {} end

    cleanupExpired(ply)
    local record = playerRecord(ply)
    if not record then return {} end

    local out = {}
    for productID, owned in pairs(record.items or {}) do
        local product = productForOwned(productID, owned)
        if product and tostring(product.type or "") == "weapon" then
            local copy = table.Copy(product)
            copy.id = tostring(productID)
            copy._owned = table.Copy(owned)
            out[#out + 1] = copy
        end
    end

    table.sort(out, function(a, b)
        return string.lower(tostring(a.name or a.id or "")) < string.lower(tostring(b.name or b.id or ""))
    end)

    return out
end

local function isValidModelPath(path)
    if not isstring(path) or path == "" then return false end
    if util.IsValidModel then
        return util.IsValidModel(path)
    end
    return file.Exists(path, "GAME")
end

local function callCustomHandler(ply, product, action, owned)
    local handler = C.CustomGrantHandlers and C.CustomGrantHandlers[product.id]
    if isfunction(handler) then
        local ok, handled = pcall(handler, ply, product, action, owned)
        if not ok then
            ErrorNoHalt("[grn_store] CustomGrantHandlers error for " .. tostring(product.id) .. ": " .. tostring(handled) .. "\n")
            return false
        end
        return handled == true
    end
    return false
end

local function applyUpgrade(ply, product, owned)
    ply:SetNWBool("grn_store_upgrade_" .. S.Slug(product.id), true)
    hook.Run("GRNStoreApplyUpgrade", ply, product, owned)
end

local function grantImmediate(ply, product, action, owned)
    if callCustomHandler(ply, product, action, owned) then return true end

    if product.type == "weapon" then
        -- In armory mode the store only records ownership. The actual SWEP is
        -- withdrawn from the Personal Armory entity, never auto-given here.
        if C.Inventory.WeaponsUseArmory and action ~= "armory" then
            return true
        end

        local className = S.ClampString(product.className, C.Limits.MaxClassLength)
        if className ~= "" then
            local weapon = ply:Give(className)
            return IsValid(weapon) or ply:HasWeapon(className)
        end
        return false
    end

    if product.type == "model" then
        if action == "purchase" and not C.Inventory.AutoEquipModelsOnPurchase then
            return true
        end

        local model = S.ClampString(product.className, C.Limits.MaxClassLength)
        if isValidModelPath(model) then
            ply:SetModel(model)
            local record = playerRecord(ply)
            if record then
                record.equippedModel = product.id
                saveInventory()
            end
            return true
        end
        return false
    end

    if product.type == "upgrade" then
        applyUpgrade(ply, product, owned)
        return true
    end

    if product.type == "rank" or product.type == "other" then
        hook.Run("GRNStoreGrantProduct", ply, product, action, owned)
        return true
    end

    -- Entityes/vehiculos/mascotas se spawnean manualmente desde inventario.
    if product.type == "entity" or product.type == "vehicle" or product.type == "pet" then
        return true
    end

    return false
end

local function spawnedCount(ply)
    local count = 0
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.GRNStoreOwner == ply then
            count = count + 1
        end
    end
    return count
end

local function spawnOwnedEntity(ply, product)
    if spawnedCount(ply) >= C.Inventory.MaxSpawnedPerPlayer then
        return false, "Du hast das Limit aktiver Shop-Entities erreicht."
    end

    ply.GRNStoreSpawnCooldown = ply.GRNStoreSpawnCooldown or {}
    local nextUse = ply.GRNStoreSpawnCooldown[product.id] or 0
    if nextUse > CurTime() then
        return false, "Warte ein paar Sekunden, bevor du das Produkt erneut spawnst."
    end

    local className = S.ClampString(product.className, C.Limits.MaxClassLength)
    if className == "" then return false, "This product has no configured class." end

    local ent = ents.Create(className)
    if not IsValid(ent) then
        return false, "Die konfigurierte Entity/Klasse konnte nicht erstellt werden."
    end

    local spawnModel = S.ClampString(product.spawnModel or product.previewModel, C.Limits.MaxPreviewModelLength)
    if spawnModel ~= "" and isValidModelPath(spawnModel) and isfunction(ent.SetModel) then
        ent:SetModel(spawnModel)
    end

    local forward = ply:GetForward()
    local startPos = ply:GetPos() + Vector(0, 0, 44)
    local desired = startPos + forward * C.Inventory.SpawnDistance

    local tr = util.TraceHull({
        start = startPos,
        endpos = desired,
        mins = Vector(-18, -18, 0),
        maxs = Vector(18, 18, 72),
        filter = ply,
        mask = MASK_SOLID,
    })

    local pos = tr.Hit and (tr.HitPos - forward * 30) or desired
    ent:SetPos(pos)
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    ent:Spawn()
    ent:Activate()
    ent:SetCreator(ply)
    ent.GRNStoreOwner = ply
    ent.GRNStoreProductID = product.id

    if isfunction(ent.CPPISetOwner) then
        ent:CPPISetOwner(ply)
    end

    ply.GRNStoreSpawnCooldown[product.id] = CurTime() + C.Inventory.SpawnCooldown
    hook.Run("GRNStoreEntitySpawned", ply, ent, product)
    return true
end

local function buildInventoryPayload(ply)
    cleanupExpired(ply)
    local record = playerRecord(ply)
    local result = {}
    if not record then return result end

    for productID, owned in pairs(record.items) do
        local product = productForOwned(productID, owned)
        if product then
            table.insert(result, {
                productID = productID,
                name = product.name or productID,
                category = product.category or "other",
                type = product.type or "other",
                purchaseType = product.purchaseType or "permanent",
                className = product.className or "",
                previewModel = product.previewModel or "",
                rarity = product.rarity or "cyan",
                description = product.description or "",
                expires = tonumber(owned.expires) or 0,
                quantity = tonumber(owned.quantity) or 1,
                equipped = record.equippedModel == productID,
            })
        end
    end

    table.sort(result, function(a, b)
        return string.lower(a.name or "") < string.lower(b.name or "")
    end)

    return result
end

local function sanitizeCategoriesForClient()
    local out = {}
    for _, cat in ipairs(S.Data.categories or {}) do
        table.insert(out, {
            id = tostring(cat.id or ""),
            name = tostring(cat.name or ""),
            icon = tostring(cat.icon or "fa-solid fa-folder"),
            desc = tostring(cat.desc or ""),
            protected = C.ProtectBaseCategories and isBaseCategory(cat.id) or false,
        })
    end
    return out
end

local function sanitizeProductsForClient()
    local out = {}
    for _, p in ipairs(S.Data.products or {}) do
        table.insert(out, {
            id = tostring(p.id or ""),
            name = tostring(p.name or ""),
            category = tostring(p.category or ""),
            type = tostring(p.type or "other"),
            price = math.max(0, math.floor(tonumber(p.price) or 0)),
            className = tostring(p.className or ""),
            previewModel = tostring(p.previewModel or ""),
            spawnModel = tostring(p.spawnModel or ""),
            rarity = tostring(p.rarity or "cyan"),
            purchaseType = tostring(p.purchaseType or "permanent"),
            duration = math.max(0, math.floor(tonumber(p.duration) or 0)),
            description = tostring(p.description or ""),
        })
    end
    return out
end

local function buildPayload(ply)
    return {
        storeName = C.StoreName,
        categories = sanitizeCategoriesForClient(),
        products = sanitizeProductsForClient(),
        inventory = buildInventoryPayload(ply),
        money = S.GetMoney(ply),
        isStaff = S.IsStaff(ply),
    }
end

local function writeCompressedTable(tbl)
    local json = util.TableToJSON(tbl, false) or "{}"
    local compressed = util.Compress(json) or ""
    net.WriteUInt(#compressed, 32)
    if #compressed > 0 then
        net.WriteData(compressed, #compressed)
    end
end

function S.SendState(ply, shouldOpen)
    if not IsValid(ply) then return end

    net.Start("grn_store_state")
        net.WriteBool(shouldOpen == true)
        net.WriteEntity(IsValid(ply.GRNStoreVendor) and ply.GRNStoreVendor or NULL)
        writeCompressedTable(buildPayload(ply))
    net.Send(ply)
end

function S.BroadcastOpenState()
    for _, ply in ipairs(player.GetHumans()) do
        if IsValid(ply.GRNStoreVendor) then
            S.SendState(ply, false)
        end
    end
end

function S.OpenForPlayer(ply, vendor)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(vendor) then return end
    if ply:GetPos():DistToSqr(vendor:GetPos()) > (C.Entity.UseDistance * C.Entity.UseDistance) then return end

    ply.GRNStoreVendor = vendor
    ply.GRNStoreOpenAt = CurTime()
    S.SendState(ply, true)
end

local function canUseStore(ply)
    if not IsValid(ply) or not ply:Alive() then return false end
    local vendor = ply.GRNStoreVendor
    if not IsValid(vendor) or vendor:GetClass() ~= C.Entity.Class then return false end
    return ply:GetPos():DistToSqr(vendor:GetPos()) <= (C.Entity.MenuMaxDistance * C.Entity.MenuMaxDistance)
end

local function staffAck(ply, kind)
    if not IsValid(ply) then return end
    net.Start("grn_store_staff_ack")
        net.WriteString(tostring(kind or ""))
    net.Send(ply)
end

local function notify(ply, message)
    if not IsValid(ply) then return end

    net.Start("grn_store_notify")
        net.WriteString(tostring(message or ""))
    net.Send(ply)

    if DarkRP and isfunction(DarkRP.notify) then
        DarkRP.notify(ply, 0, 4, message)
    else
        ply:ChatPrint("[Echoes of Clones Shop] " .. message)
    end
end

local function uniqueID(base, finder)
    local id = S.Slug(base)
    local candidate = id
    local suffix = 2
    while finder(candidate) do
        candidate = id .. "_" .. suffix
        suffix = suffix + 1
    end
    return candidate
end

local function sanitizeCategoryPayload(data)
    if not istable(data) then return nil, "Ungültige Daten." end

    local editID = S.Slug(data.editID or "")
    local name = S.ClampString(data.name, C.Limits.MaxNameLength)
    local requestedID = S.Slug(data.id or name)
    local icon = S.ClampString(data.icon or "fa-solid fa-folder", 80)
    local desc = S.ClampString(data.desc or "Eigene Kategorie.", C.Limits.MaxDescriptionLength)

    if name == "" then return nil, "Category name is required." end

    if editID ~= "" then
        local existing = findCategory(editID)
        if not existing then return nil, "Die bearbeitete Kategorie existiert nicht mehr." end
        return {
            editID = editID,
            id = editID,
            name = string.upper(name),
            icon = icon,
            desc = desc,
        }
    end

    if #S.Data.categories >= C.Limits.MaxCategories then
        return nil, "Das Kategorielimit ist erreicht."
    end

    if findCategory(requestedID) then
        return nil, "Eine Kategorie mit dieser ID existiert bereits."
    end

    return {
        editID = "",
        id = requestedID,
        name = string.upper(name),
        icon = icon,
        desc = desc,
    }
end

local function sanitizeProductPayload(data)
    if not istable(data) then return nil, "Ungültige Daten." end

    local editID = S.Slug(data.editID or "")
    local name = S.ClampString(data.name, C.Limits.MaxNameLength)
    local category = S.Slug(data.category or "")
    local productType = S.ClampString(data.type or "other", 32)
    local rarity = S.ClampString(data.rarity or "cyan", 16)
    local purchaseType = S.ClampString(data.purchaseType or "permanent", 24)
    local className = S.ClampString(data.className, C.Limits.MaxClassLength)
    local previewModel = S.ClampString(data.previewModel, C.Limits.MaxPreviewModelLength)
    local spawnModel = S.ClampString(data.spawnModel or data.previewModel, C.Limits.MaxPreviewModelLength)
    local description = S.ClampString(data.description, C.Limits.MaxDescriptionLength)
    local price = math.Clamp(math.floor(tonumber(data.price) or 0), 0, C.Limits.MaxPrice)
    local duration = math.max(0, math.floor(tonumber(data.duration) or 0))

    if name == "" then return nil, "Product name is required." end
    if not findCategory(category) then return nil, "Die Kategorie existiert nicht." end
    if not C.AllowedProductTypes[productType] then return nil, "Dieser Produkttyp ist nicht erlaubt." end
    if not C.AllowedRarities[rarity] then return nil, "Diese Seltenheit ist nicht erlaubt." end
    if not C.AllowedPurchaseTypes[purchaseType] then return nil, "Diese Kaufart ist nicht erlaubt." end

    if purchaseType == "temporary" and duration <= 0 then
        return nil, "Temporäre Produkte brauchen eine Dauer größer als 0."
    end

    if (productType == "weapon" or productType == "model" or productType == "vehicle" or productType == "entity" or productType == "pet") and className == "" then
        return nil, "Dieser Produkttyp braucht eine konfigurierte Klasse bzw. ein Modell."
    end

    local id
    if editID ~= "" then
        if not findProduct(editID) then return nil, "Das bearbeitete Produkt existiert nicht mehr." end
        id = editID
    else
        if #S.Data.products >= C.Limits.MaxProducts then
            return nil, "Das Produktlimit ist erreicht."
        end
        id = uniqueID(name, function(candidate) return findProduct(candidate) ~= nil end)
    end

    return {
        editID = editID,
        id = id,
        name = name,
        category = category,
        type = productType,
        price = price,
        className = className,
        previewModel = previewModel,
        spawnModel = spawnModel,
        rarity = rarity,
        purchaseType = purchaseType,
        duration = duration,
        description = description,
    }
end

net.Receive("grn_store_buy", function(_, ply)
    if not rateLimit(ply, "buy", 0.3) then return end
    if not canUseStore(ply) then return end

    local productID = S.Slug(net.ReadString())
    local product = findProduct(productID)
    if not product then
        notify(ply, "Dieses Produkt existiert nicht mehr.")
        S.SendState(ply, false)
        return
    end

    local record = playerRecord(ply)
    if not record then return end

    local owned = ownershipEntry(ply, productID)
    if product.purchaseType == "permanent" and owned then
        notify(ply, "Du besitzt dieses dauerhafte Produkt bereits.")
        S.SendState(ply, false)
        return
    end

    local price = math.max(0, math.floor(tonumber(product.price) or 0))
    if S.GetMoney(ply) < price then
        notify(ply, "Du hast nicht genug Geld.")
        S.SendState(ply, false)
        return
    end

    if not S.TakeMoney(ply, price) then
        notify(ply, "Die Zahlung konnte nicht verarbeitet werden.")
        S.SendState(ply, false)
        return
    end

    local now = os.time()
    local entry = owned or {
        purchasedAt = now,
        expires = 0,
        quantity = 0,
        snapshot = snapshotProduct(product),
    }

    entry.snapshot = snapshotProduct(product)

    if product.purchaseType == "temporary" then
        local duration = math.max(1, math.floor(tonumber(product.duration) or 1))
        entry.expires = math.max(now, tonumber(entry.expires) or 0) + duration
        entry.quantity = 1
    elseif product.purchaseType == "consumable" then
        entry.quantity = math.max(0, tonumber(entry.quantity) or 0) + 1
    else
        entry.expires = 0
        entry.quantity = 1
    end

    record.items[productID] = entry
    saveInventory()

    grantImmediate(ply, product, "purchase", entry)
    hook.Run("GRNStoreProductPurchased", ply, product, entry)

    if product.type == "weapon" and C.Inventory.WeaponsUseArmory then
        notify(ply, "Du hast " .. tostring(product.name) .. " gekauft. Es ist jetzt dauerhaft in deiner Waffenkammer verfügbar.")
    else
        notify(ply, "Du hast " .. tostring(product.name) .. " gekauft.")
    end
    S.SendState(ply, false)
end)

net.Receive("grn_store_use_item", function(_, ply)
    if not rateLimit(ply, "use_item", 0.25) then return end
    if not canUseStore(ply) then return end

    local productID = S.Slug(net.ReadString())
    local owned = ownershipEntry(ply, productID)
    if not owned then
        notify(ply, "Du besitzt dieses Produkt nicht.")
        S.SendState(ply, false)
        return
    end

    local product = productForOwned(productID, owned)
    if not product then
        notify(ply, "Die Produktkonfiguration konnte nicht geladen werden.")
        return
    end

    local ok = true
    local err

    if product.type == "entity" or product.type == "vehicle" or product.type == "pet" then
        ok, err = spawnOwnedEntity(ply, product)
    elseif product.type == "model" then
        ok = grantImmediate(ply, product, "use", owned)
    elseif product.type == "weapon" then
        if C.Inventory.WeaponsUseArmory then
            notify(ply, "Diese Waffe liegt in deiner Waffenkammer. Hol sie dir am Waffenkammer-Terminal.")
            ok = true
        else
            ok = grantImmediate(ply, product, "use", owned)
        end
    elseif product.type == "upgrade" then
        applyUpgrade(ply, product, owned)
        ok = true
    else
        ok = grantImmediate(ply, product, "use", owned)
    end

    if product.purchaseType == "consumable" and ok then
        owned.quantity = math.max(0, (tonumber(owned.quantity) or 1) - 1)
        if owned.quantity <= 0 then
            local record = playerRecord(ply)
            if record then record.items[productID] = nil end
        end
        saveInventory()
    end

    if not ok then
        notify(ply, err or "Das Produkt konnte nicht benutzt werden.")
    end

    S.SendState(ply, false)
end)

net.Receive("grn_store_close", function(_, ply)
    ply.GRNStoreVendor = nil
    ply.GRNStoreOpenAt = nil
end)

local function readJSONNet(maxLen)
    local raw = net.ReadString()
    if #raw > (maxLen or 12000) then return nil end
    return util.JSONToTable(raw)
end

net.Receive("grn_store_staff_category_save", function(_, ply)
    if not rateLimit(ply, "staff_cat_save", 0.35) then return end
    if not canUseStore(ply) or not S.IsStaff(ply) then return end

    local payload, err = sanitizeCategoryPayload(readJSONNet(6000))
    if not payload then
        notify(ply, err or "Ungültige Kategorie.")
        return
    end

    if payload.editID ~= "" then
        local existing = findCategory(payload.editID)
        existing.name = payload.name
        existing.icon = payload.icon
        existing.desc = payload.desc
    else
        table.insert(S.Data.categories, {
            id = payload.id,
            name = payload.name,
            icon = payload.icon,
            desc = payload.desc,
        })
    end

    saveStore()
    S.BroadcastOpenState()
    staffAck(ply, "category")
    notify(ply, "Kategorie gespeichert.")
end)

net.Receive("grn_store_staff_category_delete", function(_, ply)
    if not rateLimit(ply, "staff_cat_delete", 0.35) then return end
    if not canUseStore(ply) or not S.IsStaff(ply) then return end

    local id = S.Slug(net.ReadString())
    local cat, index = findCategory(id)
    if not cat then return end

    if C.ProtectBaseCategories and isBaseCategory(id) then
        notify(ply, "Diese Basiskategorie ist in config.lua geschützt.")
        return
    end

    for _, product in ipairs(S.Data.products) do
        if product.category == id then
            notify(ply, "Eine Kategorie mit Produkten kann nicht gelöscht werden.")
            return
        end
    end

    table.remove(S.Data.categories, index)
    saveStore()
    S.BroadcastOpenState()
    notify(ply, "Kategorie gelöscht.")
end)

net.Receive("grn_store_staff_product_save", function(_, ply)
    if not rateLimit(ply, "staff_product_save", 0.35) then return end
    if not canUseStore(ply) or not S.IsStaff(ply) then return end

    local payload, err = sanitizeProductPayload(readJSONNet(12000))
    if not payload then
        notify(ply, err or "Ungültiges Produkt.")
        return
    end

    if payload.editID ~= "" then
        local _, index = findProduct(payload.editID)
        S.Data.products[index] = payload
        S.Data.products[index].editID = nil
    else
        payload.editID = nil
        table.insert(S.Data.products, payload)
    end

    saveStore()
    S.BroadcastOpenState()
    staffAck(ply, "product")
    notify(ply, "Produkt gespeichert.")
end)

net.Receive("grn_store_staff_product_delete", function(_, ply)
    if not rateLimit(ply, "staff_product_delete", 0.35) then return end
    if not canUseStore(ply) or not S.IsStaff(ply) then return end

    local id = S.Slug(net.ReadString())
    local _, index = findProduct(id)
    if not index then return end

    table.remove(S.Data.products, index)
    saveStore()
    S.BroadcastOpenState()
    notify(ply, "Produkt aus dem Shop entfernt. Bestehende Käufe bleiben erhalten.")
end)

hook.Add("PlayerSpawn", "GRNStore_ReapplyOwned", function(ply)
    timer.Simple(0.8, function()
        if not IsValid(ply) or not ply:Alive() then return end

        cleanupExpired(ply)
        local record = playerRecord(ply)
        if not record then return end

        for productID, owned in pairs(record.items) do
            local product = productForOwned(productID, owned)
            if product then
                if product.type == "weapon" and C.Inventory.RegrantWeaponsOnSpawn then
                    grantImmediate(ply, product, "spawn", owned)
                elseif product.type == "upgrade" then
                    applyUpgrade(ply, product, owned)
                end
            end
        end

        if C.Inventory.ReapplyEquippedModelOnSpawn and record.equippedModel and record.equippedModel ~= "" then
            local owned = record.items[record.equippedModel]
            local product = owned and productForOwned(record.equippedModel, owned) or nil
            if product and product.type == "model" then
                grantImmediate(ply, product, "spawn", owned)
            end
        end
    end)
end)

hook.Add("PlayerDisconnected", "GRNStore_CleanupPlayerEntities", function(ply)
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.GRNStoreOwner == ply then
            ent:Remove()
        end
    end
end)

hook.Add("ShutDown", "GRNStore_SaveOnShutdown", function()
    saveStore()
    saveInventory()
end)

-- Comando util para admins: crea el vendedor donde estas mirando.
concommand.Add("grn_store_spawn", function(ply)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local pos = Vector(0, 0, 0)
    local ang = Angle(0, 0, 0)

    if IsValid(ply) then
        local tr = ply:GetEyeTrace()
        pos = tr.HitPos + tr.HitNormal * 2
        ang = Angle(0, ply:EyeAngles().y + 180, 0)
    end

    local ent = ents.Create(C.Entity.Class)
    if not IsValid(ent) then return end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
end)
