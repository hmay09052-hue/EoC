local cvar = GetConVar("ks_qa_enabled")

local function Tell(ply, text)
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text) else print(text) end
end

local function Toggle(ply, enable)
    RunConsoleCommand("ks_qa_enabled", enable and "1" or "0")
    RunConsoleCommand("ks_reload")
    Tell(ply, "[KS QA] " .. (enable and "enabled, reloading the addon" or "disabled, reloading the addon"))
end

concommand.Add("ks_qa", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end
    local what = args[1]
    if what == "on" or what == "off" then return Toggle(ply, what == "on") end
    if not KrakensStore.QA then return Tell(ply, "[KS QA] runner disabled. Use: ks_qa on") end
    KrakensStore.QA.Command(ply, args)
end)

if not cvar:GetBool() then
    KrakensStore.QA = nil
    return
end

local QA = { Scenarios = {}, Order = {} }
KrakensStore.QA = QA

local PREFIX = "qa_"
local SInv = KrakensStore.ServerInventory
local Data = KrakensStore.Data

local KEEP_TIMERS = {
    KrakensStore_Regeneration = true, KrakensStore_Backup = true,
    KrakensStore_PruneExpiredOnline = true, KrakensStore_LockSweep = true, KrakensStore_PruneLogs = true,
    KrakensStore_MySQLReconnect = true, KrakensStore_MySQLPending = true,
}

function QA.Scenario(id, def)
    def.id = id
    if not QA.Scenarios[id] then QA.Order[#QA.Order + 1] = id end
    QA.Scenarios[id] = def
end

local function Starts(s, prefix) return isstring(s) and string.sub(s, 1, #prefix) == prefix end

local function HookCounts()
    local out = {}
    for event, tbl in pairs(hook.GetTable()) do
        local n = 0
        for name in pairs(tbl) do
            if Starts(tostring(name), "KrakensStore") or Starts(tostring(name), "KS") then n = n + 1 end
        end
        if n > 0 then out[event] = n end
    end
    return out
end

local function EntitySet()
    local set = {}
    for _, ent in ipairs(ents.GetAll()) do set[ent] = true end
    return set
end

local function StateLeaks(T)
    local leaks = {}
    for steamId in pairs(T.botIds) do
        if KrakensStore.Inventory.Cache[steamId] then leaks[#leaks + 1] = "Inventory.Cache[" .. steamId .. "]" end
        if SInv.Locks[steamId] and next(SInv.Locks[steamId]) then leaks[#leaks + 1] = "Locks[" .. steamId .. "]" end
        if KrakensStore.Buffs.ActiveBuffs[steamId] then leaks[#leaks + 1] = "ActiveBuffs[" .. steamId .. "]" end
        if SInv.AppliedByPlayer[steamId] then leaks[#leaks + 1] = "AppliedByPlayer[" .. steamId .. "]" end
    end
    for id in pairs(T.items) do
        if KrakensStore.Items.Get(id) then leaks[#leaks + 1] = "Items.Cache[" .. id .. "]" end
    end
    for id in pairs(T.categories) do
        if KrakensStore.Categories.Get(id) then leaks[#leaks + 1] = "Categories.Cache[" .. id .. "]" end
    end
    for id in pairs(T.npcs) do
        if KrakensStore.NPCs.Get(id) then leaks[#leaks + 1] = "NPCs.Cache[" .. id .. "]" end
    end
    return leaks
end

local Context = {}
Context.__index = Context

function Context:Check(label, ok, detail)
    self.rows[#self.rows + 1] = { label = label, ok = ok == true, detail = detail ~= nil and tostring(detail) or "" }
    if ok ~= true then self.failed = true end
    return ok == true
end

function Context:Wait(seconds) coroutine.yield({ at = CurTime() + seconds }) end
function Context:Ticks(n) coroutine.yield({ ticks = n or 1 }) end

function Context:WaitFor(pred, timeout)
    local deadline = CurTime() + (timeout or 3)
    while true do
        if pred() then return true end
        if CurTime() >= deadline then return false end
        self:Ticks(1)
    end
end

function Context:Await(fn, timeout)
    local done, result = false, nil
    fn(function(...) done = true result = { ... } end)
    local ok = self:WaitFor(function() return done end, timeout or 5)
    return ok, result or {}
end

function Context:Skip(seconds)
    KrakensStore.TimeOffset = KrakensStore.TimeOffset + seconds
    self.shifted = true
end

function Context:Undo(fn) self.undo[#self.undo + 1] = fn end

function Context:Count(event)
    local counter = { n = 0 }
    self.hookId = self.hookId + 1
    local name = "KSQA_" .. self.hookId
    hook.Add(event, name, function(...)
        counter.n = counter.n + 1
        counter.last = { ... }
    end)
    self:Undo(function() hook.Remove(event, name) end)
    return counter
end

function Context:Sends(message, target)
    local counter = { n = 0 }
    local send, broadcast = KF.Net.Send, KF.Net.Broadcast
    local function Hit()
        self.sends = self.sends + 1
        counter.n, counter.at = counter.n + 1, self.sends
    end
    KF.Net.Send = function(name, writeFn, to)
        if name == message and (to == nil or to == target or istable(to) and table.HasValue(to, target)) then Hit() end
        return send(name, writeFn, to)
    end
    KF.Net.Broadcast = function(name, writeFn)
        if name == message then Hit() end
        return broadcast(name, writeFn)
    end
    self:Undo(function() KF.Net.Send, KF.Net.Broadcast = send, broadcast end)
    return counter
end

function Context:Bot(label)
    self:WaitFor(function() return #player.GetAll() < game.MaxPlayers() end, 2)
    local bot = player.CreateNextBot(PREFIX .. label)
    if not IsValid(bot) then error("cannot create bot " .. label) end
    self.bots[#self.bots + 1] = bot
    local steamId = bot:SteamID64()
    self.botIds[steamId] = true
    self:WaitFor(function() return IsValid(bot) and KrakensStore.Inventory.Cache[steamId] ~= nil end, 8)
    if not KrakensStore.Inventory.Cache[steamId] then error("bot " .. label .. " never loaded its inventory") end
    bot:SetPos(self.origin)
    self:Ticks(1)
    return bot
end

function Context:Money(ply) return KF.Currency.Get(ply, KrakensStore.CurrencyKey) end

function Context:SetMoney(ply, amount)
    local current = self:Money(ply)
    if amount > current then KF.Currency.Add(ply, amount - current, KrakensStore.CurrencyKey)
    elseif amount < current then KF.Currency.Remove(ply, current - amount, KrakensStore.CurrencyKey) end
end

function Context:Item(id, overrides)
    id = PREFIX .. id
    self:WaitFor(function() return Data.IsLoaded() end, 10)
    local item = KrakensStore.Schema.CreateItem(table.Merge({
        id = id, name = "QA " .. id, type = "custom", category = "misc", price = 100, enabled = true,
    }, overrides or {}))
    KrakensStore.Items.Cache[id] = item
    self.items[id] = true
    return item
end

function Context:Category(id, overrides)
    id = PREFIX .. id
    local cat = KrakensStore.Schema.CreateCategory(table.Merge({ id = id, name = "QA " .. id }, overrides or {}))
    KrakensStore.Categories.Cache[id] = cat
    self.categories[id] = true
    return cat
end

function Context:NPC(id, overrides)
    id = PREFIX .. id
    local npc = KrakensStore.NPCs.CreateNPC(table.Merge({ id = id, name = "QA " .. id }, overrides or {}))
    KrakensStore.NPCs.Cache[id] = npc
    self.npcs[id] = true
    return npc
end

function Context:Setting(key, value)
    local general = KrakensStore.Config.General
    if self.settings[key] == nil then self.settings[key] = { general[key] } end
    general[key] = value
end

function Context:Inv(ply) return KrakensStore.Inventory.Cache[ply:SteamID64()] or {} end
function Context:Has(ply, itemId) return self:Inv(ply)[itemId] ~= nil end
function Context:Qty(ply, itemId)
    local row = self:Inv(ply)[itemId]
    return row and row.quantity or 0
end

function Context:BreakDB()
    if self.dbBroken then return end
    self.dbBroken = true
    self.realQuery, self.realTransaction = KrakensStore.DB.Query, KrakensStore.DB.Transaction
    KrakensStore.DB.Query = function(_, cb) KrakensStore.Fire(cb, nil, "QA induced failure") end
    KrakensStore.DB.Transaction = function(_, cb) KrakensStore.Fire(cb, false, "QA induced failure") end
    self:Undo(function() self:RestoreDB() end)
end

function Context:RestoreDB()
    if not self.dbBroken then return end
    KrakensStore.DB.Query, KrakensStore.DB.Transaction = self.realQuery, self.realTransaction
    self.dbBroken = false
end

function Context:Teardown()
    self:RestoreDB()
    for i = #self.undo, 1, -1 do
        local ok, err = pcall(self.undo[i])
        if not ok then self:Check("undo step " .. i, false, err) end
    end
    for key, stored in pairs(self.settings) do
        KrakensStore.Config.General[key] = stored[1]
    end
    for _, bot in ipairs(self.bots) do
        if IsValid(bot) then bot:Kick("QA finished") end
    end
    self:Wait(0.5)
    for steamId in pairs(self.botIds) do
        SInv.CleanupPlayer(steamId)
        KrakensStore.Buffs.CleanupPlayer(steamId)
        Data.ClearPlayerInventory(steamId)
        Data.DeletePlayerData(steamId)
    end
    for id in pairs(self.items) do
        KrakensStore.Items.Cache[id] = nil
        Data.DeleteItem(id)
    end
    for id in pairs(self.categories) do
        KrakensStore.Categories.Cache[id] = nil
        Data.DeleteCategory(id)
    end
    for id in pairs(self.npcs) do
        KrakensStore.NPCs.Cache[id] = nil
        Data.DeleteNPC(id)
    end
    if self.shifted then KrakensStore.TimeOffset = 0 end
    self:Ticks(2)
end

function Context:Verify()
    self:Ticks(3)
    local leftovers = {}
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and not self.entities[ent] and Starts(ent:GetClass(), "ks_") then
            leftovers[#leftovers + 1] = ent:GetClass()
            ent:Remove()
        end
    end
    self:Check("runtime entities cleaned", #leftovers == 0, table.concat(leftovers, ", "))

    local timers = {}
    for name in pairs(self.timers) do
        if timer.Exists(name) and not KEEP_TIMERS[name] then
            timers[#timers + 1] = name
            timer.Remove(name)
        end
    end
    self:Check("no timer remained after completion", #timers == 0, table.concat(timers, ", "))

    local diff = {}
    for event, n in pairs(HookCounts()) do
        if (self.hookCounts[event] or 0) ~= n then diff[#diff + 1] = event .. " " .. (self.hookCounts[event] or 0) .. "->" .. n end
    end
    self:Check("addon hooks unchanged", #diff == 0, table.concat(diff, ", "))
    local leaks = StateLeaks(self)
    self:Check("runtime state cleaned", #leaks == 0, table.concat(leaks, ", "))
end

local function SpawnOrigin()
    for _, ent in ipairs(ents.GetAll()) do
        if Starts(ent:GetClass(), "info_player_") then return ent:GetPos() + Vector(0, 0, 8) end
    end
    return Vector(0, 0, 64)
end

local function NewContext(def, actor, id)
    return setmetatable({
        id = id, def = def,
        origin = IsValid(actor) and actor:GetPos() or SpawnOrigin(),
        rows = {}, undo = {}, bots = {}, botIds = {}, settings = {},
        timers = {}, items = {}, categories = {}, npcs = {}, hookId = 0, sends = 0,
        entities = EntitySet(), hookCounts = HookCounts(),
    }, Context)
end

local Run

local function Instrument(run)
    run.timerCreate = timer.Create
    timer.Create = function(name, ...)
        local T = run.current
        if T and Starts(name, "KrakensStore_") then T.timers[name] = true end
        return run.timerCreate(name, ...)
    end
end

local function Report(run, T)
    local ok = not T.failed
    MsgC(Color(255, 190, 50), "[KS QA] ", ok and Color(80, 255, 80) or Color(255, 80, 80), ok and "PASS " or "FAIL ",
        Color(255, 255, 255), T.def.system .. " / " .. T.def.title, "\n")
    for _, row in ipairs(T.rows) do
        MsgC(row.ok and Color(80, 255, 80) or Color(255, 80, 80), row.ok and "   PASS - " or "   FAIL - ",
            Color(220, 220, 220), row.label, row.detail ~= "" and (" (" .. row.detail .. ")") or "", "\n")
        if not row.ok then run.failures[#run.failures + 1] = { system = T.def.system, scenario = T.def.title, label = row.label, detail = row.detail } end
        run.checks = run.checks + 1
        if row.ok then run.passed = run.passed + 1 end
    end
end

local function Finish(run)
    timer.Create = run.timerCreate
    hook.Remove("Think", "KSQA_Runner")
    Run = nil
    local failed = run.checks - run.passed
    MsgC(Color(255, 190, 50), "[KS QA] ", Color(255, 255, 255),
        string.format("%d checks, %d passed, %d failed\n", run.checks, run.passed, failed))
    for _, row in ipairs(run.failures) do
        MsgC(Color(255, 80, 80), "   FAIL ", Color(220, 220, 220),
            row.system .. " / " .. row.scenario .. " - " .. row.label, row.detail ~= "" and (": " .. row.detail) or "", "\n")
    end
    hook.Run("KrakensStore_QADone", run.passed, failed, run.failures)
end

local function Start(run, id)
    local def = QA.Scenarios[id]
    run.index = run.index + 1
    local T = NewContext(def, run.ply, run.index)
    run.current = T
    MsgC(Color(255, 190, 50), "[KS QA] ", Color(255, 255, 255), "running " .. def.title .. "\n")
    T.co = coroutine.create(function()
        local ok, err = pcall(def.run, T)
        if not ok then T:Check("scenario completed without error", false, err) end
        local okDown, errDown = pcall(T.Teardown, T)
        if not okDown then T:Check("teardown completed without error", false, errDown) end
        local okVerify, errVerify = pcall(T.Verify, T)
        if not okVerify then T:Check("verify completed without error", false, errVerify) end
    end)
end

local function Pump()
    local run = Run
    if not run then return end
    local T = run.current
    if not T then
        local id = run.queue[run.cursor]
        if not id then return Finish(run) end
        run.cursor = run.cursor + 1
        return Start(run, id)
    end
    if T.gate then
        if T.gate.at and CurTime() < T.gate.at then return end
        if T.gate.ticks and T.gate.ticks > 0 then T.gate.ticks = T.gate.ticks - 1 return end
        T.gate = nil
    end
    local ok, yielded = coroutine.resume(T.co)
    if not ok then
        T:Check("scenario did not crash the runner", false, yielded)
    end
    if coroutine.status(T.co) == "dead" then
        Report(run, T)
        run.current = nil
        return
    end
    T.gate = istable(yielded) and yielded or nil
end

function QA.Run(ids, ply)
    if Run then
        Tell(ply, "[KS QA] a run is already in progress")
        return
    end
    if not Data.IsLoaded() then
        Tell(ply, "[KS QA] store data is still loading, retrying shortly")
        timer.Simple(1, function() QA.Run(ids, ply) end)
        return
    end
    Run = { queue = ids, cursor = 1, index = 0, ply = ply, checks = 0, passed = 0, failures = {} }
    Instrument(Run)
    hook.Add("Think", "KSQA_Runner", Pump)
    MsgC(Color(255, 190, 50), "[KS QA] ", Color(255, 255, 255), "starting " .. #ids .. " scenario(s)\n")
end

function QA.Command(ply, args)
    local what = args[1]
    if what == nil or what == "list" then
        Tell(ply, "[KS QA] scenarios:")
        for _, id in ipairs(QA.Order) do
            local def = QA.Scenarios[id]
            Tell(ply, string.format("  %-34s %s / %s", id, def.system, def.title))
        end
        Tell(ply, "[KS QA] usage: ks_qa all | ks_qa <id> | ks_qa system:<name>")
        return
    end
    local ids = {}
    if what == "all" then
        ids = table.Copy(QA.Order)
    elseif Starts(what, "system:") then
        local system = string.sub(what, 8)
        for _, id in ipairs(QA.Order) do
            if QA.Scenarios[id].system == system then ids[#ids + 1] = id end
        end
    elseif QA.Scenarios[what] then
        ids = { what }
    else
        Tell(ply, "[KS QA] unknown scenario '" .. tostring(what) .. "'")
        return
    end
    if #ids == 0 then
        Tell(ply, "[KS QA] nothing matched")
        return
    end
    QA.Run(ids, ply)
end


local function Prepare(T)
    T:Setting("RequireEntity", false)
    T:Setting("RequireWorkbench", false)
end

QA.Scenario("purchase_flow", { system = "economy", title = "Purchase: money debited, item stacked, stock decremented", run = function(T)
    Prepare(T)
    local item = T:Item("basic", { price = 250, stock = 5 })
    local bot = T:Bot("Buyer")
    T:SetMoney(bot, 1000)
    local purchased = T:Count("KrakensStore_ItemPurchased")

    local ok = T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Check("purchase callback fired", ok)
    T:Check("item is owned", T:Qty(bot, item.id) == 1, T:Qty(bot, item.id))
    T:Check("money debited exactly once", T:Money(bot) == 750, T:Money(bot))
    T:Check("stock decremented", item.stock == 4, item.stock)
    T:Check("purchase hook fired once", purchased.n == 1, purchased.n)

    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 2, done) end)
    T:Check("second purchase stacks", T:Qty(bot, item.id) == 3, T:Qty(bot, item.id))
    T:Check("money debited for the stack", T:Money(bot) == 250, T:Money(bot))
    T:Check("stock tracks the stack", item.stock == 2, item.stock)
end })

QA.Scenario("purchase_insufficient_funds", { system = "economy", title = "Purchase refused when the player cannot pay", run = function(T)
    Prepare(T)
    local item = T:Item("pricey", { price = 5000 })
    local bot = T:Bot("Broke")
    T:SetMoney(bot, 100)

    local _, res = T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Check("purchase rejected", res[1] == false, tostring(res[1]))
    T:Check("nothing was granted", not T:Has(bot, item.id))
    T:Check("money untouched", T:Money(bot) == 100, T:Money(bot))
end })

QA.Scenario("purchase_db_failure", { system = "economy", title = "DB failure during purchase restores money and releases the lock", run = function(T)
    Prepare(T)
    local item = T:Item("dbfail", { price = 300 })
    local bot = T:Bot("Unlucky")
    T:SetMoney(bot, 1000)
    local steamId = bot:SteamID64()

    T:BreakDB()
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:RestoreDB()

    T:Check("money restored after DB failure", T:Money(bot) == 1000, T:Money(bot))
    T:Check("item not granted", not T:Has(bot, item.id))
    T:Check("item lock released", not (SInv.Locks[steamId] and SInv.Locks[steamId][item.id]))
    T:Check("stock restored", item.stock == -1, item.stock)
end })

QA.Scenario("sell_refund", { system = "economy", title = "Sell returns the configured refund percentage", run = function(T)
    Prepare(T)
    local item = T:Item("sellable", { price = 400, refundPercent = 50 })
    local bot = T:Bot("Seller")
    T:SetMoney(bot, 1000)

    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    local afterBuy = T:Money(bot)
    T:Await(function(done) SInv.SellItem(bot, item.id, 1, done) end)

    T:Check("item removed on sale", not T:Has(bot, item.id))
    T:Check("half the price refunded", T:Money(bot) == afterBuy + 200, T:Money(bot) - afterBuy)
end })

QA.Scenario("refund_integer_percent", { system = "economy", title = "Refund percentages are whole percents everywhere, 1 means 1 percent", run = function(T)
    local refund = KrakensStore.Config.General.Refund
    local previous = refund.Percentage
    T:Undo(function() refund.Percentage = previous end)
    local bot = T:Bot("Refunder")

    local onePercent = T:Item("onepercent", { price = 400, refundPercent = 1 })
    T:Check("an item refund of 1 pays 1 percent", KrakensStore:GetItemRefund(bot, onePercent.id, 1) == 4, KrakensStore:GetItemRefund(bot, onePercent.id, 1))

    refund.Percentage = 25
    local inherited = T:Item("inherited", { price = 400 })
    T:Check("an item without its own refund uses the global percent", KrakensStore:GetItemRefund(bot, inherited.id, 1) == 100, KrakensStore:GetItemRefund(bot, inherited.id, 1))

    local spec = KrakensStore.Config.SettingByKey.refundPercentage
    T:Check("the refund setting reads the stored percent unchanged", spec.get() == 25, tostring(spec.get()))

    local sanitized = KrakensStore.Validation.ItemData({ id = "qa_refund_probe", name = "probe", refundPercent = 150 })
    T:Check("item refund percent is clamped to 100", sanitized and sanitized.refundPercent == 100, sanitized and sanitized.refundPercent)
end })

QA.Scenario("max_owned", { system = "economy", title = "maxOwned is enforced from the very first purchase", run = function(T)
    Prepare(T)
    local item = T:Item("limited", { price = 10, maxOwned = 2 })
    local bot = T:Bot("Hoarder")
    T:SetMoney(bot, 10000)

    local _, res = T:Await(function(done) SInv.PurchaseItem(bot, item.id, 5, done) end)
    T:Check("bulk purchase over the cap is refused", res[1] == false, tostring(res[1]))
    T:Check("nothing granted", T:Qty(bot, item.id) == 0, T:Qty(bot, item.id))

    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 2, done) end)
    T:Check("purchase up to the cap works", T:Qty(bot, item.id) == 2, T:Qty(bot, item.id))

    local _, res2 = T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Check("purchase beyond the cap is refused", res2[1] == false, tostring(res2[1]))
end })

QA.Scenario("stock_limit", { system = "economy", title = "Stock cannot go negative", run = function(T)
    Prepare(T)
    local item = T:Item("scarce", { price = 10, stock = 1 })
    local bot = T:Bot("First")
    T:SetMoney(bot, 1000)

    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Check("stock exhausted", item.stock == 0, item.stock)

    local _, res = T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Check("purchase refused with no stock", res[1] == false, tostring(res[1]))
    T:Check("stock still zero", item.stock == 0, item.stock)
end })

QA.Scenario("equip_unequip_effect", { system = "inventory", title = "Equip applies the type effect and unequip reverses it", run = function(T)
    Prepare(T)
    local applied, removed = 0, 0
    local item = T:Item("equippable", { price = 10, type = "custom", data = { hookName = "qa_effect" } })
    hook.Add("KrakensStore_Item_qa_effect_Equip", "KSQA_Equip", function() applied = applied + 1 end)
    hook.Add("KrakensStore_Item_qa_effect_Unequip", "KSQA_Unequip", function() removed = removed + 1 end)
    T:Undo(function() hook.Remove("KrakensStore_Item_qa_effect_Equip", "KSQA_Equip") end)
    T:Undo(function() hook.Remove("KrakensStore_Item_qa_effect_Unequip", "KSQA_Unequip") end)

    local bot = T:Bot("Wearer")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)

    T:Await(function(done) SInv.EquipItem(bot, item.id, done) end)
    T:Check("equipped flag set", T:Inv(bot)[item.id].equipped == true)
    T:Check("equip effect applied once", applied == 1, applied)

    T:Await(function(done) SInv.UnequipItem(bot, item.id, done) end)
    T:Check("equipped flag cleared", T:Inv(bot)[item.id].equipped == false)
    T:Check("unequip effect applied once", removed == 1, removed)
end })

QA.Scenario("equip_reapplies_per_life", { system = "inventory", title = "Equipped items are reapplied after death, not once per session", run = function(T)
    Prepare(T)
    local loadouts = 0
    local item = T:Item("perlife", { price = 10, type = "custom", data = { hookName = "qa_life" } })
    hook.Add("KrakensStore_Item_qa_life_Loadout", "KSQA_Life", function() loadouts = loadouts + 1 end)
    T:Undo(function() hook.Remove("KrakensStore_Item_qa_life_Loadout", "KSQA_Life") end)

    local bot = T:Bot("Mortal")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Await(function(done) SInv.EquipItem(bot, item.id, done) end)
    local before = loadouts

    bot:Kill()
    T:Wait(0.5)
    bot:Spawn()
    T:Wait(1.5)

    T:Check("loadout ran again after respawn", loadouts > before, before .. " -> " .. loadouts)
end })

QA.Scenario("team_change_keeps_loadout", { system = "inventory", title = "A team change without a respawn neither re-dispatches equipped items nor resets buffs", run = function(T)
    Prepare(T)
    local assignments = KrakensStore.SpawnAssignments
    KrakensStore.SpawnAssignments = {}
    T:Undo(function() KrakensStore.SpawnAssignments = assignments end)
    local loadouts = 0
    local item = T:Item("teamchange", { price = 10, type = "custom", data = { hookName = "qa_team" } })
    hook.Add("KrakensStore_Item_qa_team_Loadout", "KSQA_Team", function() loadouts = loadouts + 1 end)
    T:Undo(function() hook.Remove("KrakensStore_Item_qa_team_Loadout", "KSQA_Team") end)

    local bot = T:Bot("Recruit")
    local steamId = bot:SteamID64()
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Await(function(done) SInv.EquipItem(bot, item.id, done) end)
    T:Wait(1)
    KrakensStore.types["permbooster"].onEquip(bot, { action = "speed", percents = 50 }, { itemId = "qa_team_booster" })
    local before, boostedSpeed = loadouts, bot:GetWalkSpeed()

    hook.GetTable().OnPlayerChangedTeam.KrakensStore_EnforceItemAccess(bot, bot:Team(), bot:Team())
    T:Wait(1.5)

    T:Check("equipped items are not dispatched again", loadouts == before, before .. " -> " .. loadouts)
    T:Check("active buffs survive the team change", (KrakensStore.Buffs.ActiveBuffs[steamId] or {})[1] ~= nil)
    T:Check("the boosted walk speed is kept", bot:GetWalkSpeed() == boostedSpeed, bot:GetWalkSpeed() .. " vs " .. boostedSpeed)
end })

QA.Scenario("consume_removable", { system = "inventory", title = "Consumable option removes exactly one unit", run = function(T)
    Prepare(T)
    local item = T:Item("consumable", { price = 10 })
    local bot = T:Bot("User")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 2, done) end)
    T:Check("two units owned", T:Qty(bot, item.id) == 2, T:Qty(bot, item.id))

    local steamId = bot:SteamID64()
    T:Await(function(done) SInv.ConsumeItem(bot, item.id, false, done) end)
    T:Check("one unit consumed", T:Qty(bot, item.id) == 1, T:Qty(bot, item.id))
    T:Check("lock released after consume", not (SInv.Locks[steamId] and SInv.Locks[steamId][item.id]))

    T:Await(function(done) SInv.ConsumeItem(bot, item.id, false, done) end)
    T:Check("last unit removes the row", not T:Has(bot, item.id))
end })

QA.Scenario("consume_db_failure_keeps_item", { system = "inventory", title = "A failed consume leaves the item and releases the lock", run = function(T)
    Prepare(T)
    local item = T:Item("safeconsume", { price = 10 })
    local bot = T:Bot("Keeper")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)

    local steamId = bot:SteamID64()
    T:BreakDB()
    local _, res = T:Await(function(done) SInv.ConsumeItem(bot, item.id, false, done) end)
    T:RestoreDB()

    T:Check("consume reported failure", res[1] == false, tostring(res[1]))
    T:Check("item still owned", T:Qty(bot, item.id) == 1, T:Qty(bot, item.id))
    T:Check("lock released", not (SInv.Locks[steamId] and SInv.Locks[steamId][item.id]))
end })

QA.Scenario("consume_lock_handoff", { system = "inventory", title = "A caller-held lock is released even when consume aborts early", run = function(T)
    Prepare(T)
    local item = T:Item("lockprobe", { price = 10 })
    local bot = T:Bot("Locked")
    local steamId = bot:SteamID64()

    T:Check("lock acquired by the caller", SInv.AcquireItemLock(steamId, item.id) == true)
    local _, res = T:Await(function(done) SInv.ConsumeItem(bot, item.id, true, done) end)
    T:Check("consume refused for an unowned item", res[1] == false, tostring(res[1]))
    T:Check("caller lock was released on the abort path", not (SInv.Locks[steamId] and SInv.Locks[steamId][item.id]))
end })

QA.Scenario("expiry_prune", { system = "inventory", title = "Temporary items expire and are pruned", run = function(T)
    Prepare(T)
    local item = T:Item("temporary", { price = 10, duration = 60 })
    local bot = T:Bot("Renter")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Check("temporary item owned", T:Has(bot, item.id))
    T:Check("expiry stamped", (T:Inv(bot)[item.id].expires or -1) > 0)

    T:Skip(120)
    T:Check("expired item reads as not owned", not KrakensStore.Inventory.HasItem(bot, item.id))
    SInv.PruneExpiredItems(bot)
    T:Wait(0.5)
    T:Check("expired item pruned from the cache", not T:Has(bot, item.id))
end })

QA.Scenario("expired_stack_not_inherited", { system = "inventory", title = "Buying again after expiry starts a fresh stack", run = function(T)
    Prepare(T)
    local item = T:Item("retemp", { price = 10, duration = 60 })
    local bot = T:Bot("Returner")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Skip(120)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)

    local row = T:Inv(bot)[item.id]
    T:Check("row exists", row ~= nil)
    T:Check("quantity reset to one", row and row.quantity == 1, row and row.quantity)
    T:Check("new item is not already expired", row and not KrakensStore.Inventory.IsExpired(row))
end })

QA.Scenario("whitelist_deny", { system = "access", title = "requiresWhitelist gates access, an empty flag does not", run = function(T)
    Prepare(T)
    local open = T:Item("open", { price = 10, requiresWhitelist = false, whitelist = { usergroups = { "nobody" } } })
    local closed = T:Item("closed", { price = 10, requiresWhitelist = true, whitelist = { usergroups = { "nobody" } } })
    local bot = T:Bot("Guest")
    T:SetMoney(bot, 1000)

    T:Check("requiresWhitelist false ignores the rules", KrakensStore.Inventory.CanAccessItem(bot, open.id, open) == true)
    T:Check("requiresWhitelist true enforces the rules", KrakensStore.Inventory.CanAccessItem(bot, closed.id, closed) ~= true)

    local _, res = T:Await(function(done) SInv.PurchaseItem(bot, closed.id, 1, done) end)
    T:Check("purchase of a gated item is refused", res[1] == false, tostring(res[1]))
end })

QA.Scenario("npc_whitelist_polarity", { system = "access", title = "NPC whitelist uses the same polarity as items", run = function(T)
    local openNpc = T:NPC("open", { requiresWhitelist = false, whitelist = { usergroups = { "nobody" } } })
    local closedNpc = T:NPC("closed", { requiresWhitelist = true, whitelist = { usergroups = { "nobody" } } })
    local bot = T:Bot("Visitor")

    T:Check("open NPC is accessible", KrakensStore.NPCs.CanPlayerAccessNPC(bot, openNpc.id) == true)
    T:Check("gated NPC is not accessible", KrakensStore.NPCs.CanPlayerAccessNPC(bot, closedNpc.id) ~= true)
end })

QA.Scenario("admin_give_take", { system = "admin", title = "Admin give and take mutate the inventory and survive DB failure", run = function(T)
    Prepare(T)
    local item = T:Item("granted", { price = 10 })
    local bot = T:Bot("Receiver")

    T:Await(function(done) SInv.GiveItem(NULL, bot, item.id, 2, nil, done) end)
    T:Check("admin grant applied", T:Qty(bot, item.id) == 2, T:Qty(bot, item.id))

    T:Await(function(done) SInv.TakeItem(NULL, bot, item.id, 1, done) end)
    T:Check("admin take applied", T:Qty(bot, item.id) == 1, T:Qty(bot, item.id))

    T:BreakDB()
    T:Await(function(done) SInv.GiveItem(NULL, bot, item.id, 3, nil, done) end)
    T:RestoreDB()
    T:Check("failed grant preserves the previous stack", T:Qty(bot, item.id) == 1, T:Qty(bot, item.id))

    T:Await(function(done) SInv.GiveItem(NULL, bot, item.id, 2.5, nil, done) end)
    T:Check("admin grants floor fractional quantities like purchases", T:Qty(bot, item.id) == 3, T:Qty(bot, item.id))
end })

QA.Scenario("npc_long_id_delete", { system = "admin", title = "Every NPC id the editor accepts can also be deleted", run = function(T)
    local npc = T:NPC(string.rep("n", 90))
    local response = {}
    T:Check("an id longer than 64 characters passes the NPC id validator", KrakensStore.Validation.NpcId(npc.id) == npc.id, #npc.id)
    T:Check("a malformed NPC id reports an NPC error", select(2, KrakensStore.Validation.NpcId("bad id")) == KrakensStore.L("err_npc_id_invalid_chars"))
    T:Check("delete accepts the id", KrakensStore._NetHelpers.AdminActions.delete_npc(NULL, { id = npc.id }, response) == true, response.message)
    T:Check("the NPC is gone", T:WaitFor(function() return KrakensStore.NPCs.Get(npc.id) == nil end, 3))
end })

QA.Scenario("admin_delete_syncs_before_reply", { system = "admin", title = "A delete reaches clients before the AdminResponse that confirms it", run = function(T)
    local item = T:Item("confirmed_delete")
    local admin = T:Bot("Deleter")
    local synced, replied = T:Sends("KrakensStore_EntitySync"), T:Sends("KrakensStore_AdminResponse", admin)

    local response = { action = "delete_item", success = false }
    T:Check("delete accepts the item", KrakensStore._NetHelpers.AdminActions.delete_item(admin, { id = item.id }, response) == true, response.message)
    T:WaitFor(function() return replied.n > 0 end, 3)
    T:Check("the delete is confirmed as a success", response.success == true, response.message)
    T:Check("the EntitySync goes out before the AdminResponse", synced.n > 0 and replied.n > 0 and synced.at < replied.at, tostring(synced.at) .. " / " .. tostring(replied.at))
end })

QA.Scenario("chunked_sync_restarts_on_change", { system = "inventory", title = "A change during a chunked inventory transfer restarts the transfer once", run = function(T)
    Prepare(T)
    local bot = T:Bot("Hoarder")
    local inv = KrakensStore.Inventory.Cache[bot:SteamID64()]
    for i = 1, 500 do inv[PREFIX .. "bulk_" .. i] = { quantity = 1, equipped = false } end
    T:Undo(function() for i = 1, 500 do inv[PREFIX .. "bulk_" .. i] = nil end end)
    local timerName = "KrakensStore_InvSync_" .. bot:SteamID64()
    local synced = T:Count("KrakensStore_InventoryFullSynced")
    local chunks = T:Sends("KrakensStore_SyncInventory", bot)
    local atDelta = {}
    hook.Add("KrakensStore_InventoryItemSynced", "KSQA_ChunkRestart", function(ply) if ply == bot then atDelta[#atDelta + 1] = chunks.n end end)
    T:Undo(function() hook.Remove("KrakensStore_InventoryItemSynced", "KSQA_ChunkRestart") end)

    SInv.SyncInventory(bot)
    T:Check("the first chunk goes out at once", chunks.n == 1, chunks.n)
    T:Check("the remaining chunks are timed", timer.RepsLeft(timerName) == 9, tostring(timer.RepsLeft(timerName)))

    T:WaitFor(function() return chunks.n == 2 end, 2)
    for i = 1, 3 do inv[PREFIX .. "bulk_" .. i].expires = 1 end
    SInv.PruneExpiredItems(bot)
    T:WaitFor(function() return #atDelta == 3 end, 5)
    T:Check("every delta of the commit went out", #atDelta == 3, #atDelta)
    T:Check("the deltas are not interleaved with restarts", atDelta[1] == atDelta[3], table.concat(atDelta, ","))

    T:WaitFor(function() return synced.n > 0 end, 3)
    T:Check("one restart resends the whole inventory", chunks.n == (atDelta[1] or 0) + 10, chunks.n .. " after " .. tostring(atDelta[1]))
    T:Check("the full sync is reported once", synced.n == 1, synced.n)
    T:Check("no transfer timer is left behind", not timer.Exists(timerName))
end })

QA.Scenario("item_delete_purges_inventories", { system = "admin", title = "Deleting an item removes it from live inventories", run = function(T)
    Prepare(T)
    local item = T:Item("doomed", { price = 10 })
    local bot = T:Bot("Owner")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Check("item owned before deletion", T:Has(bot, item.id))

    SInv.PurgeItem(item.id)
    T:Wait(0.5)
    T:Check("item gone from the live inventory", not T:Has(bot, item.id))
end })

QA.Scenario("admin_update_keeps_live_state", { system = "admin", title = "Admin updates never write stale stock and never touch the cache before the DB", run = function(T)
    Prepare(T)
    local actions = KrakensStore._NetHelpers.AdminActions
    local item = T:Item("stocked", { price = 10, stock = 5 })
    local stale = table.Copy(item)
    local bot = T:Bot("Shopper")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 2, done) end)

    stale.name = "QA renamed"
    actions.update_item(NULL, stale, {})
    T:WaitFor(function() return KrakensStore.Items.Get(item.id).name == "QA renamed" end, 3)
    T:Check("the admin edit was applied", KrakensStore.Items.Get(item.id).name == "QA renamed")
    T:Check("the stale editor snapshot did not restore the stock", KrakensStore.Items.Get(item.id).stock == 3, KrakensStore.Items.Get(item.id).stock)

    local cat = T:Category("guarded", { name = "Before" })
    local renamedId = cat.id .. "_renamed"
    T:Undo(function()
        KrakensStore.Categories.Cache[renamedId] = nil
        Data.DeleteCategory(renamedId)
    end)

    T:BreakDB()
    actions.update_category(NULL, { id = cat.id, name = "After" }, {})
    actions.update_category(NULL, { oldId = cat.id, id = renamedId, name = "Moved" }, {})
    T:RestoreDB()

    local live = KrakensStore.Categories.Get(cat.id)
    T:Check("a failed category update leaves the cache untouched", live and live.name == "Before", live and live.name)
    T:Check("a failed rename keeps the category under its old id", live ~= nil and KrakensStore.Categories.Get(renamedId) == nil)

    local sawOldId
    hook.Add("KrakensStore_StoreDataChanged", "KSQA_RenameOrder", function() sawOldId = KrakensStore.Categories.Get(cat.id) ~= nil end)
    T:Undo(function() hook.Remove("KrakensStore_StoreDataChanged", "KSQA_RenameOrder") end)
    actions.update_category(NULL, { oldId = cat.id, id = renamedId, name = "Moved" }, {})
    T:WaitFor(function() return KrakensStore.Categories.Get(cat.id) == nil end, 3)
    T:Check("the store payload is invalidated after the old category is gone", sawOldId == false, tostring(sawOldId))
end })

QA.Scenario("log_toggles_gate_every_log", { system = "admin", title = "Log toggles gate every log row while PostDataLog keeps firing for admin edits", run = function(T)
    local logging = KrakensStore.Config.Logging
    local admin, purchases = logging.LogAdminActions, logging.LogPurchases
    T:Undo(function()
        logging.LogAdminActions = admin
        logging.LogPurchases = purchases
    end)
    logging.LogAdminActions = false
    logging.LogPurchases = false
    local logged = T:Count("KrakensStore_PostDataLog")
    T:BreakDB()

    local written = 0
    for _, logType in ipairs({ "admin_update_item", "purchase", "admin_give" }) do
        Data.Log(logType, nil, { itemId = "qa_probe" }, function(ok) if not ok then written = written + 1 end end)
    end
    T:Check("disabled log types are not recorded", written == 0, written)
    T:Check("admin edits still fire PostDataLog", logged.n == 1, logged.n)
end })

QA.Scenario("cvar_settings_stay_live", { system = "config", title = "Cvar settings are applied live and never kept in the settings blob", run = function(T)
    local spec
    for _, s in ipairs(KrakensStore.Config.SettingSpec) do
        if s.kind == "bool" and s.cvar and (not spec or GetConVar(s.cvar)) then spec = s end
    end
    local _, stored = T:Await(function(done) Data.GetConfig("settings", done) end)
    local original = spec.get()
    T:Undo(function()
        if original ~= nil then spec.set(original) end
        if istable(stored[1]) then Data.SetConfig("settings", stored[1]) else Data.DeleteConfig("settings") end
    end)

    local seeded = table.Copy(stored[1] or {})
    seeded[spec.key] = true
    T:Await(function(done) Data.SetConfig("settings", seeded, done) end)
    T:Await(function(done) KrakensStore.DB.Migrations[8](done) end)
    local _, migrated = T:Await(function(done) Data.GetConfig("settings", done) end)
    T:Check("the migration drops stored cvar values",
        istable(migrated[1]) and migrated[1][spec.key] == nil and table.Count(migrated[1]) == table.Count(seeded) - 1)

    if original == nil then return end
    local save, applied = KrakensStore._NetHelpers.AdminActions.save_settings, T:Count("KrakensStore_GeneralSettingsLoaded")
    save(NULL, { [spec.key] = not original }, {})
    T:WaitFor(function() return applied.n == 1 end, 3)
    T:Check("a saved cvar is set on the live cvar", spec.get() == not original, tostring(spec.get()))
    T:Check("a saved cvar is not written to the settings blob", applied.n == 1 and applied.last[1][spec.key] == nil)

    spec.set(original)
    save(NULL, { storeName = KrakensStore.Config.General.StoreName }, {})
    T:WaitFor(function() return applied.n == 2 end, 3)
    T:Check("saving another setting leaves the live cvar alone", spec.get() == original, tostring(spec.get()))
end })

QA.Scenario("rank_names", { system = "config", title = "Purchasable rank names survive validation, including vip plus", run = function(T)
    T:Check("plain rank accepted", KrakensStore.IsValidRankName("vip") == true)
    T:Check("rank with a plus accepted", KrakensStore.IsValidRankName("vip+") == true)
    T:Check("rank with a dot accepted", KrakensStore.IsValidRankName("vip.gold") == true)
    T:Check("rank with whitespace rejected", KrakensStore.IsValidRankName("vip gold") == false)
    T:Check("empty rank rejected", KrakensStore.IsValidRankName("") == false)
end })

QA.Scenario("settings_derive_from_spec", { system = "config", title = "Settings come from the spec, cvars from the live engine value", run = function(T)
    local Cfg = KrakensStore.Config
    local missing = {}
    for _, spec in ipairs(Cfg.SettingSpec) do
        if not spec.cvar and (spec.default == nil or spec.get() == nil) then missing[#missing + 1] = spec.key end
    end
    T:Check("every store setting has a default and a live value", #missing == 0, table.concat(missing, ", "))

    local settings = Cfg.ReadSettings()
    local fabricated = {}
    for _, spec in ipairs(Cfg.SettingSpec) do
        if spec.cvar then
            local cv = GetConVar(spec.cvar)
            local live
            if cv and spec.kind == "bool" then live = cv:GetBool() elseif cv then live = cv:GetInt() end
            if settings[spec.key] ~= live then fabricated[#fabricated + 1] = spec.key end
            if cv then
                spec.set(live)
                if spec.get() ~= live then fabricated[#fabricated + 1] = spec.key .. " (set)" end
            end
        end
    end
    T:Check("cvar settings report the live cvar and never a made-up default", #fabricated == 0, table.concat(fabricated, ", "))

    local npcSpec = Cfg.SettingByKey.npcModel
    local previous = npcSpec.get()
    local placed = ents.Create(KrakensStore.EntityClasses.NPC)
    placed:SetPos(T.origin + Vector(96, 0, 0))
    placed:Spawn()
    T:Undo(function()
        npcSpec.set(previous)
        if IsValid(placed) then placed:Remove() end
    end)
    npcSpec.set("models/humans/group01/female_01.mdl")
    local npc = KrakensStore.NPCs.CreateNPC({ id = "qa_model_probe" })
    T:Check("the default NPC model setting drives new NPCs", npc.model == "models/humans/group01/female_01.mdl", npc.model)
    Data.ApplyConfiguredEntityModels()
    T:Check("the default NPC model setting reaches unconfigured NPCs already in the world", placed:GetModel() == "models/humans/group01/female_01.mdl", placed:GetModel())

    T:Setting("MaxDistance", 500)
    T:Check("the use distance setting applies to NPCs", KrakensStore.Utils.GetUseDistance("NPC") == 500, KrakensStore.Utils.GetUseDistance("NPC"))
    T:Check("the use distance setting applies to terminals", KrakensStore.Utils.GetUseDistance("Terminal") == 500, KrakensStore.Utils.GetUseDistance("Terminal"))
end })

QA.Scenario("admin_group_membership", { system = "config", title = "Admin and action permissions use the framework group match", run = function(T)
    local perms = KrakensStore.Config.Permissions
    local adminGroups, configGroups = perms.AdminGroups, perms.ActionPermissions.manage_config
    T:Undo(function()
        perms.AdminGroups = adminGroups
        perms.ActionPermissions.manage_config = configGroups
    end)
    local bot = T:Bot("Member")
    local group = bot:GetUserGroup()

    perms.AdminGroups = {}
    T:Check("a player outside the admin groups is not an admin", KrakensStore.IsAdmin(bot) == bot:IsSuperAdmin())

    perms.AdminGroups = { string.upper(group) }
    T:Check("admin groups match regardless of case", KrakensStore.IsAdmin(bot) == true, group)

    perms.ActionPermissions.manage_config = { " " .. string.upper(group) .. " " }
    T:Check("action permissions use the same match", KrakensStore.HasActionPermission(bot, "manage_config") == true, group)

    perms.ActionPermissions.manage_config = { "qa_nobody" }
    T:Check("action permissions still deny other groups", KrakensStore.HasActionPermission(bot, "manage_config") == false)
end })

QA.Scenario("type_settings_validation", { system = "types", title = "Type settings validate min, max and required on the server", run = function(T)
    local ok1 = KrakensStore:ValidateTypeSettings("permbooster", { action = "speed", percents = 20 })
    T:Check("valid booster accepted", ok1 == true)

    local ok2 = KrakensStore:ValidateTypeSettings("permbooster", { action = "speed", percents = 500 })
    T:Check("out of range percentage rejected", ok2 == false)

    local ok3 = KrakensStore:ValidateTypeSettings("permbooster", { percents = 20 })
    T:Check("missing required setting rejected", ok3 == false)

    local ok4 = KrakensStore:ValidateTypeSettings("trail", { texture = "trails/laser", trailColor = "not a colour" })
    T:Check("malformed colour rejected", ok4 == false)

    local ok5 = KrakensStore:ValidateTypeSettings("custom", { hookName = string.rep("h", 65) })
    T:Check("hook names follow the framework length limit", ok5 == false)

    local ok6 = KrakensStore:ValidateTypeSettings("weapon", { weaponClass = false })
    T:Check("false does not satisfy a required setting", ok6 == false)
end })

QA.Scenario("architecture", { system = "architecture", title = "Static invariants hold across the addon", run = function(T)
    local badTypes = {}
    for id, item in pairs(KrakensStore.Items.GetAll()) do
        if item.type and not KrakensStore.types[item.type] then badTypes[#badTypes + 1] = id .. ":" .. tostring(item.type) end
    end
    T:Check("every stored item has a registered type", #badTypes == 0, table.concat(badTypes, ", "))

    local dropped = {}
    for typeId, def in pairs(KrakensStore.types) do
        local probe = { id = "qa_probe", name = "probe", type = typeId, data = {} }
        for _, setting in ipairs(def.settings or {}) do probe.data[setting.key] = "probe" end
        local sanitized = KrakensStore.Validation.ItemData(probe)
        for _, setting in ipairs(def.settings or {}) do
            if sanitized and sanitized.data and sanitized.data[setting.key] == nil then
                dropped[#dropped + 1] = typeId .. "." .. setting.key
            end
        end
    end
    T:Check("no declared setting key is dropped by the sanitiser", #dropped == 0, table.concat(dropped, ", "))

    local missingLang = {}
    for _, code in ipairs({ "en", "es", "de", "fr", "pt", "ru", "uk" }) do
        local missing = KF.Lang.Audit(KrakensStore.AID, code)
        if #missing > 0 then missingLang[#missingLang + 1] = code .. "(" .. #missing .. ")" end
    end
    T:Check("all languages are complete against en", #missingLang == 0, table.concat(missingLang, ", "))

    local optionKeys = {}
    for typeId, def in pairs(KrakensStore.types) do
        for optionId in pairs(def.options or {}) do
            local key = "btn_option_" .. optionId
            if KrakensStore.L(key) == "[" .. key .. "]" then optionKeys[#optionKeys + 1] = typeId .. "/" .. optionId end
        end
    end
    T:Check("every option id has a button label", #optionKeys == 0, table.concat(optionKeys, ", "))
end })

QA.Scenario("registered_content_survives_reload", { system = "registry", title = "Content registered in code survives a full data reload", run = function(T)
    Prepare(T)
    local item = T:Item("registered", { price = 10 })
    local cat = T:Category("registered")
    local npc = T:NPC("registered")

    local itemsTable = KrakensStore.Items.Cache
    local catsTable = KrakensStore.Categories.Cache
    local npcsTable = KrakensStore.NPCs.Cache

    local reloaded = false
    Data.LoadAllData(true)
    T:WaitFor(function()
        reloaded = Data.IsLoaded()
        return reloaded
    end, 10)

    T:Check("data reload completed", reloaded)
    T:Check("registered item survived the reload", KrakensStore.Items.Get(item.id) ~= nil)
    T:Check("registered category survived the reload", KrakensStore.Categories.Get(cat.id) ~= nil)
    T:Check("registered NPC survived the reload", KrakensStore.NPCs.Get(npc.id) ~= nil)

    T:Check("Items.Cache table identity preserved", KrakensStore.Items.Cache == itemsTable)
    T:Check("Categories.Cache table identity preserved", KrakensStore.Categories.Cache == catsTable)
    T:Check("NPCs.Cache table identity preserved", KrakensStore.NPCs.Cache == npcsTable)
end })

QA.Scenario("booster_unit_validation", { system = "types", title = "Booster amount is validated against the unit of the chosen buff", run = function(T)
    local ok1, err1 = KrakensStore:ValidateTypeSettings("permbooster", { action = "speed", percents = 150 })
    T:Check("a percent buff rejects 150", ok1 == false, tostring(err1))

    local ok2 = KrakensStore:ValidateTypeSettings("permbooster", { action = "speed", percents = 50 })
    T:Check("a percent buff accepts 50", ok2 == true)

    local ok3 = KrakensStore:ValidateTypeSettings("permbooster", { action = "max_health", percents = 150 })
    T:Check("a flat buff accepts 150", ok3 == true)

    local ok4, err4 = KrakensStore:ValidateTypeSettings("permbooster", { action = "max_health", percents = 5000 })
    T:Check("a flat buff still has an upper bound", ok4 == false, tostring(err4))
    T:Check("the rejection message formats without erroring", isstring(err4), type(err4))
end })

QA.Scenario("attachment_blacklist_case", { system = "types", title = "Attachment blacklist matches ids regardless of case", run = function(T)
    local cfg = KrakensStore.Config.Integrations.ARC9
    local original = cfg.AccessoryBlacklist
    T:Undo(function() cfg.AccessoryBlacklist = original end)
    cfg.AccessoryBlacklist = { optic_eotech = true, Legacy_Att = true }

    local Int = KrakensStore.Integrations
    T:Check("a mixed-case id matches its lowercased entry", Int.IsAttachmentBlacklisted("arc9", "Optic_EOTech") == true)
    T:Check("a legacy mixed-case entry still matches", Int.IsAttachmentBlacklisted("arc9", "Legacy_Att") == true)
    T:Check("other ids are not blocked", Int.IsAttachmentBlacklisted("arc9", "optic_other") == false)
end })

QA.Scenario("integration_single_source", { system = "types", title = "One availability check decides the type list, purchase and option use of an integration", run = function(T)
    Prepare(T)
    local Int = KrakensStore.Integrations
    local wiltos, lscs = Int.Globals.wiltos, Int.Globals.lscs
    T:Undo(function() Int.Globals.wiltos, Int.Globals.lscs, _G.KSQA_WiltOS = wiltos, lscs, nil end)
    Int.Globals.wiltos = { "KSQA_WOS", "KSQA_WiltOS" }
    Int.Globals.lscs = { "KSQA_LSCS" }

    local bot = T:Bot("Integrator")
    local skill = T:Item("wiltos_gate", { type = "wiltos_skill", data = { skillid = "ksqa_skill" } })
    local crystal = T:Item("lscs_gate", { type = "lscs_crystal", data = { crystalId = "ksqa_crystal" } })

    T:Check("a missing integration hides its type", KrakensStore:IsTypeAvailable("wiltos_skill") == false)
    local notInstalled = KrakensStore.L("type_integration_not_installed")
    local bought, reason = KrakensStore:CanPlayerPurchase(bot, skill)
    T:Check("a missing integration refuses the purchase by its readable name", bought == false and reason == string.format(notInstalled, "KSQA_WiltOS"), tostring(reason))
    local used, useReason = KrakensStore:ExecuteOption(bot, "unlock", crystal, { itemId = crystal.id, quantity = 1 }, crystal.id)
    T:Check("a missing integration refuses option use", used == false and useReason == string.format(notInstalled, "KSQA_LSCS"), tostring(useReason))

    _G.KSQA_WiltOS = {}
    T:Check("any alias of the integration makes the type available", KrakensStore:IsTypeAvailable("wiltos_skill") == true)
    T:Check("purchase agrees with the type list", KrakensStore:CanPlayerPurchase(bot, skill) == true)
end })

QA.Scenario("crystal_unlock_reports_failure", { system = "types", title = "A Kyber crystal unlock that grants nothing reports failure so the item is kept", run = function(T)
    local bot = T:Bot("Crystal")
    local unlock = KrakensStore.types["lscs_crystal"].options.unlock
    T:Check("an unknown crystal is not reported as unlocked", unlock.func(bot, { crystalId = "ksqa_missing_crystal" }) == false)
    T:Check("a missing crystal id is not reported as unlocked", unlock.func(bot, {}) == false)
end })

QA.Scenario("attachment_pairs_share_ownership", { system = "types", title = "Consumable and permanent attachments both refuse an attachment the player already unlocked", run = function(T)
    local bot = T:Bot("Collector")
    KrakensStore.TypeHelpers.GetUnlockedAttachmentStore(bot, "arc9", true).ksqa_owned_att = true
    for _, typeId in ipairs({ "attachment_arc9", "permattachment_arc9" }) do
        T:Check(typeId .. " refuses an unlocked attachment", KrakensStore.types[typeId].canPurchase(bot, nil, { attachmentId = "ksqa_owned_att" }) == false)
    end
    T:Check("an attachment that is not unlocked stays purchasable", KrakensStore.types["permattachment_arc9"].canPurchase(bot, nil, { attachmentId = "ksqa_other_att" }) == true)
end })

QA.Scenario("stats_follow_item_type", { system = "types", title = "Attachment stats come from the system of the item type even when both systems share the id", run = function(T)
    local Int = KrakensStore.Integrations
    local arc9, arccw = Int.Globals.arc9, Int.Globals.arccw
    T:Undo(function() Int.Globals.arc9, Int.Globals.arccw, _G.KSQA_ARC9, _G.KSQA_ArcCW = arc9, arccw, nil, nil end)
    Int.Globals.arc9, Int.Globals.arccw = { "KSQA_ARC9" }, { "KSQA_ArcCW" }
    _G.KSQA_ARC9 = { Attachments = { ksqa_shared = { RecoilMult = 2 } } }
    _G.KSQA_ArcCW = { AttachmentTable = { ksqa_shared = { Mult_Recoil = 0.5 } } }

    local data, kind = KrakensStore.Stats.GetItemStats({ type = "permattachment_arccw", data = { attachmentId = "ksqa_shared" } })
    local prop = data and data.props[1]
    T:Check("the item is read as an attachment", kind == "attachment", tostring(kind))
    T:Check("the ArcCW entry is used for an ArcCW item", prop ~= nil and prop.key == "recoil" and prop.value == 0.5, prop and tostring(prop.value))
    T:Check("a plain weapon has no attachment-system stats", KrakensStore.Stats.ItemKind("weapon") == nil)
end })

QA.Scenario("command_placeholders", { system = "types", title = "Console command items substitute every player placeholder", run = function(T)
    T:Setting("CommandAllowlist", { say = true })
    local bot = T:Bot("Commander")
    local realCommand, sent = game.ConsoleCommand, nil
    T:Undo(function() game.ConsoleCommand = realCommand end)
    game.ConsoleCommand = function(cmd) sent = cmd end

    KrakensStore.types["runconsolecommand"].options.use.func(bot, { command = "say {steamid64} {steamid} {userid} {name}" })
    game.ConsoleCommand = realCommand

    local expected = string.format("say %s %s %s \"%s\"\n", bot:SteamID64(), bot:SteamID(), bot:UserID(), bot:Nick())
    T:Check("every placeholder is replaced", sent == expected, tostring(sent))
end })

QA.Scenario("booster_apply_matches_validation", { system = "types", title = "A booster applies the same amount its validation accepted", run = function(T)
    local bot = T:Bot("Boosted")
    local steamId = bot:SteamID64()
    local booster = KrakensStore.types["permbooster"]
    local function Applied(buffId)
        for _, buff in ipairs(KrakensStore.Buffs.ActiveBuffs[steamId] or {}) do
            if buff.type == buffId then return buff.value end
        end
    end

    booster.onEquip(bot, { action = "max_health", percents = 150 }, { itemId = "qa_flat" })
    T:Check("a flat buff applies the full 150", Applied("max_health") == 150, tostring(Applied("max_health")))
    booster.onUnequip(bot, { action = "max_health", percents = 150 }, { itemId = "qa_flat" })

    booster.onEquip(bot, { action = "speed", percents = 150 }, { itemId = "qa_pct" })
    T:Check("a percent buff is capped at 100", Applied("speed") == 100, tostring(Applied("speed")))
    booster.onUnequip(bot, { action = "speed", percents = 150 }, { itemId = "qa_pct" })
end })

QA.Scenario("load_failure_preserves_cache", { system = "lifecycle", title = "A failed item read keeps the cache, reports FAILED and recovers when the cause is fixed", run = function(T)
    Prepare(T)
    local item = T:Item("survivor", { price = 10 })
    local LC = KrakensStore.Lifecycle
    local realGetAll = Data.GetAllItems

    T:Undo(function()
        Data.GetAllItems = realGetAll
        timer.Remove("KrakensStore_Recovery")
    end)

    Data.GetAllItems = function(cb) KrakensStore.Fire(cb, nil, "QA induced item read failure") end
    Data.LoadAllData(true)
    T:WaitFor(function() return LC.Phase == "FAILED" end, 10)
    Data.GetAllItems = realGetAll
    timer.Remove("KrakensStore_Recovery")

    T:Check("the load reports FAILED, never READY", LC.Phase == "FAILED", LC.Phase)
    T:Check("Data.IsLoaded stays false", Data.IsLoaded() == false)
    T:Check("the failing step is named", string.find(LC.Failure or "", "Items", 1, true) ~= nil, tostring(LC.Failure))
    T:Check("the real cause is reported", string.find(LC.Failure or "", "QA induced", 1, true) ~= nil, tostring(LC.Failure))
    T:Check("the item cache was not wiped by the failed read", KrakensStore.Items.Get(item.id) ~= nil)
    T:Check("earlier steps are reported as complete", LC.Steps.Categories == "COMPLETE", tostring(LC.Steps.Categories))
    T:Check("the failing step is reported as failed", LC.Steps.Items == "FAILED", tostring(LC.Steps.Items))
    T:Check("the status line carries the failure", string.find(LC.Describe(), "Failure:", 1, true) ~= nil, LC.Describe())

    Data.LoadAllData(true)
    T:WaitFor(function() return LC.Phase == "READY" end, 15)
    T:Check("the store recovers once the cause is gone", LC.Phase == "READY", LC.Phase)
    T:Check("the item is still there after recovery", KrakensStore.Items.Get(item.id) ~= nil)
end })

QA.Scenario("pre_ready_requests_queue_centrally", { system = "lifecycle", title = "Requests before READY queue once per player through one central mechanism", run = function(T)
    Prepare(T)
    local bot = T:Bot("Waiter")
    local LC = KrakensStore.Lifecycle
    local H = KrakensStore._NetHelpers
    local steamId = bot:SteamID64()
    local phase = LC.Phase

    T:Undo(function()
        LC.CancelWaitsFor(steamId)
        LC.Phase = phase
    end)

    local settings = T:Sends("KrakensStore_SyncSettings", bot)
    local store = T:Sends("KrakensStore_SyncStoreData", bot)

    LC.Phase = "LOADING"
    local before = LC.PendingCount()
    H.SyncPlayer(bot)
    H.SyncPlayer(bot)
    H.SyncPlayer(bot)
    T:Check("three sync requests produce one queued entry", LC.PendingCount() == before + 1, LC.PendingCount())
    T:Check("settings about to be reloaded are not sent", settings.n == 0, settings.n)

    H.SendAdminData(bot)
    T:Check("a different request kind queues separately", LC.PendingCount() == before + 2, LC.PendingCount())

    LC.CancelWaitsFor(steamId)
    T:Check("a disconnect clears every entry for that player", LC.PendingCount() == before, LC.PendingCount())

    LC.Phase = "FAILED"
    H.SyncPlayer(bot)
    T:Check("a failed store still sends the settings it holds", settings.n == 1, settings.n)
    T:Check("the catalogue stays queued until READY", store.n == 0 and LC.PendingCount() == before + 1, store.n .. " / " .. LC.PendingCount())
    LC.CancelWaitsFor(steamId)

    LC.Phase = phase
    T:Check("WhenReady runs immediately once READY", LC.WhenReady("qa:" .. steamId, function() end) == true)
end })

QA.Scenario("reload_syncs_each_player_once", { system = "lifecycle", title = "A data reload sends the catalogue and settings to each player exactly once", run = function(T)
    Prepare(T)
    local bot = T:Bot("Resynced")
    local H = KrakensStore._NetHelpers
    local store = T:Sends("KrakensStore_SyncStoreData", bot)
    local settings = T:Sends("KrakensStore_SyncSettings", bot)
    local loaded = T:Count("KrakensStore_DataLoaded")

    hook.Add("KrakensStore_StateChanged", "KSQA_MidLoadRequest", function(phase)
        if phase == "LOADING" then H.SyncPlayer(bot) end
    end)
    T:Undo(function() hook.Remove("KrakensStore_StateChanged", "KSQA_MidLoadRequest") end)

    Data.LoadAllData(true)
    T:WaitFor(function() return loaded.n > 0 end, 15)

    T:Check("the reload finished", loaded.n == 1, loaded.n)
    T:Check("store data sent once despite a request during loading", store.n == #H.StoreChunks(), store.n)
    T:Check("settings sent once", settings.n == 1, settings.n)
end })

QA.Scenario("player_load_failure_recovers", { system = "lifecycle", title = "A failed inventory read leaves the player unloaded and the next sync loads them", run = function(T)
    Prepare(T)
    local bot = T:Bot("Reloader")
    local steamId = bot:SteamID64()
    local fullSyncs = T:Count("KrakensStore_InventoryFullSynced")

    SInv.CleanupPlayer(steamId)
    T:BreakDB()
    SInv.LoadPlayer(bot)
    T:RestoreDB()

    T:Check("a failed read leaves no inventory entry", KrakensStore.Inventory.Cache[steamId] == nil)
    T:Check("a failed read does not leave the player marked as loading", bot._KSLoading == nil)
    SInv.SyncInventory(bot)
    T:Check("an unloaded player is never sent an empty inventory", fullSyncs.n == 0, fullSyncs.n)

    KrakensStore._NetHelpers.SyncPlayer(bot)
    T:Check("the next sync loads the inventory", T:WaitFor(function() return KrakensStore.Inventory.Cache[steamId] ~= nil end, 5))
end })

QA.Scenario("migrations_refuse_unreadable_version", { system = "lifecycle", title = "An unreadable schema version fails the migration run instead of replaying every migration", run = function(T)
    T:BreakDB()
    local _, res = T:Await(function(done) KrakensStore.DB.RunMigrations(done) end)
    T:RestoreDB()
    T:Check("the migration run reports failure", res[1] == false, tostring(res[1]))
    T:Check("the cause names the schema version", string.find(tostring(res[2]), "schema version", 1, true) ~= nil, tostring(res[2]))
end })

QA.Scenario("server_migration_moves_recoveries", { system = "lifecycle", title = "Migrating a server id also moves pending currency recoveries", run = function(T)
    local DB = KrakensStore.DB
    local oldId, steamId = "qa_old_server", "76561190000000042"
    T:Undo(function() DB.Query(string.format("DELETE FROM krakens_store_recoveries WHERE steamid='%s'", steamId)) end)

    T:Await(function(done)
        DB.Query(string.format("INSERT INTO krakens_store_recoveries (server_id, steamid, type, amount, reason, created) VALUES ('%s','%s','refund',50,'qa',0)", oldId, steamId), done)
    end)
    T:Await(function(done) Data.MigrateServerData(oldId, DB.GetServerId(), done) end)
    local _, res = T:Await(function(done)
        DB.Query(string.format("SELECT server_id FROM krakens_store_recoveries WHERE steamid='%s'", steamId), done)
    end)
    local row = istable(res[1]) and res[1][1]
    T:Check("the recovery row follows the migration", row and row.server_id == DB.GetServerId(), row and row.server_id)
end })

QA.Scenario("player_first_seen_is_server_scoped", { system = "lifecycle", title = "A player's first-seen time is never borrowed from another server id", run = function(T)
    local DB = KrakensStore.DB
    local steamId = "76561190000000043"
    T:Undo(function() DB.Query(string.format("DELETE FROM krakens_store_players WHERE steamid='%s'", steamId)) end)

    T:Await(function(done)
        DB.Query(string.format("INSERT INTO krakens_store_players (server_id, steamid, data, first_seen) VALUES ('qa_other_server','%s','{}',1)", steamId), done)
    end)
    T:Await(function(done)
        Data.SavePlayerData(steamId, { firstSeen = 500 }, done)
        Data.FlushPendingPlayer(steamId)
    end)
    local _, res = T:Await(function(done)
        DB.Query(string.format("SELECT first_seen FROM krakens_store_players WHERE server_id='%s' AND steamid='%s'", DB.GetEscapedServerId(), steamId), done)
    end)
    local row = istable(res[1]) and res[1][1]
    T:Check("the current server row keeps its own first-seen time", row and tonumber(row.first_seen) == 500, row and row.first_seen)
end })

QA.Scenario("respawn_drops_stale_buffs", { system = "inventory", title = "A respawn rebuilds buffs from the equipped inventory and drops buffs nothing grants any more", run = function(T)
    Prepare(T)
    local assignments = KrakensStore.SpawnAssignments
    KrakensStore.SpawnAssignments = {}
    T:Undo(function() KrakensStore.SpawnAssignments = assignments end)
    local item = T:Item("respawn_booster", { price = 10, type = "permbooster", data = { action = "speed", percents = 50 } })
    local bot = T:Bot("Rebuffed")
    local steamId = bot:SteamID64()
    local baseSpeed = bot:GetWalkSpeed()
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Await(function(done) SInv.EquipItem(bot, item.id, done) end)

    KrakensStore.types.permbooster.onEquip(bot, { action = "speed", percents = 50 }, { itemId = "qa_stale_booster" })
    T:Check("the equipped and the stale booster are both active before respawn", #(KrakensStore.Buffs.ActiveBuffs[steamId] or {}) == 2, #(KrakensStore.Buffs.ActiveBuffs[steamId] or {}))

    bot:Spawn()
    T:Wait(1)
    local active = KrakensStore.Buffs.ActiveBuffs[steamId] or {}
    T:Check("only the equipped booster is active after respawn", #active == 1 and active[1].itemId == item.id and active[1].value == 50, #active)
    T:Check("the walk speed is the base plus the equipped booster", math.abs(bot:GetWalkSpeed() - baseSpeed * 1.5) < 1, bot:GetWalkSpeed() .. " vs " .. baseSpeed * 1.5)
end })

QA.Scenario("addon_namespace_isolation", { system = "lifecycle", title = "Every identifier the store claims is namespaced and actually registered", run = function(T)
    local missing = {}
    for _, name in ipairs(KrakensStore.NetNames) do
        if not string.StartsWith(name, "KrakensStore_") or util.NetworkStringToID(name) == 0 then missing[#missing + 1] = name end
    end
    T:Check("every declared net name is namespaced and registered", #missing == 0, table.concat(missing, ", "))

    local unprefixed = {}
    for _, dialect in pairs(KrakensStore.DB.Schema) do
        for _, ddl in ipairs(dialect) do
            local tbl = string.match(ddl, "CREATE TABLE IF NOT EXISTS%s+([%w_]+)")
            if tbl and not string.StartsWith(tbl, "krakens_store_") then unprefixed[#unprefixed + 1] = tbl end
        end
    end
    T:Check("every table the store creates is namespaced", #unprefixed == 0, table.concat(unprefixed, ", "))

    local strays = {}
    for event, entries in pairs(hook.GetTable()) do
        for id in pairs(entries) do
            if isstring(id) and not string.StartsWith(id, "KrakensStore") and string.find(string.Replace(id, event, ""), "KrakensStore", 1, true) then
                strays[#strays + 1] = event .. "/" .. id
            end
        end
    end
    T:Check("every store hook identifier starts with the namespace", #strays == 0, table.concat(strays, ", "))
end })

QA.Scenario("equip_twice_refused", { system = "inventory", title = "Equipping an item that is already equipped is refused with its reason and applies nothing", run = function(T)
    Prepare(T)
    local applied = 0
    local item = T:Item("equip_twice", { price = 10, type = "custom", data = { hookName = "qa_twice" } })
    hook.Add("KrakensStore_Item_qa_twice_Equip", "KSQA_Twice", function() applied = applied + 1 end)
    T:Undo(function() hook.Remove("KrakensStore_Item_qa_twice_Equip", "KSQA_Twice") end)
    local bot = T:Bot("Doubler")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Await(function(done) SInv.EquipItem(bot, item.id, done) end)

    local _, res = T:Await(function(done) SInv.EquipItem(bot, item.id, done) end)
    T:Check("the second equip is refused", res[1] == false, tostring(res[1]))
    T:Check("the refusal carries the already-equipped reason", res[2] == KrakensStore.L("err_item_already_equipped"), tostring(res[2]))
    T:Check("the equip effect ran once", applied == 1, applied)
end })

QA.Scenario("join_loads_inventory_server_side", { system = "lifecycle", title = "A joining player's inventory loads from PlayerInitialSpawn without any client request", run = function(T)
    Prepare(T)
    local bot = T:Bot("Joiner")
    local steamId = bot:SteamID64()
    SInv.CleanupPlayer(steamId)
    hook.GetTable().PlayerInitialSpawn.KrakensStore_LoadInventory(bot)
    T:Check("the inventory is loaded by the join hook", T:WaitFor(function() return KrakensStore.Inventory.Cache[steamId] ~= nil end, 5))
end })

QA.Scenario("settings_read_failure_keeps_blob", { system = "config", title = "A failed read of the stored settings aborts the save and the migration instead of overwriting them", run = function(T)
    local realGet, realSet = Data.GetConfig, Data.SetConfig
    local writes = 0
    T:Undo(function() Data.GetConfig, Data.SetConfig = realGet, realSet end)
    Data.GetConfig = function(_, cb) KrakensStore.Fire(cb, nil, "QA induced read failure") end
    Data.SetConfig = function(_, _, cb) writes = writes + 1 KrakensStore.Fire(cb, true) end

    local response = { action = "save_settings", success = false }
    KrakensStore._NetHelpers.AdminActions.save_settings(NULL, { storeName = "QA unsaved name" }, response)
    local _, migrated = T:Await(function(done) KrakensStore.DB.Migrations[6](done) end)
    Data.GetConfig, Data.SetConfig = realGet, realSet

    T:Check("nothing is written when the stored settings cannot be read", writes == 0, writes)
    T:Check("the save reports the store as not ready", response.success == false and response.message == KrakensStore.L("err_store_not_ready"), tostring(response.message))
    T:Check("the legacy settings migration fails instead of completing", migrated[1] == false, tostring(migrated[1]))
end })

QA.Scenario("simfphys_spawn_call", { system = "types", title = "Simfphys vehicles are spawned with the spawnname, position and angle simfphys expects", run = function(T)
    Prepare(T)
    local bot = T:Bot("Driver")
    local vehicles = list.GetForEdit("simfphys_vehicles")
    local realSimfphys = simfphys
    local spawnArgs
    T:Undo(function()
        vehicles.ksqa_car = nil
        simfphys = realSimfphys
        hook.Remove("PlayerSpawnVehicle", "KSQA_AllowVehicle")
    end)
    vehicles.ksqa_car = { Name = "QA car" }
    simfphys = { SpawnVehicleSimple = function(...) spawnArgs = { ... } return NULL end }
    hook.Add("PlayerSpawnVehicle", "KSQA_AllowVehicle", function() return true end)

    local pos, ang = bot:GetPos() + Vector(0, 0, 50), Angle(0, 90, 0)
    local ok, err = pcall(KrakensStore.types.vehicle_simfphys.options.spawn.func, bot, { vehicleClass = "ksqa_car" }, nil, pos, ang)
    simfphys = realSimfphys
    T:Check("the spawn option ran", ok, err)
    T:Check("simfphys was asked to spawn", spawnArgs ~= nil)
    T:Check("the spawnname is the first argument", spawnArgs ~= nil and spawnArgs[1] == "ksqa_car", spawnArgs and tostring(spawnArgs[1]))
    T:Check("the position and angle follow the spawnname", spawnArgs ~= nil and spawnArgs[2] == pos and spawnArgs[3] == ang)
end })

QA.Scenario("store_state_failure_admin_only", { system = "lifecycle", title = "Startup failure details are sent to administrators only", run = function(T)
    local bot = T:Bot("Onlooker")
    local LC = KrakensStore.Lifecycle
    local failure, realWrite = LC.Failure, net.WriteString
    local written = {}
    T:Undo(function()
        LC.Failure = failure
        net.WriteString = realWrite
    end)
    LC.Failure = "QA secret failure"
    net.WriteString = function(text)
        written[#written + 1] = text
        return realWrite(text)
    end
    KrakensStore._NetHelpers.SendStoreState(bot)
    net.WriteString = realWrite
    LC.Failure = failure

    T:Check("the probe player is not an administrator", not KrakensStore.IsAdmin(bot))
    T:Check("the failure text is not sent to a non-administrator", not table.HasValue(written, "QA secret failure"), table.concat(written, " | "))
end })

QA.Scenario("npc_scope_without_npc_id", { system = "access", title = "A purchase without an NPC id next to a vendor NPC is scoped to that vendor", run = function(T)
    Prepare(T)
    T:Setting("RequireEntity", true)
    local sold = T:Item("vendor_sold", { price = 10 })
    local other = T:Item("vendor_other", { price = 10 })
    local npc = T:NPC("vendor", { items = { [sold.id] = true } })
    local bot = T:Bot("Customer")
    local H = KrakensStore._NetHelpers

    T:Check("no store terminal stands at the probe position", not H.IsNearStoreEntity(bot))
    T:Check("nothing is purchasable without a vendor nearby", H.ValidatePurchaseScope(bot, "", sold.id) ~= true)

    local vendor = ents.Create(KrakensStore.EntityClasses.NPC)
    vendor:SetPos(bot:GetPos() + Vector(48, 0, 0))
    vendor:Spawn()
    KrakensStore.NPCs.ConfigureEntity(vendor, npc.id)
    T:Undo(function() if IsValid(vendor) then vendor:Remove() end end)

    T:Check("an item the nearby vendor sells is allowed", H.ValidatePurchaseScope(bot, "", sold.id) == true)
    T:Check("an item the nearby vendor does not sell is refused", H.ValidatePurchaseScope(bot, "", other.id) ~= true)
    T:Check("the vendor still allows selling and option use", H.CanUseStoreAction(bot, nil) == true)
end })

QA.Scenario("stale_item_save_keeps_live_stock", { system = "admin", title = "Saving a stale copy of an item keeps the live table and its live stock", run = function(T)
    Prepare(T)
    local item = T:Item("stale_copy", { price = 10, stock = 5 })
    local stale = table.Copy(item)
    stale.name = "QA stale rename"
    local bot = T:Bot("Racer")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)
    T:Await(function(done) KrakensStore.Items.Save(stale, done) end)

    local live = KrakensStore.Items.Get(item.id)
    T:Check("the cached table is still the one in-flight purchases hold", live == item)
    T:Check("the stale copy did not restore the stock", live.stock == 4, live.stock)
    T:Check("the edit from the copy reached the live table", live.name == "QA stale rename", live.name)
end })

QA.Scenario("admin_item_messages_resolve", { system = "admin", title = "Admin give and take report translated messages", run = function(T)
    Prepare(T)
    local item = T:Item("messaged", { price = 10 })
    local bot = T:Bot("Messaged")
    local actions = KrakensStore._NetHelpers.AdminActions
    for _, action in ipairs({ "give_item", "take_item" }) do
        local response = { action = action, success = false }
        actions[action](NULL, { targetSteamId = bot:SteamID64(), itemId = item.id, quantity = 1 }, response)
        T:WaitFor(function() return response.success == true end, 3)
        T:Check(action .. " succeeds", response.success == true, response.message)
        T:Check(action .. " message has no missing-key marker", isstring(response.message) and not string.find(response.message, "[", 1, true), response.message)
    end
end })

QA.Scenario("option_use_is_logged", { system = "inventory", title = "Every option run through the removable-option path writes one use_item log", run = function(T)
    Prepare(T)
    T:Setting("CommandAllowlist", { say = true })
    local item = T:Item("logged_use", { price = 10, type = "runconsolecommand", data = { command = "say qa" } })
    local bot = T:Bot("Logger")
    T:SetMoney(bot, 1000)
    T:Await(function(done) SInv.PurchaseItem(bot, item.id, 1, done) end)

    local realCommand = game.ConsoleCommand
    local logged = {}
    T:Undo(function()
        game.ConsoleCommand = realCommand
        hook.Remove("KrakensStore_PostDataLog", "KSQA_UseLog")
    end)
    game.ConsoleCommand = function() end
    hook.Add("KrakensStore_PostDataLog", "KSQA_UseLog", function(logType, _, data)
        if logType == "use_item" then logged[#logged + 1] = data end
    end)

    local H = KrakensStore._NetHelpers
    local invItem, invSteamId, itemTable, option = H.LookupVerifiedOption(bot, item.id, "use", false, function() end)
    if not T:Check("the use option resolves", option ~= nil) then return end
    local finished = false
    H.RunRemovableOption(bot, { invSteamId = invSteamId, itemId = item.id, optionId = "use", option = option, itemTable = itemTable, invItem = invItem }, function() finished = true end)
    T:WaitFor(function() return finished end, 3)
    game.ConsoleCommand = realCommand

    T:Check("the use is logged once", #logged == 1 and logged[1].itemId == item.id, #logged)
    T:Check("the consumed unit is recorded", logged[1] ~= nil and logged[1].consumed == true)
end })

QA.Scenario("settings_list_rejects_invalid", { system = "config", title = "List settings drop entries their validator rejects instead of keeping them as plain strings", run = function(T)
    local clean = KrakensStore.Config.SanitizeSetting("purchasableRanks", { "vip", "vip gold", "VIP+" })
    T:Check("valid entries survive lowercased", clean and clean[1] == "vip" and clean[2] == "vip+", table.concat(clean or {}, ","))
    T:Check("an entry with whitespace is dropped", clean and #clean == 2, clean and #clean)
end })

QA.Scenario("refund_inherits_global", { system = "economy", title = "Items without an explicit refund percent or window inherit the global settings", run = function(T)
    local refund = KrakensStore.Config.General.Refund
    local pct, hours = refund.Percentage, refund.WindowHours
    T:Undo(function() refund.Percentage, refund.WindowHours = pct, hours end)
    refund.Percentage, refund.WindowHours = 40, 12
    local inherit = T:Item("refund_inherit", { price = 100, refundPercent = -1, refundWindowHours = -1 })
    local explicit = T:Item("refund_explicit", { price = 100, refundPercent = 10, refundWindowHours = 0 })
    T:Check("inherited percent follows the global", KrakensStore:GetItemRefund(NULL, inherit.id, 1) == 40, KrakensStore:GetItemRefund(NULL, inherit.id, 1))
    T:Check("inherited window follows the global", KrakensStore:GetRefundWindowHours(inherit) == 12, KrakensStore:GetRefundWindowHours(inherit))
    T:Check("explicit percent overrides the global", KrakensStore:GetItemRefund(NULL, explicit.id, 1) == 10, KrakensStore:GetItemRefund(NULL, explicit.id, 1))
    T:Check("explicit zero window disables the limit", KrakensStore:GetRefundWindowHours(explicit) == 0, KrakensStore:GetRefundWindowHours(explicit))
end })

QA.Scenario("category_sort_deterministic", { system = "config", title = "Categories with the same order sort by name and never reorder between calls", run = function(T)
    T:Category("sort_b", { name = "Beta", order = 0 })
    T:Category("sort_a", { name = "Alpha", order = 0 })
    local first = KrakensStore.Categories.GetSorted()
    local pos = {}
    for i, cat in ipairs(first) do pos[cat.id] = i end
    T:Check("equal orders fall back to the name", pos["qa_sort_a"] ~= nil and pos["qa_sort_b"] ~= nil and pos["qa_sort_a"] < pos["qa_sort_b"])
    local stable = true
    for _ = 1, 5 do
        for i, cat in ipairs(KrakensStore.Categories.GetSorted()) do
            if first[i].id ~= cat.id then stable = false end
        end
    end
    T:Check("the order is identical across calls", stable)
end })

local QA_SID = "76561198000000042"

local function Json(tbl) return "'" .. KrakensStore.DB.Escape(util.TableToJSON(tbl)) .. "'" end

local function LegacySchema(mysql)
    local ID, SID, TEXT, INT = unpack(mysql and { "VARCHAR(128)", "VARCHAR(32)", "LONGTEXT", "BIGINT" } or { "TEXT", "TEXT", "TEXT", "INTEGER" })
    local KEY = mysql and "`key`" or "key"
    local AUTO = mysql and "BIGINT AUTO_INCREMENT PRIMARY KEY" or "INTEGER PRIMARY KEY AUTOINCREMENT"
    local ENGINE = mysql and " ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" or ""
    local function Blob(name) return string.format("CREATE TABLE %s (id %s PRIMARY KEY, data %s NOT NULL, modified %s DEFAULT 0)%s", name, ID, TEXT, INT, ENGINE) end
    return {
        Blob("krakens_store_items"), Blob("krakens_store_categories"), Blob("krakens_store_npcs"),
        string.format("CREATE TABLE krakens_store_inventory (steamid %s NOT NULL, item_id %s NOT NULL, quantity %s NOT NULL DEFAULT 1, equipped %s NOT NULL DEFAULT 0, data %s NOT NULL, purchased %s DEFAULT 0, expires %s, PRIMARY KEY (steamid, item_id))%s", SID, ID, INT, INT, TEXT, INT, INT, ENGINE),
        string.format("CREATE TABLE krakens_store_players (steamid %s PRIMARY KEY, data %s NOT NULL, first_seen %s DEFAULT 0, last_seen %s DEFAULT 0, total_spent %s DEFAULT 0, total_earned %s DEFAULT 0, items_purchased %s DEFAULT 0, items_sold %s DEFAULT 0)%s", SID, TEXT, INT, INT, INT, INT, INT, INT, ENGINE),
        string.format("CREATE TABLE krakens_store_config (%s %s PRIMARY KEY, value %s NOT NULL, modified %s DEFAULT 0)%s", KEY, ID, TEXT, INT, ENGINE),
        string.format("CREATE TABLE krakens_store_meta (%s %s PRIMARY KEY, value %s NOT NULL)%s", KEY, ID, TEXT, ENGINE),
        string.format("CREATE TABLE krakens_store_logs (id %s, type %s NOT NULL, steamid %s, item_id %s, item_name %s, quantity %s DEFAULT 0, amount %s DEFAULT 0, data %s, timestamp %s DEFAULT 0)%s", AUTO, ID, SID, ID, ID, INT, INT, TEXT, INT, ENGINE),
    }
end

local function LegacyItemRows()
    return {
        "INSERT INTO krakens_store_items (id, data, modified) VALUES ('qa_legacy_model', " .. Json({ id = "qa_legacy_model", name = "Legacy Model", type = "permmodel", category = "qa_legacy_cat", price = 100, refundPercent = 0.5, data = { modelPath = "models/humans/group01/male_01.mdl" } }) .. ", 1)",
        "INSERT INTO krakens_store_items (id, data, modified) VALUES ('qa_legacy_weapon', " .. Json({ id = "qa_legacy_weapon", name = "Legacy Weapon", type = "weapon", category = "qa_legacy_cat", price = 200, itemData = { weapon = "weapon_pistol" } }) .. ", 1)",
        "INSERT INTO krakens_store_items (id, data, modified) VALUES ('qa_legacy_booster', " .. Json({ id = "qa_legacy_booster", name = "Legacy Booster", type = "permbooster", category = "qa_legacy_cat", price = 300, data = { action = 2, value = 20 } }) .. ", 1)",
    }
end

local function LegacyRows()
    local k = KrakensStore.DB.KeyCol()
    local rows = LegacyItemRows()
    table.Add(rows, {
        "INSERT INTO krakens_store_categories (id, data, modified) VALUES ('qa_legacy_cat', " .. Json({ id = "qa_legacy_cat", name = "Legacy", order = 1 }) .. ", 1)",
        "INSERT INTO krakens_store_categories (id, data, modified) VALUES ('misc', " .. Json({ id = "misc", name = "Misc", order = 99 }) .. ", 1)",
        "INSERT INTO krakens_store_npcs (id, data, modified) VALUES ('qa_legacy_npc', " .. Json({ id = "qa_legacy_npc", name = "Legacy NPC", model = "models/humans/group01/male_01.mdl", categories = {}, items = {} }) .. ", 1)",
        string.format("INSERT INTO krakens_store_inventory (steamid, item_id, quantity, equipped, data, purchased, expires) VALUES ('%s', 'qa_legacy_model', 1, 1, '{}', 1000, NULL)", QA_SID),
        string.format("INSERT INTO krakens_store_inventory (steamid, item_id, quantity, equipped, data, purchased, expires) VALUES ('%s', 'qa_legacy_weapon', 2, 0, '{}', 1000, 0)", QA_SID),
        string.format("INSERT INTO krakens_store_players (steamid, data, first_seen, last_seen, total_spent) VALUES ('%s', '{}', 1000, 2000, 500)", QA_SID),
        string.format("INSERT INTO krakens_store_config (%s, value, modified) VALUES ('general_settings', %s, 1)", k, Json({ storeName = "Legacy Shop", cvar_arc9_free_atts = true, cvars = {} })),
        string.format("INSERT INTO krakens_store_config (%s, value, modified) VALUES ('pending_recoveries', %s, 1)", k, Json({ [QA_SID] = { { amount = 150, type = "refund", reason = "qa", timestamp = 1000 } } })),
    })
    return rows
end

local function CurrentSchema()
    local DB = KrakensStore.DB
    return DB.Schema[DB.GetType() == "mysql" and "MySQL" or "SQLite"]
end

local function Run(statements)
    for _, statement in ipairs(statements) do KrakensStore.DB.Query(statement) end
end

local function SchemaVersionRow(T)
    local DB = KrakensStore.DB
    local _, res = T:Await(function(done)
        DB.Query("SELECT value FROM krakens_store_meta WHERE " .. DB.KeyCol() .. "='schema_version' AND server_id='" .. DB.GetEscapedServerId() .. "'",
            function(rows) done(tonumber(rows and rows[1] and rows[1].value)) end)
    end)
    return res[1]
end

function Context:SwapDatabase(build)
    local DB = KrakensStore.DB
    local mysql = DB.GetType() == "mysql"
    local _, leftovers = self:Await(function(done)
        DB.Query(mysql and "SHOW TABLES LIKE 'krakens_store%qa_saved'" or "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'krakens_store%qa_saved'",
            function(rows) done(rows and #rows or 0) end)
    end)
    if (leftovers[1] or 0) > 0 then error("stale *_qa_saved tables remain from an interrupted run; restore or drop them before running database scenarios") end
    Data.FlushAllPlayerData()
    local swapped = {}
    self:Undo(function()
        for i = #swapped, 1, -1 do
            DB.Query("DROP TABLE IF EXISTS " .. swapped[i])
            DB.Query(string.format("ALTER TABLE %s_qa_saved RENAME TO %s", swapped[i], swapped[i]))
        end
        timer.Remove("KrakensStore_Recovery")
        KrakensStore.Boot(true)
        self:WaitFor(function() return KrakensStore.Lifecycle.Phase == "READY" end, 60)
    end)
    for _, tbl in ipairs(DB.Tables) do
        if not mysql then
            for _, idx in ipairs(tbl.indexes or {}) do DB.Query("DROP INDEX IF EXISTS " .. idx[1]) end
        end
        local finished, renamed = self:Await(function(done)
            DB.Query(string.format("ALTER TABLE %s RENAME TO %s_qa_saved", tbl.name, tbl.name), function(_, err) done(err == nil) end)
        end)
        if not (finished and renamed[1]) then error("could not set aside " .. tbl.name .. " for the scenario") end
        swapped[#swapped + 1] = tbl.name
    end
    if build then build(mysql) end
    KrakensStore.Boot(true)
    self:WaitFor(function() local p = KrakensStore.Lifecycle.Phase return p == "READY" or p == "FAILED" end, 60)
    return KrakensStore.Lifecycle.Phase, mysql
end

QA.Scenario("init_fresh_database", { system = "initialization", title = "A fresh database creates the current schema and reaches READY with empty data", run = function(T)
    local LC = KrakensStore.Lifecycle
    local phase = T:SwapDatabase()
    T:Check("fresh database reaches READY", phase == "READY", LC.Describe())
    T:Check("migrations are reported complete", LC.Migrations == "COMPLETE", LC.Migrations)
    T:Check("schema version is current", SchemaVersionRow(T) == KrakensStore.DB.SchemaVersion, tostring(SchemaVersionRow(T)))
    T:Check("default categories are seeded once", table.Count(KrakensStore.Categories.Cache) == 5, table.Count(KrakensStore.Categories.Cache))
    T:Check("zero items is a loaded state, not a failure", Data.IsLoaded() and table.Count(KrakensStore.Items.Cache) == 0)
end })

QA.Scenario("init_previous_version", { system = "initialization", title = "A database from the previous schema version migrates one step and keeps its rows", run = function(T)
    local LC, DB = KrakensStore.Lifecycle, KrakensStore.DB
    local phase = T:SwapDatabase(function()
        Run(CurrentSchema())
        Run(LegacyItemRows())
        DB.Query(string.format("UPDATE krakens_store_items SET server_id='%s'", DB.GetEscapedServerId()))
        DB.Query(string.format("INSERT INTO krakens_store_inventory (server_id, steamid, item_id, quantity, equipped, data, purchased, expires) VALUES ('%s', '%s', 'qa_legacy_model', 1, 0, '{}', 1000, 0)", DB.GetEscapedServerId(), QA_SID))
        DB.SetMeta("schema_version", DB.SchemaVersion - 1)
    end)
    T:Check("previous version reaches READY", phase == "READY", LC.Describe())
    T:Check("schema version advanced to current", SchemaVersionRow(T) == DB.SchemaVersion, tostring(SchemaVersionRow(T)))
    T:Check("all rows survived the step", table.Count(KrakensStore.Items.Cache) == 3, table.Count(KrakensStore.Items.Cache))
    local weapon = KrakensStore.Items.Get("qa_legacy_weapon")
    T:Check("legacy itemData blobs are folded into data", weapon and weapon.itemData == nil and weapon.data.weaponClass == "weapon_pistol", weapon and util.TableToJSON(weapon.data or {}))
    local _, res = T:Await(function(done) Data.GetPlayerInventory(QA_SID, done) end)
    T:Check("zero expiry rows became permanent", res[1] and res[1].qa_legacy_model and res[1].qa_legacy_model.expires == -1, res[1] and res[1].qa_legacy_model and res[1].qa_legacy_model.expires)
end })

QA.Scenario("init_legacy_generations", { system = "initialization", title = "A pre-server_id database with every legacy representation migrates through the whole chain without losing data", run = function(T)
    local LC, DB = KrakensStore.Lifecycle, KrakensStore.DB
    local backupsBefore = #file.Find("krakens_store/backups/*.json", "DATA")
    local phase, mysql = T:SwapDatabase(function(isMysql)
        Run(LegacySchema(isMysql))
        Run(LegacyRows())
    end)
    T:Check("legacy database reaches READY", phase == "READY", LC.Describe())
    T:Check("schema version is current", SchemaVersionRow(T) == DB.SchemaVersion, tostring(SchemaVersionRow(T)))
    T:Check("a backup was written before migrating", #file.Find("krakens_store/backups/*.json", "DATA") > backupsBefore)

    local model, weapon, booster = KrakensStore.Items.Get("qa_legacy_model"), KrakensStore.Items.Get("qa_legacy_weapon"), KrakensStore.Items.Get("qa_legacy_booster")
    T:Check("every legacy item survived", model and weapon and booster and table.Count(KrakensStore.Items.Cache) == 3, table.Count(KrakensStore.Items.Cache))
    T:Check("fractional refund percent became a whole percent", model and model.refundPercent == 50, model and model.refundPercent)
    T:Check("data aliases were rewritten to canonical keys", model and model.data.model == "models/humans/group01/male_01.mdl" and model.data.modelPath == nil, model and util.TableToJSON(model.data))
    T:Check("itemData blobs were folded and weapon aliases renamed", weapon and weapon.itemData == nil and weapon.data.weaponClass == "weapon_pistol" and weapon.data.weapon == nil, weapon and util.TableToJSON(weapon.data or {}))
    T:Check("numeric booster actions became buff ids", booster and booster.data.action == "speed" and booster.data.percents == 20 and booster.data.value == nil, booster and util.TableToJSON(booster.data))
    T:Check("legacy categories survived without default seeding", table.Count(KrakensStore.Categories.Cache) == 2, table.Count(KrakensStore.Categories.Cache))
    T:Check("legacy NPC survived", KrakensStore.NPCs.Get("qa_legacy_npc") ~= nil)

    local _, invRes = T:Await(function(done) Data.GetPlayerInventory(QA_SID, done) end)
    local inv = invRes[1] or {}
    T:Check("inventory rows survived with their quantities", inv.qa_legacy_model and inv.qa_legacy_weapon and inv.qa_legacy_weapon.quantity == 2, table.Count(inv))
    T:Check("NULL and zero expiries became permanent", inv.qa_legacy_model and inv.qa_legacy_model.expires == -1 and inv.qa_legacy_weapon and inv.qa_legacy_weapon.expires == -1)
    local _, pdRes = T:Await(function(done) Data.GetPlayerData(QA_SID, done) end)
    T:Check("player record survived with its first-seen time and stats", pdRes[1] and pdRes[1].firstSeen == 1000 and pdRes[1].stats.totalSpent == 500, pdRes[1] and pdRes[1].firstSeen)
    T:Check("legacy general_settings were merged into the settings blob", KrakensStore.Config.General.StoreName == "Legacy Shop", KrakensStore.Config.General.StoreName)
    local _, cfgRes = T:Await(function(done) Data.GetConfig("general_settings", function(_, _, found) done(found) end) end)
    T:Check("the legacy settings blob was removed after the merge", cfgRes[1] == false)
    local _, settingsRes = T:Await(function(done) Data.GetConfig("settings", function(v) done(v) end) end)
    T:Check("cvar keys never live in the settings blob", settingsRes[1] and settingsRes[1].cvar_arc9_free_atts == nil)
    local _, recRes = T:Await(function(done) DB.Query("SELECT amount FROM krakens_store_recoveries WHERE steamid='" .. QA_SID .. "'", function(rows) done(rows) end) end)
    T:Check("pending currency recoveries moved into their table", recRes[1] and #recRes[1] == 1 and tonumber(recRes[1][1].amount) == 150, recRes[1] and #recRes[1])
    local _, cols = T:Await(function(done) DB.ListColumns("krakens_store_inventory", done) end)
    T:Check("missing columns were added by the repair", cols[1] and cols[1].server_id == true)
    local _, owners = T:Await(function(done) DB.Query("SELECT DISTINCT server_id FROM krakens_store_items", function(rows) done(rows) end) end)
    T:Check("legacy rows were relabelled to this server's id", owners[1] and #owners[1] == 1 and owners[1][1].server_id == DB.GetServerId(), owners[1] and owners[1][1] and owners[1][1].server_id)
    if not mysql then
        local _, ddl = T:Await(function(done) DB.Query("SELECT sql FROM sqlite_master WHERE type='table' AND name='krakens_store_items'", function(rows) done(rows and rows[1] and rows[1].sql) end) end)
        T:Check("the primary key was rebuilt around server_id", ddl[1] and string.find(ddl[1], "PRIMARY KEY (server_id, id)", 1, true) ~= nil, ddl[1])
        local _, idx = T:Await(function(done) DB.Query("PRAGMA index_list(krakens_store_inventory)", function(rows) done(rows) end) end)
        local found = false
        for _, row in ipairs(idx[1] or {}) do if row.name == "ks_idx_inventory_steamid" then found = true end end
        T:Check("indexes were created on the legacy table", found)
    end
end })

QA.Scenario("init_partial_columns", { system = "initialization", title = "A database that claims a recent version but is missing columns is repaired instead of failing", run = function(T)
    local LC, DB = KrakensStore.Lifecycle, KrakensStore.DB
    local phase = T:SwapDatabase(function(isMysql)
        local current = CurrentSchema()
        local legacy = LegacySchema(isMysql)
        Run({ legacy[1], current[2], current[3], current[4], current[5], current[6], current[7], current[8], current[9] })
        Run(LegacyItemRows())
        DB.SetMeta("schema_version", DB.SchemaVersion - 1)
    end)
    T:Check("partially migrated database reaches READY", phase == "READY", LC.Describe())
    T:Check("the legacy-shaped items table kept its rows", table.Count(KrakensStore.Items.Cache) == 3, table.Count(KrakensStore.Items.Cache))
    local _, cols = T:Await(function(done) DB.ListColumns("krakens_store_items", done) end)
    T:Check("the missing server_id column was added", cols[1] and cols[1].server_id == true)
    T:Check("schema version is current", SchemaVersionRow(T) == DB.SchemaVersion, tostring(SchemaVersionRow(T)))
end })

QA.Scenario("init_interrupted_migration", { system = "initialization", title = "Current tables without a schema version replay the chain idempotently and keep every row", run = function(T)
    local LC, DB = KrakensStore.Lifecycle, KrakensStore.DB
    local phase = T:SwapDatabase(function()
        Run(CurrentSchema())
        Run(LegacyItemRows())
        DB.Query(string.format("UPDATE krakens_store_items SET server_id='%s'", DB.GetEscapedServerId()))
    end)
    T:Check("interrupted migration reaches READY", phase == "READY", LC.Describe())
    T:Check("schema version is current", SchemaVersionRow(T) == DB.SchemaVersion, tostring(SchemaVersionRow(T)))
    T:Check("rows survived the replay", table.Count(KrakensStore.Items.Cache) == 3, table.Count(KrakensStore.Items.Cache))
    local model = KrakensStore.Items.Get("qa_legacy_model")
    T:Check("a fractional percent still lands on 50, never 100", model and model.refundPercent == 50, model and model.refundPercent)
end })

QA.Scenario("init_empty_legacy_schema", { system = "initialization", title = "An empty legacy schema is a valid empty store, not a failed load", run = function(T)
    local LC = KrakensStore.Lifecycle
    local phase = T:SwapDatabase(function(isMysql) Run(LegacySchema(isMysql)) end)
    T:Check("empty legacy schema reaches READY", phase == "READY", LC.Describe())
    T:Check("migrations completed", LC.Migrations == "COMPLETE", LC.Migrations)
    T:Check("items are empty and loaded", Data.IsLoaded() and table.Count(KrakensStore.Items.Cache) == 0)
    T:Check("default categories are seeded", table.Count(KrakensStore.Categories.Cache) == 5, table.Count(KrakensStore.Categories.Cache))
end })

QA.Scenario("init_extra_legacy_columns", { system = "initialization", title = "Unknown legacy columns and tables are ignored, never a reason to fail", run = function(T)
    local LC, DB = KrakensStore.Lifecycle, KrakensStore.DB
    T:Undo(function() DB.Query("DROP TABLE IF EXISTS krakens_store_old_shop") end)
    local phase = T:SwapDatabase(function(isMysql)
        Run(LegacySchema(isMysql))
        DB.Query("ALTER TABLE krakens_store_items ADD COLUMN legacy_note " .. (isMysql and "VARCHAR(64)" or "TEXT"))
        DB.Query("CREATE TABLE krakens_store_old_shop (id " .. (isMysql and "VARCHAR(64)" or "TEXT") .. ")")
        Run(LegacyRows())
    end)
    T:Check("database with extra legacy columns reaches READY", phase == "READY", LC.Describe())
    T:Check("rows survived with the extra column in place", table.Count(KrakensStore.Items.Cache) == 3, table.Count(KrakensStore.Items.Cache))
    local _, cols = T:Await(function(done) DB.ListColumns("krakens_store_items", done) end)
    T:Check("the unknown column was preserved, not dropped", cols[1] and cols[1].legacy_note == true)
end })

QA.Scenario("init_migration_failure_keeps_data", { system = "initialization", title = "A failing migration ends in FAILED with its cause, never touches the caches or the version, and recovers once fixed", run = function(T)
    local LC, DB = KrakensStore.Lifecycle, KrakensStore.DB
    local probe = T:Item("migration_probe", { price = 10 })
    local target = DB.SchemaVersion
    local real = DB.Migrations[target]
    T:Undo(function() DB.Migrations[target] = real end)
    DB.Migrations[target] = function(done) done(false, "QA induced migration failure") end

    local phase = T:SwapDatabase(function()
        Run(CurrentSchema())
        Run(LegacyItemRows())
        DB.Query(string.format("UPDATE krakens_store_items SET server_id='%s'", DB.GetEscapedServerId()))
        DB.SetMeta("schema_version", target - 1)
    end)
    T:Check("the store ends in FAILED, not LOADING and not READY", phase == "FAILED", LC.Describe())
    T:Check("the cause is reported", string.find(LC.Failure or "", "QA induced", 1, true) ~= nil, tostring(LC.Failure))
    T:Check("migrations are reported as failed", LC.Migrations == "FAILED", LC.Migrations)
    T:Check("the in-memory catalog was never replaced", KrakensStore.Items.Get(probe.id) ~= nil)
    T:Check("the schema version was not advanced", SchemaVersionRow(T) == target - 1, tostring(SchemaVersionRow(T)))
    T:Check("a retry is scheduled and visible in the status line", timer.Exists("KrakensStore_Recovery") and string.find(LC.Describe(), "Retry:", 1, true) ~= nil, LC.Describe())
    T:Check("administrators get the retry detail", string.find(LC.FailureDetail(), "attempt", 1, true) ~= nil, LC.FailureDetail())

    DB.Migrations[target] = real
    timer.Remove("KrakensStore_Recovery")
    KrakensStore.Boot(true)
    T:WaitFor(function() return LC.Phase == "READY" end, 60)
    T:Check("the store recovers once the migration works", LC.Phase == "READY", LC.Describe())
    T:Check("the rows are loaded after recovery", table.Count(KrakensStore.Items.Cache) == 3, table.Count(KrakensStore.Items.Cache))
    T:Check("schema version is current after recovery", SchemaVersionRow(T) == target, tostring(SchemaVersionRow(T)))
end })

QA.Scenario("init_mysql_without_module_fails_clearly", { system = "initialization", title = "A server configured for MySQL without mysqloo fails with a cause instead of silently switching to SQLite", run = function(T)
    local LC, DB = KrakensStore.Lifecycle, KrakensStore.DB
    local cfg = KrakensStore.ServerConfig.Database
    local realType, realModule = cfg.Type, _G.mysqloo
    T:Undo(function()
        cfg.Type, _G.mysqloo = realType, realModule
        timer.Remove("KrakensStore_Recovery")
        KrakensStore.Boot(true)
        T:WaitFor(function() return LC.Phase == "READY" end, 60)
    end)
    cfg.Type, _G.mysqloo = "mysql", nil
    KrakensStore.Boot(true)
    T:WaitFor(function() return LC.Phase == "FAILED" or LC.Phase == "READY" end, 10)
    T:Check("the store fails instead of falling back to SQLite", LC.Phase == "FAILED" and DB.GetType() ~= "sqlite", LC.Phase .. "/" .. DB.GetType())
    T:Check("the cause names the missing module", string.find(LC.Failure or "", "mysqloo", 1, true) ~= nil, tostring(LC.Failure))
    T:Check("a bounded retry is scheduled and reported", timer.Exists("KrakensStore_Recovery") and LC.RetryInfo() ~= nil, LC.Describe())
end })

QA.Scenario("init_recovery_retries_automatically", { system = "initialization", title = "After a failed load the scheduled retry brings the store back without manual intervention", run = function(T)
    local LC = KrakensStore.Lifecycle
    local realGetAll = Data.GetAllItems
    T:Undo(function()
        Data.GetAllItems = realGetAll
        timer.Remove("KrakensStore_Recovery")
        if LC.Phase ~= "READY" then
            KrakensStore.Boot(true)
            T:WaitFor(function() return LC.Phase == "READY" end, 60)
        end
    end)
    Data.GetAllItems = function(cb) KrakensStore.Fire(cb, nil, "QA induced item read failure") end
    Data.LoadAllData(true)
    T:WaitFor(function() return LC.Phase == "FAILED" end, 10)
    T:Check("the failure schedules the first retry quickly", timer.Exists("KrakensStore_Recovery") and timer.TimeLeft("KrakensStore_Recovery") <= 5, tostring(timer.TimeLeft("KrakensStore_Recovery")))
    Data.GetAllItems = realGetAll
    T:WaitFor(function() return LC.Phase == "READY" end, 20)
    T:Check("the automatic retry reached READY", LC.Phase == "READY", LC.Describe())
    T:Check("the retry counter is reset on success", LC.RetryInfo() == nil)
end })
