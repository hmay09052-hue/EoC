KrakensStore.types = KrakensStore.types or {}
KrakensStore.AutoFill = KrakensStore.AutoFill or {}

local L = KrakensStore.L
local Types = KrakensStore.types
local AutoFill = KrakensStore.AutoFill

local SafeStr = KF.Utils.SafeString
local function Phrase(name) return CLIENT and language.GetPhrase(name) or tostring(name) end

local function FindMaterialPath(paths)
    for _, p in ipairs(paths) do
        if file.Exists("materials/" .. p, "GAME") then return p end
    end
end

local function ResolveMaterialName(matOrTable)
    if type(matOrTable) == "IMaterial" or (istable(matOrTable) and matOrTable.GetName) then
        local ok, n = pcall(function() return matOrTable:GetName() end)
        if ok and n and n ~= "" and n ~= "__error" then return n end
    end
end

local MATERIAL_PREFIXES = { "", "materials/", "vgui/entities/", "entities/" }
local MATERIAL_EXTS = { ".png", ".vmt", "" }

local function MatPath(v)
    if istable(v) and not v.GetName then return MatPath(v.Material) end
    if not isstring(v) then return ResolveMaterialName(v) end
    if v == "" or string.StartsWith(v, "icon16/") or string.StartsWith(v, "icon32/") then return nil end
    for _, prefix in ipairs(MATERIAL_PREFIXES) do
        for _, ext in ipairs(MATERIAL_EXTS) do
            if file.Exists("materials/" .. prefix .. v .. ext, "GAME") then return prefix .. v .. ext end
        end
    end
    return v
end

function AutoFill.GuessEntityIcon(class)
    if not isstring(class) or class == "" then return nil end
    return FindMaterialPath({ "entities/" .. class .. ".png", "entities/" .. class .. ".vmt", "vgui/entities/" .. class .. ".png" })
end

function AutoFill.GetAttachmentIcon(att, attId)
    if not att then return nil end
    if att.Icon then
        local resolved = ResolveMaterialName(att.Icon)
        if resolved then
            if not resolved:find("%.") then resolved = resolved .. ".png" end
            return resolved
        end
        if type(att.Icon) == "IMaterial" or (istable(att.Icon) and att.Icon.GetName) then
            local tok, texPath = pcall(function()
                local tex = att.Icon:GetTexture("$basetexture")
                return tex and tex:GetName() or nil
            end)
            if tok and texPath and texPath ~= "" then return texPath .. ".png" end
        end
        if isstring(att.Icon) and att.Icon ~= "" then
            local m = Material(att.Icon, "noclamp smooth")
            if m and not m:IsError() then return att.Icon end
        end
    end
    for _, f in ipairs({"IconOverride","AttIcon","MenuIcon","IconMaterial","PreviewIcon"}) do
        local s = att[f]
        if s then
            local p = MatPath(s)
            if p and p ~= "" and not p:find("^icon16/") then
                local m = Material(p, "noclamp smooth")
                if m and not m:IsError() then return p end
            end
        end
    end
    local variants = {
        "arc9/atts/" .. attId, "arc9_atts/" .. attId, "vgui/arc9/" .. attId, "arc9/attachments/" .. attId,
        "arccw/atts/" .. attId, "arccw_atts/" .. attId, "vgui/hud/arccw/" .. attId, "arccw/attachments/" .. attId,
        "entities/" .. attId, "vgui/entities/" .. attId,
        "arc9/att_" .. attId, "arccw/att_" .. attId
    }
    for _, base in ipairs(variants) do
        for _, ext in ipairs({".png", "", ".vmt", ".vtf"}) do
            local full = base .. ext
            if file.Exists("materials/" .. full, "GAME") then
                local m = Material(full, "noclamp smooth")
                if m and not m:IsError() then return full end
            end
        end
    end
    local model = att.Model or att.WorldModel or att.ViewModel
    if model and isstring(model) then
        local nm = string.StripExtension(string.GetFileFromFilename(model))
        local found = FindMaterialPath({ "entities/" .. nm .. ".png", "vgui/entities/" .. nm .. ".png", "arc9/atts/" .. nm .. ".png" })
        if found then return found end
    end
    return AutoFill.GuessEntityIcon(attId)
end

function AutoFill.GetLSCSIcon(item, itemType, itemId)
    if not item then return nil end
    for _, f in ipairs({"icon","Icon","MenuIcon","IconOverride"}) do
        local s = item[f]
        if s then
            local resolved = ResolveMaterialName(s)
            if resolved then return resolved end
            if isstring(s) and s ~= "" then
                local m = Material(s, "noclamp smooth")
                if m and not m:IsError() then return s end
            end
        end
    end
    local found = FindMaterialPath({
        "lscs/hud/" .. itemId .. ".png",
        "lscs/hud/" .. itemType .. "/" .. itemId .. ".png",
        "lscs/icons/" .. itemId .. ".png",
        "lscs/icons/" .. itemType .. "/" .. itemId .. ".png",
        "lscs/" .. itemType .. "/" .. itemId .. ".png",
        "lscs/" .. itemType .. "s/" .. itemId .. ".png",
        "entities/lscs_" .. itemId .. ".png",
        "entities/item_" .. itemType .. "_" .. itemId .. ".png",
        "vgui/lscs/" .. itemId .. ".png",
        "vgui/lscs/" .. itemType .. "/" .. itemId .. ".png"
    })
    if found then return found end
    if item.mdl and isstring(item.mdl) then
        local modelName = string.StripExtension(string.GetFileFromFilename(item.mdl))
        return FindMaterialPath({
            "entities/" .. modelName .. ".png",
            "vgui/entities/" .. modelName .. ".png",
            "lscs/hud/" .. modelName .. ".png"
        })
    end
end

function AutoFill.GetWeaponIcon(wepTable, class)
    if not wepTable then return nil end
    local icon = MatPath(wepTable.IconOverride or wepTable.Icon)
    if icon then return icon end
    return AutoFill.GuessEntityIcon(class)
end

function AutoFill.BuildWeaponDesc(tbl)
    if not istable(tbl) then return "" end
    local d = SafeStr(tbl.Description)
    if d ~= "" then return d end
    local purpose = SafeStr(tbl.Purpose)
    if purpose ~= "" then return purpose end
    if istable(tbl.Trivia) then
        local td = SafeStr(tbl.Trivia.Description or tbl.Trivia.Desc)
        if td ~= "" then return td end
    end
    return ""
end

local LazyNameMT = {
    __index = function(t, k)
        if not isstring(k) then return nil end
        local key = rawget(t, k .. "Key")
        if key then return L(key) end
    end
}

function KrakensStore.LazyName(tbl)
    return setmetatable(tbl, LazyNameMT)
end

function KrakensStore:RegisterType(id, data)
    assert(isstring(id) and id ~= "", "RegisterType: id must be a non-empty string")
    assert(istable(data), "RegisterType: data must be a table")

    data.id = id
    data.stacking = data.stacking or false
    data.noDuplicates = data.noDuplicates or false
    data.equip = data.equip or false
    data.uniqueEquip = data.uniqueEquip or false
    data.options = data.options or {}
    data.settings = data.settings or {}

    for _, setting in ipairs(data.settings) do
        KrakensStore.LazyName(setting)
    end

    if data.nameKey then
        KrakensStore.LazyName(data)
    else
        data.name = data.name or id
    end

    Types[id] = data
    hook.Run("KrakensStore_TypeRegistered", id, data)
    return data
end

function KrakensStore:IsTypeAvailable(id)
    local def = Types[id]
    if not def then return false end
    if def.available then return def.available() end
    if def.integration then return KrakensStore.Integrations.IsAvailable(def.integration) end
    return true
end

KrakensStore.TypeHelpers = KrakensStore.TypeHelpers or {}
local TH = KrakensStore.TypeHelpers

local function CachedOptions(ttl, fetch)
    local cache, cacheAt
    return function()
        if cache and CurTime() - cacheAt < ttl then return cache end
        local options = fetch()
        table.sort(options, function(a, b) return a.name < b.name end)
        cache, cacheAt = options, CurTime()
        return options
    end
end

function KrakensStore.TypeHelpers.GetUnlockedAttachmentStore(ply, system, create)
    if not IsValid(ply) then return nil end
    if not isstring(system) or system == "" then return nil end

    local data = ply.KrakensStoreData
    if not create then
        if not data or not data.unlockedAttachments or not data.unlockedAttachments[system] then return nil end
        return data.unlockedAttachments[system], data
    end

    data = data or {}
    data.unlockedAttachments = data.unlockedAttachments or {}
    data.unlockedAttachments[system] = data.unlockedAttachments[system] or {}
    ply.KrakensStoreData = data

    return data.unlockedAttachments[system], data
end

function KrakensStore.TypeHelpers.HasUnlockedAttachment(ply, system, attachmentId)
    if not IsValid(ply) then return false end
    if not isstring(attachmentId) or attachmentId == "" then return false end

    local unlocked = KrakensStore.TypeHelpers.GetUnlockedAttachmentStore(ply, system)
    if not unlocked then return false end

    return unlocked[attachmentId] == true
end

function KrakensStore.TypeHelpers.MarkAttachmentUnlocked(ply, system, attachmentId)
    if not SERVER then return false end
    if not IsValid(ply) then return false end
    if not isstring(attachmentId) or attachmentId == "" then return false end

    local unlocked, data = KrakensStore.TypeHelpers.GetUnlockedAttachmentStore(ply, system, true)
    if not unlocked then return false end

    if unlocked[attachmentId] == true then
        return false
    end

    unlocked[attachmentId] = true
    KrakensStore.Data.SavePlayerData(ply:SteamID64(), data)

    return true
end

function KrakensStore.TypeHelpers.ValidateWorkbenchRequirement(ply, itemTable, fallbackKey)
    if not SERVER or not istable(itemTable) then return true end
    local typeData = Types[itemTable.type]
    if not (typeData and KrakensStore.Integrations.AttachmentSystems[typeData.integration]) then return true end
    if KrakensStore.Workbench.CanCustomize(ply) then return true end
    return false, L(fallbackKey or "err_cannot_use_item")
end

local function WeaponOnChoose(index, text, data, fields)
    local wep = weapons.Get(data)
    if wep then
        return {
            name = wep.PrintName or data,
            description = AutoFill.BuildWeaponDesc(wep),
            model = wep.WorldModel ~= "" and wep.WorldModel or nil,
            icon = AutoFill.GetWeaponIcon(wep, data)
        }
    end
end

local function GivePermWeapon(ply, itemData)
    local wc = itemData.weaponClass
    if not wc then return end
    local wep = ply:HasWeapon(wc) and ply:GetWeapon(wc) or ply:Give(wc)
    if IsValid(wep) then
        wep.KrakensStore_Permanent = true
        wep.ignoreInv = true
    end
end

local function StripPermWeapon(ply, itemData)
    local wc = itemData.weaponClass
    local wep = wc and ply:GetWeapon(wc)
    if IsValid(wep) and wep.KrakensStore_Permanent then ply:StripWeapon(wc) end
end

local function RegisterWeaponTypes(weaponId, permId, cfg)
    KrakensStore:RegisterType(weaponId, {
        nameKey = cfg.weaponName,
        stacking = true,
        integration = cfg.integration,
        options = {
            ["use"] = {
                requireWorkbench = false,
                removeItem = true,
                check = function(ply, data)
                    if not ply:Alive() then return false, L("type_must_be_alive") end
                    if data.weaponClass and ply:HasWeapon(data.weaponClass) then return false, L("type_already_have_weapon") end
                    return true
                end,
                func = function(ply, data)
                    return data.weaponClass ~= nil and IsValid(ply:Give(data.weaponClass))
                end
            }
        },
        settings = { cfg.setting }
    })

    KrakensStore:RegisterType(permId, {
        nameKey = cfg.permName,
        noDuplicates = true,
        equip = true,
        integration = cfg.integration,
        onEquip = GivePermWeapon,
        onUnequip = StripPermWeapon,
        settings = { cfg.setting }
    })
end

function KrakensStore:ValidateTypeSettings(typeId, itemData)
    local typeData = Types[typeId]
    if not typeData then return true end

    for _, setting in ipairs(typeData.settings or {}) do
        local value = itemData[setting.key]

        if setting.required and (value == nil or value == "" or value == false) then
            return false, string.format(L("err_field_required"), setting.name)
        end

        if value ~= nil and value ~= "" then
            if setting.type == "number" then
                local num = tonumber(value)
                if not num then
                    return false, string.format(L("err_field_invalid"), setting.name)
                end
                if setting.min and num < setting.min then
                    return false, string.format(L("err_field_invalid"), setting.name)
                end
                if setting.max and num > setting.max then
                    return false, string.format(L("err_field_invalid"), setting.name)
                end
                itemData[setting.key] = num
            end

            if setting.validateOption then
                local valid, err = setting.validateOption(itemData[setting.key], itemData)
                if not valid then
                    return false, err or string.format(L("err_field_invalid"), setting.name)
                end
            end
        end
    end

    return true
end

local function MissingIntegration(typeData)
    if not typeData.integration or KrakensStore:IsTypeAvailable(typeData.id) then return nil end
    local globals = KrakensStore.Integrations.Globals[typeData.integration]
    return string.format(L("type_integration_not_installed"), globals and globals[#globals] or typeData.integration)
end

function KrakensStore:ExecuteOption(ply, optionId, itemTable, invItem, itemIndex, ...)
    if not IsValid(ply) then return false, L("err_invalid_player") end
    if not itemTable then return false, L("err_unknown_item_type") end

    local typeData = Types[itemTable.type]
    if not typeData then return false, L("err_unknown_item_type") end

    local option = typeData.options[optionId]
    if not option then return false, L("err_unknown_option") end

    local missing = MissingIntegration(typeData)
    if missing then return false, missing end

    local itemId = itemTable.id

    if SERVER then
        local canAccess, accessErr = KrakensStore.Inventory.CanAccessItem(ply, itemId, itemTable)
        if not canAccess then
            return false, accessErr or L("err_no_item_access")
        end
    end

    if SERVER then
        local requiresWorkbench = option.requireWorkbench
        if requiresWorkbench == nil then requiresWorkbench = true end
        if requiresWorkbench then
            local canUseWithWorkbench, workbenchReason = KrakensStore.TypeHelpers.ValidateWorkbenchRequirement(ply, itemTable, "err_cannot_use_item")
            if canUseWithWorkbench == false then
                return false, workbenchReason
            end
        end
    end

    local itemData = itemTable.data or {}

    if option.check then
        local checkOk, allowed, reason = pcall(option.check, ply, itemData, invItem)
        if not checkOk then
            ErrorNoHaltWithStack("[KrakensStore] option.check error: " .. tostring(allowed))
            return false, L("err_cannot_use_item")
        end
        if allowed == false then
            return false, reason or L("err_cannot_use_item")
        end
    end

    local hookAllowed, hookReason = hook.Run("KrakensStore_CanPlayerUseOption", ply, optionId, invItem, itemTable, typeData)
    if hookAllowed == false then
        return false, hookReason or L("err_cannot_use_item")
    end

    if not option.func then return false, L("err_no_function_defined") end

    local funcOk, success, reason = pcall(option.func, ply, itemData, invItem, ...)
    if not funcOk then
        ErrorNoHaltWithStack("[KrakensStore] option.func error: " .. tostring(success))
        return false, L("err_cannot_use_item")
    end
    if success == false then return false, reason or L("err_cannot_use_item") end

    hook.Run("KrakensStore_PlayerUsedOption", ply, itemId, optionId, itemTable, invItem)
    return true, nil, option.removeItem == true
end

function KrakensStore:CanPlayerPurchase(ply, itemTable)
    if not IsValid(ply) then return false, L("err_invalid_player") end
    if not itemTable then return false, L("err_unknown_item_type") end

    local typeData = Types[itemTable.type]
    if not typeData then return true end

    local missing = MissingIntegration(typeData)
    if missing then return false, missing end

    if typeData.customCheck then
        local ok, allowed, reason = pcall(typeData.customCheck, ply, itemTable)
        if not ok then
            KrakensStore.Log("error", "customCheck error for type '" .. tostring(itemTable.type) .. "': " .. tostring(allowed))
            return false, L("err_cannot_purchase")
        end
        if allowed == false then
            return false, reason
        end
    end

    if typeData.canPurchase then
        local ok, allowed, reason = pcall(typeData.canPurchase, ply, itemTable, itemTable.data)
        if not ok then
            KrakensStore.Log("error", "canPurchase error for type '" .. tostring(itemTable.type) .. "': " .. tostring(allowed))
            return false, L("err_cannot_purchase")
        end
        if allowed == false then
            return false, reason
        end
    end

    return true
end

function KrakensStore:GetTypeSettings(typeId)
    local typeData = Types[typeId]
    return typeData and typeData.settings or {}
end

KrakensStore.Integrations = KrakensStore.Integrations or {}
KrakensStore.Integrations.AttachmentSystems = KrakensStore.Integrations.AttachmentSystems or {}

KrakensStore.Integrations.Globals = {
    arc9 = { "ARC9" }, arccw = { "ArcCW" }, lscs = { "LSCS" }, lvs = { "LVS" },
    simfphys = { "simfphys" }, wiltos = { "WOS", "WiltOS" }, darkrp = { "DarkRP" },
}

function KrakensStore.Integrations.Global(name)
    for _, globalName in ipairs(KrakensStore.Integrations.Globals[name] or { name }) do
        if _G[globalName] ~= nil then return _G[globalName] end
    end
end

function KrakensStore.Integrations.IsAvailable(name)
    return KrakensStore.Integrations.Global(name) ~= nil
end

function KrakensStore.Integrations.DetectWeaponSystem(weapon)
    if not IsValid(weapon) then return nil end
    for key, cfg in pairs(KrakensStore.Integrations.AttachmentSystems) do
        if KrakensStore.Integrations.IsAvailable(key) and cfg.weaponDetect(weapon) then return key end
    end
end

function KrakensStore.Integrations.IsAttachmentBlacklisted(system, attId)
    local cfg = KrakensStore.Integrations.AttachmentSystems[system]
    if not attId or not cfg then return false end
    local blacklist = cfg.GetBlacklist()
    return blacklist[string.lower(string.Trim(tostring(attId)))] == true or blacklist[attId] == true
end

function KrakensStore.Integrations.GiveAttachment(system, ply, attId)
    local g = KrakensStore.Integrations.Global(system)
    if not (attId and g and g.PlayerGiveAtt and g.PlayerGetAtts) then return false end
    if KrakensStore.Integrations.IsAttachmentBlacklisted(system, attId) then return false end
    local ok, owned = pcall(function()
        local before = tonumber(g:PlayerGetAtts(ply, attId)) or 0
        g:PlayerGiveAtt(ply, attId, 1)
        local after = tonumber(g:PlayerGetAtts(ply, attId)) or 0
        if after <= 0 and before <= 0 then
            g:PlayerGiveAtt(ply, attId, 1)
            after = tonumber(g:PlayerGetAtts(ply, attId)) or 0
        end
        return after > 0 or before > 0
    end)
    return ok and owned
end

function KrakensStore.Integrations.SendAttachmentInventory(system, ply)
    local g = KrakensStore.Integrations.Global(system)
    if g and g.PlayerSendAttInv then g:PlayerSendAttInv(ply) end
end

function KrakensStore.TypeHelpers.RegisterAttachmentIntegration(cfg)
    KrakensStore.Integrations.AttachmentSystems[cfg.key] = cfg

    function cfg.GetBlacklist()
        return KrakensStore.Config.Integrations[cfg.name].AccessoryBlacklist
    end

    function cfg.GetAttTable()
        local g = KrakensStore.Integrations.Global(cfg.key)
        return g and g[cfg.attTableKey]
    end

    local attNameFn = cfg.attName or function(attData, attId)
        return attData.PrintName or attId
    end

    local resolveSearchFn = cfg.resolveSearchName or function(attData)
        return attData and attData.PrintName
    end

    local function ResolveAttachmentId(rawId)
        if rawId == nil then return nil end
        local attId = string.Trim(tostring(rawId))
        if attId == "" then return nil end

        local tbl = cfg.GetAttTable()
        if tbl then
            if tbl[attId] then return attId end
            local needle = string.lower(attId)
            for id, attData in pairs(tbl) do
                if string.lower(tostring(id)) == needle then return id end
                local printName = resolveSearchFn(attData)
                if isstring(printName) and string.lower(printName) == needle then return id end
            end
        end

        return cfg.resolveFallback and cfg.resolveFallback(attId) or attId
    end

    local function ExtractAttachmentId(data)
        if not istable(data) then return nil end
        return ResolveAttachmentId(data.attachmentId)
    end

    local function IsExternalOwnership(ply, attId)
        local g = KrakensStore.Integrations.Global(cfg.key)
        if not (g and g.PlayerGetAtts) then return false end
        local cv = GetConVar(cfg.freeCvar)
        if cv and cv:GetBool() then return false end
        local owned = g:PlayerGetAtts(ply, attId)
        return owned and owned > 0
    end

    local lk = cfg.langKeys

    local function CanUnlock(ply, data)
        local attId = ExtractAttachmentId(data)
        if not attId then return false, L("type_err_attachment_required") end
        if KrakensStore.Integrations.IsAttachmentBlacklisted(cfg.key, attId) then return false, L("type_attachment_blacklisted") end
        if TH.HasUnlockedAttachment(ply, cfg.key, attId) or IsExternalOwnership(ply, attId) then return false, L(lk.alreadyOwnAtt) end
        return true
    end

    local function CanPurchase(ply, itemTable, data)
        return CanUnlock(ply, data)
    end

    local unlockOption = {
        requireWorkbench = false,
        removeItem = true,
        check = CanUnlock,
        func = function(ply, data)
            local attId = ExtractAttachmentId(data)
            if not (attId and KrakensStore.Integrations.GiveAttachment(cfg.key, ply, attId)) then return false end
            KrakensStore.Integrations.SendAttachmentInventory(cfg.key, ply)
            TH.MarkAttachmentUnlocked(ply, cfg.key, attId)
            return true
        end
    }

    RegisterWeaponTypes(cfg.typeIds.weapon, cfg.typeIds.permWeapon, {
        weaponName = lk.weaponName,
        permName = lk.permWeaponName,
        integration = cfg.key,
        setting = {
            key = "weaponClass",
            nameKey = lk.settingWeapon,
            descKey = lk.settingWeaponDesc,
            type = "combo",
            required = true,
            searchable = true,
            getOptions = CachedOptions(30, function()
                local options = {}
                for _, wep in pairs(weapons.GetList()) do
                    if cfg.weaponDetect(wep) and wep.ClassName and wep.Spawnable ~= false then
                        options[#options + 1] = { name = wep.PrintName or wep.ClassName, value = wep.ClassName }
                    end
                end
                return options
            end),
            onChoose = WeaponOnChoose,
        }
    })

    local attachmentSetting = {
        key = "attachmentId",
        nameKey = lk.settingAttachment,
        descKey = "type_setting_attachment_desc",
        type = "combo",
        required = true,
        searchable = true,
        getOptions = CachedOptions(30, function()
            local options = {}
            for attId, attData in pairs(cfg.GetAttTable() or {}) do
                options[#options + 1] = { name = attNameFn(attData, attId), value = attId }
            end
            return options
        end),
        onChoose = function(index, text, data)
            local att = (cfg.GetAttTable() or {})[data]
            if not att then return end
            return {
                name = attNameFn(att, data),
                description = att.Description or "",
                model = att.Model or att.WorldModel,
                icon = AutoFill.GetAttachmentIcon(att, data)
            }
        end,
    }

    KrakensStore:RegisterType(cfg.typeIds.attachment, {
        nameKey = lk.attachmentName,
        stacking = true,
        integration = cfg.key,
        canPurchase = CanPurchase,
        options = { ["unlock"] = unlockOption },
        settings = { attachmentSetting }
    })

    KrakensStore:RegisterType(cfg.typeIds.permAttachment, {
        nameKey = lk.permAttachmentName,
        noDuplicates = true,
        integration = cfg.key,
        canPurchase = CanPurchase,
        options = { ["unlock"] = unlockOption },
        settings = { attachmentSetting }
    })

    function cfg.EnsureUnlocked(ply)
        local g = KrakensStore.Integrations.Global(cfg.key)
        if not (g and g.PlayerGetAtts) then return end
        local given = false
        for attId, enabled in pairs(TH.GetUnlockedAttachmentStore(ply, cfg.key) or {}) do
            local normalizedAttId = enabled == true and ResolveAttachmentId(attId)
            if normalizedAttId and (tonumber(g:PlayerGetAtts(ply, normalizedAttId)) or 0) <= 0 then
                given = KrakensStore.Integrations.GiveAttachment(cfg.key, ply, normalizedAttId) or given
            end
        end
        if given then KrakensStore.Integrations.SendAttachmentInventory(cfg.key, ply) end
    end
end

function KrakensStore.Integrations.RestoreUnlocks(ply)
    if not SERVER or not IsValid(ply) then return end
    for _, cfg in pairs(KrakensStore.Integrations.AttachmentSystems) do cfg.EnsureUnlocked(ply) end
end

KrakensStore.BuffDefs = KrakensStore.BuffDefs or {}

KrakensStore.BuffDefs.Types = {
    max_health = KrakensStore.LazyName({ nameKey = "buff_max_health", unit = "HP" }),
    health_regen = KrakensStore.LazyName({ nameKey = "buff_health_regen", unit = "HP/s" }),
    max_armor = KrakensStore.LazyName({ nameKey = "buff_max_armor", unit = "AP" }),
    armor_regen = KrakensStore.LazyName({ nameKey = "buff_armor_regen", unit = "AP/s" }),
    speed = KrakensStore.LazyName({ nameKey = "buff_speed", unit = "%" }),
    jump_power = KrakensStore.LazyName({ nameKey = "buff_jump", unit = "%" }),
    damage_bonus = KrakensStore.LazyName({ nameKey = "buff_damage", unit = "%" }),
    damage_resistance = KrakensStore.LazyName({ nameKey = "buff_damage_resist", unit = "%" }),
    gravity = KrakensStore.LazyName({ nameKey = "buff_gravity", unit = "%" }),
    fall_damage = KrakensStore.LazyName({ nameKey = "buff_fall_damage", unit = "%" }),
}

KrakensStore.TypeHelpers.RegisterAttachmentIntegration({
    key = "arc9",
    name = "ARC9",
    freeCvar = "arc9_free_atts",
    attTableKey = "Attachments",
    weaponDetect = function(wep)
        local isARC9 = wep.ARC9 or (wep.Category and string.find(wep.Category, "ARC9")) or (wep.GetSubCategory and wep.ARC9 ~= nil)
        return isARC9 and not wep.LVS
    end,
    resolveFallback = function(attId)
        local g = KrakensStore.Integrations.Global("arc9")
        local attData = g and g.GetAttTable and g.GetAttTable(attId)
        return attData and attData.ShortName
    end,
    typeIds = {
        weapon = "weapon_arc9",
        permWeapon = "permarc9weapon",
        attachment = "attachment_arc9",
        permAttachment = "permattachment_arc9"
    },
    langKeys = {
        weaponName = "type_arc9_weapon_name",
        permWeaponName = "type_arc9_permweapon_name",
        attachmentName = "type_arc9_attachment_name",
        permAttachmentName = "type_arc9_permattachment_name",
        settingWeapon = "type_setting_arc9_weapon",
        settingWeaponDesc = "type_setting_arc9_weapon_desc",
        settingAttachment = "type_setting_arc9_attachment",
        alreadyOwnAtt = "type_already_own_attachment_arc9"
    }
})

KrakensStore.TypeHelpers.RegisterAttachmentIntegration({
    key = "arccw",
    name = "ArcCW",
    freeCvar = "arccw_attinv_free",
    attTableKey = "AttachmentTable",
    attName = function(attData, attId)
        return attData.PrintName or attData.ShortName or attId
    end,
    resolveSearchName = function(attData)
        return attData and (attData.PrintName or attData.ShortName)
    end,
    weaponDetect = function(wep)
        return wep.ArcCW or (wep.Category and string.find(wep.Category, "ArcCW")) or wep.RegularClipSize
    end,
    typeIds = {
        weapon = "weapon_arccw",
        permWeapon = "permarccwweapon",
        attachment = "attachment_arccw",
        permAttachment = "permattachment_arccw"
    },
    langKeys = {
        weaponName = "type_arccw_weapon_name",
        permWeaponName = "type_arccw_permweapon_name",
        attachmentName = "type_arccw_attachment_name",
        permAttachmentName = "type_arccw_permattachment_name",
        settingWeapon = "type_setting_arccw_weapon",
        settingWeaponDesc = "type_setting_arccw_weapon_desc",
        settingAttachment = "type_setting_arccw_attachment",
        alreadyOwnAtt = "type_already_own_attachment_arccw"
    }
})

local function CreateStatBoostType(typeId, cfg)
    KrakensStore:RegisterType(typeId, {
        nameKey = cfg.nameKey,
        stacking = true,
        options = {
            ["use"] = {
                removeItem = true,
                check = function(ply)
                    if not ply:Alive() then return false, L("type_must_be_alive") end
                    if cfg.isFull(ply) then return false, L("type_already_at_max") end
                    return true
                end,
                func = function(ply, data)
                    cfg.apply(ply, math.max(tonumber(data[cfg.key]) or 100, 1))
                    return true
                end
            }
        },
        settings = {
            {
                key = cfg.key,
                nameKey = cfg.settingName,
                descKey = cfg.settingDesc,
                type = "number",
                default = 100,
                min = 1,
                max = cfg.max,
                required = true,
            }
        }
    })
end

CreateStatBoostType("armor", {
    key = "armor",
    nameKey = "type_armor_name",
    settingName = "type_setting_armor_amount", settingDesc = "type_setting_armor_amount_desc",
    max = KrakensStore.Validation.Limits.MAX_ARMOR,
    isFull = function(ply) return ply:Armor() >= math.max(ply:GetMaxArmor(), 1) end,
    apply = function(ply, amt) ply:SetArmor(math.min(ply:Armor() + amt, math.max(ply:GetMaxArmor(), ply:Armor()))) end
})

CreateStatBoostType("health", {
    key = "health",
    nameKey = "type_health_name",
    settingName = "type_setting_health_amount", settingDesc = "type_setting_health_amount_desc",
    isFull = function(ply) return ply:Health() >= ply:GetMaxHealth() end,
    apply = function(ply, amt) ply:SetHealth(math.min(ply:Health() + amt, math.max(ply:Health(), ply:GetMaxHealth()))) end
})

local BOOSTER_BUFFS = { "max_health", "max_armor", "speed", "damage_bonus", "jump_power" }

local function ResolveBuffId(action)
    return isstring(action) and KrakensStore.BuffDefs.Types[action] and action or nil
end

local function BoosterLimit(buffId)
    local meta = KrakensStore.BuffDefs.Types[buffId]
    local unit = meta and meta.unit or "%"
    return unit == "%" and 100 or 1000, unit
end

local function ApplyBooster(ply, itemData, invItem, apply)
    local buffId = ResolveBuffId(itemData.action)
    if not buffId then return end
    local pct = math.Clamp(tonumber(itemData.percents) or 0, 0, (BoosterLimit(buffId)))
    if pct <= 0 then return end

    local itemId = invItem and invItem.itemId
    if apply then
        KrakensStore.Buffs.ApplyBuff(ply, buffId, pct, itemId)
    else
        KrakensStore.Buffs.RemoveBuff(ply, buffId, itemId)
    end
end

KrakensStore:RegisterType("permbooster", {
    nameKey = "type_booster_name",
    noDuplicates = true,
    equip = true,
    onEquip = function(ply, itemData, invItem) ApplyBooster(ply, itemData, invItem, true) end,
    onUnequip = function(ply, itemData, invItem) ApplyBooster(ply, itemData, invItem, false) end,
    settings = {
        {
            key = "action",
            nameKey = "type_setting_variable",
            descKey = "type_setting_variable_desc",
            type = "combo",
            required = true,
            getOptions = function()
                local options = {}
                for _, buffId in ipairs(BOOSTER_BUFFS) do
                    local meta = KrakensStore.BuffDefs.Types[buffId]
                    if meta then options[#options + 1] = { name = meta.name, value = buffId } end
                end
                return options
            end,
            onChoose = function(index, text, data)
                local meta = KrakensStore.BuffDefs.Types[ResolveBuffId(data)]
                local label = meta and meta.name or text
                return { name = label .. L("type_booster_suffix") }
            end,
            validateOption = function(data)
                if not ResolveBuffId(data) then return false, L("type_err_variable_required") end
                return true
            end
        },
        {
            key = "percents",
            nameKey = "type_setting_booster_amount",
            descKey = "type_setting_booster_amount_desc",
            type = "number",
            default = 20,
            min = 1,
            max = 1000,
            required = true,
            placeholder = "20",
            validateOption = function(value, itemData)
                local limit, unit = BoosterLimit(ResolveBuffId(itemData.action))
                if value > limit then
                    return false, string.format(L("type_err_booster_range"), limit, unit)
                end
                return true
            end,
        }
    }
})

local function SanitizePlaceholderValue(val)
    val = tostring(val or "")
    val = val:gsub("[\r\n]", " ")
    val = val:gsub("[;\"%']", "")
    return (val:gsub("%%", "%%%%"))
end

local function IsCommandAllowed(cmd)
    if not isstring(cmd) or cmd == "" then return false end
    local allowlist = KrakensStore.Config.General.CommandAllowlist
    if not istable(allowlist) then return false end
    return allowlist[cmd] == true
end

KrakensStore:RegisterType("runconsolecommand", {
    nameKey = "type_command_name",
    stacking = true,
    options = {
        ["use"] = {
            removeItem = true,
            func = function(ply, data)
                if CLIENT then return false end
                local command = data.command
                if not command then return false end

                command = command:gsub("{steamid64}", SanitizePlaceholderValue(ply:SteamID64()))
                command = command:gsub("{steamid}", SanitizePlaceholderValue(ply:SteamID()))
                command = command:gsub("{userid}", SanitizePlaceholderValue(ply:UserID()))
                command = command:gsub("{name}", "\"" .. SanitizePlaceholderValue(ply:Nick()) .. "\"")
                command = command:Trim()

                command = command:gsub("[;\r\n]", " ")
                command = command:gsub("&&", " ")
                command = command:gsub("||", " ")
                local args = string.Explode(" ", command)
                local cmd = string.lower(args[1] or "")
                if not IsCommandAllowed(cmd) then return false end

                game.ConsoleCommand(command .. "\n")
                return true
            end
        }
    },
    settings = {
        {
            key = "command",
            nameKey = "type_setting_command",
            descKey = "type_setting_command_desc",
            type = "string",
            required = true,
            placeholder = "say Player {name} used an item!",
            validateOption = function(data)
                if not isstring(data) then
                    return false, L("type_err_command_required")
                end

                local args = string.Explode(" ", data)
                local cmd = string.lower(args[1] or "")

                if not IsCommandAllowed(cmd) then
                    return false, L("type_err_command_blocked") .. cmd .. "\""
                end

                return true
            end
        }
    }
})

local function RunCustomHooks(generic, suffix, ply, itemData, invItem)
    local result = hook.Run("KrakensStore_CustomItem" .. generic, ply, itemData, invItem)
    local hookName = itemData.hookName
    if hookName and hookName ~= "" then
        local specific = hook.Run("KrakensStore_Item_" .. hookName .. "_" .. suffix, ply, itemData, invItem)
        if specific ~= nil then result = specific end
    end
    return result
end

KrakensStore:RegisterType("custom", {
    nameKey = "type_custom_name",
    equip = true,
    onEquip = function(ply, itemData, invItem) RunCustomHooks("Equipped", "Equip", ply, itemData, invItem) end,
    onUnequip = function(ply, itemData, invItem) RunCustomHooks("Unequipped", "Unequip", ply, itemData, invItem) end,
    onLoadout = function(ply, itemData, invItem) RunCustomHooks("Loadout", "Loadout", ply, itemData, invItem) end,
    options = {
        ["use"] = {
            removeItem = false,
            func = function(ply, data, invItem)
                local result = RunCustomHooks("Used", "Use", ply, data, invItem)
                if result == nil then return false, L("type_custom_no_handler") end
                return result
            end
        }
    },
    settings = {
        {
            key = "hookName",
            nameKey = "type_setting_hook_name",
            descKey = "type_setting_hook_name_desc",
            type = "string",
            placeholder = "my_custom_item",
            validateOption = function(value)
                if not KrakensStore.Validation.HookName(value) then
                    return false, L("type_err_hook_invalid")
                end
                return true
            end
        }
    }
})

KrakensStore:RegisterType("entity", {
    nameKey = "type_entity_name",
    stacking = true,
    options = {
        ["spawn"] = {
            removeItem = true,
            check = function(ply, data)
                if not ply:Alive() then
                    return false, L("type_must_be_alive")
                end
                if (ply.KS_LastEntitySpawn or 0) > CurTime() then
                    return false, L("err_cannot_use_item")
                end
                return true
            end,
            func = function(ply, data)
                local entClass = data.entclass
                if not entClass then return false end
                if not list.GetForEdit("SpawnableEntities")[entClass] then return false end

                if not ply:CheckLimit("sents") then return false, L("type_err_entity_limit") end
                if hook.Run("PlayerSpawnSENT", ply, entClass) == false then
                    return false, L("type_err_entity_blocked")
                end

                local ent = ents.Create(entClass)
                if not IsValid(ent) then return false end

                KrakensStore.Utils.PlaceInFront(ent, ply, util.QuickTrace(ply:GetShootPos(), ply:GetAimVector() * 300, ply))
                ent:Spawn()
                ent:Activate()
                ent:SetCreator(ply)
                if ent.CPPISetOwner then ent:CPPISetOwner(ply) end

                ply:AddCount("sents", ent)
                ply:AddCleanup("sents", ent)
                undo.Create("SENT")
                    undo.AddEntity(ent)
                    undo.SetPlayer(ply)
                undo.Finish()

                hook.Run("PlayerSpawnedSENT", ply, ent)

                ply.KS_LastEntitySpawn = CurTime() + 3
                return true
            end
        }
    },
    settings = {
        {
            key = "entclass",
            nameKey = "type_setting_entity",
            descKey = "type_setting_entity_desc",
            type = "combo",
            required = true,
            getOptions = CachedOptions(30, function()
                local options = {}
                for id, data in pairs(list.GetForEdit("SpawnableEntities")) do
                    if data.PrintName then options[#options + 1] = { name = Phrase(data.PrintName), value = id } end
                end
                return options
            end),
            onChoose = function(index, text, data, fields)
                local ent = list.GetForEdit("SpawnableEntities")[data]
                if ent then
                    return {
                        name = Phrase(ent.PrintName or L("ui_unknown")),
                        model = ent.WorldModel or ent.Model,
                        icon = AutoFill.GuessEntityIcon(data)
                    }
                end
            end,
            validateOption = function(data)
                if not list.GetForEdit("SpawnableEntities")[data] then return false, L("type_err_entity_invalid") end
                return true
            end
        }
    }
})

local function ApplyStoreModel(ply, model)
    if not model or ply:GetModel() == model then return end
    if not ply.KrakensStore_OldModel then
        ply.KrakensStore_OldModel = ply:GetModel()
    end
    ply:SetModel(model)
    ply:SetupHands()
end

KrakensStore:RegisterType("permmodel", {
    nameKey = "type_permmodel_name",
    noDuplicates = true,
    equip = true,
    uniqueEquip = true,
    onEquip = function(ply, itemData, invItem)
        ApplyStoreModel(ply, itemData.model)
    end,
    onUnequip = function(ply, itemData, invItem)
        if ply.KrakensStore_OldModel then
            ply:SetModel(ply.KrakensStore_OldModel)
            ply:SetupHands()
            ply.KrakensStore_OldModel = nil
        end
    end,
    onLoadout = function(ply, itemData, invItem)
        local model = itemData.model
        if not model then return end
        timer.Simple(engine.TickInterval() * 10, function()
            if IsValid(ply) then ApplyStoreModel(ply, model) end
        end)
    end,
    settings = {
        {
            key = "model",
            nameKey = "type_setting_model",
            descKey = "type_setting_model_desc",
            type = "combo",
            required = true,
            getOptions = CachedOptions(30, function()
                local options = {}
                for name, path in pairs(player_manager.AllValidModels()) do
                    options[#options + 1] = { name = name, value = path }
                end
                return options
            end),
            onChoose = function(index, text, data, fields)
                local name
                for n, p in pairs(player_manager.AllValidModels() or {}) do
                    if p == data then name = n break end
                end
                return { name = name, model = data }
            end,
            validateOption = function(value)
                if not KrakensStore.Validation.PlayerModelPath(value) then
                    return false, L("type_err_model_invalid")
                end
                return true
            end
        }
    }
})

RegisterWeaponTypes("weapon", "permweapon", {
    weaponName = "type_weapon_name",
    permName = "type_permweapon_name",
    setting = {
        key = "weaponClass",
        nameKey = "type_setting_weapon",
        descKey = "type_setting_weapon_desc",
        type = "combo",
        required = true,
        getOptions = CachedOptions(30, function()
            local options = {}
            for _, data in pairs(weapons.GetList()) do
                if data.ClassName and data.Spawnable ~= false and data.PrintName then
                    options[#options + 1] = { name = (data.Category or "Other") .. " | " .. Phrase(data.PrintName), value = data.ClassName }
                end
            end
            return options
        end),
        onChoose = WeaponOnChoose,
        validateOption = function(data)
            if not weapons.Get(data) then return false, L("type_err_weapon_invalid") end
            return true
        end
    }
})

if SERVER then
    hook.Add("canDropWeapon", "KrakensStore_PermWeapon", function(ply, weapon)
        if IsValid(weapon) and weapon.KrakensStore_Permanent then
            return false
        end
    end)
end

local function IsRankAllowed(group)
    if not KrakensStore.IsValidRankName(group) then return false end
    local allowed = KrakensStore.Config.Permissions.PurchasableRanks
    if not istable(allowed) then return false end
    local lower = string.lower(group)
    for _, g in ipairs(allowed) do
        if string.lower(g) == lower then return true end
    end
    return false
end

local function SetPlayerRank(ply, group, bypassAllowlist)
    if not IsValid(ply) or not isstring(group) then return false end
    if not bypassAllowlist and not IsRankAllowed(group) then return false end

    ply.KS_RankChangeFromStore = group

    if istable(sam) then
        ply:SetUserGroup(group)
        if ply.sam_setrank then ply:sam_setrank(group) end
    elseif istable(sAdmin) and sAdmin.setRank then
        sAdmin.setRank(ply, group)
    elseif istable(serverguard) and istable(serverguard.player) and serverguard.player.SetRank then
        serverguard.player:SetRank(ply, group)
    elseif istable(xAdmin) and xAdmin.SetGroup then
        xAdmin.SetGroup(ply, group)
    else
        ply:SetUserGroup(group)
    end

    timer.Simple(0, function()
        if IsValid(ply) and ply.KS_RankChangeFromStore == group then
            ply.KS_RankChangeFromStore = nil
        end
    end)
    return true
end

local function EnsureInitRank(ply)
    if not ply.KrakensStore_InitRank then
        ply.KrakensStore_InitRank = ply:GetUserGroup()
    end
end

local function ApplyStoreRank(ply)
    for itemId in pairs(KrakensStore.Inventory.GetEquippedItems(ply)) do
        local storeItem = KrakensStore.Items.Get(itemId)
        if storeItem and storeItem.type == "permrank" then
            local rank = storeItem.data and storeItem.data.rank
            if rank then SetPlayerRank(ply, rank) end
            break
        end
    end
end

KrakensStore:RegisterType("permrank", {
    nameKey = "type_permrank_name",
    noDuplicates = true,
    equip = true,
    uniqueEquip = true,
    onEquip = function(ply, itemData, invItem)
        EnsureInitRank(ply)
        local rank = itemData.rank
        if rank then SetPlayerRank(ply, rank) end
    end,
    onUnequip = function(ply, itemData, invItem)
        if ply.KrakensStore_InitRank then
            SetPlayerRank(ply, ply.KrakensStore_InitRank, true)
        end
    end,
    onLoadout = function(ply, itemData, invItem)
        EnsureInitRank(ply)
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            local rank = itemData and itemData.rank
            if rank then SetPlayerRank(ply, rank) end
        end)
    end,
    settings = {
        {
            key = "rank",
            nameKey = "type_setting_rank",
            descKey = "type_setting_rank_desc",
            type = "string",
            required = true,
            placeholder = "vip",
            validateOption = function(value)
                if not IsRankAllowed(value) then
                    return false, L("type_err_rank_required")
                end
                return true
            end
        }
    }
})

if SERVER then
    hook.Add("CAMI.PlayerUsergroupChanged", "KrakensStore_Rank", function(ply, old, new)
        if IsValid(ply) then
            if ply.KS_RankChangeFromStore then return end
            ply.KrakensStore_InitRank = new
            ApplyStoreRank(ply)
        end
    end)
end

local ParseTrailColor = KrakensStore.Schema.ParseColor

local TrailOptions = CachedOptions(30, function()
    local options, seen = {}, {}
    local function add(name, texture)
        if not texture or seen[texture] then return end
        seen[texture] = true
        options[#options + 1] = { name = name, value = texture }
    end
    for name, texture in pairs(list.GetForEdit("trail_materials")) do
        add(Phrase(name), texture)
    end
    add(L("type_trail_laser"), "trails/laser")
    add(L("type_trail_smoke"), "trails/smoke")
    add(L("type_trail_plasma"), "trails/plasma")
    return options
end)

local function ClearTrail(ply)
    if IsValid(ply.KrakensStore_TrailEnt) then
        ply.KrakensStore_TrailEnt:Remove()
        ply.KrakensStore_TrailEnt = nil
    end
end

local function ApplyTrail(ply, itemData)
    ClearTrail(ply)
    local color = ParseTrailColor(itemData.trailColor) or Color(255, 255, 255)
    local startWidth = tonumber(itemData.trailWidth) or 15
    local lifetime = tonumber(itemData.trailLength) or 4
    local material = itemData.texture or "trails/laser"
    ply.KrakensStore_TrailEnt = util.SpriteTrail(ply, 0, color, false, startWidth, 1, lifetime, 1 / 16 * 0.5, material)
end

KrakensStore:RegisterType("trail", {
    nameKey = "type_trail_name",
    noDuplicates = true,
    equip = true,
    uniqueEquip = true,
    onEquip = function(ply, itemData) ApplyTrail(ply, itemData) end,
    onUnequip = ClearTrail,
    onLoadout = function(ply, itemData)
        timer.Simple(0.5, function()
            if IsValid(ply) then ApplyTrail(ply, itemData) end
        end)
    end,
    settings = {
        {
            key = "texture",
            nameKey = "type_setting_texture",
            descKey = "type_setting_texture_desc",
            type = "combo",
            required = true,
            getOptions = TrailOptions,
            onChoose = function(index, text, data, fields)
                return { name = text, icon = data }
            end,
            validateOption = function(data)
                for _, opt in ipairs(TrailOptions()) do
                    if opt.value == data then return true end
                end
                return false, L("type_err_trail_required")
            end
        },
        {
            key = "trailColor",
            nameKey = "type_setting_color",
            descKey = "type_setting_color_desc",
            type = "string",
            default = "255,255,255",
            placeholder = "255,255,255",
            validateOption = function(value)
                if not ParseTrailColor(value) then return false, L("type_err_color_invalid") end
                return true
            end
        },
        {
            key = "trailWidth",
            nameKey = "type_setting_width",
            descKey = "type_setting_width_desc",
            type = "number",
            default = 15,
            min = 1,
            max = 100
        },
        {
            key = "trailLength",
            nameKey = "type_setting_length",
            descKey = "type_setting_length_desc",
            type = "number",
            default = 4,
            min = 0.5,
            max = 30
        }
    }
})

if SERVER then hook.Add("PlayerDeath", "KrakensStore_TrailCleanup", ClearTrail) end

local MAX_VEHICLES_PER_PLAYER = 3
local VEHICLE_SPAWN_COOLDOWN = 5

local function DropToGround(ent)
    local mins = ent:OBBMins()
    if not mins then return end
    local tr = util.TraceLine({
        start = ent:GetPos() + Vector(0, 0, 100),
        endpos = ent:GetPos() - Vector(0, 0, 500),
        filter = ent
    })
    if tr.Hit then ent:SetPos(tr.HitPos + Vector(0, 0, math.abs(mins.z))) end
end

local function SpawnScriptedVehicle(ply, class, pos, ang)
    local ent = ents.Create(class)
    if not IsValid(ent) then return nil end
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    DropToGround(ent)
    return ent
end

local function SpawnListVehicle(ply, class, pos, ang)
    local def = list.GetForEdit("Vehicles")[class]
    if not def then return nil end
    local ent = ents.Create(def.Class)
    if not IsValid(ent) then return nil end
    ent:SetModel(def.Model)
    ent:SetPos(pos)
    ent:SetAngles(ang)
    for key, value in pairs(def.KeyValues or {}) do
        ent:SetKeyValue(key, value)
    end
    ent:Spawn()
    ent:Activate()
    DropToGround(ent)
    return ent
end

local function RegisterVehicleType(cfg)
    local storageKey, system = cfg.storageKey, cfg.system

    KrakensStore:RegisterType(cfg.typeId, {
        nameKey = cfg.nameKey,
        stacking = true,
        integration = system,
        available = cfg.available,
        options = {
            ["spawn"] = {
                removeItem = true,
                usePreview = true,
                check = function(ply)
                    if not ply:Alive() then return false, L("type_must_be_alive") end
                    return true
                end,
                func = function(ply, data, invItem, spawnPos, spawnAng)
                    if (ply.KS_LastVehicleSpawn or 0) > CurTime() then
                        return false, L("type_err_vehicle_cooldown")
                    end

                    local vehicleClass = data.vehicleClass
                    if not vehicleClass or vehicleClass == "" then return false end
                    if not cfg.classExists(vehicleClass) then return false, L(cfg.requiredErrKey) end

                    local owned = ply[storageKey] or {}
                    ply[storageKey] = owned
                    for i = #owned, 1, -1 do
                        if not IsValid(owned[i]) then table.remove(owned, i) end
                    end
                    if #owned >= MAX_VEHICLES_PER_PLAYER or not ply:CheckLimit("vehicles") then
                        return false, L("type_err_vehicle_limit")
                    end
                    if hook.Run("PlayerSpawnVehicle", ply, nil, vehicleClass, nil) == false then
                        return false, L("type_err_vehicle_blocked")
                    end

                    spawnPos = spawnPos or (ply:GetEyeTrace().HitPos + Vector(0, 0, 50))
                    spawnAng = spawnAng or Angle(0, ply:EyeAngles().y, 0)

                    local ok, vehicle = pcall(cfg.spawn, ply, vehicleClass, spawnPos, spawnAng)
                    if not ok or not IsValid(vehicle) then return false end

                    vehicle:SetCreator(ply)
                    if vehicle.CPPISetOwner then vehicle:CPPISetOwner(ply) end

                    ply:AddCount("vehicles", vehicle)
                    ply:AddCleanup("vehicles", vehicle)
                    undo.Create("Vehicle")
                        undo.AddEntity(vehicle)
                        undo.SetPlayer(ply)
                    undo.Finish()
                    hook.Run("PlayerSpawnedVehicle", ply, vehicle)

                    owned[#owned + 1] = vehicle
                    ply.KS_LastVehicleSpawn = CurTime() + VEHICLE_SPAWN_COOLDOWN
                    return true
                end,
            }
        },
        settings = {
            {
                key = "vehicleClass",
                nameKey = cfg.settingNameKey,
                descKey = cfg.settingDescKey,
                type = cfg.settingType or "combo",
                required = true,
                placeholder = cfg.placeholder,
                getOptions = cfg.getOptions,
                onChoose = cfg.onChoose,
                validateOption = function(val)
                    if not cfg.classExists(val) then
                        return false, L(cfg.requiredErrKey)
                    end
                    return true
                end,
            }
        }
    })
end

RegisterVehicleType({
    typeId = "vehicle_lvs",
    nameKey = "type_lvs_vehicle_name",
    system = "lvs",
    storageKey = "KrakensStore_LVSVehicle",
    classExists = function(class) return scripted_ents.GetStored(class) ~= nil end,
    spawn = SpawnScriptedVehicle,
    settingNameKey = "type_setting_lvs_vehicle",
    settingDescKey = "type_setting_lvs_vehicle_desc",
    requiredErrKey = "type_err_vehicle_required",
    getOptions = CachedOptions(30, function()
        local options = {}
        for class, ent in pairs(scripted_ents.GetList()) do
            if ent.t and ent.t.Base and string.find(ent.t.Base, "lvs") then
                options[#options + 1] = { name = ent.t.PrintName or class, value = class }
            end
        end
        return options
    end),
    onChoose = function(index, text, data)
        local ent = scripted_ents.GetStored(data)
        if ent and ent.t then
            return {
                name = ent.t.PrintName or data,
                description = ent.t.Information or "",
                model = ent.t.WorldModel or ent.t.Model or ent.t.MDL,
                icon = KrakensStore.AutoFill.GuessEntityIcon(data),
            }
        end
    end,
})

RegisterVehicleType({
    typeId = "vehicle_simfphys",
    nameKey = "type_simfphys_vehicle_name",
    system = "simfphys",
    storageKey = "KrakensStore_SimfphysVehicle",
    classExists = function(class) return list.GetForEdit("simfphys_vehicles")[class] ~= nil end,
    spawn = function(_, class, pos, ang)
        return simfphys.SpawnVehicleSimple(class, pos, ang)
    end,
    settingNameKey = "type_setting_simfphys_vehicle",
    settingDescKey = "type_setting_simfphys_vehicle_desc",
    requiredErrKey = "type_err_vehicle_required",
    getOptions = CachedOptions(30, function()
        local options = {}
        for id, data in pairs(list.GetForEdit("simfphys_vehicles")) do
            options[#options + 1] = { name = data.Name or id, value = id }
        end
        return options
    end),
    onChoose = function(index, text, data)
        local veh = list.GetForEdit("simfphys_vehicles")[data]
        if veh then
            return {
                name = veh.Name or data,
                description = veh.Description or "",
                model = veh.Model,
                icon = KrakensStore.AutoFill.GuessEntityIcon(data),
            }
        end
    end,
})

RegisterVehicleType({
    typeId = "vehicle_tdm",
    nameKey = "type_tdm_vehicle_name",
    system = "tdm",
    storageKey = "KrakensStore_TDMVehicle",
    classExists = function(class) return list.GetForEdit("Vehicles")[class] ~= nil end,
    available = function() return next(list.GetForEdit("Vehicles")) ~= nil end,
    spawn = SpawnListVehicle,
    settingNameKey = "type_setting_tdm_vehicle",
    settingDescKey = "type_setting_tdm_vehicle_desc",
    requiredErrKey = "type_err_vehicle_class_required",
    getOptions = CachedOptions(30, function()
        local options = {}
        for class, def in pairs(list.GetForEdit("Vehicles")) do
            options[#options + 1] = { name = def.Name or class, value = class }
        end
        return options
    end),
    onChoose = function(index, text, data)
        local def = list.GetForEdit("Vehicles")[data]
        if def then
            return { name = def.Name or data, model = def.Model }
        end
    end,
})

local function WOSRegistry(registryTable)
    local root = KrakensStore.Integrations.Global("wiltos")
    return root and root[registryTable]
end

local function WOSCall(method, ply, id)
    local root = KrakensStore.Integrations.Global("wiltos")
    if not root or not id then return end
    local fn = root[method]
    if not fn then return end
    if isfunction(ply[method]) then return ply[method](ply, id) end
    return fn(root, ply, id)
end

local function CreateWiltOSType(config)
    local idKey = config.idKey
    local giveMethod = config.giveMethod
    local removeMethod = config.removeMethod
    local registryTable = config.registryTable

    return {
        nameKey = config.nameKey,
        noDuplicates = true,
        equip = true,
        integration = "wiltos",
        onEquip = function(ply, itemData)
            WOSCall(giveMethod, ply, itemData[idKey])
        end,
        onUnequip = function(ply, itemData)
            WOSCall(removeMethod, ply, itemData[idKey])
        end,
        onLoadout = function(ply, itemData)
            local id = itemData[idKey]
            timer.Simple(1, function()
                if IsValid(ply) then WOSCall(giveMethod, ply, id) end
            end)
        end,
        settings = {
            {
                key = idKey,
                nameKey = config.settingNameKey,
                descKey = config.settingDescKey,
                type = "combo",
                required = true,
                getOptions = CachedOptions(30, function()
                    local options = {}
                    for id, data in pairs(WOSRegistry(registryTable) or {}) do
                        options[#options + 1] = { name = data.Name or id, value = id }
                    end
                    return options
                end),
                onChoose = function(index, text, data, fields)
                    local entry = (WOSRegistry(registryTable) or {})[data]
                    if entry then
                        return {
                            name = entry.Name or data,
                            description = entry.Description or entry.Desc or "",
                            icon = entry.Icon or entry.Material
                        }
                    end
                end,
                validateOption = function(data)
                    local registry = WOSRegistry(registryTable)
                    if registry and not registry[data] then
                        return false, L(config.errKey)
                    end
                    return true
                end
            }
        }
    }
end

KrakensStore:RegisterType("wiltos_skill", CreateWiltOSType({
    idKey = "skillid",
    nameKey = "type_wiltos_skill_name",
    giveMethod = "GiveSkill",
    removeMethod = "RemoveSkill",
    registryTable = "Skills",
    settingNameKey = "type_setting_skill",
    settingDescKey = "type_setting_skill_desc",
    errKey = "type_err_skill_required",
}))

KrakensStore:RegisterType("wiltos_ability", CreateWiltOSType({
    idKey = "abilityid",
    nameKey = "type_wiltos_ability_name",
    giveMethod = "GiveAbility",
    removeMethod = "RemoveAbility",
    registryTable = "Abilities",
    settingNameKey = "type_setting_ability",
    settingDescKey = "type_setting_ability_desc",
    errKey = "type_err_ability_required",
}))

KrakensStore:RegisterType("wiltos_perk", CreateWiltOSType({
    idKey = "perkid",
    nameKey = "type_wiltos_perk_name",
    giveMethod = "GivePerk",
    removeMethod = "RemovePerk",
    registryTable = "Perks",
    settingNameKey = "type_setting_perk",
    settingDescKey = "type_setting_perk_desc",
    errKey = "type_err_perk_required",
}))

local function LSCSTable(key)
    local root = KrakensStore.Integrations.Global("lscs")
    return root and root[key] or {}
end

local function LSCSGetClass(lscsTableKey, itemId)
    local itemData = LSCSTable(lscsTableKey)[itemId]
    return itemData and itemData.class
end

local function LSCSPlayerHasItem(ply, lscsTableKey, itemId)
    if not ply.lscsGetInventory then return false end
    local class = LSCSGetClass(lscsTableKey, itemId)
    if not class then return false end
    local inv = ply:lscsGetInventory()
    if not inv then return false end
    for _, c in pairs(inv) do
        if c == class then return true end
    end
    return false
end

local function LSCSGiveItem(ply, lscsTableKey, itemId, equip)
    if not ply.lscsAddInventory then return false end
    local class = LSCSGetClass(lscsTableKey, itemId)
    if not class then return false end
    if LSCSPlayerHasItem(ply, lscsTableKey, itemId) then return true end
    ply:lscsAddInventory(class, equip)
    return true
end

local function LSCSRemoveItem(ply, lscsTableKey, itemId)
    if not ply.lscsGetInventory or not ply.lscsRemoveItem then return false end
    local class = LSCSGetClass(lscsTableKey, itemId)
    if not class then return false end
    local inv = ply:lscsGetInventory()
    if not inv then return false end
    for index, c in pairs(inv) do
        if c == class then
            ply:lscsRemoveItem(index)
            if ply.lscsBuildPlayerInfo then ply:lscsBuildPlayerInfo() end
            return true
        end
    end
    return false
end

local function LSCSOnChoose(lscsTableKey)
    return function(index, text, data)
        local item = LSCSTable(lscsTableKey)[data]
        if not item then return end
        return { name = item.name or data, description = item.description or "", model = item.mdl, icon = AutoFill.GetLSCSIcon(item, lscsTableKey, data) }
    end
end

local BladeOnChoose = LSCSOnChoose("Blade")

local function CrystalOnChoose(index, text, data)
    local result = BladeOnChoose(index, text, data)
    local color = result and LSCSTable("Blade")[data].color_blur
    if color then
        result.description = string.format(L("type_lscs_blade_color_desc"), color.r or 0, color.g or 0, color.b or 0)
    end
    return result
end

local function LSCSNotOwned(cfg)
    return function(ply, itemTable, data)
        local id = data and data[cfg.idKey]
        if id and LSCSPlayerHasItem(ply, cfg.lscsTable, id) then return false, L(cfg.alreadyOwnErr) end
        return true
    end
end

local function LSCSSetting(cfg)
    return {
        key = cfg.idKey,
        nameKey = cfg.settingName,
        descKey = cfg.settingDesc,
        type = "combo",
        required = true,
        getOptions = CachedOptions(30, function()
            local options = {}
            for id, data in pairs(LSCSTable(cfg.lscsTable)) do
                options[#options + 1] = { name = data.name or id, value = id }
            end
            return options
        end),
        onChoose = cfg.onChoose or LSCSOnChoose(cfg.lscsTable),
    }
end

local function RegisterLSCSEquipType(typeId, nameKey, cfg)
    local idKey, lscsTable = cfg.idKey, cfg.lscsTable
    KrakensStore:RegisterType(typeId, {
        nameKey = nameKey,
        noDuplicates = true,
        equip = true,
        integration = "lscs",
        canPurchase = LSCSNotOwned(cfg),
        onEquip = function(ply, itemData) LSCSGiveItem(ply, lscsTable, itemData[idKey], true) end,
        onUnequip = function(ply, itemData) LSCSRemoveItem(ply, lscsTable, itemData[idKey]) end,
        onLoadout = function(ply, itemData)
            timer.Simple(0.5, function()
                if IsValid(ply) then LSCSGiveItem(ply, lscsTable, itemData[idKey], true) end
            end)
        end,
        settings = { LSCSSetting(cfg) }
    })
end

RegisterLSCSEquipType("lscs_power", "type_force_power_name", {
    idKey = "powerId", lscsTable = "Force", alreadyOwnErr = "type_already_own_force_lscs",
    settingName = "type_setting_force_power", settingDesc = "type_setting_force_power_desc",
})

RegisterLSCSEquipType("lscs_form", "type_saber_form_name", {
    idKey = "formId", lscsTable = "Stance", alreadyOwnErr = "type_already_own_form_lscs",
    settingName = "type_setting_saber_form", settingDesc = "type_setting_saber_form_desc",
})

RegisterLSCSEquipType("lscs_hilt", "type_saber_hilt_name", {
    idKey = "hiltId", lscsTable = "Hilt", alreadyOwnErr = "type_already_own_hilt_lscs",
    settingName = "type_setting_saber_hilt", settingDesc = "type_setting_saber_hilt_desc",
})

local CRYSTAL = {
    idKey = "crystalId", lscsTable = "Blade", alreadyOwnErr = "type_already_own_crystal_lscs",
    settingName = "type_setting_kyber_crystal", settingDesc = "type_setting_kyber_crystal_desc",
    onChoose = CrystalOnChoose,
}

RegisterLSCSEquipType("permcrystal", "type_perm_crystal_name", CRYSTAL)

local CrystalNotOwned = LSCSNotOwned(CRYSTAL)

KrakensStore:RegisterType("lscs_crystal", {
    nameKey = "type_kyber_crystal_name",
    stacking = true,
    integration = "lscs",
    canPurchase = CrystalNotOwned,
    options = {
        ["unlock"] = {
            removeItem = true,
            check = function(ply, data) return CrystalNotOwned(ply, nil, data) end,
            func = function(ply, data)
                return data.crystalId ~= nil and LSCSGiveItem(ply, "Blade", data.crystalId)
            end
        }
    },
    settings = { LSCSSetting(CRYSTAL) }
})

KrakensStore.XPSystems = KrakensStore.XPSystems or {
    { name = "LevelSystemConfiguration", check = function() return _G.LevelSystemConfiguration ~= nil end,
        give = function(ply, amt) ply:addXP(amt, true) end },
    { name = "Sublime", check = function() return _G.Sublime ~= nil end,
        give = function(ply, amt) ply:SL_AddExperience(amt, "Purchase", true) end },
    { name = "DarkRPEssentials", check = function() return _G.DARKRP_ESSENTIALS ~= nil or _G.DarkRPFoundation ~= nil or _G.UUI ~= nil end,
        give = function(ply, amt) ply:AddExperience(amt, "Purchase") end },
    { name = "GlorifiedLeveling", check = function() return _G.GlorifiedLeveling ~= nil end,
        give = function(ply, amt) GlorifiedLeveling.AddPlayerXP(ply, amt) end },
    { name = "addXP", check = function(ply) return isfunction(ply.addXP) end,
        give = function(ply, amt) ply:addXP(amt) end },
    { name = "AddXP", check = function(ply) return isfunction(ply.AddXP) end,
        give = function(ply, amt) ply:AddXP(amt) end },
}

local function FindXPGiver(ply)
    for _, sys in ipairs(KrakensStore.XPSystems) do
        if sys.check(ply) then return sys.give end
    end
end

KrakensStore:RegisterType("xp", {
    nameKey = "type_xp_name",
    stacking = true,
    options = {
        ["use"] = {
            removeItem = true,
            check = function(ply)
                if not ply:Alive() then return false, L("type_must_be_alive") end
                if SERVER and not FindXPGiver(ply) then return false, L("type_err_xp_no_method") end
                return true
            end,
            func = function(ply, data)
                local amount = math.max(tonumber(data.amount) or 0, 1)
                local give = FindXPGiver(ply)
                if not give then return false end
                give(ply, amount)
                return true
            end,
        },
    },
    settings = {
        {
            key = "amount",
            nameKey = "type_setting_xp_amount",
            descKey = "type_setting_xp_amount_desc",
            type = "number",
            default = 100,
            min = 1,
            required = true,
            placeholder = "100",
        },
    },
})

local function FindDarkRPJob(command)
    for _, job in pairs(RPExtraTeams or {}) do
        if job.command == command then return job end
    end
end

KrakensStore:RegisterType("darkrp_job", {
    nameKey = "type_darkrp_job_name",
    noDuplicates = true,
    equip = true,
    uniqueEquip = true,
    integration = "darkrp",
    settings = {
        {
            key = "jobcommand",
            nameKey = "type_setting_darkrp_job",
            descKey = "type_setting_darkrp_job_desc",
            type = "combo",
            required = true,
            searchable = true,
            getOptions = CachedOptions(30, function()
                local options = {}
                for _, job in ipairs(KF.Integrations.GetJobs()) do
                    if job.command ~= "" then options[#options + 1] = { name = job.name, value = job.command } end
                end
                return options
            end),
            onChoose = function(index, text, data)
                local job = FindDarkRPJob(data)
                if not job then return end
                local model = istable(job.model) and job.model[1] or job.model
                return { name = job.name, model = model }
            end,
            validateOption = function(value)
                if SERVER and not FindDarkRPJob(value) then return false, L("type_err_darkrp_job_invalid") end
                return true
            end,
        },
    },
})

local function GateDenial(ply, typeId, dataKey, value, ownedKey, missingKey)
    local gated, owned = false, false
    for id, itemTable in pairs(KrakensStore.Items.Cache) do
        if itemTable.type == typeId and itemTable.data and itemTable.data[dataKey] == value then
            if KrakensStore.Inventory.IsEquipped(ply, id) then return nil end
            gated = true
            owned = owned or KrakensStore.Inventory.HasItem(ply, id) == true
        end
    end
    if gated then return L(owned and ownedKey or missingKey) end
end

if SERVER then
    hook.Add("playerCanChangeTeam", "KrakensStore_DarkRPJobGate", function(ply, teamIndex, force)
        if force then return end
        local teamData = RPExtraTeams and RPExtraTeams[teamIndex]
        if not teamData or not isstring(teamData.command) then return end
        local denial = GateDenial(ply, "darkrp_job", "jobcommand", teamData.command, "err_job_restricted", "err_job_restricted_no_item")
        if denial then return false, denial end
    end)
end

local function SandboxTools()
    local toolWep = weapons.Get("gmod_tool")
    return toolWep and toolWep.Tool or {}
end

KrakensStore:RegisterType("sandbox_tool", {
    nameKey = "type_sandbox_tool_name",
    noDuplicates = true,
    equip = true,
    settings = {
        {
            key = "tool",
            nameKey = "type_setting_tool",
            descKey = "type_setting_tool_desc",
            type = "combo",
            required = true,
            searchable = true,
            getOptions = CachedOptions(30, function()
                local options = {}
                for id, data in pairs(SandboxTools()) do
                    if isstring(data.Name) and isfunction(data.LeftClick) and data.AddToMenu ~= false then
                        options[#options + 1] = { name = (data.Category or "Other") .. " | " .. Phrase(data.Name), value = id }
                    end
                end
                return options
            end),
            validateOption = function(value)
                if not SandboxTools()[value] then return false, L("type_err_tool_invalid") end
                return true
            end,
        },
    },
})

hook.Add("CanTool", "KrakensStore_SandboxToolGate", function(ply, tr, toolName)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local denial = GateDenial(ply, "sandbox_tool", "tool", toolName, "err_tool_restricted", "err_tool_restricted_no_item")
    if not denial then return end
    if CLIENT and IsFirstTimePredicted() then KrakensStore.UI.ShowNotification(denial, "error") end
    return false
end)
KrakensStore.Stats = KrakensStore.Stats or {}

local Stats = KrakensStore.Stats

local function clamp01(x)
    if not x then return 0 end
    return math.max(0, math.min(1, x))
end

local function norm(val, minV, maxV)
    val = tonumber(val or 0) or 0
    if maxV <= minV then return 0.5 end
    local t = (val - minV) / (maxV - minV)
    return clamp01(t)
end

local function getARC9RangeHU(tbl)
    local r = tbl.RangeMax or tbl.RangeMaxUBGL or tbl.DamageMaxRange or tbl.EffectiveRange
    if (not r) and tbl.GetProcessedValue then
        local ok, v = pcall(function() return tbl:GetProcessedValue("RangeMax") end)
        if ok and tonumber(v) then r = v end
    end
    return tonumber(r or 0) or 0
end

local function getArcCWRangeM(tbl)
    local r = tbl.Range or (tbl.Primary and tbl.Primary.Range) or tbl.RangeMax or tbl.EffectiveRange
    return tonumber(r or 0) or 0
end

local function heuristicRangeMeters(tbl)
    local cls = tostring(tbl.ClassName or tbl.Classname or tbl.Class or ""):lower()
    local cat = tostring(tbl.Category or ""):lower()
    local hold = tostring(tbl.HoldType or (tbl.Primary and tbl.Primary.HoldType) or ""):lower()
    local ammo = tostring((tbl.Primary and tbl.Primary.Ammo) or tbl.Ammo or ""):lower()

    local function any(str, words)
        for _, w in ipairs(words) do if str:find(w, 1, true) then return true end end
        return false
    end

    if any(cls, {"shotgun"}) or any(cat, {"shotgun"}) or any(ammo, {"buckshot"}) then return 45 end
    if any(cls, {"pistol", "smg", "mp"}) or any(cat, {"pistol", "smg"}) or any(hold, {"pistol", "revolver"}) or any(ammo, {"pistol"}) then return 120 end
    if any(cls, {"sniper", "dmr", "marksman"}) or any(cat, {"sniper", "dmr", "marksman"}) then return 700 end
    if any(cls, {"lmg", "rifle", "carbine", "ar_", "ar-", "ak", "m4", "g3", "famas", "galil"}) or any(cat, {"rifle", "assault"}) then return 350 end

    return 200
end

function Stats.ComputeWeaponStats(tbl, sys)
    if not tbl or not sys then return nil end

    local dmg = tbl.Damage or tbl.DamageMax or tbl.DamageMin or
                (tbl.Primary and tbl.Primary.Damage) or 30
    dmg = tonumber(dmg) or 30

    local rangeM = 0
    if sys == "arc9" then
        local hu = getARC9RangeHU(tbl)
        local arc9 = KrakensStore.Integrations.Global("arc9")
        local metersPerHU = (arc9 and tonumber(arc9.HUToM)) or 0.0254
        if hu > 0 then
            rangeM = hu * metersPerHU
        end
    elseif sys == "arccw" then
        rangeM = getArcCWRangeM(tbl)
    end

    if rangeM == 0 then
        local fallback = tbl.Range or (tbl.Primary and tbl.Primary.Range) or 0
        fallback = tonumber(fallback) or 0
        if fallback > 120 then
            rangeM = fallback / 39.37
        elseif fallback > 0 then
            rangeM = fallback
        else
            rangeM = heuristicRangeMeters(tbl)
        end
    end

    local mag = tbl.ClipSize or
                (tbl.Primary and (tbl.Primary.ClipSize or tbl.Primary.ClipSizeDefault)) or
                tbl.DefaultClip or 30
    mag = tonumber(mag) or 30

    local recoil = tbl.Recoil or tbl.RecoilUp or tbl.RecoilKick or
                   (tbl.Primary and tbl.Primary.Recoil) or 1
    recoil = tonumber(recoil) or 1

    local rpm = tbl.RPM or (tbl.Primary and tbl.Primary.RPM) or 0
    if rpm == 0 then
        local delay = tbl.Delay or (tbl.Primary and tbl.Primary.Delay) or tbl.CycleTime or 0
        delay = tonumber(delay) or 0
        if delay > 0 then
            rpm = math.floor(60 / delay)
        end
    end
    rpm = tonumber(rpm) or 600

    local nd = norm(dmg, 10, 100)
    local nr = norm(rangeM, 30, 800)
    local nm = norm(mag, 5, 100)
    local nrec = 1 - norm(recoil, 0.1, 3)
    local nrpm = norm(rpm, 100, 1200)

    return {
        damage = math.floor(nd * 100),
        range = math.floor(nr * 100),
        mag = math.floor(nm * 100),
        recoil = math.floor(clamp01(nrec) * 100),
        rpm = math.floor(nrpm * 100),
        _raw = {
            damage = dmg,
            range = math.floor(rangeM),
            mag = mag,
            recoil = recoil,
            rpm = rpm,
        },
        system = sys,
    }
end

function Stats.GetWeaponStatsByClass(weaponClass, system)
    if not weaponClass or weaponClass == "" then return nil end
    return Stats.ComputeWeaponStats(weapons.GetStored(weaponClass), system)
end

Stats.PositivesHigher = {
    damage = true, range = true, rpm = true, clip_size = true,
    move_speed = true, sighted_speed = true
}

Stats.PositivesLower = {
    recoil = true, spread = true, sway = true, ads = true,
    sprint_to_fire = true, reload = true
}

local function extractPropsARC9(tbl)
    local props = {}
    local function add(label, kind, val)
        table.insert(props, {key = label, type = kind, value = val})
    end

    if tbl.RecoilMult then add("recoil", "mult", tbl.RecoilMult) end
    if tbl.RecoilUpMult then add("recoil_up", "mult", tbl.RecoilUpMult) end
    if tbl.RecoilSideMult then add("recoil_side", "mult", tbl.RecoilSideMult) end
    if tbl.SpreadMult then add("spread", "mult", tbl.SpreadMult) end
    if tbl.SwayMult then add("sway", "mult", tbl.SwayMult) end
    if tbl.AimDownSightsTimeMult then add("ads", "mult", tbl.AimDownSightsTimeMult) end
    if tbl.SprintToFireTimeMult then add("sprint_to_fire", "mult", tbl.SprintToFireTimeMult) end
    if tbl.ReloadTimeMult then add("reload", "mult", tbl.ReloadTimeMult) end
    if tbl.SpeedMult then add("move_speed", "mult", tbl.SpeedMult) end
    if tbl.SightedSpeedMult then add("sighted_speed", "mult", tbl.SightedSpeedMult) end
    if tbl.RPMMult then add("rpm", "mult", tbl.RPMMult) end
    if tbl.RangeMaxMult or tbl.RangeMinMult then add("range", "mult", tbl.RangeMaxMult or tbl.RangeMinMult) end
    if tbl.DamageMaxMult or tbl.DamageMinMult then add("damage", "mult", tbl.DamageMaxMult or tbl.DamageMinMult) end

    if tbl.RPMAdd then add("rpm", "add", tbl.RPMAdd) end
    if tbl.ClipSizeAdd then add("clip_size", "add", tbl.ClipSizeAdd) end
    if tbl.DamageMaxAdd or tbl.DamageMinAdd then add("damage", "add", tbl.DamageMaxAdd or tbl.DamageMinAdd) end

    if tbl.ClipSizeOverride then add("clip_size", "override", tbl.ClipSizeOverride) end
    if tbl.RPMOverride then add("rpm", "override", tbl.RPMOverride) end

    return props
end

local function extractPropsArcCW(tbl)
    local props = {}
    local function add(label, kind, val)
        table.insert(props, {key = label, type = kind, value = val})
    end
    local function get(k) return tbl["Mult_" .. k] or tbl[k] end

    if get("Recoil") then add("recoil", "mult", get("Recoil")) end
    if get("RecoilSide") then add("recoil_side", "mult", get("RecoilSide")) end
    if get("AccuracyMOA") then add("spread", "mult", get("AccuracyMOA")) end
    if get("SightTime") then add("ads", "mult", get("SightTime")) end
    if get("SpeedMult") then add("move_speed", "mult", get("SpeedMult")) end
    if get("SightedSpeedMult") then add("sighted_speed", "mult", get("SightedSpeedMult")) end
    if get("ReloadTime") then add("reload", "mult", get("ReloadTime")) end
    if get("RPM") then add("rpm", "mult", get("RPM")) end
    if get("Sway") then add("sway", "mult", get("Sway")) end
    if get("Range") then add("range", "mult", get("Range")) end
    if get("Damage") then add("damage", "mult", get("Damage")) end

    if tbl.Add_ClipSize then add("clip_size", "add", tbl.Add_ClipSize) end
    if tbl.Add_RPM then add("rpm", "add", tbl.Add_RPM) end
    if tbl.Add_Damage then add("damage", "add", tbl.Add_Damage) end

    if tbl.Override_ClipSize then add("clip_size", "override", tbl.Override_ClipSize) end
    if tbl.Override_RPM then add("rpm", "override", tbl.Override_RPM) end

    return props
end

local EXTRACT_PROPS = { arc9 = extractPropsARC9, arccw = extractPropsArcCW }

function Stats.GetAttachmentData(attachmentId, system)
    local cfg = KrakensStore.Integrations.AttachmentSystems[system]
    local att = cfg and attachmentId and (cfg.GetAttTable() or {})[attachmentId]
    if not att then return nil end
    return { id = attachmentId, system = system, props = EXTRACT_PROPS[system](att) }
end

function Stats.IsPropBuff(key, propType, value)
    if not value then return nil end

    local keyLower = string.lower(key)

    if propType == "mult" then
        if Stats.PositivesHigher[keyLower] then
            return value > 1
        elseif Stats.PositivesLower[keyLower] then
            return value < 1
        else
            if keyLower:find("recoil") or keyLower:find("spread") or
               keyLower:find("sway") or keyLower:find("time") then
                return value < 1
            end
            return value > 1
        end
    elseif propType == "add" then
        if Stats.PositivesHigher[keyLower] then
            return value > 0
        elseif Stats.PositivesLower[keyLower] then
            return value < 0
        else
            if keyLower:find("recoil") or keyLower:find("spread") or
               keyLower:find("sway") then
                return value < 0
            end
            return value > 0
        end
    end

    return nil
end

local function humanize(key)
    local s = tostring(key or ""):gsub("_", " ")
    return (s:gsub("(%a)(%w*)", function(a, b) return a:upper() .. b end))
end

local function LookupStat(key)
    local AID = KrakensStore.AID
    return KF.Lang.RawGet(AID, "stat_" .. key) or humanize(key)
end

function Stats.FormatPropValue(key, propType, value)
    local label = LookupStat(key)

    if propType == "mult" then
        local pct = math.Round((value - 1) * 100)
        if pct == 0 then return nil end
        return string.format("%s %s%d%%", label, pct > 0 and "+" or "", pct)
    elseif propType == "add" then
        local n = math.floor(value)
        if n == 0 then return nil end
        return string.format("%s %s%d", label, n > 0 and "+" or "", n)
    else
        return string.format("%s = %s", label, tostring(value))
    end
end

local PRIMARY_STAT_KEYS = {
    damage = "stats_damage", range = "stats_range",
    mag = "stats_magazine", recoil = "stats_recoil", rpm = "stat_rpm",
}

function Stats.GetStatLabel(key)
    local mapped = PRIMARY_STAT_KEYS[key]
    if mapped then
        return KF.Lang.RawGet(KrakensStore.AID, mapped) or humanize(key)
    end
    return LookupStat(key)
end

function Stats.WeaponBars(stats)
    local raw = stats._raw or {}
    local function Bar(key, rawText)
        return { label = Stats.GetStatLabel(key), raw = rawText, fill = (stats[key] or 0) / 100 }
    end
    return {
        Bar("damage", tostring(raw.damage or 0)),
        Bar("range", (raw.range or 0) .. " " .. L("unit_meters")),
        Bar("mag", tostring(raw.mag or 0)),
        Bar("recoil", string.format("%.2f", raw.recoil or 0)),
        Bar("rpm", (raw.rpm or 0) .. " RPM"),
    }
end

function Stats.AttachmentLines(attData)
    local lines = {}
    for _, prop in ipairs(attData.props or {}) do
        local text = Stats.FormatPropValue(prop.key, prop.type, prop.value)
        if text then
            lines[#lines + 1] = { label = text, buff = Stats.IsPropBuff(prop.key, prop.type, prop.value) }
        end
    end
    return lines
end

function Stats.ItemKind(itemType)
    local def = Types[itemType]
    if not (def and KrakensStore.Integrations.AttachmentSystems[def.integration]) then return nil end
    return (def.settings[1] or {}).key == "weaponClass" and "weapon" or "attachment", def.integration
end

function Stats.GetItemStats(item)
    if not item then return nil end

    local kind, system = Stats.ItemKind(item.type or item.itemType)
    local data = item.data or item

    if kind == "weapon" then
        local weaponClass = data.weaponClass
        if weaponClass then
            return Stats.GetWeaponStatsByClass(weaponClass, system), kind
        end
    elseif kind == "attachment" then
        local attachmentId = data.attachmentId
        if attachmentId then
            return Stats.GetAttachmentData(attachmentId, system), kind
        end
    end

    return nil, nil
end
