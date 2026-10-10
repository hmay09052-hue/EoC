KrakensStore = KrakensStore or {}
KrakensStore.AID = "krakens_store"
KrakensStore.CurrencyKey = "KrakensStore_Currency"

function KrakensStore.Fire(cb, ...) if cb then cb(...) end end

KrakensStore.TimeOffset = KrakensStore.TimeOffset or 0
function KrakensStore.Now() return os.time() + KrakensStore.TimeOffset end

local AID = KrakensStore.AID

KrakensStore.L = KF.Lang.CreateAccessor(AID)

KrakensStore.Config = KrakensStore.Config or {}

KrakensStore.Config.General = {
    Currency = {},

    Refund = {},

    Commands = {
        Store = {"/store", "/tienda", "!tienda"},
        Inventory = {"/inventory", "/inv", "!inventory", "!inv", "/inventario", "!inventario"},
        Admin = {"/storeadmin", "!storeadmin"},
    },

    CommandAllowlist = {
        ["say"] = true,
    },
}

KrakensStore.Config.Permissions = {
    AdminGroups = {
        "superadmin",
        "admin",
        "operator"
    },

    CustomAdminCheck = nil,

    ActionPermissions = {
        manage_items       = {},
        manage_categories  = {},
        manage_npcs        = {},
        manage_players     = {},
        manage_config      = { "superadmin" },
        view_logs          = {},
    },
}

KrakensStore.Config.UI = {
    OpenKey = KEY_F6,

    Colors = {},

    Sounds = {
        Open = "kraken/sw_squadrons/ux/navigation/navigation_tab_01.mp3",
        Close = "kraken/sw_squadrons/ux/navigation/navigation_back_01.mp3",
        Hover = "kraken/sw_squadrons/ux/navigation/navigation_slider_02.mp3",
        Click = "kraken/sw_squadrons/ux/navigation/navigation_activate_01.mp3",
        Equip = "kraken/sw_squadrons/ux/navigation/navigation_weaponequip_01.mp3",
        Purchase = "kraken/sw_squadrons/ux/navigation/navigation_matchmakingsuccess_01.mp3",
        Error = "kraken/sw_squadrons/ux/navigation/navigation_error_01.mp3",
    }
}

KrakensStore.Config.Integrations = {
    ARC9 = {
        AccessoryBlacklist = {}
    },

    ArcCW = {
        AccessoryBlacklist = {}
    },
}

KrakensStore.Config.CvarAllowlist = {
    { system = "arccw", key = "enable_customization", type = "int", min = -1, max = 1 },
    { system = "arccw", key = "attinv_loseondie", type = "bool" },
    { system = "arccw", key = "attinv_free", type = "bool" },
    { system = "arccw", key = "attinv_lockmode", type = "int", min = 0, max = 3 },
    { system = "arc9", key = "free_atts", type = "bool" },
    { system = "arc9", key = "atts_lock", type = "bool" },
    { system = "arc9", key = "atts_loseondie", type = "bool" },
}

KrakensStore.Config.Entities = {
    Terminal = {},
    Workbench = { UseDistance = 80 },
    NPC = {},
}

KrakensStore.Config.Logging = {}

function KrakensStore.Config.ApplyBlacklist(saved)
    if not istable(saved) then return end
    for key, system in pairs(KrakensStore.Integrations.AttachmentSystems) do
        if istable(saved[key]) then KrakensStore.Config.Integrations[system.name].AccessoryBlacklist = table.Copy(saved[key]) end
    end
end

local Cfg = KrakensStore.Config

Cfg.SettingSpec = {
    { key = "storeName", kind = "string", max = 128, default = "Kraken's Store", path = "General.StoreName", group = "admin_general_settings" },
    { key = "currencySymbol", kind = "string", max = 8, default = "$", path = "General.Currency.Symbol", group = "admin_general_settings" },
    { key = "language", kind = "enum", default = "en", path = "General.Language", group = "admin_general_settings",
      options = function() return KF.Lang.GetAvailable(AID) end },
    { key = "chatCommand", kind = "command", max = 32, default = "!store", path = "General.Commands.OpenStore", group = "admin_general_settings" },

    { key = "requireEntity", kind = "bool", default = false, path = "General.RequireEntity", group = "admin_access_settings" },
    { key = "requireWorkbench", kind = "bool", default = false, path = "General.RequireWorkbench", group = "admin_access_settings" },
    { key = "hideNonPurchasable", kind = "bool", default = false, path = "General.HideNonPurchasable", group = "admin_access_settings" },
    { key = "maxDistance", kind = "number", min = 32, max = 1024, default = 200, path = "General.MaxDistance", group = "admin_access_settings" },

    { key = "refundPercentage", kind = "number", min = 0, max = 100, default = 50, path = "General.Refund.Percentage", group = "admin_refund_settings" },
    { key = "refundTemporaryItems", kind = "bool", default = false, path = "General.Refund.TemporaryItems", group = "admin_refund_settings" },
    { key = "refundWindowHours", kind = "number", min = 0, max = 8760, default = 0, path = "General.Refund.WindowHours", group = "admin_refund_settings" },

    { key = "storeConsoleModel", kind = "model", default = "models/props_combine/combine_interface001.mdl", path = "Entities.Terminal.Model", group = "admin_entity_settings", lookKey = "storeConsoleLook" },
    { key = "storeConsoleLook", kind = "look", default = { skin = 0, bodygroups = {} }, path = "Entities.Terminal.Look", group = "admin_entity_settings", hidden = true },
    { key = "workbenchModel", kind = "model", default = "models/props_c17/FurnitureTable002a.mdl", path = "Entities.Workbench.Model", group = "admin_entity_settings", lookKey = "workbenchLook" },
    { key = "workbenchLook", kind = "look", default = { skin = 0, bodygroups = {} }, path = "Entities.Workbench.Look", group = "admin_entity_settings", hidden = true },
    { key = "npcModel", kind = "model", default = "models/humans/group01/male_01.mdl", path = "Entities.NPC.Model", group = "admin_entity_settings", lookKey = "npcLook" },
    { key = "npcLook", kind = "look", default = { skin = 0, bodygroups = {} }, path = "Entities.NPC.Look", group = "admin_entity_settings", hidden = true },

    { key = "purchasableRanks", kind = "list", default = { "vip", "vip+", "premium" }, path = "Permissions.PurchasableRanks", group = "admin_permission_settings",
      validate = function(v) return KrakensStore.IsValidRankName(v) and string.lower(v) or nil end },

    { key = "logPurchases", kind = "bool", default = true, path = "Logging.LogPurchases", group = "admin_logging_settings" },
    { key = "logSales", kind = "bool", default = true, path = "Logging.LogSales", group = "admin_logging_settings" },
    { key = "logEquips", kind = "bool", default = true, path = "Logging.LogEquips", group = "admin_logging_settings" },
    { key = "logAdminActions", kind = "bool", default = true, path = "Logging.LogAdminActions", group = "admin_logging_settings" },
}

function Cfg.CvarSettingKey(system, key) return "cvar_" .. system .. "_" .. key end

for _, def in ipairs(Cfg.CvarAllowlist) do
    local cvarName = def.system .. "_" .. def.key
    local isBool = def.type == "bool"
    local spec = {
        key = Cfg.CvarSettingKey(def.system, def.key),
        kind = isBool and "bool" or "number",
        min = def.min, max = def.max,
        labelKey = cvarName,
        cvar = cvarName,
        integration = def.system,
        group = "admin_integration_settings",
    }
    spec.get = function()
        if CLIENT then return spec.value end
        local cv = GetConVar(cvarName)
        if not cv then return nil end
        if isBool then return cv:GetBool() end
        return cv:GetInt()
    end
    spec.set = function(v)
        if CLIENT then spec.value = v return end
        local cv = GetConVar(cvarName)
        if cv then cv:SetInt(isbool(v) and (v and 1 or 0) or v) end
    end
    Cfg.SettingSpec[#Cfg.SettingSpec + 1] = spec
end

Cfg.SettingByKey = {}
for _, spec in ipairs(Cfg.SettingSpec) do
    Cfg.SettingByKey[spec.key] = spec
    if spec.path then
        local parents = string.Explode(".", spec.path)
        local field = table.remove(parents)
        local function Parent()
            local node = Cfg
            for _, part in ipairs(parents) do node = node[part] end
            return node
        end
        spec.get = function() return Parent()[field] end
        spec.set = function(v) Parent()[field] = v end
    end
    if spec.default ~= nil then spec.set(istable(spec.default) and table.Copy(spec.default) or spec.default) end
end

function Cfg.SanitizeSetting(key, value)
    local spec = Cfg.SettingByKey[key]
    if not spec or value == nil then return nil end
    local V = KrakensStore.Validation

    if spec.kind == "bool" then
        if not isbool(value) then return nil end
        return value
    end

    if spec.kind == "number" then
        local num = tonumber(value)
        if not num then return nil end
        return math.Clamp(num, spec.min or -2147483648, spec.max or 2147483647)
    end

    if spec.kind == "model" then
        return V.ModelPath(value)
    end

    if spec.kind == "look" then
        if not istable(value) then return nil end
        return KF.Utils.CleanLook(value)
    end

    if spec.kind == "enum" then
        local str = V.String(value, 32)
        if not str then return nil end
        str = string.lower(str)
        return spec.options()[str] and str or nil
    end

    if spec.kind == "command" then
        local str = V.String(value, spec.max or 32)
        if not str then return nil end
        str = string.lower(string.Trim(str))
        if not string.match(str, "^[!/][%w_%-]+$") then return nil end
        return str
    end

    if spec.kind == "list" then
        if not istable(value) then return nil end
        local out = {}
        for _, entry in ipairs(value) do
            local clean
            if spec.validate then clean = spec.validate(entry) else clean = V.String(entry, 64) end
            if clean then out[#out + 1] = clean end
        end
        return out
    end

    return V.String(value, spec.max or 256)
end

function Cfg.ReadSettings()
    local out = {}
    for _, spec in ipairs(Cfg.SettingSpec) do
        local value = spec.get()
        out[spec.key] = istable(value) and table.Copy(value) or value
    end
    return out
end

function Cfg.ApplySettings(saved)
    if not istable(saved) then return end
    for _, spec in ipairs(Cfg.SettingSpec) do
        local raw = saved[spec.key]
        if raw ~= nil then
            local clean = Cfg.SanitizeSetting(spec.key, raw)
            if clean ~= nil then spec.set(clean) end
        end
    end
    if saved.blacklist then Cfg.ApplyBlacklist(saved.blacklist) end
end

function KrakensStore.IsValidRankName(group)
    if not isstring(group) or group == "" or #group > 64 then return false end
    return not string.find(group, "[%s%c]")
end

local function InUsergroups(ply, groups)
    return #groups > 0 and KF.Whitelist.CanAccess(ply, { usergroups = groups }) == true
end

function KrakensStore.IsAdmin(ply)
    if not IsValid(ply) then return false end
    if ply:IsSuperAdmin() then return true end

    local perms = KrakensStore.Config.Permissions
    if perms.CustomAdminCheck and perms.CustomAdminCheck(ply) then return true end

    return InUsergroups(ply, perms.AdminGroups)
end

function KrakensStore.HasActionPermission(ply, permissionKey)
    if not KrakensStore.IsAdmin(ply) then return false end
    local groups = KrakensStore.Config.Permissions.ActionPermissions[permissionKey]
    return not groups or #groups == 0 or InUsergroups(ply, groups)
end

KrakensStore.EntityClasses = {
    NPC = "ks_store_npc",
    Workbench = "ks_workbench",
    Terminal = "ks_store_terminal",
}

KrakensStore.Utils = KrakensStore.Utils or {}
local U = KrakensStore.Utils

function U.SetupEntityPhysics(ent, model, look)
    ent:SetModel(model)
    KF.Utils.ApplyLook(ent, look and look.skin, look and look.bodygroups)
    ent:PhysicsInit(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetUseType(SIMPLE_USE)
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
end

function U.PlaceInFront(ent, ply, tr)
    ent:SetPos(tr.HitPos + tr.HitNormal * 16)
    ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
end

function U.EntitySpawnFunction(self, ply, tr, className)
    if not tr.Hit then return end
    local ent = ents.Create(className)
    if not IsValid(ent) then return end
    U.PlaceInFront(ent, ply, tr)
    ent:Spawn()
    ent:Activate()
    return ent
end

function U.UseDebounce(ply, seconds)
    if not IsValid(ply) then return false end
    if (ply.KS_LastUse or 0) > CurTime() then return false end
    ply.KS_LastUse = CurTime() + (seconds or 1)
    return true
end

function U.SortByOrder(list)
    table.sort(list, function(a, b)
        local oa, ob = tonumber(a.order) or 0, tonumber(b.order) or 0
        if oa ~= ob then return oa < ob end
        local na, nb = tostring(a.name or ""), tostring(b.name or "")
        if na ~= nb then return na < nb end
        return tostring(a.id) < tostring(b.id)
    end)
    return list
end

function U.GetUseDistance(kind)
    return KrakensStore.Config.Entities[kind].UseDistance or KrakensStore.Config.General.MaxDistance
end

function U.FindNearEntity(ply, kind, match)
    if not IsValid(ply) then return nil end
    local maxDistSqr = U.GetUseDistance(kind) ^ 2
    local plyPos = ply:GetPos()
    for _, ent in ipairs(ents.FindByClass(KrakensStore.EntityClasses[kind])) do
        if plyPos:DistToSqr(ent:GetPos()) <= maxDistSqr and (not match or match(ent)) then return ent end
    end
end

local SPAWN_RULES = {
    NPC = { mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 72), offset = Vector(0, 0, 36), minDist = 30, maxDist = 500 },
    Vehicle = { mins = Vector(-40, -40, 0), maxs = Vector(40, 40, 80), offset = Vector(0, 0, 40), minDist = 50, maxDist = 500 },
}

local function FiniteAxis(n)
    return isnumber(n) and n == n and math.abs(n) <= 32768
end

function U.ValidSpawnInput(pos, ang)
    if not isvector(pos) or not FiniteAxis(pos.x) or not FiniteAxis(pos.y) or not FiniteAxis(pos.z) then return false end
    if ang == nil then return true end
    return isangle(ang) and FiniteAxis(ang.p) and FiniteAxis(ang.y) and FiniteAxis(ang.r)
end

function U.CheckSpawnPos(pos, kind, ply)
    local rule = SPAWN_RULES[kind]
    local dist = pos:Distance(ply:GetPos())
    if dist > rule.maxDist * (SERVER and 1.25 or 1) then return false, "far" end
    if CLIENT and dist < rule.minDist then return false, "close" end
    if bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER then return false, "water" end
    local ground = util.TraceLine({ start = pos, endpos = pos - Vector(0, 0, 500), mask = MASK_SOLID_BRUSHONLY })
    if not ground.Hit then return false, "ground" end
    if ground.HitNormal.z < 0.7 then return false, "steep" end
    local origin = pos + rule.offset
    if util.TraceHull({ start = origin, endpos = origin, mins = rule.mins, maxs = rule.maxs, mask = MASK_SOLID, filter = ply }).Hit then
        return false, "obstructed"
    end
    return true
end

function KrakensStore.FormatMoney(amount)
    return KrakensStore.Config.General.Currency.Symbol .. KF.FormatNumber(amount or 0)
end

local S = KF.Sanitize
local L = KrakensStore.L

KrakensStore.Validation = setmetatable({}, { __index = S })
local V = KrakensStore.Validation

V.Limits = setmetatable({
    MAX_ARMOR = 500,
    MAX_ACTION_NAME_LENGTH = 64,
    MAX_DECOMPRESSED = S.Limits.MAX_PAYLOAD_SIZE * 4,
}, { __index = S.Limits })

function V.ModelPath(value)
    local path = V.Path(value)
    if not path or path == "" then return nil end
    if not KF.Utils.IsValidModel(path) then return nil end
    return path
end

function V.PlayerModelPath(value)
    local path = V.ModelPath(value)
    if not path then return nil end
    for _, valid in pairs(player_manager.AllValidModels() or {}) do
        if valid == path then return path end
    end
    return nil
end

function V.Id(rawId, plainErrKey, charsErrKey)
    local str = S.String(rawId, S.Limits.MAX_ID_LENGTH)
    if not str then return nil, L(plainErrKey) end
    if not string.match(str, S.Patterns.IDENTIFIER) then return nil, L(charsErrKey) end
    return str
end

function V.ItemId(itemId)
    return V.Id(itemId, "err_invalid_item_id_plain", "err_item_id_invalid_chars")
end

function V.CategoryId(categoryId)
    return V.Id(categoryId, "err_invalid_category_id_plain", "err_category_id_invalid_chars")
end

function V.NpcId(npcId)
    return V.Id(npcId, "err_invalid_npc_id", "err_npc_id_invalid_chars")
end

local MAX_WHITELIST_ENTRIES = 2048

local function SanitizeWhitelist(wl)
    if not wl or not istable(wl) then return nil end
    local clean = {}
    for wlKey, wlVal in pairs(wl) do
        if isstring(wlKey) and #wlKey <= 128 then
            if isbool(wlVal) then
                clean[wlKey] = wlVal
            elseif istable(wlVal) then
                local cleanEntries = {}
                for _, entry in ipairs(wlVal) do
                    if isstring(entry) and #entry <= 128 and #cleanEntries < MAX_WHITELIST_ENTRIES then
                        table.insert(cleanEntries, entry)
                    end
                end
                clean[wlKey] = cleanEntries
            end
        end
    end
    return clean
end

function V.AllowedDataKeys(typeId)
    local keys = {}
    local typeDef = typeId and KrakensStore.types[typeId]
    for _, setting in ipairs(typeDef and typeDef.settings or {}) do
        keys[#keys + 1] = setting.key
    end
    return keys
end

function V.ItemData(data)
    if not istable(data) then return nil, L("err_item_data_must_be_table") end
    local sanitized = {}

    local id, idErr = V.ItemId(data.id)
    if not id then return nil, idErr end
    sanitized.id = id

    local name = V.String(data.name, V.Limits.MAX_NAME_LENGTH)
    if not name then return nil, L("err_invalid_item_name") end
    sanitized.name = name

    if data.description then sanitized.description = V.String(data.description, V.Limits.MAX_DESCRIPTION_LENGTH, true) or "" end
    if data.icon then sanitized.icon = V.Path(data.icon) or "" end
    if data.model then sanitized.model = V.Path(data.model) or "" end
    if data.price ~= nil then sanitized.price = V.Price(data.price) or 0 end
    if data.category and data.category ~= "" then sanitized.category = V.CategoryId(data.category) end
    if data.type then sanitized.type = V.String(data.type, 64) or "custom" end

    if data.data and istable(data.data) then
        sanitized.data = {}
        for _, key in ipairs(V.AllowedDataKeys(sanitized.type or data.type)) do
            local val = data.data[key]
            if val ~= nil then
                if isstring(val) then sanitized.data[key] = V.String(val, V.Limits.MAX_GENERIC_STRING_LENGTH, true)
                elseif isnumber(val) then sanitized.data[key] = V.Number(val, -2147483648, 2147483647)
                elseif isbool(val) then sanitized.data[key] = val
                elseif IsColor(val) then sanitized.data[key] = Color(math.Clamp(val.r or 255,0,255), math.Clamp(val.g or 255,0,255), math.Clamp(val.b or 255,0,255), math.Clamp(val.a or 255,0,255))
                elseif istable(val) then
                    local json = util.TableToJSON(val)
                    if json and #json <= V.Limits.MAX_GENERIC_STRING_LENGTH then
                        sanitized.data[key] = util.JSONToTable(json) or {}
                    end
                end
            end
        end
    end

    for _, key in ipairs({"enabled","refundable","requiresWhitelist"}) do
        if data[key] ~= nil and isbool(data[key]) then sanitized[key] = data[key] end
    end

    if data.whitelist then
        local wl = SanitizeWhitelist(data.whitelist)
        if wl then sanitized.whitelist = wl end
    end

    for _, key in ipairs({"stock","maxOwned","duration"}) do
        if data[key] ~= nil then sanitized[key] = V.Number(data[key]) end
    end
    if data.refundPercent ~= nil then sanitized.refundPercent = V.Number(data.refundPercent, -1, 100) end
    if data.refundWindowHours ~= nil then sanitized.refundWindowHours = V.Number(data.refundWindowHours, -1, 8760) end

    return sanitized
end

function V.CategoryData(data)
    if not istable(data) then return nil, L("err_category_data_must_be_table") end
    local sanitized = {}

    local id, idErr = V.CategoryId(data.id)
    if not id then return nil, idErr end
    sanitized.id = id

    local name = V.String(data.name, V.Limits.MAX_NAME_LENGTH)
    if not name then return nil, L("err_invalid_category_name") end
    sanitized.name = name

    if data.icon then sanitized.icon = V.Path(data.icon) or "" end
    if data.order ~= nil then sanitized.order = V.Number(data.order, -1000, 1000, 0) end
    if data.description then sanitized.description = V.String(data.description, V.Limits.MAX_DESCRIPTION_LENGTH, true) or "" end
    if data.requiresWhitelist ~= nil then sanitized.requiresWhitelist = data.requiresWhitelist == true end
    local wl = SanitizeWhitelist(data.whitelist)
    if wl then sanitized.whitelist = wl end

    return sanitized
end

function V.NPCData(data)
    if not istable(data) then return nil, L("err_npc_data_must_be_table") end
    local sanitized = {}

    local id, idErr = V.NpcId(data.id)
    if not id then return nil, idErr end
    sanitized.id = id

    local name = V.String(data.name, V.Limits.MAX_NAME_LENGTH)
    if not name then return nil, L("err_invalid_npc_name") end
    sanitized.name = name

    if data.model then
        sanitized.model = V.Path(data.model)
        if not sanitized.model or sanitized.model == "" then return nil, L("err_npc_model_required") end
    end
    if data.skin ~= nil or data.bodygroups ~= nil then
        local look = KF.Utils.CleanLook(data)
        sanitized.skin, sanitized.bodygroups = look.skin, look.bodygroups
    end
    if data.floatingText ~= nil then sanitized.floatingText = V.String(data.floatingText, V.Limits.MAX_NAME_LENGTH, true) or "" end
    if data.idleAnim ~= nil then sanitized.idleAnim = V.String(data.idleAnim, V.Limits.MAX_NAME_LENGTH, true) or nil end
    if data.order ~= nil then sanitized.order = V.Number(data.order, -1000, 1000, 0) end
    if data.requiresWhitelist ~= nil then sanitized.requiresWhitelist = data.requiresWhitelist == true end
    local wl = SanitizeWhitelist(data.whitelist)
    if wl then sanitized.whitelist = wl end

    if data.categories and istable(data.categories) then
        sanitized.categories = {}
        for k, v in pairs(data.categories) do
            if isstring(k) and v == true and V.CategoryId(k) and KrakensStore.Categories.Get(k) then
                sanitized.categories[k] = true
            end
        end
    end

    if data.items and istable(data.items) then
        sanitized.items = {}
        for k, v in pairs(data.items) do
            if isstring(k) and v == true and V.ItemId(k) and KrakensStore.Items.Get(k) then
                sanitized.items[k] = true
            end
        end
    end

    return sanitized
end

KrakensStore.Workbench = KrakensStore.Workbench or { _patched = {} }
local WB = KrakensStore.Workbench

function WB.PatchWeapon(className, methodName, check)
    local base = weapons.GetStored(className)
    if not base or not base[methodName] then return end
    local key = className .. "." .. methodName
    if WB._patched[key] then return end
    local orig = base[methodName]
    base[methodName] = function(self, on)
        if on then
            local owner = SERVER and self:GetOwner() or LocalPlayer()
            if SERVER and (not IsValid(owner) or not owner:IsPlayer()) then
                return orig(self, on)
            end
            if not check(owner) then return end
        end
        return orig(self, on)
    end
    WB._patched[key] = true
end

function WB.CanCustomize(ply)
    return not KrakensStore.Config.General.RequireWorkbench
        or (CLIENT and KrakensStore._atWorkbench == true)
        or U.FindNearEntity(ply, "Workbench") ~= nil
end

function WB.InstallGate(notify)
    local function check(ply)
        if WB.CanCustomize(ply) then return true end
        notify(ply)
        return false
    end
    hook.Add("InitPostEntity", "KrakensStore_WorkbenchGating_" .. (SERVER and "SV" or "CL"), function()
        timer.Simple(1, function()
            WB.PatchWeapon("arc9_base", "ToggleCustomize", check)
            WB.PatchWeapon("arccw_base", "ToggleCustomizeHUD", check)
        end)
    end)
end

local Fire = KrakensStore.Fire

KrakensStore.Schema = KrakensStore.Schema or {}
local Schema = KrakensStore.Schema

Schema.DefaultCategories = nil
Schema.OrphanCategoryId = "misc"

function Schema.ParseColor(value)
    if IsColor(value) then return value end
    local function clamp(v, fallback) return math.Clamp(tonumber(v) or fallback, 0, 255) end
    if isstring(value) then
        local r, g, b, a = string.match(value, "^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,?%s*(%d*)%s*$")
        if not r then return nil end
        return Color(clamp(r, 255), clamp(g, 255), clamp(b, 255), clamp(a, 255))
    end
    if istable(value) and value.r then
        return Color(clamp(value.r, 255), clamp(value.g, 255), clamp(value.b, 255), clamp(value.a, 255))
    end
    return nil
end

function Schema.GetDefaultCategories()
    if not Schema.DefaultCategories then
        Schema.DefaultCategories = {
            { id = "weapons", name = L("cat_default_weapons"), icon = nil, order = 1 },
            { id = "armor", name = L("cat_default_armor"), icon = nil, order = 2 },
            { id = "consumables", name = L("cat_default_consumables"), icon = nil, order = 3 },
            { id = "cosmetics", name = L("cat_default_cosmetics"), icon = nil, order = 4 },
            { id = "misc", name = L("cat_default_misc"), icon = nil, order = 99 },
        }
    end
    return Schema.DefaultCategories
end

function Schema.PlayerDataDefaults()
    return {
        stats = { totalSpent = 0, totalEarned = 0, itemsPurchased = 0, itemsSold = 0 },
        unlockedAttachments = {},
    }
end

function Schema.MergeDefaults(target, defaults)
    if not istable(target) then return defaults end
    if not istable(defaults) then return target end
    for k, v in pairs(defaults) do
        if target[k] == nil then
            target[k] = istable(v) and table.Copy(v) or v
        elseif istable(v) and istable(target[k]) then
            Schema.MergeDefaults(target[k], v)
        end
    end
    return target
end

function Schema.NormalizeItemData(item)
    if not istable(item) then return end
    item.data = item.data or {}
    if item.duration == nil then item.duration = -1 end
end

function Schema.CreateItem(data)
    local defaults = {
        id = "", name = L("admin_new_item_name"), description = "", icon = "", model = "", type = "custom",
        category = "misc", price = 1000, duration = -1, stock = -1, maxOwned = 0,
        enabled = true, refundable = true,
        created = os.time(), modified = os.time(),
        whitelist = {}, requiresWhitelist = false, data = {},
    }
    local item = table.Copy(defaults)
    for k, v in pairs(data or {}) do item[k] = v end
    Schema.NormalizeItemData(item)
    return item
end

function Schema.CreateCategory(data)
    local defaults = {
        id = "", name = L("admin_new_category_name"), icon = "",
        order = 0, description = "", requiresWhitelist = false, whitelist = {},
        created = os.time(), modified = os.time(),
    }
    local category = table.Copy(defaults)
    for k, v in pairs(data or {}) do category[k] = v end
    return category
end

function Schema.ValidateItem(item)
    local errors = {}
    local _, idErr = KrakensStore.Validation.ItemId(item.id)
    if not item.id or item.id == "" then
        errors[#errors + 1] = {field = "id", message = L("err_item_id_required")}
    elseif idErr then
        errors[#errors + 1] = {field = "id", message = idErr}
    end
    if not item.name or item.name == "" then
        errors[#errors + 1] = {field = "name", message = L("err_item_name_required")}
    end
    if not item.type or item.type == "" then
        errors[#errors + 1] = {field = "type", message = L("err_type_required")}
    elseif not KrakensStore.types[item.type] then
        errors[#errors + 1] = {field = "type", message = L("err_unknown_item_type")}
    end
    if item.price ~= nil then
        local price = tonumber(item.price)
        if not price or price < 0 then
            errors[#errors + 1] = {field = "price", message = L("err_price_positive")}
        end
    end
    return #errors == 0, errors
end

KrakensStore.Items = KrakensStore.Items or {}
KrakensStore.Categories = KrakensStore.Categories or {}
local Items = KrakensStore.Items
local Categories = KrakensStore.Categories

Items.Cache = Items.Cache or {}
Categories.Cache = Categories.Cache or {}

function Items.Get(itemId) return Items.Cache[itemId] end
function Items.GetAll() return Items.Cache end

function KrakensStore:GetItemPrice(ply, itemId, quantity)
    quantity = quantity or 1
    local item = Items.Get(itemId)
    if not item then return 0 end
    local basePrice = tonumber(item.price) or 0
    local total = basePrice * quantity
    local hookPrice = hook.Run("KrakensStore_CalcItemPrice", ply, item, quantity, total)
    if isnumber(hookPrice) then total = hookPrice end
    return math.max(0, math.floor(total))
end

function KrakensStore:GetItemRefund(ply, itemId, quantity)
    quantity = quantity or 1
    local item = Items.Get(itemId)
    if not item then return 0 end
    local basePrice = tonumber(item.price) or 0
    local refundPct = tonumber(item.refundPercent) or -1
    if refundPct < 0 then refundPct = KrakensStore.Config.General.Refund.Percentage end
    local total = math.floor(basePrice * refundPct / 100) * quantity
    local hookRefund = hook.Run("KrakensStore_CalcItemRefund", ply, item, quantity, total)
    if isnumber(hookRefund) then total = hookRefund end
    return math.max(0, math.floor(total))
end

function KrakensStore:GetRefundWindowHours(item)
    local h = item and tonumber(item.refundWindowHours) or -1
    if h < 0 then h = KrakensStore.Config.General.Refund.WindowHours end
    return math.max(0, h)
end

function KrakensStore:GetRefundDeadline(item, invItem)
    local hours = self:GetRefundWindowHours(item)
    if hours <= 0 then return -1 end
    local purchased = invItem and tonumber(invItem.purchased) or 0
    if purchased <= 0 then return -1 end
    return purchased + hours * 3600
end

function KrakensStore:IsRefundExpired(item, invItem)
    local deadline = self:GetRefundDeadline(item, invItem)
    if deadline <= 0 then return false end
    return KrakensStore.Now() >= deadline
end

local function InstallStoreCRUD(store, cfg)
    function store.BroadcastUpdate(entity)
        if CLIENT or not entity or not entity.id then return end
        KF.Net.Broadcast("KrakensStore_EntitySync", function()
            net.WriteString(cfg.kind)
            net.WriteString(entity.id)
            net.WriteBool(true)
            return KF.Net.WriteCompressed(entity, 16)
        end)
        if cfg.afterBroadcastUpdate then cfg.afterBroadcastUpdate(entity) end
    end

    function store.BroadcastDelete(id)
        if CLIENT or not id then return end
        KF.Net.Broadcast("KrakensStore_EntitySync", function()
            net.WriteString(cfg.kind)
            net.WriteString(id)
            net.WriteBool(false)
        end)
        if cfg.afterBroadcastDelete then cfg.afterBroadcastDelete(id) end
    end

    local function CarryRuntimeKeys(entity)
        local live = store.Cache[entity.id]
        if not live or live == entity then return live end
        for _, key in ipairs(cfg.runtimeKeys or {}) do entity[key] = live[key] end
        return live
    end

    function store.Save(entity, callback)
        if CLIENT then Fire(callback, false, "client") return end
        if cfg.beforeSave then cfg.beforeSave(entity) end
        CarryRuntimeKeys(entity)
        entity.modified = os.time()
        KrakensStore.Data[cfg.dataSave](entity, function(ok, err)
            if ok then
                local live = CarryRuntimeKeys(entity)
                if live and live ~= entity then
                    table.Empty(live)
                    for key, value in pairs(entity) do live[key] = value end
                else
                    live = entity
                    store.Cache[entity.id] = entity
                end
                store.BroadcastUpdate(live)
                if cfg.postChangeHook then hook.Run(cfg.postChangeHook) end
            end
            Fire(callback, ok, err)
        end)
    end

    function store.DropId(id, callback)
        if CLIENT or not id then Fire(callback, false, "client") return end
        KrakensStore.Data[cfg.dataDelete](id, function(ok, err)
            if ok then
                store.Cache[id] = nil
                store.BroadcastDelete(id)
            end
            Fire(callback, ok, err)
        end)
    end

    function store.Delete(id, callback)
        if CLIENT then Fire(callback, false, "client") return end
        local removed = store.Cache[id]
        store.DropId(id, function(ok, err)
            if ok then
                if cfg.afterDelete then cfg.afterDelete(id, removed) end
                if cfg.postChangeHook then hook.Run(cfg.postChangeHook) end
            end
            Fire(callback, ok, err)
        end)
    end
end

InstallStoreCRUD(Items, {
    kind = "item",
    dataSave = "SaveItem", dataDelete = "DeleteItem",
    runtimeKeys = { "stock" },
    beforeSave = Schema.NormalizeItemData,
    afterDelete = function(id, item) KrakensStore.ServerInventory.PurgeItem(id, item) end,
    postChangeHook = "KrakensStore_StoreDataChanged",
})

function Categories.Get(categoryId) return Categories.Cache[categoryId] end
function Categories.GetAll() return Categories.Cache end

function Categories.GetSorted()
    local result = {}
    for id, cat in pairs(Categories.Cache) do
        local entry = table.Copy(cat)
        entry.id = id
        table.insert(result, entry)
    end
    return U.SortByOrder(result)
end

InstallStoreCRUD(Categories, {
    kind = "category",
    dataSave = "SaveCategory", dataDelete = "DeleteCategory",
    postChangeHook = "KrakensStore_StoreDataChanged",
    afterDelete = function(id)
        KrakensStore.Data.BulkUpdateItemCategory(id, KrakensStore.Schema.OrphanCategoryId)
    end,
})

KrakensStore.Inventory = KrakensStore.Inventory or {}
local Inv = KrakensStore.Inventory

Inv.Cache = Inv.Cache or {}

function Inv.HasExpiry(invItem)
    if not invItem then return false end
    local expires = tonumber(invItem.expires)
    return expires ~= nil and expires > 0
end

function Inv.IsExpired(invItem)
    if not Inv.HasExpiry(invItem) then return false end
    return tonumber(invItem.expires) < KrakensStore.Now()
end

function Inv.GetCache(ply)
    if not IsValid(ply) then return {} end
    if CLIENT then
        if ply == LocalPlayer() then
            return Inv.LocalCache or {}
        end
        return {}
    end
    return Inv.Cache[ply:SteamID64()] or {}
end

function Inv.HasItem(ply, itemId)
    local cache = Inv.GetCache(ply)
    local item = cache[itemId]
    if not item or Inv.IsExpired(item) then return false, 0 end
    return true, item.quantity or 1
end

function Inv.IsEquipped(ply, itemId)
    local cache = Inv.GetCache(ply)
    local item = cache[itemId]
    return item and not Inv.IsExpired(item) and item.equipped == true
end

function Inv.GetEquippedItems(ply)
    local cache = Inv.GetCache(ply)
    local equipped = {}
    for itemId, invItem in pairs(cache) do
        if invItem.equipped and not Inv.IsExpired(invItem) then equipped[itemId] = invItem end
    end
    return equipped
end

function KrakensStore.PassesWhitelist(ply, entity)
    if not istable(entity) then return true end
    if entity.requiresWhitelist ~= true then return true end
    return KF.Whitelist.CheckProfile("krakens_store", ply, entity.whitelist) and true or false
end

function Inv.CanAccessItem(ply, itemId, storeItem)
    local resolvedItem = storeItem or Items.Get(itemId)
    if not resolvedItem then return false, L("err_item_not_found") end

    if not KrakensStore.PassesWhitelist(ply, resolvedItem) then
        return false, L("err_no_item_access")
    end

    if not KrakensStore.PassesWhitelist(ply, Categories.Get(resolvedItem.category)) then
        return false, L("err_no_category_access")
    end

    return true
end

function Inv.CanPurchase(ply, itemId, quantity, external)
    quantity = quantity or 1
    local storeItem = Items.Get(itemId)
    if not storeItem then return false, L("err_item_not_found") end
    if storeItem.enabled == false then return false, L("err_item_not_available") end

    local stock = tonumber(storeItem.stock) or -1
    if not external and stock >= 0 and stock < quantity then return false, L("err_not_enough_stock") end

    local hasItem, currentQuantity = Inv.HasItem(ply, itemId)
    local maxOwned = storeItem.maxOwned or 0
    if maxOwned > 0 and ((hasItem and currentQuantity or 0) + quantity) > maxOwned then
        return false, string.format(L("err_max_owned"), maxOwned)
    end

    local canAccess, accessErr = Inv.CanAccessItem(ply, itemId, storeItem)
    if not canAccess then return false, accessErr end

    local typeAllowed, typeReason = KrakensStore:CanPlayerPurchase(ply, storeItem)
    if not typeAllowed then return false, typeReason or L("err_cannot_purchase") end

    local typeData = KrakensStore.types[storeItem.type]
    if typeData and typeData.noDuplicates and hasItem then
        return false, L("type_already_own")
    end

    if not external and KF.Currency.Get(ply, KrakensStore.CurrencyKey) < KrakensStore:GetItemPrice(ply, itemId, quantity) then
        return false, L("err_not_enough_money")
    end

    return true
end

function Inv.CanSell(ply, itemId, quantity, external)
    quantity = quantity or 1
    local storeItem = Items.Get(itemId)
    if not storeItem then return false, L("err_item_not_found") end
    if storeItem.refundable == false then return false, L("err_item_cannot_sell") end

    local hasItem, currentQuantity = Inv.HasItem(ply, itemId)
    if not hasItem or currentQuantity < quantity then return false, L("err_not_enough_owned") end

    local invItem = Inv.GetCache(ply)[itemId]
    if Inv.HasExpiry(invItem) and not KrakensStore.Config.General.Refund.TemporaryItems then
        return false, L("err_temp_item_no_refund")
    end
    if not external and KrakensStore:IsRefundExpired(storeItem, invItem) then
        return false, L("err_refund_window_expired")
    end

    return true
end

function Inv.CanEquip(ply, itemId)
    local storeItem = Items.Get(itemId)
    if not storeItem then return false, L("err_item_not_found") end

    local canAccess, accessErr = Inv.CanAccessItem(ply, itemId, storeItem)
    if not canAccess then return false, accessErr end

    local typeData = KrakensStore.types[storeItem.type]
    if not typeData or not typeData.equip then return false, L("err_item_cannot_equip") end

    if not Inv.HasItem(ply, itemId) then return false, L("err_item_not_owned") end
    if Inv.IsEquipped(ply, itemId) then return false, L("err_item_already_equipped") end

    return true
end

function Inv.CanUnequip(ply, itemId)
    local storeItem = Items.Get(itemId)
    if not storeItem then return false, L("err_item_not_found") end
    if not Inv.IsEquipped(ply, itemId) then return false, L("err_item_not_equipped") end
    return true
end

if CLIENT then
    Inv.LocalCache = Inv.LocalCache or {}
end

KrakensStore.NPCs = KrakensStore.NPCs or {}

local NPCs = KrakensStore.NPCs

NPCs.Cache = NPCs.Cache or {}

function NPCs.Resolve(npcId)
    local cfg = NPCs.Get(npcId)
    local model = cfg and cfg.model
    if model and model ~= "" and KF.Utils.IsValidModel(model) then return model, cfg.skin, cfg.bodygroups end
    local defaults = KrakensStore.Config.Entities.NPC
    return defaults.Model, defaults.Look and defaults.Look.skin, defaults.Look and defaults.Look.bodygroups
end

function NPCs.ResolveModel(npcId)
    return (NPCs.Resolve(npcId))
end

function NPCs.ConfigureEntity(ent, npcId)
    if not SERVER then return end
    if not IsValid(ent) then return end
    if ent.SetNPCConfigId then ent:SetNPCConfigId(npcId or "") end
    local cfg = (npcId and npcId ~= "") and NPCs.Get(npcId) or nil
    local model, skin, bodygroups = NPCs.Resolve(npcId)
    ent:SetModel(model)
    KF.Utils.ApplyLook(ent, skin, bodygroups)
    ent:PhysicsInit(SOLID_BBOX)
    ent:SetMoveType(MOVETYPE_NONE)
    ent:SetSolid(SOLID_BBOX)
    ent:SetCollisionGroup(COLLISION_GROUP_PLAYER)
    local mins, maxs = ent:GetModelBounds()
    if mins and maxs then ent:SetCollisionBounds(mins, maxs) end
    if ent.SetNPCName then ent:SetNPCName((cfg and cfg.name) or L("npc_default_name")) end
    if ent.SetFloatingText then ent:SetFloatingText((cfg and cfg.floatingText) or "") end
end

function NPCs.CreateNPC(data)
    local defaults = {
        id = "",
        name = L("npc_default_name"),
        model = KrakensStore.Config.Entities.NPC.Model,
        skin = 0,
        bodygroups = {},
        floatingText = "",
        categories = {},
        items = {},
        whitelist = {},
        requiresWhitelist = false,
        order = 0,
        created = os.time(),
        modified = os.time(),
        spawnPos = nil,
        spawnAng = nil,
        spawnMap = nil,
        idleAnim = nil,
    }
    local npc = table.Copy(defaults)
    for k, v in pairs(data or {}) do npc[k] = v end
    return npc
end

function NPCs.Get(npcId)
    return NPCs.Cache[npcId]
end

function NPCs.GetList()
    local list = {}
    for _, npc in pairs(NPCs.Cache) do
        table.insert(list, npc)
    end
    return U.SortByOrder(list)
end

function NPCs.GetItemsForNPC(npcId)
    local npc = NPCs.Get(npcId)
    if not npc then return {} end
    local allItems = KrakensStore.Items.GetAll()
    local result = {}
    local npcItems = npc.items or {}
    local npcCategories = npc.categories or {}
    local hasCategoryFilter = next(npcCategories) ~= nil
    local hasItemFilter = next(npcItems) ~= nil
    if not hasCategoryFilter and not hasItemFilter then
        return allItems
    end
    for itemId, item in pairs(allItems) do
        local include = false
        if npcItems[itemId] then
            include = true
        elseif hasCategoryFilter and item.category and npcCategories[item.category] then
            include = true
        end
        if include then
            result[itemId] = item
        end
    end
    return result
end

function NPCs.CanPlayerAccessNPC(ply, npcId)
    if not IsValid(ply) then return false end
    local npc = NPCs.Get(npcId)
    if not npc then return false end
    return KrakensStore.PassesWhitelist(ply, npc)
end

InstallStoreCRUD(NPCs, {
    kind = "npc",
    dataSave = "SaveNPC", dataDelete = "DeleteNPC",
    postChangeHook = "KrakensStore_StoreDataChanged",
    afterBroadcastUpdate = function(npc) hook.Run("KrakensStore_NPCUpdated", npc.id, npc) end,
    afterBroadcastDelete = function(id) hook.Run("KrakensStore_NPCDeleted", id) end,
})

function NPCs.IsPlacedOnMap(npc, mapName)
    if not npc or not npc.spawnPos or not npc.spawnMap then return false end
    mapName = mapName or game.GetMap()
    return npc.spawnMap == mapName
end

function NPCs.GetPlacedNPCsForMap(mapName)
    mapName = mapName or game.GetMap()
    local result = {}
    for id, npc in pairs(NPCs.Cache) do
        if NPCs.IsPlacedOnMap(npc, mapName) then
            result[id] = npc
        end
    end
    return result
end

if SERVER then
    function NPCs.SpawnAtPos(npcId, pos, ang)
        local ent = ents.Create(KrakensStore.EntityClasses.NPC)
        if not IsValid(ent) then return nil end
        ent:SetPos(pos)
        ent:SetAngles(ang or Angle(0, 0, 0))
        ent:Spawn()
        ent:Activate()
        NPCs.ConfigureEntity(ent, npcId)
        ent.KS_AutoSpawned = true
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then phys:EnableMotion(false) end
        return ent
    end

    function NPCs.RemoveAutoSpawnedByConfigId(npcId)
        NPCs.ForEachEntity(function(ent)
            if ent:GetNPCConfigId() == npcId and ent.KS_AutoSpawned then ent:Remove() end
        end)
    end

    function NPCs.SpawnPlaced()
        local spawnedIds = {}
        NPCs.ForEachEntity(function(ent)
            if ent.KS_AutoSpawned then spawnedIds[ent:GetNPCConfigId()] = true end
        end)
        for npcId, npcData in pairs(NPCs.GetPlacedNPCsForMap(game.GetMap())) do
            if not spawnedIds[npcId] then
                local sp, sa = npcData.spawnPos, npcData.spawnAng
                NPCs.SpawnAtPos(npcId, Vector(sp.x, sp.y, sp.z), sa and Angle(sa.p, sa.y, sa.r))
            end
        end
    end

    hook.Add("PostCleanupMap", "KrakensStore_RespawnNPCs", function()
        timer.Simple(1, NPCs.SpawnPlaced)
    end)
end

function NPCs.ForEachEntity(fn)
    for _, ent in ipairs(ents.FindByClass(KrakensStore.EntityClasses.NPC)) do
        if IsValid(ent) then fn(ent) end
    end
end
