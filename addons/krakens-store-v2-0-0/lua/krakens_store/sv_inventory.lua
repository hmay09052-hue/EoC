KrakensStore.Buffs = KrakensStore.Buffs or {}

local BUFFS = KrakensStore.Buffs

BUFFS.ActiveBuffs = BUFFS.ActiveBuffs or {}

local function GetBuffState(ply)
    ply.KS_Buffs = ply.KS_Buffs or {}
    return ply.KS_Buffs
end

local function MakeSimpleBuff(field, default, minVal, opts)
    local applyCap = opts and opts.applyCap
    local extraSync = opts and opts.extraSync
    return {
        apply = function(ply, value)
            local b = GetBuffState(ply)
            local newVal = (b[field] or default) + value
            b[field] = applyCap and math.min(applyCap, newVal) or newVal
            if extraSync then extraSync(b) end
        end,
        remove = function(ply, value)
            local b = GetBuffState(ply)
            b[field] = math.max(minVal, (b[field] or default) - value)
            if extraSync then extraSync(b) end
        end
    }
end

local resistSync = function(b) b.DamageResist = math.min(90, b.DamageResistRaw or 0) end

local function MakePercentBaselineBuff(bonusField, baseFields, applyFn)
    return {
        apply = function(ply, value)
            local b = GetBuffState(ply)
            for _, entry in ipairs(baseFields) do
                if not b[entry.field] then b[entry.field] = entry.read(ply) end
            end
            b[bonusField] = (b[bonusField] or 0) + value
            applyFn(ply, b, 1 + b[bonusField] / 100)
        end,
        remove = function(ply, value)
            local b = GetBuffState(ply)
            b[bonusField] = math.max(0, (b[bonusField] or 0) - value)
            applyFn(ply, b, 1 + b[bonusField] / 100)
        end,
    }
end

local function MakeMaxStatBuff(bonusField, baseField, read, write)
    local function refresh(ply, b)
        if not b[baseField] then b[baseField] = read(ply) end
        write(ply, math.max(1, b[baseField] + (b[bonusField] or 0)))
    end
    return {
        apply = function(ply, value)
            local b = GetBuffState(ply)
            b[bonusField] = (b[bonusField] or 0) + value
            refresh(ply, b)
        end,
        remove = function(ply, value)
            local b = GetBuffState(ply)
            b[bonusField] = math.max(0, (b[bonusField] or 0) - value)
            refresh(ply, b)
        end
    }
end

BUFFS.Types = {
    max_health = MakeMaxStatBuff("MaxHealthBonus", "BaseMaxHealth",
        function(ply) return ply:GetMaxHealth() end,
        function(ply, v)
            ply:SetMaxHealth(v)
            if ply:Health() > v then ply:SetHealth(v) end
        end),

    max_armor = MakeMaxStatBuff("MaxArmorBonus", "BaseMaxArmor",
        function(ply) return ply:GetMaxArmor() end,
        function(ply, v)
            ply:SetMaxArmor(v)
            if ply:Armor() > v then ply:SetArmor(v) end
        end),

    health_regen = MakeSimpleBuff("HealthRegen", 0, 0),
    armor_regen = MakeSimpleBuff("ArmorRegen", 0, 0),

    speed = MakePercentBaselineBuff("SpeedBonus",
        {
            { field = "BaseWalkSpeed", read = function(p) return p:GetWalkSpeed() end },
            { field = "BaseRunSpeed",  read = function(p) return p:GetRunSpeed()  end },
        },
        function(ply, b, mult)
            ply:SetWalkSpeed(b.BaseWalkSpeed * mult)
            ply:SetRunSpeed(b.BaseRunSpeed * mult)
        end),

    jump_power = MakePercentBaselineBuff("JumpBonus",
        { { field = "BaseJumpPower", read = function(p) return p:GetJumpPower() end } },
        function(ply, b, mult) ply:SetJumpPower(b.BaseJumpPower * mult) end),

    damage_bonus = MakeSimpleBuff("DamageBonus", 0, 0),
    damage_resistance = MakeSimpleBuff("DamageResistRaw", 0, 0, { extraSync = resistSync }),

    gravity = {
        apply = function(ply, value) ply:SetGravity(value / 100) end,
        remove = function(ply) ply:SetGravity(1) end,
    },

    fall_damage = MakeSimpleBuff("FallDamageReduce", 0, 0, { applyCap = 100 }),
}

for buffId, handler in pairs(BUFFS.Types) do
    local meta = KrakensStore.BuffDefs.Types[buffId]
    if meta then
        meta.apply = handler.apply
        meta.remove = handler.remove
        BUFFS.Types[buffId] = meta
    end
end

function BUFFS.ApplyBuff(ply, buffType, value, itemId)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local buffDef = BUFFS.Types[buffType]
    if not buffDef then return false end

    value = tonumber(value) or 0
    if value == 0 then return false end
    value = math.Clamp(value, -1000, 1000)

    local steamId = ply:SteamID64()
    BUFFS.ActiveBuffs[steamId] = BUFFS.ActiveBuffs[steamId] or {}

    local existing
    for _, buff in ipairs(BUFFS.ActiveBuffs[steamId]) do
        if buff.type == buffType and (not itemId or buff.itemId == itemId) then
            existing = buff
            break
        end
    end

    if existing then
        buffDef.remove(ply, existing.value)
        existing.value = value
        existing.itemId = itemId
    else
        table.insert(BUFFS.ActiveBuffs[steamId], { type = buffType, value = value, itemId = itemId })
    end
    buffDef.apply(ply, value)

    return true
end

function BUFFS.RemoveBuff(ply, buffType, itemId)
    if not IsValid(ply) or not ply:IsPlayer() then return false end

    local steamId = ply:SteamID64()
    if not BUFFS.ActiveBuffs[steamId] then return false end

    local buffDef = BUFFS.Types[buffType]
    if not buffDef then return false end

    for i = #BUFFS.ActiveBuffs[steamId], 1, -1 do
        local buff = BUFFS.ActiveBuffs[steamId][i]

        if buff.type == buffType and (not itemId or buff.itemId == itemId) then
            buffDef.remove(ply, buff.value)
            table.remove(BUFFS.ActiveBuffs[steamId], i)

            if itemId then break end
        end
    end

    return true
end

function BUFFS.CleanupPlayer(steamId)
    BUFFS.ActiveBuffs[steamId] = nil
end

function BUFFS.ResetPlayerState(ply)
    BUFFS.ActiveBuffs[ply:SteamID64()] = nil
    local b = GetBuffState(ply)
    local base = {
        BaseWalkSpeed = b.BaseWalkSpeed or ply:GetWalkSpeed(),
        BaseRunSpeed = b.BaseRunSpeed or ply:GetRunSpeed(),
        BaseJumpPower = b.BaseJumpPower or ply:GetJumpPower(),
        BaseMaxHealth = math.max(1, b.BaseMaxHealth or ply:GetMaxHealth()),
        BaseMaxArmor = b.BaseMaxArmor or ply:GetMaxArmor(),
    }
    ply.KS_Buffs = base

    ply:SetWalkSpeed(base.BaseWalkSpeed)
    ply:SetRunSpeed(base.BaseRunSpeed)
    ply:SetJumpPower(base.BaseJumpPower)
    ply:SetMaxHealth(base.BaseMaxHealth)
    ply:SetMaxArmor(base.BaseMaxArmor)
    if ply:Health() > base.BaseMaxHealth then ply:SetHealth(base.BaseMaxHealth) end
    if ply:Armor() > base.BaseMaxArmor then ply:SetArmor(base.BaseMaxArmor) end
    ply:SetGravity(1)
end

hook.Add("EntityTakeDamage", "KrakensStore_DamageModifiers", function(target, dmginfo)
    local attacker = dmginfo:GetAttacker()
    if IsValid(attacker) and attacker:IsPlayer() then
        local b = attacker.KS_Buffs
        local bonus = b and b.DamageBonus or 0
        if bonus > 0 then dmginfo:SetDamage(dmginfo:GetDamage() * (1 + bonus / 100)) end
    end
    if IsValid(target) and target:IsPlayer() then
        local b = target.KS_Buffs
        local resist = b and b.DamageResist or 0
        if resist > 0 then dmginfo:SetDamage(dmginfo:GetDamage() * (1 - resist / 100)) end
    end
end)

hook.Add("GetFallDamage", "KrakensStore_FallDamage", function(ply, speed)
    local b = ply.KS_Buffs
    local reduction = b and b.FallDamageReduce or 0
    if reduction > 0 then return (speed / 8) * (1 - reduction / 100) end
end)

timer.Create("KrakensStore_Regeneration", 1, 0, function()
    for _, ply in player.Iterator() do
        local b = ply.KS_Buffs
        if not b or not ply:Alive() then continue end

        local hp = b.HealthRegen or 0
        if hp > 0 then
            local cur, max = ply:Health(), ply:GetMaxHealth()
            if cur < max then ply:SetHealth(math.min(cur + hp, max)) end
        end

        local ar = b.ArmorRegen or 0
        if ar > 0 then
            local cur, maxA = ply:Armor(), ply:GetMaxArmor()
            if cur < maxA then ply:SetArmor(math.min(cur + ar, maxA)) end
        end
    end
end)

KrakensStore.ServerInventory = KrakensStore.ServerInventory or {}

local SInv = KrakensStore.ServerInventory
local Fire = KrakensStore.Fire

local L = KrakensStore.L

SInv.AppliedByPlayer = SInv.AppliedByPlayer or {}
SInv.Locks = SInv.Locks or {}

local InvCache = KrakensStore.Inventory.Cache

local function GetApplied(ply)
    if not IsValid(ply) then return nil end
    local sid = ply:SteamID64()
    SInv.AppliedByPlayer[sid] = SInv.AppliedByPlayer[sid] or {}
    return SInv.AppliedByPlayer[sid]
end

local LOCK_TIMEOUT = 30

local lockToken = 0

local function NextLockToken()
    lockToken = lockToken + 1
    return lockToken
end

function SInv.AcquireItemLock(steamId, itemId, token)
    SInv.Locks[steamId] = SInv.Locks[steamId] or {}
    if SInv.Locks[steamId][itemId] then return false end
    SInv.Locks[steamId][itemId] = { token = token, at = SysTime() }
    return true
end

function SInv.ReleaseItemLock(steamId, itemId, token)
    local locks = SInv.Locks[steamId]
    local held = locks and locks[itemId]
    if not held then return end
    if token and held.token ~= token then return end
    locks[itemId] = nil
end

timer.Create("KrakensStore_LockSweep", 30, 0, function()
    local now = SysTime()
    for steamId, locks in pairs(SInv.Locks) do
        for itemId, held in pairs(locks) do
            if now - held.at > LOCK_TIMEOUT then locks[itemId] = nil end
        end
        if not next(locks) then SInv.Locks[steamId] = nil end
    end
end)

function SInv.CleanupPlayer(steamId)
    SInv.Locks[steamId] = nil
    InvCache[steamId] = nil
    SInv.AppliedByPlayer[steamId] = nil
end

function SInv.ResetApplied(ply)
    if IsValid(ply) then SInv.AppliedByPlayer[ply:SteamID64()] = {} end
end

local function MakeInvItem(itemId, storeItem, existing, quantity)
    if existing and not KrakensStore.Inventory.IsExpired(existing) then
        local newItem = table.Copy(existing)
        newItem.quantity = (newItem.quantity or 1) + quantity
        return newItem
    end
    local now = KrakensStore.Now()
    local duration = tonumber(storeItem.duration) or -1
    return {
        itemId = itemId,
        quantity = quantity,
        equipped = false,
        purchased = now,
        expires = duration > 0 and (now + duration) or -1,
        customData = {},
    }
end

function SInv.LoadPlayer(ply)
    if not IsValid(ply) or ply._KSLoading then return end
    local steamId = ply:SteamID64()
    if InvCache[steamId] then return end

    if not KrakensStore.Data.IsLoaded() then
        KrakensStore.Lifecycle.WhenReady("inventory:" .. steamId, function()
            if IsValid(ply) then SInv.LoadPlayer(ply) end
        end)
        return
    end

    ply._KSLoading = true
    SInv.ResetApplied(ply)

    KrakensStore.Data.GetPlayerData(steamId, function(data, err)
        if not IsValid(ply) then return end
        if err or not data then
            ply._KSLoading = nil
            KrakensStore.Log("error", "Player data load failed for " .. steamId .. ": " .. tostring(err or "no row"))
            return
        end

        ply.KrakensStoreData = data

        KrakensStore.Data.GetPlayerInventory(steamId, function(inventory, invErr)
            if not IsValid(ply) then return end
            ply._KSLoading = nil
            if invErr then
                KrakensStore.Log("error", "Inventory load failed for " .. steamId .. ": " .. tostring(invErr))
                return
            end

            local valid = {}
            local expired = {}
            for itemId, invItem in pairs(inventory) do
                if KrakensStore.Inventory.IsExpired(invItem) then
                    expired[#expired + 1] = itemId
                else
                    valid[itemId] = invItem
                end
            end
            if #expired > 0 then KrakensStore.Data.RemoveInventoryItems(steamId, expired) end

            InvCache[steamId] = valid
            SInv.SyncInventory(ply)
            SInv.ApplyEquippedItems(ply)
            KrakensStore.Integrations.RestoreUnlocks(ply)
            hook.Run("KrakensStore_PlayerLoaded", ply)
        end)
    end)
end

function SInv.SavePlayer(ply)
    if not IsValid(ply) then return end
    local data = ply.KrakensStoreData
    if data then
        data.lastSeen = os.time()
        KrakensStore.Data.SavePlayerData(ply:SteamID64(), data)
    end
end

function SInv.UnloadPlayer(ply)
    if not IsValid(ply) then return end
    SInv.RemoveEquippedItems(ply)
    SInv.SavePlayer(ply)
end

local CHUNK_SIZE = 50

function SInv.SyncInventory(ply, inFlightOnly)
    local inventory = IsValid(ply) and InvCache[ply:SteamID64()]
    if not inventory then return end
    local timerName = "KrakensStore_InvSync_" .. ply:SteamID64()
    if inFlightOnly and not timer.Exists(timerName) then return end

    local chunks = {}
    local current, n = {}, 0
    for itemId, invItem in pairs(inventory) do
        current[itemId] = invItem
        n = n + 1
        if n >= CHUNK_SIZE then chunks[#chunks + 1] = current; current, n = {}, 0 end
    end
    if n > 0 or #chunks == 0 then chunks[#chunks + 1] = current end

    local total = #chunks
    local idx = 0
    local function SendNext()
        idx = idx + 1
        KF.Net.Send("KrakensStore_SyncInventory", function()
            net.WriteUInt(idx, 16)
            net.WriteUInt(total, 16)
            return KF.Net.WriteCompressed(chunks[idx], 32)
        end, ply)
        if idx < total then return end
        timer.Remove(timerName)
        hook.Run("KrakensStore_InventoryFullSynced", ply)
    end

    timer.Remove(timerName)
    SendNext()
    if total > 1 then
        timer.Create(timerName, 0.05, total - 1, function()
            if IsValid(ply) then SendNext() else timer.Remove(timerName) end
        end)
    end
end

function SInv.SyncItem(ply, itemId, invItem)
    if not IsValid(ply) then return end
    KF.Net.Send("KrakensStore_UpdateItem", function()
        net.WriteString(itemId)
        net.WriteBool(invItem ~= nil)
        if invItem then KF.Net.WriteCompressed(invItem, 16) end
    end, ply)
    hook.Run("KrakensStore_InventoryItemSynced", ply, itemId, invItem)
end

local function FailCb(cb, msg) if cb then cb(false, msg) end return false, msg end

local function ValidateAction(ply, itemId, quantity, onComplete, needQuantity)
    if not KrakensStore.Validation.Player(ply) then FailCb(onComplete, L("err_invalid_player")) return end
    local sanitized, idErr = KrakensStore.Validation.ItemId(itemId)
    if not sanitized then FailCb(onComplete, idErr) return end
    local qty = quantity
    if needQuantity then
        qty = KrakensStore.Validation.Quantity(quantity) or 1
    end
    if not KrakensStore.DB.IsConnected() then FailCb(onComplete, L("err_store_not_ready")) return end
    return sanitized, qty
end

local function ToggleEquip(ply, itemId, equip, onComplete)
    itemId = ValidateAction(ply, itemId, nil, onComplete, false)
    if not itemId then return false end

    local storeItem = KrakensStore.Items.Get(itemId)
    if not storeItem then return FailCb(onComplete, L("err_item_not_found")) end

    local displaced = {}
    local locks = { itemId }

    if equip then
        local typeData = KrakensStore.types[storeItem.type]
        if typeData and typeData.uniqueEquip then
            for otherId, otherItem in pairs(InvCache[ply:SteamID64()] or {}) do
                if otherId ~= itemId and otherItem.equipped then
                    local otherStore = KrakensStore.Items.Get(otherId)
                    if otherStore and otherStore.type == storeItem.type then
                        displaced[#displaced + 1] = { id = otherId, storeItem = otherStore }
                        locks[#locks + 1] = otherId
                    end
                end
            end
        end
    end

    return SInv.Commit({
        ply = ply,
        itemId = itemId,
        locks = locks,
        sync = locks,

        precheck = function(tx)
            local canDo, err
            if equip then
                canDo, err = KrakensStore.Inventory.CanEquip(ply, itemId)
            else
                canDo, err = KrakensStore.Inventory.CanUnequip(ply, itemId)
            end
            if not canDo then return false, err end
            if equip then
                local ok, reason = KrakensStore.TypeHelpers.ValidateWorkbenchRequirement(ply, storeItem, "err_must_use_workbench")
                if ok == false then return false, reason end
            end
            if not tx.inventory[itemId] then return false, L("err_inventory_out_of_sync") end
            return true
        end,

        stage = function(tx)
            for _, entry in ipairs(displaced) do
                local other = tx.inventory[entry.id]
                if other then
                    other.equipped = false
                    SInv.RemoveItemEffect(ply, entry.storeItem, other)
                end
            end
            local invItem = tx.inventory[itemId]
            invItem.equipped = equip
            if equip then SInv.ApplyItemEffect(ply, storeItem, invItem)
            else SInv.RemoveItemEffect(ply, storeItem, invItem) end
        end,

        revert = function(tx)
            local invItem = tx.inventory[itemId]
            if invItem then
                invItem.equipped = not equip
                if equip then SInv.RemoveItemEffect(ply, storeItem, invItem)
                else SInv.ApplyItemEffect(ply, storeItem, invItem) end
            end
            for _, entry in ipairs(displaced) do
                local other = tx.inventory[entry.id]
                if other then
                    other.equipped = true
                    SInv.ApplyItemEffect(ply, entry.storeItem, other)
                end
            end
        end,

        queries = function(tx)
            local queries = {}
            for _, entry in ipairs(displaced) do
                queries[#queries + 1] = KrakensStore.Data.BuildSaveInventoryItemQuery(tx.steamId, entry.id, tx.inventory[entry.id])
            end
            queries[#queries + 1] = KrakensStore.Data.BuildSaveInventoryItemQuery(tx.steamId, itemId, tx.inventory[itemId])
            return queries
        end,

        log = { type = equip and "equip" or "unequip",
                payload = { itemId = itemId, itemName = storeItem.name } },

        after = function(tx)
            for _, entry in ipairs(displaced) do
                KrakensStore.Data.Log("unequip", tx.steamId, { itemId = entry.id, itemName = entry.storeItem.name })
                hook.Run("KrakensStore_ItemUnequipped", ply, entry.storeItem, tx.inventory[entry.id])
            end
            hook.Run(equip and "KrakensStore_ItemEquipped" or "KrakensStore_ItemUnequipped", ply, storeItem, tx.inventory[itemId])
        end,

        onComplete = onComplete,
    })
end

local function ReleaseAll(steamId, ids, token)
    for _, id in ipairs(ids) do SInv.ReleaseItemLock(steamId, id, token) end
end

function SInv.Commit(tx)
    local ply = tx.ply
    if not IsValid(ply) then return FailCb(tx.onComplete, L("err_invalid_player")) end
    if not KrakensStore.DB.IsConnected() then return FailCb(tx.onComplete, L("err_store_not_ready")) end

    local steamId = ply:SteamID64()
    tx.steamId = steamId
    tx.inventory = InvCache[steamId]
    if not tx.inventory then return FailCb(tx.onComplete, L("err_store_not_ready")) end

    if tx.precheck then
        local ok, reason = tx.precheck(tx)
        if not ok then return FailCb(tx.onComplete, reason) end
    end

    local token = NextLockToken()
    local locks = tx.locks or { tx.itemId }
    local held = {}
    for _, id in ipairs(locks) do
        if id then
            if not SInv.AcquireItemLock(steamId, id, token) then
                ReleaseAll(steamId, held, token)
                return FailCb(tx.onComplete, L("err_action_in_progress"))
            end
            held[#held + 1] = id
        end
    end

    local staged = tx.stage and tx.stage(tx)
    if staged == false then
        ReleaseAll(steamId, held, token)
        return FailCb(tx.onComplete, tx.stageError or L("err_action_failed"))
    end

    local currency = tx.currency
    if currency and currency.amount and currency.amount > 0 then
        if currency.dir == "deduct" then KF.Currency.Remove(ply, currency.amount, KrakensStore.CurrencyKey)
        else KF.Currency.Add(ply, currency.amount, KrakensStore.CurrencyKey) end
    end

    local function rollback()
        if currency and currency.amount and currency.amount > 0 then
            if IsValid(ply) then
                if currency.dir == "deduct" then KF.Currency.Add(ply, currency.amount, KrakensStore.CurrencyKey)
                else KF.Currency.Remove(ply, currency.amount, KrakensStore.CurrencyKey) end
            else
                KrakensStore.Data.QueueRecovery(steamId, {
                    amount = currency.amount,
                    type = currency.dir == "deduct" and "refund" or "clawback",
                    reason = "db_write_failed",
                })
            end
        end
        if tx.revert then tx.revert(tx) end
    end

    local queries = tx.queries and tx.queries(tx) or {}

    KrakensStore.DB.Transaction(queries, function(ok)
        if not ok then
            rollback()
            ReleaseAll(steamId, held, token)
            return FailCb(tx.onComplete, tx.failMessage or L("err_action_failed"))
        end

        if tx.effect then tx.effect(tx) end
        ReleaseAll(steamId, held, token)

        if IsValid(ply) then
            for _, id in ipairs(tx.sync or { tx.itemId }) do
                if id then SInv.SyncItem(ply, id, tx.inventory[id]) end
            end
            SInv.SyncInventory(ply, true)
            if tx.savePlayerData then
                KrakensStore.Data.SavePlayerData(steamId, ply.KrakensStoreData)
            end
        end

        if tx.log then
            KrakensStore.Data.Log(tx.log.type, steamId, tx.log.payload)
        end
        if tx.after then tx.after(tx) end

        Fire(tx.onComplete, true, tx.result)
    end)

    return true
end

local function RowQuery(itemId)
    return function(tx)
        if tx.row then return { KrakensStore.Data.BuildSaveInventoryItemQuery(tx.steamId, itemId, tx.row) } end
        return { KrakensStore.Data.BuildRemoveInventoryItemQuery(tx.steamId, itemId) }
    end
end

local function StageDecrement(tx, ply, itemId, storeItem, quantity)
    local invItem = tx.inventory[itemId]
    tx.previous = table.Copy(invItem)
    tx.wasEquipped = invItem.equipped
    if tx.wasEquipped and storeItem then
        invItem.equipped = false
        SInv.RemoveItemEffect(ply, storeItem, invItem)
    end
    local newQty = (invItem.quantity or 1) - quantity
    if newQty <= 0 then tx.inventory[itemId] = nil else invItem.quantity = newQty end
    tx.row = tx.inventory[itemId]
end

local function RevertDecrement(tx, ply, itemId, storeItem)
    tx.inventory[itemId] = tx.previous
    if tx.wasEquipped and storeItem and IsValid(ply) then
        SInv.ApplyItemEffect(ply, storeItem, tx.previous)
    end
end

local function AddStats(ply, deltas)
    local data = ply.KrakensStoreData or {}
    data.stats = data.stats or {}
    for key, delta in pairs(deltas) do
        data.stats[key] = (data.stats[key] or 0) + delta
    end
    ply.KrakensStoreData = data
end

function SInv.PurchaseItem(ply, itemId, quantity, onComplete, external)
    itemId, quantity = ValidateAction(ply, itemId, quantity, onComplete, true)
    if not itemId then return false end

    local storeItem = KrakensStore.Items.Get(itemId)
    if not storeItem then return FailCb(onComplete, L("err_item_not_found")) end

    local source = istable(external) and external.source or nil
    local price = source and math.max(0, math.floor(tonumber(external.price) or 0)) or KrakensStore:GetItemPrice(ply, itemId, quantity)
    local prevStock = -1

    return SInv.Commit({
        ply = ply,
        itemId = itemId,
        currency = not source and { dir = "deduct", amount = price } or nil,
        failMessage = L("err_purchase_failed"),
        savePlayerData = true,

        precheck = function()
            local canPurchase, err = KrakensStore.Inventory.CanPurchase(ply, itemId, quantity, source ~= nil)
            if not canPurchase then return false, err end
            local allowed, reason = hook.Run("KrakensStore_CanPlayerPurchaseItem", ply, storeItem, quantity, price, source)
            if allowed == false then return false, reason or L("err_cannot_purchase") end
            return true
        end,

        stage = function(tx)
            tx.previous = tx.inventory[itemId]
            tx.row = MakeInvItem(itemId, storeItem, tx.inventory[itemId], quantity)
            tx.inventory[itemId] = tx.row
            if not source then prevStock = tonumber(storeItem.stock) or -1 end
            if prevStock >= 0 then storeItem.stock = math.max(0, prevStock - quantity) end
            AddStats(ply, { totalSpent = price, itemsPurchased = quantity })
        end,

        revert = function(tx)
            tx.inventory[itemId] = tx.previous
            if prevStock >= 0 then
                storeItem.stock = math.max(0, (tonumber(storeItem.stock) or 0) + quantity)
            end
            if IsValid(ply) then AddStats(ply, { totalSpent = -price, itemsPurchased = -quantity }) end
        end,

        queries = RowQuery(itemId),

        log = { type = "purchase",
                payload = { itemId = itemId, itemName = storeItem.name, quantity = quantity, price = price, source = source } },

        after = function()
            if prevStock >= 0 and KrakensStore.Items.Get(itemId) == storeItem then KrakensStore.Items.Save(storeItem) end
            hook.Run("KrakensStore_ItemPurchased", ply, storeItem, quantity, price, source)
        end,

        onComplete = onComplete,
    })
end

function SInv.SellItem(ply, itemId, quantity, onComplete, external)
    itemId, quantity = ValidateAction(ply, itemId, quantity, onComplete, true)
    if not itemId then return false end

    local storeItem = KrakensStore.Items.Get(itemId)
    if not storeItem then return FailCb(onComplete, L("err_item_not_found")) end

    local source = istable(external) and external.source or nil
    local refund = source and math.max(0, math.floor(tonumber(external.price) or 0)) or KrakensStore:GetItemRefund(ply, itemId, quantity)

    return SInv.Commit({
        ply = ply,
        itemId = itemId,
        currency = not source and { dir = "credit", amount = refund } or nil,
        failMessage = L("err_sale_failed"),
        savePlayerData = true,
        result = refund,

        precheck = function(tx)
            local canSell, err = KrakensStore.Inventory.CanSell(ply, itemId, quantity, source ~= nil)
            if not canSell then return false, err end
            if not tx.inventory[itemId] then return false, L("err_item_not_in_inv") end
            return true
        end,

        stage = function(tx)
            StageDecrement(tx, ply, itemId, storeItem, quantity)
            AddStats(ply, { totalEarned = refund, itemsSold = quantity })
        end,

        revert = function(tx)
            RevertDecrement(tx, ply, itemId, storeItem)
            if IsValid(ply) then AddStats(ply, { totalEarned = -refund, itemsSold = -quantity }) end
        end,

        queries = RowQuery(itemId),

        log = { type = "sale",
                payload = { itemId = itemId, itemName = storeItem.name, quantity = quantity, refund = refund, source = source } },

        after = function()
            local stock = source and -1 or (tonumber(storeItem.stock) or -1)
            if stock >= 0 and KrakensStore.Items.Get(itemId) == storeItem then
                storeItem.stock = stock + quantity
                KrakensStore.Items.Save(storeItem)
            end
            hook.Run("KrakensStore_ItemSold", ply, storeItem, quantity, refund, source)
        end,

        onComplete = onComplete,
    })
end

function SInv.EquipItem(ply, itemId, cb) return ToggleEquip(ply, itemId, true, cb) end
function SInv.UnequipItem(ply, itemId, cb) return ToggleEquip(ply, itemId, false, cb) end

local function DispatchTypeEvent(ply, storeItem, invItem, typeEvent, fallback)
    local typeData = KrakensStore.types[storeItem.type]
    if not typeData then return end
    local fn = typeData[typeEvent] or (fallback and typeData[fallback])
    if fn then pcall(fn, ply, storeItem.data or {}, invItem) end
end

function SInv.ApplyItemEffect(ply, storeItem, invItem)
    if not IsValid(ply) or not storeItem then return end
    local applied = GetApplied(ply)
    if applied and storeItem.id then applied[storeItem.id] = true end
    DispatchTypeEvent(ply, storeItem, invItem, "onEquip")
end

function SInv.RemoveItemEffect(ply, storeItem, invItem)
    if not IsValid(ply) or not storeItem then return end
    local applied = GetApplied(ply)
    if applied and storeItem.id then applied[storeItem.id] = nil end
    DispatchTypeEvent(ply, storeItem, invItem, "onUnequip")
end

function SInv.ApplyEquippedItems(ply)
    if not IsValid(ply) then return end
    SInv.EnforceEquippedAccess(ply, false)
    local applied = GetApplied(ply)
    local equipped = KrakensStore.Inventory.GetEquippedItems(ply)
    for itemId, invItem in pairs(equipped) do
        if applied and applied[itemId] then continue end
        local storeItem = KrakensStore.Items.Get(itemId)
        if storeItem then
            DispatchTypeEvent(ply, storeItem, invItem, "onLoadout", "onEquip")
            if applied then applied[itemId] = true end
        end
    end
end

function SInv.RemoveEquippedItems(ply)
    if not IsValid(ply) then return end
    local applied = GetApplied(ply)
    local equipped = KrakensStore.Inventory.GetEquippedItems(ply)
    for itemId, invItem in pairs(equipped) do
        local storeItem = KrakensStore.Items.Get(itemId)
        if storeItem then DispatchTypeEvent(ply, storeItem, invItem, "onUnequip") end
        if applied then applied[itemId] = nil end
    end
end

function SInv.EnforceEquippedAccess(ply, notify)
    if not IsValid(ply) then return 0 end
    local inventory = InvCache[ply:SteamID64()]
    if not inventory then return 0 end
    local removed = 0
    for itemId, invItem in pairs(inventory) do
        if invItem.equipped then
            local storeItem = KrakensStore.Items.Get(itemId)
            if storeItem then
                local canAccess, accessErr = KrakensStore.Inventory.CanAccessItem(ply, itemId, storeItem)
                if not canAccess and SInv.UnequipItem(ply, itemId) then
                    removed = removed + 1
                    if notify then
                        KrakensStore._NetHelpers.SendNotification(ply, (accessErr or L("err_no_item_access")) .. ": " .. (storeItem.name or itemId), "error")
                    end
                end
            end
        end
    end
    return removed
end

function SInv.GiveItem(admin, targetPly, itemId, quantity, customData, onComplete)
    if not IsValid(targetPly) then return FailCb(onComplete, L("err_invalid_player")) end
    quantity = KrakensStore.Validation.Quantity(quantity) or 1

    local storeItem = KrakensStore.Items.Get(itemId)
    if not storeItem then return FailCb(onComplete, L("err_item_not_found")) end

    return SInv.Commit({
        ply = targetPly,
        itemId = itemId,

        stage = function(tx)
            tx.previous = tx.inventory[itemId]
            local row = MakeInvItem(itemId, storeItem, tx.previous, quantity)
            if istable(customData) then
                if customData.expires ~= nil then
                    local expires = tonumber(customData.expires)
                    row.expires = (expires and expires > 0) and expires or -1
                end
                if customData.equipped == true and KrakensStore.Inventory.CanAccessItem(targetPly, itemId, storeItem) then
                    row.equipped = true
                elseif customData.equipped == false then
                    row.equipped = false
                end
                local cd = table.Copy(customData)
                cd.expires, cd.equipped, cd.quantity = nil, nil, nil
                if next(cd) then row.customData = cd end
            end
            tx.row = row
            tx.inventory[itemId] = row
            tx.wasEquipped = tx.previous and tx.previous.equipped
        end,

        revert = function(tx) tx.inventory[itemId] = tx.previous end,

        queries = RowQuery(itemId),

        effect = function(tx)
            if tx.wasEquipped and not tx.row.equipped then
                SInv.RemoveItemEffect(targetPly, storeItem, tx.previous)
            elseif tx.row.equipped and not tx.wasEquipped then
                SInv.ApplyItemEffect(targetPly, storeItem, tx.row)
            end
        end,

        log = { type = "admin_give",
                payload = { admin = IsValid(admin) and admin:SteamID64() or "CONSOLE",
                            itemId = itemId, itemName = storeItem.name, quantity = quantity } },

        after = function(tx) hook.Run("KrakensStore_ItemGiven", targetPly, storeItem, tx.row) end,
        onComplete = onComplete,
    })
end

function SInv.TakeItem(admin, targetPly, itemId, quantity, onComplete)
    if not IsValid(targetPly) then return FailCb(onComplete, L("err_invalid_player")) end
    quantity = KrakensStore.Validation.Quantity(quantity) or 1

    local storeItem = KrakensStore.Items.Get(itemId)

    return SInv.Commit({
        ply = targetPly,
        itemId = itemId,

        precheck = function(tx)
            if not tx.inventory[itemId] then return false, L("err_item_not_in_inv") end
            return true
        end,

        stage = function(tx) StageDecrement(tx, targetPly, itemId, storeItem, quantity) end,
        revert = function(tx) RevertDecrement(tx, targetPly, itemId, storeItem) end,
        queries = RowQuery(itemId),

        log = { type = "admin_take",
                payload = { admin = IsValid(admin) and admin:SteamID64() or "CONSOLE",
                            itemId = itemId, itemName = storeItem and storeItem.name or itemId, quantity = quantity } },

        after = function() hook.Run("KrakensStore_ItemTaken", targetPly, storeItem, quantity) end,
        onComplete = onComplete,
    })
end

function SInv.ConsumeItem(ply, itemId, lockHeld, onComplete)
    local steamId = IsValid(ply) and ply:SteamID64() or nil
    if lockHeld and steamId then SInv.ReleaseItemLock(steamId, itemId) end

    local storeItem = KrakensStore.Items.Get(itemId)

    return SInv.Commit({
        ply = ply,
        itemId = itemId,

        precheck = function(tx)
            if not tx.inventory[itemId] then return false, L("err_item_not_in_inv") end
            return true
        end,

        stage = function(tx) StageDecrement(tx, ply, itemId, storeItem, 1) end,
        revert = function(tx) RevertDecrement(tx, ply, itemId, storeItem) end,
        queries = RowQuery(itemId),

        onComplete = onComplete,
    })
end

function SInv.PruneExpiredItems(ply)
    if not IsValid(ply) then return 0 end
    local inventory = InvCache[ply:SteamID64()]
    if not inventory then return 0 end

    local expired = {}
    for itemId, invItem in pairs(inventory) do
        if KrakensStore.Inventory.IsExpired(invItem) then expired[#expired + 1] = itemId end
    end
    if #expired == 0 then return 0 end

    SInv.Commit({
        ply = ply,
        locks = expired,
        sync = expired,

        stage = function(tx)
            tx.previous = {}
            for _, itemId in ipairs(expired) do
                local invItem = tx.inventory[itemId]
                tx.previous[itemId] = invItem
                local storeItem = KrakensStore.Items.Get(itemId)
                if invItem.equipped and storeItem then
                    SInv.RemoveItemEffect(ply, storeItem, invItem)
                end
                tx.inventory[itemId] = nil
            end
        end,

        revert = function(tx)
            for itemId, row in pairs(tx.previous) do tx.inventory[itemId] = row end
        end,

        queries = function(tx)
            local queries = {}
            for _, itemId in ipairs(expired) do
                queries[#queries + 1] = KrakensStore.Data.BuildRemoveInventoryItemQuery(tx.steamId, itemId)
            end
            return queries
        end,

        after = function() hook.Run("KrakensStore_ItemsExpired", ply, expired) end,
    })

    return #expired
end

local pruneIndex = 0
timer.Create("KrakensStore_PruneExpiredOnline", 5, 0, function()
    local players = player.GetAll()
    if #players == 0 then return end
    pruneIndex = (pruneIndex % #players) + 1
    local ply = players[pruneIndex]
    if IsValid(ply) and InvCache[ply:SteamID64()] then
        SInv.PruneExpiredItems(ply)
        SInv.EnforceEquippedAccess(ply, false)
    end
end)

function SInv.ResetInventory(admin, targetPly, onComplete)
    if not IsValid(targetPly) then return FailCb(onComplete, L("err_invalid_player")) end

    local inventory = InvCache[targetPly:SteamID64()] or {}
    local itemIds = {}
    for itemId in pairs(inventory) do itemIds[#itemIds + 1] = itemId end
    if #itemIds == 0 then Fire(onComplete, true) return true end

    return SInv.Commit({
        ply = targetPly,
        locks = itemIds,
        sync = itemIds,

        stage = function(tx)
            tx.previous = {}
            tx.applied = SInv.AppliedByPlayer[tx.steamId]
            for _, itemId in ipairs(itemIds) do
                local invItem = tx.inventory[itemId]
                tx.previous[itemId] = invItem
                local storeItem = KrakensStore.Items.Get(itemId)
                if invItem.equipped and storeItem then
                    SInv.RemoveItemEffect(targetPly, storeItem, invItem)
                end
                tx.inventory[itemId] = nil
            end
            SInv.AppliedByPlayer[tx.steamId] = {}
        end,

        revert = function(tx)
            SInv.AppliedByPlayer[tx.steamId] = tx.applied
            for itemId, row in pairs(tx.previous) do
                tx.inventory[itemId] = row
                local storeItem = KrakensStore.Items.Get(itemId)
                if row.equipped and storeItem and IsValid(targetPly) then
                    SInv.ApplyItemEffect(targetPly, storeItem, row)
                end
            end
        end,

        queries = function(tx)
            local queries = {}
            for _, itemId in ipairs(itemIds) do
                queries[#queries + 1] = KrakensStore.Data.BuildRemoveInventoryItemQuery(tx.steamId, itemId)
            end
            return queries
        end,

        log = { type = "admin_reset",
                payload = { admin = IsValid(admin) and admin:SteamID64() or "CONSOLE" } },

        onComplete = onComplete,
    })
end

function SInv.PurgeItem(itemId, storeItem)
    if not itemId then return end
    storeItem = storeItem or KrakensStore.Items.Get(itemId)

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local inventory = InvCache[ply:SteamID64()]
            local invItem = inventory and inventory[itemId]
            if invItem then
                if invItem.equipped and storeItem then
                    SInv.RemoveItemEffect(ply, storeItem, invItem)
                end
                inventory[itemId] = nil
                SInv.SyncItem(ply, itemId, nil)
                SInv.SyncInventory(ply, true)
            end
        end
    end

    for steamId, inventory in pairs(InvCache) do
        inventory[itemId] = nil
        local applied = SInv.AppliedByPlayer[steamId]
        if applied then applied[itemId] = nil end
    end

    KrakensStore.Data.DeleteInventoryItemEverywhere(itemId)
end

local SPAWN_FRAMEWORKS = { helix = "helix", nut = "nutscript" }

local function GetPlayerSpawnTargets(ply)
    local targets = { usergroups = { ply:GetUserGroup() } }
    local job = ply.getJobTable and ply:getJobTable()
    if job then
        targets.jobs = job.command and { job.command }
        targets.jobCategories = job.category and { job.category }
    end
    for prefix, frameworkId in pairs(SPAWN_FRAMEWORKS) do
        local acc = KF.Integrations.GetAccessors(frameworkId)
        local char = acc.getChar(ply)
        if char then
            local faction, class = acc.getFaction(char), acc.getClass(char)
            local factionData, classData = acc.factionData(faction), acc.classData(class)
            targets[prefix .. "Factions"] = factionData and { factionData.uniqueID or tostring(faction) }
            targets[prefix .. "Classes"] = classData and { classData.uniqueID or tostring(class) }
        end
    end
    return targets
end

function KrakensStore.ApplySpawnAssignments(ply)
    local assignments = KrakensStore.SpawnAssignments or {}
    local playerTargets = GetPlayerSpawnTargets(ply)
    local itemsToGive, attsToGive = {}, {}
    for targetType, playerValues in pairs(playerTargets) do
        local typeAssignments = assignments[targetType] or {}
        for _, val in ipairs(playerValues) do
            local assign = typeAssignments[val]
            if assign then
                for _, itemId in ipairs(assign.items or {}) do itemsToGive[itemId] = true end
                for _, att in ipairs(assign.attachments or {}) do
                    attsToGive[att.system .. "_" .. att.id] = att
                end
            end
        end
    end
    local touched = {}
    for itemId in pairs(itemsToGive) do
        local item = KrakensStore.Items.Get(itemId)
        local typeDef = item and item.type and KrakensStore.types[item.type]
        if typeDef then
            local d = item.data or {}
            local invItem = { itemId = itemId, data = d, customData = {} }
            local grant = typeDef.onLoadout or typeDef.onEquip
            if grant then
                local ok, err = pcall(grant, ply, d, invItem)
                if not ok then
                    KrakensStore.Log("error", "ApplySpawnAssignment error for " .. tostring(itemId) .. ": " .. tostring(err))
                end
            elseif d.weaponClass then
                ply:Give(d.weaponClass)
            elseif d.attachmentId and typeDef.integration then
                if KrakensStore.Integrations.GiveAttachment(typeDef.integration, ply, d.attachmentId) then
                    touched[typeDef.integration] = true
                else
                    KrakensStore.Log("error", "ApplySpawnAssignment attachment failed for " .. tostring(itemId))
                end
            end
        end
    end
    for _, att in pairs(attsToGive) do
        if KrakensStore.Integrations.GiveAttachment(att.system, ply, att.id) then
            touched[att.system] = true
        else
            KrakensStore.Log("error", "SpawnAssignment " .. att.system .. " att error for " .. tostring(att.id))
        end
    end
    for system in pairs(touched) do KrakensStore.Integrations.SendAttachmentInventory(system, ply) end
end

local function ReapplyLoadout(ply, reset)
    local name = "KrakensStore_ReapplyLoadout_" .. ply:SteamID64()
    if not reset and timer.Exists(name) then return end
    timer.Create(name, 0.2, 1, function()
        if not IsValid(ply) or not ply:Alive() then return end
        if reset then
            BUFFS.ResetPlayerState(ply)
            SInv.ResetApplied(ply)
        end
        if InvCache[ply:SteamID64()] then
            SInv.EnforceEquippedAccess(ply, true)
            SInv.ApplyEquippedItems(ply)
        end
        KrakensStore.ApplySpawnAssignments(ply)
        KrakensStore.Integrations.RestoreUnlocks(ply)
        hook.Run("KrakensStore_LoadoutApplied", ply)
    end)
end

hook.Add("PlayerLoadout", "KrakensStore_Loadout", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        local b = GetBuffState(ply)
        b.BaseWalkSpeed = ply:GetWalkSpeed()
        b.BaseRunSpeed = ply:GetRunSpeed()
        b.BaseJumpPower = ply:GetJumpPower()
        b.BaseMaxHealth = ply:GetMaxHealth()
        b.BaseMaxArmor = ply:GetMaxArmor()
    end)
    ReapplyLoadout(ply, true)
end)

hook.Add("OnPlayerChangedTeam", "KrakensStore_EnforceItemAccess", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        ReapplyLoadout(ply)
    end)
end)

hook.Add("PlayerInitialSpawn", "KrakensStore_LoadInventory", SInv.LoadPlayer)

hook.Add("PlayerDisconnected", "KrakensStore_PlayerCleanup", function(ply)
    local steamId = ply:SteamID64()
    SInv.UnloadPlayer(ply)
    SInv.CleanupPlayer(steamId)
    KrakensStore.Queue.Cleanup(steamId)
    KrakensStore.Data.FlushPendingPlayer(steamId)
    BUFFS.CleanupPlayer(steamId)
    KrakensStore.Lifecycle.CancelWaitsFor(steamId)
    KrakensStore._NetHelpers.AdminUnwatchAll(ply)
    timer.Remove("KrakensStore_ReapplyLoadout_" .. steamId)
    hook.Run("KrakensStore_PlayerCleanup", ply, steamId)
end)

hook.Add("ShutDown", "KrakensStore_ShutdownSave", function()
    KrakensStore.DB.SetShutdownMode()
    for _, ply in ipairs(player.GetAll()) do SInv.UnloadPlayer(ply) end
    KrakensStore.Data.FlushAllPlayerData()
end)
