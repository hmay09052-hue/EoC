KrakensStore.Queue = KrakensStore.Queue or {}

local Q = KrakensStore.Queue

local _queues = {}

local QUEUE_OP_TIMEOUT = 30
local MAX_QUEUE_DEPTH = 10

function Q.Enqueue(steamId, label, fn)
    if not steamId or not isfunction(fn) then return false, "invalid_args" end

    _queues[steamId] = _queues[steamId] or { ops = {}, active = false }
    local queue = _queues[steamId]

    if #queue.ops >= MAX_QUEUE_DEPTH then
        KrakensStore.Log("warn", "[Queue] Rejected '" .. label .. "' for " .. steamId .. ": queue full (" .. #queue.ops .. " pending)")
        return false, "queue_full"
    end

    table.insert(queue.ops, {
        label = label,
        fn = fn,
        enqueuedAt = SysTime(),
    })

    if not queue.active then
        Q._ProcessNext(steamId)
    end

    return true
end

function Q._ProcessNext(steamId)
    local queue = _queues[steamId]
    if not queue or #queue.ops == 0 then
        if queue then queue.active = false end
        return
    end

    queue.active = true
    local entry = table.remove(queue.ops, 1)

    local completed = false
    local timerName = "KSQueue_" .. steamId

    local function done()
        if completed then return end
        completed = true
        timer.Remove(timerName)
        timer.Simple(0, function()
            Q._ProcessNext(steamId)
        end)
    end

    timer.Create(timerName, QUEUE_OP_TIMEOUT, 1, function()
        if not completed then
            KrakensStore.Log("error", "[Queue] TIMEOUT: '" .. entry.label .. "' for " .. steamId .. " after " .. QUEUE_OP_TIMEOUT .. "s")
            done()
        end
    end)

    local ok, err = pcall(entry.fn, done)
    if not ok then
        KrakensStore.Log("error", "[Queue] ERROR in '" .. entry.label .. "' for " .. steamId .. ": " .. tostring(err))
        done()
    end
end

function Q.Drain(steamId)
    local queue = _queues[steamId]
    if queue then
        local dropped = #queue.ops
        queue.ops = {}
        if dropped > 0 then
            KrakensStore.Log("info", "[Queue] Drained " .. dropped .. " pending ops for " .. steamId)
        end
    end
end

function Q.Cleanup(steamId)
    Q.Drain(steamId)
    timer.Remove("KSQueue_" .. steamId)
    _queues[steamId] = nil
end

local L = KrakensStore.L

local RATE = {
    sync = KrakensStore.SyncCooldown,
    purchase = 1,
    sell = 1,
    equip = 0.5,
    unequip = 0.5,
    use_option = 1,
    npc_placement = 3,
    get_logs = 2,
    admin_action = 1,
    admin_data_request = 5,
    workbench_chat = 1,
}

local LIMITS = KrakensStore.Validation.Limits
local U = KrakensStore.Utils

KrakensStore._NetHelpers = {}
local H = KrakensStore._NetHelpers

function H.RejectIfNotNearStore(p, npcConfigId, done)
    if H.CanUseStoreAction(p, npcConfigId) then return false end
    H.NotifyActionResult(p, false, nil, L("err_must_be_near_store"), nil, done)
    return true
end

function H.LookupVerifiedOption(p, itemId, optionID, expectPreview, done)
    local invItem, _, invSteamId, itemTable = H.GetVerifiedInventoryItem(p, itemId)
    if not invItem then done() return end

    local typeData = KrakensStore.types[itemTable.type]
    local option = typeData and typeData.options and typeData.options[optionID]
    local previewOk = expectPreview and option and option.usePreview
    local nonPreviewOk = (not expectPreview) and option and not option.usePreview
    if not (previewOk or nonPreviewOk) then
        H.NotifyActionResult(p, false, nil, L("err_invalid_option"), nil, done)
        return
    end
    return invItem, invSteamId, itemTable, option
end

function H.ResolveTarget(data, response, requireOnline)
    local steamId, err = KrakensStore.Validation.SteamID64(data.targetSteamId)
    if not steamId then
        if response then response.message = L("err_invalid_target_steamid") .. (err or L("ui_unknown")) end
        return nil
    end
    local target = player.GetBySteamID64(steamId)
    if requireOnline and not IsValid(target) then
        if response then response.message = L("err_player_not_found_offline") end
        return nil, steamId
    end
    return target, steamId
end

function H.HandleQueuedAction(name, len, ply, opts, body)
    if not KrakensStore.Validation.Player(ply) then return end
    KrakensStore.ServerConfig.DebugLog(name .. " from", ply:SteamID64())

    local steamId = ply:SteamID64()
    local enqueued = KrakensStore.Queue.Enqueue(steamId, opts.actionKey, function(done)
        if not IsValid(ply) then done() return end
        body(ply, done)
    end)
    if not enqueued then
        H.SendNotification(ply, L("err_action_in_progress"), "error")
    end
end

function H.NotifyActionResult(ply, ok, successMsg, errMsg, sounds, done)
    if ok then
        if successMsg then H.SendNotification(ply, successMsg, "success", sounds and sounds.ok) end
    else
        H.SendNotification(ply, errMsg or L("err_action_failed"), "error", sounds and sounds.fail)
    end
    if done then done() end
end

function H.ValidateItemAndOption(ply, rawItemId, rawOptionId, done)
    local itemId = KrakensStore.Validation.ItemId(rawItemId)
    if not itemId then
        H.SendNotification(ply, L("err_invalid_item"), "error")
        done()
        return nil
    end
    local optionId = KrakensStore.Validation.String(rawOptionId, 64)
    if not optionId then
        H.SendNotification(ply, L("err_invalid_option"), "error")
        done()
        return nil
    end
    return itemId, optionId
end

function H.RunRemovableOption(ply, ctx, done, ...)
    local SInv = KrakensStore.ServerInventory
    local invSteamId, itemId, option = ctx.invSteamId, ctx.itemId, ctx.option
    local nick = ply:Nick()

    local lockHeld = false
    if option.removeItem then
        if not SInv.AcquireItemLock(invSteamId, itemId) then
            H.SendNotification(ply, L("err_action_in_progress"), "error")
            done()
            return
        end
        lockHeld = true
    end

    local success, reason, removeItem = KrakensStore:ExecuteOption(ply, ctx.optionId, ctx.itemTable, ctx.invItem, itemId, ...)
    if not success then
        if lockHeld then SInv.ReleaseItemLock(invSteamId, itemId) end
        H.NotifyActionResult(ply, false, nil, reason or ctx.failMsg, ctx.sounds, done)
        return
    end

    local function finish(consumed)
        KrakensStore.Data.Log("use_item", invSteamId, {
            playerName = nick,
            itemId = itemId,
            itemName = ctx.itemTable.name or itemId,
            optionId = ctx.optionId,
            consumed = consumed,
        })
        H.NotifyActionResult(ply, true, ctx.successMsg, nil, ctx.sounds, done)
    end

    if removeItem then
        SInv.ConsumeItem(ply, itemId, lockHeld, function(consumed)
            if not consumed then
                H.NotifyActionResult(ply, false, nil, L("err_action_failed"), ctx.sounds, done)
                return
            end
            finish(true)
        end)
    else
        if lockHeld then SInv.ReleaseItemLock(invSteamId, itemId) end
        finish(false)
    end
end

function H.SanitizeStringSet(raw, maxEntries, maxLen)
    if not istable(raw) then return nil end
    local out = {}
    local count = 0
    maxEntries = maxEntries or 2048
    maxLen = maxLen or 128

    for key, value in pairs(raw) do
        local source = nil
        if isstring(key) then
            source = key
            if value == false then
                source = nil
            end
        elseif isstring(value) then
            source = value
        end

        if source then
            local sanitized = KrakensStore.Validation.String(source, maxLen)
            if sanitized and not out[sanitized] then
                out[sanitized] = true
                count = count + 1
                if count >= maxEntries then
                    break
                end
            end
        end
    end

    return out
end

function H.CanPlayerAct(ply, actionType)
    return KF.Net.CheckRate(ply, actionType, RATE[actionType] or 0.3)
end

function H.SendNotification(ply, message, notifType, soundKey)
    if not IsValid(ply) then return end
    KF.Net.Send("KrakensStore_Notification", function()
        net.WriteString(message or "")
        net.WriteString(notifType or "info")
        net.WriteString(soundKey or "")
    end, ply)
end

function H.GetVerifiedInventoryItem(ply, itemId)
    local steamId = ply:SteamID64()
    local inventory = KrakensStore.Inventory.Cache[steamId]
    if not inventory then
        H.SendNotification(ply, L("err_store_not_ready"), "error")
        return nil
    end
    local invItem = inventory[itemId]
    if not invItem or (invItem.quantity or 1) <= 0 then
        H.SendNotification(ply, L("err_item_not_in_inv"), "error")
        return nil
    end
    if KrakensStore.Inventory.IsExpired(invItem) then
        H.SendNotification(ply, L("err_cannot_use_item"), "error")
        return nil
    end
    local itemTable = KrakensStore.Items.Get(itemId)
    if not itemTable then
        H.SendNotification(ply, L("err_item_type_not_found"), "error")
        return nil
    end
    return invItem, inventory, steamId, itemTable
end

function H.ValidateItemFull(item)
    KrakensStore.Schema.NormalizeItemData(item)
    return KrakensStore:ValidateTypeSettings(item.type, item.data)
end

local storeChunks
local CATALOG_CHUNK_ITEMS = 50
local CATALOG_CHUNK_BYTES = 60000
local CATALOG_CHUNK_RAW = KrakensStore.Validation.Limits.MAX_DECOMPRESSED / 2

function H.SendStoreState(ply)
    if not IsValid(ply) then return end
    local LC = KrakensStore.Lifecycle
    KF.Net.Send("KrakensStore_StoreState", function()
        net.WriteString(LC.Phase)
        net.WriteString(KrakensStore.IsAdmin(ply) and LC.FailureDetail() or "")
    end, ply)
end

function H.DeferUntilReady(ply, kind, resume)
    local LC = KrakensStore.Lifecycle
    if LC.Phase == "READY" then return false end
    LC.WhenReady(kind .. ":" .. ply:SteamID64(), function()
        if IsValid(ply) then resume(ply) end
    end, function()
        H.SendStoreState(ply)
    end)
    H.SendStoreState(ply)
    return true
end

local function PackCatalog(chunk, items, out)
    chunk.items = items
    local json = util.TableToJSON(chunk)
    local compressed = json and util.Compress(json)
    if not compressed then
        KrakensStore.Log("error", "SendStoreData: catalog chunk could not be encoded (" .. #items .. " items)")
        return
    end
    if (#compressed <= CATALOG_CHUNK_BYTES and #json <= CATALOG_CHUNK_RAW) or #items <= 1 then
        out[#out + 1] = compressed
        return
    end
    local mid = math.floor(#items / 2)
    PackCatalog(chunk, { unpack(items, 1, mid) }, out)
    PackCatalog({}, { unpack(items, mid + 1) }, out)
end

local function BuildStoreChunks()
    local out, batch = {}, {}
    local head = { categories = KrakensStore.Categories.Cache, npcs = KrakensStore.NPCs.Cache }
    for _, item in pairs(KrakensStore.Items.Cache) do
        batch[#batch + 1] = item
        if #batch >= CATALOG_CHUNK_ITEMS then
            PackCatalog(head, batch, out)
            head, batch = {}, {}
        end
    end
    PackCatalog(head, batch, out)
    return out
end

function H.StoreChunks()
    storeChunks = storeChunks or BuildStoreChunks()
    return storeChunks
end

function H.SendStoreData(ply)
    if not IsValid(ply) then return end
    local chunks = H.StoreChunks()
    for index, chunk in ipairs(chunks) do
        KF.Net.Send("KrakensStore_SyncStoreData", function()
            net.WriteUInt(index, 16)
            net.WriteUInt(#chunks, 16)
            net.WriteUInt(#chunk, 32)
            net.WriteData(chunk, #chunk)
        end, ply)
    end
end

function H.SyncPlayer(ply)
    if not IsValid(ply) then return end
    if KrakensStore.Lifecycle.Phase ~= "LOADING" then H.SendSettings(ply) end
    if H.DeferUntilReady(ply, "sync", H.SyncPlayer) then return end
    H.SendStoreState(ply)
    H.SendStoreData(ply)
    local SInv = KrakensStore.ServerInventory
    if KrakensStore.Inventory.Cache[ply:SteamID64()] then SInv.SyncInventory(ply) else SInv.LoadPlayer(ply) end
end

local adminInvWatchByTarget = {}
local adminInvWatchByAdmin = {}

function H.SendAdminResponse(target, tbl)
    if not IsValid(target) then return end
    KF.Net.Send("KrakensStore_AdminResponse", function() return KF.Net.WriteCompressed(tbl, 32) end, target)
end

function H.BuildInventoryArray(invDict)
    local out = {}
    for itemId, invItem in pairs(invDict or {}) do
        if not KrakensStore.Inventory.IsExpired(invItem) then
            local row = table.Copy(invItem)
            row.itemId = itemId
            out[#out + 1] = row
        end
    end
    table.sort(out, function(a, b) return a.itemId < b.itemId end)
    return out
end

local function SendAdminPlayerInventoryFull(adminPly, targetSteamId)
    H.SendAdminResponse(adminPly, {
        success = true,
        action = "player_inventory",
        steamId = targetSteamId,
        data = H.BuildInventoryArray(KrakensStore.Inventory.Cache[targetSteamId]),
    })
end

local function ForEachWatcher(targetSteamId, fn)
    local watchers = adminInvWatchByTarget[targetSteamId]
    if not watchers then return end
    for adminSteamId, adminPly in pairs(watchers) do
        if KrakensStore.IsAdmin(adminPly) then
            fn(adminPly)
        else
            watchers[adminSteamId] = nil
            adminInvWatchByAdmin[adminSteamId] = nil
        end
    end
end

function H.AdminUnwatchAll(adminPly)
    if not IsValid(adminPly) then return end
    local adminSteamId = adminPly:SteamID64()
    local targetSteamId = adminInvWatchByAdmin[adminSteamId]
    if not targetSteamId then return end

    adminInvWatchByAdmin[adminSteamId] = nil
    if adminInvWatchByTarget[targetSteamId] then
        adminInvWatchByTarget[targetSteamId][adminSteamId] = nil
        if next(adminInvWatchByTarget[targetSteamId]) == nil then
            adminInvWatchByTarget[targetSteamId] = nil
        end
    end
end

local MAX_WATCHERS_PER_PLAYER = 3

function H.AdminWatch(adminPly, targetSteamId)
    if not KrakensStore.IsAdmin(adminPly) then return false end
    targetSteamId = tostring(targetSteamId or "")
    if targetSteamId == "" then return false end

    H.AdminUnwatchAll(adminPly)

    local adminSteamId = adminPly:SteamID64()
    adminInvWatchByTarget[targetSteamId] = adminInvWatchByTarget[targetSteamId] or {}

    local watcherCount = 0
    for _ in pairs(adminInvWatchByTarget[targetSteamId]) do watcherCount = watcherCount + 1 end
    if watcherCount >= MAX_WATCHERS_PER_PLAYER then return false end

    adminInvWatchByAdmin[adminSteamId] = targetSteamId
    adminInvWatchByTarget[targetSteamId][adminSteamId] = adminPly

    SendAdminPlayerInventoryFull(adminPly, targetSteamId)
    return true
end

hook.Add("KrakensStore_InventoryItemSynced", "KrakensStore_AdminInvWatchDelta", function(ply, itemId, invItem)
    local payload = {
        success = true,
        action = "player_inventory_delta",
        steamId = ply:SteamID64(),
        itemId = itemId,
        invItem = invItem,
    }
    ForEachWatcher(payload.steamId, function(adminPly) H.SendAdminResponse(adminPly, payload) end)
end)

hook.Add("KrakensStore_InventoryFullSynced", "KrakensStore_AdminInvWatchFull", function(ply)
    local targetSteamId = ply:SteamID64()
    ForEachWatcher(targetSteamId, function(adminPly) SendAdminPlayerInventoryFull(adminPly, targetSteamId) end)
end)

function H.BuildSettingsPayload()
    local payload = KrakensStore.Config.ReadSettings()
    payload.blacklist = {}
    for key, system in pairs(KrakensStore.Integrations.AttachmentSystems) do
        payload.blacklist[key] = system.GetBlacklist()
    end
    return payload
end

function H.SendSettings(target)
    KF.Net.Send("KrakensStore_SyncSettings", function() return KF.Net.WriteCompressed(H.BuildSettingsPayload(), 16) end, target)
end

hook.Add("KrakensStore_StoreDataChanged", "KrakensStore_InvalidateStoreCache", function()
    storeChunks = nil
end)

hook.Add("KrakensStore_StateChanged", "KrakensStore_BroadcastState", function(phase)
    if phase == "LOADING" then storeChunks = nil end
    for _, ply in ipairs(player.GetAll()) do
        if phase == "LOADING" then H.SyncPlayer(ply) else H.SendStoreState(ply) end
    end
end)

function H.IsNearStoreEntity(ply)
    return U.FindNearEntity(ply, "Terminal") ~= nil
end

function H.CanUseStoreAction(ply, npcConfigId)
    if not IsValid(ply) then return false end
    if not KrakensStore.Config.General.RequireEntity then return true end
    if npcConfigId and npcConfigId ~= "" then
        return U.FindNearEntity(ply, "NPC", function(ent) return ent:GetNPCConfigId() == npcConfigId end) ~= nil
    end
    return H.IsNearStoreEntity(ply) or U.FindNearEntity(ply, "NPC") ~= nil
end

local function SendOpenMenu(ply, view, npcConfigId)
    KF.Net.Send("KrakensStore_OpenMenu", function()
        net.WriteString(view)
        net.WriteString(npcConfigId or "")
    end, ply)
end

local function OpenStoreFor(ply)
    if not IsValid(ply) then return end

    if KrakensStore.Config.General.RequireEntity and not H.IsNearStoreEntity(ply) then
        H.SendNotification(ply, L("err_must_be_near_store"), "error")
        return
    end

    SendOpenMenu(ply, "store")
end

function H.ValidateNPCScopedItemAccess(ply, npcConfigId, itemId)
    if not npcConfigId or npcConfigId == "" then return true end
    if not KrakensStore.NPCs.Get(npcConfigId) then return false, L("err_npc_not_found") end
    if not KrakensStore.NPCs.CanPlayerAccessNPC(ply, npcConfigId) then
        return false, L("err_npc_no_access")
    end
    if itemId and not KrakensStore.NPCs.GetItemsForNPC(npcConfigId)[itemId] then
        return false, L("err_no_item_access")
    end
    return true
end

function H.ValidatePurchaseScope(ply, npcConfigId, itemId)
    if npcConfigId ~= "" or not KrakensStore.Config.General.RequireEntity or H.IsNearStoreEntity(ply) then
        return H.ValidateNPCScopedItemAccess(ply, npcConfigId, itemId)
    end
    local vendor = U.FindNearEntity(ply, "NPC", function(ent)
        local id = ent:GetNPCConfigId()
        return id ~= "" and H.ValidateNPCScopedItemAccess(ply, id, itemId) == true
    end)
    if vendor then return true end
    return false, L("err_no_item_access")
end

local function OpenNPCStoreFor(ply, npcConfigId)
    if not IsValid(ply) then return end
    local allowed, err = H.ValidateNPCScopedItemAccess(ply, npcConfigId)
    if not allowed then
        H.SendNotification(ply, err, "error")
        return
    end
    SendOpenMenu(ply, "store", npcConfigId)
end

local function OpenInventoryFor(ply)
    if not IsValid(ply) then return end

    SendOpenMenu(ply, "inventory")
end

local function OpenAdminFor(ply)
    if not IsValid(ply) then return end
    if not KrakensStore.IsAdmin(ply) then
        H.SendNotification(ply, L("err_access_denied"), "error")
        return
    end

    SendOpenMenu(ply, "admin")
end

KrakensStore.OpenStoreFor = OpenStoreFor
KrakensStore.OpenNPCStoreFor = OpenNPCStoreFor
KrakensStore.OpenInventoryFor = OpenInventoryFor
KrakensStore.OpenAdminFor = OpenAdminFor

function H.AdminItemAction(ply, data, response, method, successKey, failKey)
    local target = H.ResolveTarget(data, response, true)
    if not target then return end
    local targetNick = target:Nick()
    local itemId, itemIdErr = KrakensStore.Validation.ItemId(data.itemId)
    if not itemId then
        response.message = itemIdErr
        return
    end
    local function finish(ok, err)
        response.success = ok == true
        response.message = ok and (L(successKey) .. targetNick) or (err or L(failKey))
        H.SendAdminResponse(ply, response)
    end
    if method == "GiveItem" then
        KrakensStore.ServerInventory.GiveItem(ply, target, itemId, data.quantity, nil, finish)
    else
        KrakensStore.ServerInventory.TakeItem(ply, target, itemId, data.quantity, finish)
    end
    return true
end

function H.MakeAdminSaveCallback(ply, response, entity, successMsg, logAction, logPrefix)
    return function(ok)
        if ok then
            response.success = true
            response.message = L(successMsg) .. tostring(entity.name)
            if IsValid(ply) then
                KrakensStore.Data.Log(logAction, ply:SteamID64(), { [logPrefix .. "Id"] = entity.id, [logPrefix .. "Name"] = entity.name })
            end
        else
            response.message = L("err_store_not_ready")
        end
        H.SendAdminResponse(ply, response)
    end
end

KF.Net.Receive("KrakensStore_RequestSync", function(len, ply)
    if not KrakensStore.Validation.Player(ply) then return end

    local itemCount = table.Count(KrakensStore.Items.Cache)
    local catCount = table.Count(KrakensStore.Categories.Cache)
    KrakensStore.ServerConfig.DebugLog(string.format("RequestSync from %s (items=%d, cats=%d) %s",
        ply:SteamID64(), itemCount, catCount, KrakensStore.Lifecycle.Describe()))
    H.SyncPlayer(ply)
end, { maxLen = 64, rateLimit = RATE.sync })

KF.Net.Receive("KrakensStore_RequestPurchase", function(len, ply)
    local itemId = net.ReadString() or ""
    local quantity = net.ReadUInt(16)
    local rawNpcId = net.ReadString() or ""

    H.HandleQueuedAction("RequestPurchase", len, ply, { actionKey = "purchase" }, function(p, done)
        local npcConfigId = ""
        if rawNpcId ~= "" then
            npcConfigId = KrakensStore.Validation.NpcId(rawNpcId) or ""
            if npcConfigId == "" then
                H.NotifyActionResult(p, false, nil, L("err_npc_not_found"), nil, done)
                return
            end
        end

        if H.RejectIfNotNearStore(p, npcConfigId, done) then return end

        local npcAllowed, npcErr = H.ValidatePurchaseScope(p, npcConfigId, itemId)
        if not npcAllowed then
            H.NotifyActionResult(p, false, nil, npcErr or L("err_no_item_access"), nil, done)
            return
        end

        KrakensStore.ServerInventory.PurchaseItem(p, itemId, quantity, function(success, result)
            local item = KrakensStore.Items.Get(itemId)
            local successMsg = L("success_purchased") .. (item and item.name or itemId)
            H.NotifyActionResult(p, success, successMsg, result or L("err_purchase_failed"),
                { ok = "Purchase", fail = "Error" }, done)
        end)
    end)
end, { maxLen = 1024, rateLimit = RATE.purchase })

KF.Net.Receive("KrakensStore_RequestSell", function(len, ply)
    local itemId = net.ReadString() or ""
    local quantity = net.ReadUInt(16)

    H.HandleQueuedAction("RequestSell", len, ply, { actionKey = "sell" }, function(p, done)
        if H.RejectIfNotNearStore(p, nil, done) then return end

        KrakensStore.ServerInventory.SellItem(p, itemId, quantity, function(success, result)
            local item = KrakensStore.Items.Get(itemId)
            local successMsg = success and (L("success_sold") .. (item and item.name or itemId) .. L("dialog_for") .. KrakensStore.FormatMoney(result))
            H.NotifyActionResult(p, success, successMsg, result or L("err_sale_failed"),
                { fail = "Error" }, done)
        end)
    end)
end, { maxLen = 1024, rateLimit = RATE.sell })

KF.Net.Receive("KrakensStore_RequestEquip", function(len, ply)
    local itemId = net.ReadString() or ""
    local equip = net.ReadBool()
    if not H.CanPlayerAct(ply, equip and "equip" or "unequip") then return end
    local method = equip and "EquipItem" or "UnequipItem"
    H.HandleQueuedAction("RequestEquip", len, ply, { actionKey = method }, function(p, done)
        KrakensStore.ServerInventory[method](p, itemId, function(success, errMsg)
            local item = KrakensStore.Items.Get(itemId)
            local successMsg = equip and (L("success_equipped") .. (item and item.name or itemId)) or nil
            H.NotifyActionResult(p, success, successMsg, errMsg or (equip and L("err_equip_failed") or L("err_unequip_failed")),
                { ok = "Equip", fail = "Error" }, done)
        end)
    end)
end, { maxLen = 1024 })

KF.Net.Receive("KrakensStore_RequestUseOption", function(len, ply)
    local rawItemId = net.ReadString() or ""
    local rawOptionID = net.ReadString() or ""
    local hasPos = net.ReadBool()
    local spawnPos = hasPos and net.ReadVector() or nil
    local spawnAng = hasPos and net.ReadAngle() or nil

    H.HandleQueuedAction("RequestUseOption", len, ply, { actionKey = "use_option" }, function(p, done)
        local itemId, optionID = H.ValidateItemAndOption(p, rawItemId, rawOptionID, done)
        if not itemId then return end

        if H.RejectIfNotNearStore(p, nil, done) then return end

        if hasPos then
            local valid, reason = U.ValidSpawnInput(spawnPos, spawnAng)
            if valid then valid, reason = U.CheckSpawnPos(spawnPos, "Vehicle", p) end
            if not valid then
                H.NotifyActionResult(p, false, nil, L(reason == "far" and "err_spawn_pos_too_far" or "vehicle_invalid_position"), nil, done)
                return
            end
        end

        local invItem, invSteamId, itemTable, option = H.LookupVerifiedOption(p, itemId, optionID, hasPos, done)
        if not option then return end

        H.RunRemovableOption(p, {
            invSteamId = invSteamId, itemId = itemId, optionId = optionID,
            option = option, itemTable = itemTable, invItem = invItem,
            successMsg = L(hasPos and "success_vehicle_spawned" or "success_item_used"),
            failMsg = L(hasPos and "err_failed_spawn_vehicle" or "err_cannot_use_option"),
            sounds = { ok = "Equip", fail = "Error" },
        }, done, spawnPos, spawnAng)
    end)
end, { maxLen = 3072, rateLimit = RATE.use_option })

hook.Add("PlayerSay", "KrakensStore_ChatCommands", function(ply, text)
    local first = text:sub(1, 1)
    if first ~= "!" and first ~= "/" then return end
    local lower = string.lower(text)
    local cfg = KrakensStore.Config.General.Commands

    if lower == cfg.OpenStore or table.HasValue(cfg.Store, lower) then
        OpenStoreFor(ply)
        return ""
    elseif table.HasValue(cfg.Inventory, lower) then
        OpenInventoryFor(ply)
        return ""
    elseif table.HasValue(cfg.Admin, lower) then
        OpenAdminFor(ply)
        return ""
    end
end)

KrakensStore.Workbench.InstallGate(function(ply)
    if H.CanPlayerAct(ply, "workbench_chat") then ply:ChatPrint(L("err_must_use_workbench")) end
end)

H.AdminActions = {}
local ADMIN_ACTION_HANDLERS = H.AdminActions

local ITEM_MERGE_KEYS = {
    "id", "name", "description", "icon", "model", "price", "category", "type",
    "data", "enabled", "refundable",
    "requiresWhitelist", "whitelist", "maxOwned",
    "duration", "refundPercent", "refundWindowHours",
}

local CATEGORY_MERGE_KEYS = {
    "id", "name", "icon", "order", "description", "requiresWhitelist", "whitelist",
}

local NPC_MERGE_KEYS = {
    "id", "name", "model", "skin", "bodygroups", "floatingText", "idleAnim", "order",
    "requiresWhitelist", "whitelist", "categories", "items",
}

local function MergeKeys(target, source, keys)
    for _, k in ipairs(keys) do
        if source[k] ~= nil then target[k] = source[k] end
    end
end

local function ValidationFailed(response, err)
    response.message = L("err_validation_failed") .. (err or L("ui_unknown"))
end

local function RunValidator(validatorFn, item)
    if not validatorFn then return true end
    return validatorFn(item)
end

local function MakeCreateHandler(spec)
    return function(ply, data, response)
        local sanitized, err = spec.sanitize(data)
        if not sanitized then ValidationFailed(response, err) return end
        if spec.checkExisting then
            local existsErr = spec.checkExisting(sanitized)
            if existsErr then response.message = existsErr return end
        end
        local entity = spec.create(sanitized)
        local valid, validErr = RunValidator(spec.validate, entity)
        if not valid then ValidationFailed(response, validErr) return end
        spec.store.Save(entity, H.MakeAdminSaveCallback(ply, response, entity, spec.successKey, spec.actionKey, spec.entityKind))
        return true
    end
end

local function MakeUpdateHandler(spec)
    return function(ply, data, response)
        local id, idErr = spec.idValidator(data.id)
        if not id then
            response.message = idErr
            return
        end
        local existing = spec.store.Get(id)
        if not existing then response.message = L(spec.notFoundKey) return end
        local sanitized, err = spec.sanitize(data)
        if not sanitized then ValidationFailed(response, err) return end
        local target = table.Copy(existing)
        MergeKeys(target, sanitized, spec.mergeKeys)
        local valid, validErr = RunValidator(spec.validate, target)
        if not valid then ValidationFailed(response, validErr) return end
        spec.store.Save(target, H.MakeAdminSaveCallback(ply, response, target, spec.successKey, spec.actionKey, spec.entityKind))
        return true
    end
end

local function MakeDeleteHandler(spec)
    return function(ply, data, response)
        local id = spec.idValidator(data.id)
        if not id then response.message = L(spec.notFoundKey) return end
        local entity = spec.store.Get(id)
        if not entity then response.message = L(spec.notFoundKey) return end
        spec.store.Delete(id, H.MakeAdminSaveCallback(ply, response, entity, spec.successKey, spec.actionKey, spec.entityKind))
        return true
    end
end

ADMIN_ACTION_HANDLERS["create_item"] = MakeCreateHandler({
    sanitize = KrakensStore.Validation.ItemData,
    checkExisting = function(d)
        if KrakensStore.Items.Get(d.id) then return L("err_validation_failed") .. L("err_item_id_exists") end
    end,
    create = KrakensStore.Schema.CreateItem,
    validate = H.ValidateItemFull,
    store = KrakensStore.Items,
    successKey = "success_item_created", actionKey = "admin_create_item",
    entityKind = "item",
})

ADMIN_ACTION_HANDLERS["update_item"] = MakeUpdateHandler({
    idValidator = KrakensStore.Validation.ItemId,
    notFoundKey = "err_item_not_found",
    sanitize = KrakensStore.Validation.ItemData,
    validate = H.ValidateItemFull,
    store = KrakensStore.Items,
    mergeKeys = ITEM_MERGE_KEYS,
    successKey = "success_item_updated", actionKey = "admin_update_item",
    entityKind = "item",
})

ADMIN_ACTION_HANDLERS["delete_item"] = MakeDeleteHandler({
    idValidator = KrakensStore.Validation.ItemId,
    notFoundKey = "err_item_not_found",
    store = KrakensStore.Items,
    successKey = "success_item_deleted", actionKey = "admin_delete_item",
    entityKind = "item",
})

ADMIN_ACTION_HANDLERS["set_stock"] = function(ply, data, response)
    local id, idErr = KrakensStore.Validation.ItemId(data.id)
    if not id then response.message = idErr return end
    local item = KrakensStore.Items.Get(id)
    if not item then response.message = L("err_item_not_found") return end
    local stock = KrakensStore.Validation.Number(data.stock, -1, 2147483647)
    if stock == nil then response.message = L("err_validation_failed") .. L("admin_stock") return end
    local previous, adminId = item.stock, ply:SteamID64()
    stock = math.floor(stock)
    item.stock = stock
    KrakensStore.Items.Save(item, function(ok)
        if ok then
            response.success = true
            response.message = L("success_item_updated") .. tostring(item.name)
            KrakensStore.Data.Log("admin_update_item", adminId, { itemId = item.id, itemName = item.name, stock = stock })
        else
            if item.stock == stock then item.stock = previous end
            response.message = L("err_store_not_ready")
        end
        H.SendAdminResponse(ply, response)
    end)
    return true
end

ADMIN_ACTION_HANDLERS["create_category"] = MakeCreateHandler({
    sanitize = KrakensStore.Validation.CategoryData,
    checkExisting = function(d)
        if KrakensStore.Categories.Get(d.id) then return L("err_validation_failed") .. L("err_category_id_exists") end
    end,
    create = KrakensStore.Schema.CreateCategory,
    store = KrakensStore.Categories,
    successKey = "success_category_created", actionKey = "admin_create_category",
    entityKind = "category",
})

ADMIN_ACTION_HANDLERS["update_category"] = function(ply, data, response)
    local sanitizedData, sanitizeErr = KrakensStore.Validation.CategoryData(data)
    if not sanitizedData then ValidationFailed(response, sanitizeErr) return end
    local lookupId = data.oldId and data.oldId ~= "" and KrakensStore.Validation.CategoryId(data.oldId) or sanitizedData.id
    local existing = KrakensStore.Categories.Get(lookupId)
    if not existing then
        response.message = L("err_category_not_found")
        return
    end
    local renamed = lookupId ~= sanitizedData.id
    if renamed and lookupId == KrakensStore.Schema.OrphanCategoryId then
        response.message = L("err_category_protected")
        return
    end
    if renamed and KrakensStore.Categories.Get(sanitizedData.id) then
        response.message = L("err_validation_failed") .. L("err_category_id_exists")
        return
    end
    local target = table.Copy(existing)
    MergeKeys(target, sanitizedData, CATEGORY_MERGE_KEYS)
    local respond = H.MakeAdminSaveCallback(ply, response, target, "success_category_updated", "admin_update_category", "category")
    KrakensStore.Categories.Save(target, function(ok, err)
        if not (ok and renamed) then respond(ok, err) return end
        KrakensStore.Data.BulkUpdateItemCategory(lookupId, target.id)
        KrakensStore.Categories.DropId(lookupId, function()
            hook.Run("KrakensStore_StoreDataChanged")
            respond(ok, err)
        end)
    end)
    return true
end

local DeleteCategory = MakeDeleteHandler({
    idValidator = KrakensStore.Validation.CategoryId,
    notFoundKey = "err_category_not_found",
    store = KrakensStore.Categories,
    successKey = "success_category_deleted", actionKey = "admin_delete_category",
    entityKind = "category",
})

ADMIN_ACTION_HANDLERS["delete_category"] = function(ply, data, response)
    if KrakensStore.Validation.CategoryId(data.id) == KrakensStore.Schema.OrphanCategoryId then
        response.message = L("err_category_protected")
        return
    end
    return DeleteCategory(ply, data, response)
end

ADMIN_ACTION_HANDLERS["create_npc"] = MakeCreateHandler({
    sanitize = KrakensStore.Validation.NPCData,
    checkExisting = function(d)
        if KrakensStore.NPCs.Get(d.id) then return L("err_validation_failed") .. L("err_npc_id_exists") end
    end,
    create = KrakensStore.NPCs.CreateNPC,
    store = KrakensStore.NPCs,
    successKey = "success_npc_created", actionKey = "admin_create_npc",
    entityKind = "npc",
})

ADMIN_ACTION_HANDLERS["update_npc"] = MakeUpdateHandler({
    idValidator = KrakensStore.Validation.NpcId,
    notFoundKey = "err_npc_not_found",
    sanitize = KrakensStore.Validation.NPCData,
    store = KrakensStore.NPCs,
    mergeKeys = NPC_MERGE_KEYS,
    successKey = "success_npc_updated", actionKey = "admin_update_npc",
    entityKind = "npc",
})

ADMIN_ACTION_HANDLERS["delete_npc"] = MakeDeleteHandler({
    idValidator = KrakensStore.Validation.NpcId,
    notFoundKey = "err_npc_not_found",
    store = KrakensStore.NPCs,
    successKey = "success_npc_deleted", actionKey = "admin_delete_npc",
    entityKind = "npc",
})

ADMIN_ACTION_HANDLERS["give_item"] = function(ply, data, response)
    return H.AdminItemAction(ply, data, response, "GiveItem", "success_gave_item", "err_give_item_failed")
end

ADMIN_ACTION_HANDLERS["take_item"] = function(ply, data, response)
    return H.AdminItemAction(ply, data, response, "TakeItem", "success_took_item", "err_take_item_failed")
end

ADMIN_ACTION_HANDLERS["reset_inventory"] = function(ply, data, response)
    local target = H.ResolveTarget(data, response, true)
    if not target then return end
    local targetNick = target:Nick()
    KrakensStore.ServerInventory.ResetInventory(ply, target, function(ok, err)
        response.success = ok == true
        response.message = ok and (L("success_reset_inventory") .. targetNick)
            or (err or L("err_reset_inventory_failed"))
        H.SendAdminResponse(ply, response)
    end)
    return true
end

ADMIN_ACTION_HANDLERS["watch_player_inventory"] = function(ply, data, response)
    local _, targetSteamId = H.ResolveTarget(data, response, false)
    if not targetSteamId then return end
    local watch = data.watch ~= false
    if watch then
        local ok = H.AdminWatch(ply, targetSteamId)
        response.success = ok
        if not ok then response.message = L("msg_failed_to_watch") end
    else
        H.AdminUnwatchAll(ply)
        response.success = true
        response.message = nil
    end
end

ADMIN_ACTION_HANDLERS["save_settings"] = function(ply, data, response)
    if not istable(data) then response.message = L("err_invalid_admin_action") return end

    local accepted, rejected = {}, {}
    for key, raw in pairs(data) do
        local spec = KrakensStore.Config.SettingByKey[key]
        if spec then
            local clean = KrakensStore.Config.SanitizeSetting(key, raw)
            if clean == nil then rejected[#rejected + 1] = key else accepted[key] = clean end
        end
    end

    if not next(accepted) then
        response.message = L("err_invalid_admin_action")
        return
    end

    KrakensStore.Data.GetConfig("settings", function(stored, readErr)
        if readErr then
            response.message = L("err_store_not_ready")
            H.SendAdminResponse(ply, response)
            return
        end
        local merged = istable(stored) and stored or {}
        for key, value in pairs(accepted) do
            if not KrakensStore.Config.SettingByKey[key].cvar then merged[key] = value end
        end

        KrakensStore.Data.SetConfig("settings", merged, function(ok)
            if not ok then
                response.success = false
                response.message = L("err_store_not_ready")
                H.SendAdminResponse(ply, response)
                return
            end
            KrakensStore.Config.ApplySettings(accepted)
            KrakensStore.Data.ApplyGeneralSettings(merged)
            H.SendSettings()
            for _, key in ipairs(rejected) do
                KrakensStore.Log("warn", "Rejected setting value for '" .. key .. "'")
            end
            response.success = true
            response.message = L("success_settings_saved")
            H.SendAdminResponse(ply, response)
        end)
    end)
    return true
end

ADMIN_ACTION_HANDLERS["save_blacklist"] = function(ply, data, response)
    local blacklistPayload = {}
    for key in pairs(KrakensStore.Integrations.AttachmentSystems) do
        blacklistPayload[key] = H.SanitizeStringSet(data[key], 4096, 128) or {}
    end
    KrakensStore.Data.SetConfig("attachment_blacklist", blacklistPayload, function(ok)
        if ok then
            KrakensStore.Config.ApplyBlacklist(blacklistPayload)
            H.SendSettings()
            response.success = true
            response.message = L("blacklist_saved")
        else
            response.success = false
            response.message = L("err_store_not_ready")
        end
        H.SendAdminResponse(ply, response)
    end)
    return true
end

ADMIN_ACTION_HANDLERS["save_spawn_assignments"] = function(ply, data, response)
    local validTypes = { jobs = true, jobCategories = true, usergroups = true, helixClasses = true, helixFactions = true, nutClasses = true, nutFactions = true }
    local sanitized = {}
    for targetType, targets in pairs(data) do
        if validTypes[targetType] and istable(targets) then
            local typeEntries = {}
            for targetId, assignData in pairs(targets) do
                if isstring(targetId) and #targetId <= 128 and istable(assignData) then
                    local cleanItems, cleanAtts = {}, {}
                    if istable(assignData.items) then
                        for _, itemId in ipairs(assignData.items) do
                            if isstring(itemId) and #itemId <= 128 then
                                local validId = KrakensStore.Validation.ItemId(itemId)
                                if validId and KrakensStore.Items.Get(validId) then
                                    table.insert(cleanItems, validId)
                                end
                            end
                        end
                    end
                    if istable(assignData.attachments) then
                        for _, att in ipairs(assignData.attachments) do
                            if istable(att) and KrakensStore.Integrations.AttachmentSystems[att.system] and isstring(att.id) and #att.id <= 128 then
                                table.insert(cleanAtts, { system = att.system, id = att.id })
                            end
                        end
                    end
                    if #cleanItems > 0 or #cleanAtts > 0 then
                        typeEntries[targetId] = { items = cleanItems, attachments = cleanAtts }
                    end
                end
            end
            if next(typeEntries) then
                sanitized[targetType] = typeEntries
            end
        end
    end
    KrakensStore.Data.SaveSpawnAssignments(sanitized, function(ok)
        if ok then
            for _, p in ipairs(player.GetAll()) do
                if KrakensStore.HasActionPermission(p, "manage_config") then H.SendAdminData(p) end
            end
            response.success = true
            response.message = L("spawn_saved")
        else
            response.success = false
            response.message = L("err_store_not_ready")
        end
        H.SendAdminResponse(ply, response)
    end)
    return true
end

ADMIN_ACTION_HANDLERS["get_logs"] = function(ply, data, response)
    KrakensStore.Data.GetLogs(data.limit, function(logs)
        response.success = true
        response.logs = logs
        H.SendAdminResponse(ply, response)
    end)
    return true
end

local ACTION_PERMISSION_MAP = {
    ["create_item"] = "manage_items",
    ["update_item"] = "manage_items",
    ["delete_item"] = "manage_items",
    ["set_stock"] = "manage_items",
    ["create_category"] = "manage_categories",
    ["update_category"] = "manage_categories",
    ["delete_category"] = "manage_categories",
    ["create_npc"] = "manage_npcs",
    ["update_npc"] = "manage_npcs",
    ["delete_npc"] = "manage_npcs",
    ["give_item"] = "manage_players",
    ["take_item"] = "manage_players",
    ["reset_inventory"] = "manage_players",
    ["watch_player_inventory"] = "manage_players",
    ["save_settings"] = "manage_config",
    ["save_blacklist"] = "manage_config",
    ["save_spawn_assignments"] = "manage_config",
    ["get_logs"] = "view_logs",
}

KF.Net.Receive("KrakensStore_AdminAction", function(len, ply)
    if not KrakensStore.Validation.Player(ply) then return end
    local action = KrakensStore.Validation.String(net.ReadString() or "", LIMITS.MAX_ACTION_NAME_LENGTH)
    local handler = action and ADMIN_ACTION_HANDLERS[action]

    if not handler then
        H.SendNotification(ply, L("err_invalid_admin_action"), "error")
        return
    end

    local requiredPerm = ACTION_PERMISSION_MAP[action]
    if requiredPerm and not KrakensStore.HasActionPermission(ply, requiredPerm) then
        H.SendNotification(ply, L("err_access_denied"), "error")
        return
    end

    if not KF.Net.CheckRate(ply, "admin_" .. action, RATE[action] or RATE.admin_action) then
        H.SendAdminResponse(ply, { success = false, action = action, message = L("err_action_in_progress") })
        return
    end

    local data = KF.Net.ReadCompressed(32, LIMITS.MAX_DECOMPRESSED)
    if not istable(data) then
        H.SendNotification(ply, L("err_admin_payload_corrupt"), "error")
        return
    end

    local response = {
        success = false,
        action = action,
        message = L("err_unknown_action")
    }

    if handler(ply, data, response) then return end
    H.SendAdminResponse(ply, response)
end, { maxLen = LIMITS.MAX_PAYLOAD_SIZE + 1024, permCheck = KrakensStore.IsAdmin })

function H.SendAdminData(ply)
    if not IsValid(ply) then return end
    if H.DeferUntilReady(ply, "admin", H.SendAdminData) then return end
    local data = {}
    if KrakensStore.HasActionPermission(ply, "manage_config") then
        data.spawnAssignments = KrakensStore.SpawnAssignments or {}
    end

    H.SendStoreState(ply)
    KF.Net.Send("KrakensStore_AdminData", function() return KF.Net.WriteCompressed(data, 32) end, ply)
end

KF.Net.Receive("KrakensStore_RequestAdminData", function(len, ply)
    if not KrakensStore.Validation.Player(ply) then return end
    H.SendAdminData(ply)
end, { maxLen = 64, rateLimit = RATE.admin_data_request, permCheck = KrakensStore.IsAdmin })

KF.Net.Receive("KrakensStore_NPCPlacement", function(len, ply)
    if not KrakensStore.Validation.Player(ply) then return end

    local npcId = KrakensStore.Validation.NpcId(net.ReadString())
    local place = net.ReadBool()
    local spawnPos = place and net.ReadVector()
    local spawnAng = place and net.ReadAngle()

    local existing = npcId and KrakensStore.NPCs.Get(npcId)
    if not existing then return end

    if place and not (U.ValidSpawnInput(spawnPos, spawnAng) and U.CheckSpawnPos(spawnPos, "NPC", ply)) then
        H.SendNotification(ply, L("err_invalid_spawn_position"), "error")
        return
    end

    local npc = table.Copy(existing)
    npc.spawnPos = place and { x = spawnPos.x, y = spawnPos.y, z = spawnPos.z } or nil
    npc.spawnAng = place and { p = spawnAng.p, y = spawnAng.y, r = spawnAng.r } or nil
    npc.spawnMap = place and game.GetMap() or nil

    KrakensStore.NPCs.Save(npc, function(ok)
        if not ok then return end
        KrakensStore.NPCs.RemoveAutoSpawnedByConfigId(npcId)
        if not place then
            H.SendNotification(ply, L("npc_placement_removed"), "success")
        elseif KrakensStore.NPCs.SpawnAtPos(npcId, spawnPos, spawnAng) then
            H.SendNotification(ply, L("npc_placement_saved"), "success")
        end
    end)
end, { maxLen = 1024, rateLimit = RATE.npc_placement, permCheck = function(p) return KrakensStore.HasActionPermission(p, "manage_npcs") end })
