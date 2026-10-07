local INV = GRNInventory
local C = INV.Config

util.AddNetworkString("GRNINV_RequestSync")
util.AddNetworkString("GRNINV_Sync")
util.AddNetworkString("GRNINV_Action")
util.AddNetworkString("GRNINV_Notice")
util.AddNetworkString("GRNINV_ClientClosed")
util.AddNetworkString("GRNINV_BackpackState")

INV.PlayerStates = INV.PlayerStates or {}

-- Changes on every server start (not on a Lua refresh). A player whose saved
-- token differs joined after a restart / map change and loses the weapons.
INV.ServerSession = INV.ServerSession or (tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999)))
local SESSION_KEY = "grn_inventory_session_v1"
local CHARACTER_KEY = "grn_inventory_character_v1"

local function respawnConfig()
    return istable(C.Respawn) and C.Respawn or {}
end

local function isFiniteNumber(n)
    return isnumber(n) and n == n and n ~= math.huge and n ~= -math.huge
end

local function notify(ply, text)
    if not IsValid(ply) then return end
    net.Start("GRNINV_Notice")
    net.WriteString(tostring(text or "Inventar aktualisiert."))
    net.Send(ply)
end

-- -------------------------------------------------------------------------
-- First-person backpack animation controller
-- -------------------------------------------------------------------------
local function backpackSettings()
    return istable(C.BackpackAnimation) and C.BackpackAnimation or {}
end

local function backpackClass()
    local cfg = backpackSettings()
    return tostring(cfg.WeaponClass or "weapon_grn_inventory_backpack")
end

local function canAnimateBackpack(ply)
    local cfg = backpackSettings()
    if cfg.Enabled == false then return false end
    if not IsValid(ply) then return false end
    if cfg.AliveOnly ~= false and not ply:Alive() then return false end
    return true
end

local function chooseRestoreWeapon(ply)
    if not IsValid(ply) then return nil end
    local bpClass = backpackClass()

    local desired = tostring(ply.GRNInventoryBackpackDesiredWeapon or "")
    if desired ~= "" and desired ~= bpClass and ply:HasWeapon(desired) then
        return desired
    end

    local previous = tostring(ply.GRNInventoryBackpackPrevWeapon or "")
    if previous ~= "" and previous ~= bpClass and ply:HasWeapon(previous) then
        return previous
    end

    for _, wep in ipairs(ply:GetWeapons()) do
        if IsValid(wep) and wep:GetClass() ~= bpClass then
            return wep:GetClass()
        end
    end

    return nil
end

local function finishBackpackAnimation(ply, token)
    if not IsValid(ply) then return end
    if token and ply.GRNInventoryBackpackToken ~= token then return end

    local bpClass = backpackClass()
    local restore = chooseRestoreWeapon(ply)

    -- Select the real gameplay weapon before stripping the temporary viewmodel.
    if restore then
        ply:SelectWeapon(restore)
    end

    if ply:HasWeapon(bpClass) then
        ply:StripWeapon(bpClass)
    end

    ply.GRNInventoryBackpackActive = false
    ply.GRNInventoryBackpackClosing = false
    ply.GRNInventoryBackpackPrevWeapon = nil
    ply.GRNInventoryBackpackDesiredWeapon = nil
end

function INV.StartBackpackAnimation(ply)
    if not canAnimateBackpack(ply) then return false end

    local bpClass = backpackClass()
    local active = ply:GetActiveWeapon()
    if IsValid(active) and active:GetClass() ~= bpClass then
        ply.GRNInventoryBackpackPrevWeapon = active:GetClass()
    end

    ply.GRNInventoryBackpackDesiredWeapon = nil
    ply.GRNInventoryBackpackToken = (ply.GRNInventoryBackpackToken or 0) + 1
    ply.GRNInventoryBackpackClosing = false
    ply.GRNInventoryBackpackActive = true

    local bp = ply:GetWeapon(bpClass)
    if not IsValid(bp) then
        bp = ply:Give(bpClass, true)
    end

    if not IsValid(bp) then
        ply.GRNInventoryBackpackActive = false
        return false
    end

    -- SelectWeapon invokes Deploy(), which plays ACT_VM_PULLBACK on the bundled
    -- S.T.A.L.K.E.R. 2 backpack viewmodel. If the player reopens while the
    -- closing animation is still running, redeploy the already-active SWEP.
    active = ply:GetActiveWeapon()
    if IsValid(active) and active:GetClass() == bpClass and isfunction(bp.Deploy) then
        bp:Deploy()
    else
        ply:SelectWeapon(bpClass)
    end
    return true
end

function INV.StopBackpackAnimation(ply, immediate)
    if not IsValid(ply) then return end

    local bpClass = backpackClass()
    local bp = ply:GetWeapon(bpClass)
    if not IsValid(bp) and not ply.GRNInventoryBackpackActive then
        return
    end

    -- A close request is sent both by the dedicated animation message and by
    -- GRNINV_ClientClosed as a cleanup fallback. Ignore the duplicate without
    -- invalidating the timer created by the first request.
    if ply.GRNInventoryBackpackClosing and not immediate then return end

    ply.GRNInventoryBackpackToken = (ply.GRNInventoryBackpackToken or 0) + 1
    local token = ply.GRNInventoryBackpackToken

    if immediate or not ply:Alive() then
        finishBackpackAnimation(ply, token)
        return
    end

    ply.GRNInventoryBackpackClosing = true

    local cfg = backpackSettings()
    local duration = math.max(0.05, tonumber(cfg.CloseFallbackDuration) or 1.10)
    local active = ply:GetActiveWeapon()

    -- The close animation is only meaningful while the backpack viewmodel is
    -- actually active. If another addon forcibly changed weapon, clean up
    -- immediately instead of leaving the temporary SWEP behind.
    if IsValid(active) and active:GetClass() == bpClass and isfunction(active.GRNInventoryBeginClose) then
        local reported = tonumber(active:GRNInventoryBeginClose())
        if reported and reported > 0.05 and reported < 10 then
            duration = reported
        end
    else
        finishBackpackAnimation(ply, token)
        return
    end

    timer.Simple(duration, function()
        finishBackpackAnimation(ply, token)
    end)
end

function INV.GetDarkRPMoney(ply)
    if not IsValid(ply) then return 0 end
    if ply.getDarkRPVar then
        local money = tonumber(ply:getDarkRPVar("money"))
        if money then return math.max(0, math.floor(money)) end
    end
    return math.max(0, ply:GetNWInt("GRNInventoryFallbackMoney", 0))
end

function INV.AddDarkRPMoney(ply, amount)
    if not IsValid(ply) then return false end
    amount = math.floor(tonumber(amount) or 0)
    if amount == 0 then return true end

    if ply.addMoney then
        ply:addMoney(amount)
        return true
    end

    local now = INV.GetDarkRPMoney(ply)
    ply:SetNWInt("GRNInventoryFallbackMoney", math.max(0, now + amount))
    return true
end

function INV.FormatMoney(ply)
    local amount = INV.GetDarkRPMoney(ply)
    if DarkRP and DarkRP.formatMoney then
        local ok, formatted = pcall(DarkRP.formatMoney, amount)
        if ok and formatted then return formatted end
    end
    return INV.FormatNumber(amount) .. (C.CurrencySuffix or " CR")
end

local function blankState()
    return {
        version = 2,
        items = {},
        equipment = { primary = nil, secondary = nil, specialized = nil, utility = nil },
        armor = {},
        moneySlot = INV.ClampSlot(C.MoneyItem.DefaultSlot) or 1
    }
end

local function itemFootprint(item)
    if not item then return nil end
    return INV.GetFootprintSlots(item.slot, INV.GetItemDefinition(item.id))
end

local function buildOccupancy(state, ignoreUID, ignoreMoney)
    local occupied = {}
    if not state then return occupied end

    if not ignoreMoney and state.moneySlot then
        local moneyCells = INV.GetFootprintSlots(state.moneySlot, C.MoneyItem)
        if moneyCells then
            for _, slot in ipairs(moneyCells) do occupied[slot] = "__money" end
        end
    end

    for _, item in ipairs(state.items or {}) do
        if item.uid ~= ignoreUID then
            local cells = itemFootprint(item)
            if cells then
                for _, slot in ipairs(cells) do occupied[slot] = item.uid end
            end
        end
    end
    return occupied
end

local function canPlaceAt(state, def, slot, ignoreUID, ignoreMoney)
    slot = INV.ClampSlot(slot)
    if not slot or not def then return false end
    local cells = INV.GetFootprintSlots(slot, def)
    if not cells then return false end

    local occupied = buildOccupancy(state, ignoreUID, ignoreMoney)
    for _, cell in ipairs(cells) do
        if occupied[cell] then return false end
    end
    return true
end

local function findFreeSlotForDefinition(state, def, preferred, ignoreUID, ignoreMoney)
    preferred = INV.ClampSlot(preferred)
    if preferred and canPlaceAt(state, def, preferred, ignoreUID, ignoreMoney) then
        return preferred
    end

    for slot = 1, INV.GetInventorySlotCount() do
        if canPlaceAt(state, def, slot, ignoreUID, ignoreMoney) then return slot end
    end
end

local function normalizeState(raw)
    local source = istable(raw) and raw or blankState()
    local state = blankState()
    state.version = 2
    state.equipment = istable(source.equipment) and source.equipment or state.equipment
    state.equipment.primary = isstring(state.equipment.primary) and state.equipment.primary or nil
    state.equipment.secondary = isstring(state.equipment.secondary) and state.equipment.secondary or nil
    state.equipment.specialized = isstring(state.equipment.specialized) and state.equipment.specialized or nil
    state.equipment.utility = isstring(state.equipment.utility) and state.equipment.utility or nil

    -- Place the virtual DarkRP money item first. If the saved position no longer fits,
    -- it falls back to the configured position and then to the first free cell.
    state.moneySlot = INV.ClampSlot(source.moneySlot) or INV.ClampSlot(C.MoneyItem.DefaultSlot) or 1
    if not INV.GetFootprintSlots(state.moneySlot, C.MoneyItem) then
        state.moneySlot = INV.ClampSlot(C.MoneyItem.DefaultSlot) or 1
    end

    for _, rawItem in ipairs(istable(source.items) and source.items or {}) do
        if istable(rawItem) then
            local def = INV.GetItemDefinition(rawItem.id)
            local qty = math.floor(tonumber(rawItem.qty) or 0)
            if def and not INV.IsMoneyID(rawItem.id) and qty > 0 then
                local stack = math.max(1, math.floor(tonumber(def.Stack) or 1))
                local item = {
                    uid = isstring(rawItem.uid) and rawItem.uid or INV.NewUID(),
                    id = rawItem.id,
                    qty = math.min(qty, stack),
                    slot = INV.ClampSlot(rawItem.slot),
                    ammoGranted = rawItem.ammoGranted == true
                }

                if not item.slot or not canPlaceAt(state, def, item.slot, item.uid, false) then
                    item.slot = findFreeSlotForDefinition(state, def, nil, item.uid, false)
                end

                if item.slot then state.items[#state.items + 1] = item end
            end
        end
    end

    -- If money overlaps an item after migrating an old save, move the money token.
    if not canPlaceAt(state, C.MoneyItem, state.moneySlot, nil, true) then
        state.moneySlot = findFreeSlotForDefinition(state, C.MoneyItem, C.MoneyItem.DefaultSlot, nil, true) or 1
    end

    local validUID = {}
    local itemByUID = {}
    for _, item in ipairs(state.items) do
        validUID[item.uid] = true
        itemByUID[item.uid] = item
    end
    for slotName in pairs(INV.ValidEquipSlots) do
        local uid = state.equipment[slotName]
        if uid and not validUID[uid] then state.equipment[slotName] = nil end
    end

    -- Worn armor: slot -> uid. Only keep entries whose item still exists and
    -- still belongs to that armor slot.
    state.armor = {}
    if istable(source.armor) then
        for armorSlot, uid in pairs(source.armor) do
            local item = isstring(uid) and itemByUID[uid] or nil
            local def = item and INV.GetItemDefinition(item.id)
            if item and INV.GetArmorSlotForDefinition and INV.GetArmorSlotForDefinition(def) == armorSlot then
                state.armor[armorSlot] = uid
            end
        end
    end

    return state
end

function INV.GetState(ply)
    if not IsValid(ply) then return nil end
    if not INV.PlayerStates[ply] then
        INV.LoadPlayer(ply)
    end
    return INV.PlayerStates[ply]
end

function INV.SavePlayer(ply)
    if not IsValid(ply) then return end
    local state = INV.PlayerStates[ply]
    if not state then return end

    local encoded = util.TableToJSON(state, false)
    if encoded then
        ply:SetPData(C.SaveKey, encoded)
    end
end

local function findItemByUID(state, uid)
    if not state or not uid then return nil end
    for _, item in ipairs(state.items) do
        if item.uid == uid then return item end
    end
end

local function findItemBySlot(state, slot)
    if not state then return nil end
    for _, item in ipairs(state.items) do
        if item.slot == slot then return item end
    end
end

local function findItemCoveringSlot(state, slot)
    slot = INV.ClampSlot(slot)
    if not state or not slot then return nil end
    for _, item in ipairs(state.items) do
        local cells = itemFootprint(item)
        if cells then
            for _, cell in ipairs(cells) do
                if cell == slot then return item end
            end
        end
    end
end

local function layoutValid(state)
    if not state then return false end
    local occupied = {}

    local moneyCells = INV.GetFootprintSlots(state.moneySlot, C.MoneyItem)
    if not moneyCells then return false end
    for _, cell in ipairs(moneyCells) do
        if occupied[cell] then return false end
        occupied[cell] = "__money"
    end

    for _, item in ipairs(state.items) do
        local cells = itemFootprint(item)
        if not cells then return false end
        for _, cell in ipairs(cells) do
            if occupied[cell] then return false end
            occupied[cell] = item.uid
        end
    end
    return true
end

local function findFreeSlot(state, def, preferred)
    return findFreeSlotForDefinition(state, def, preferred, nil, false)
end

local function currentWeight(state)
    local total = 0
    for _, item in ipairs(state.items) do
        local def = INV.GetItemDefinition(item.id)
        if def then
            total = total + math.max(0, tonumber(def.Weight) or 0) * math.max(0, tonumber(item.qty) or 0)
        end
    end
    return total
end
INV.GetCurrentWeight = function(ply)
    local state = INV.GetState(ply)
    return state and currentWeight(state) or 0
end

-- Armory-issued items (job weapons + armor listed in job loadouts).
function INV.IsArmoryEquipment(id, def)
    def = def or INV.GetItemDefinition(id)
    if istable(def) and def.JobEquipment == true then return true end
    return GRNStore ~= nil and isfunction(GRNStore.IsJobLoadoutItem) and GRNStore.IsJobLoadoutItem(id) or false
end

local function removeUIDFromEquipment(state, uid)
    for slotName in pairs(INV.ValidEquipSlots) do
        if state.equipment[slotName] == uid then
            state.equipment[slotName] = nil
        end
    end
    for armorSlot, armorUID in pairs(state.armor or {}) do
        if armorUID == uid then
            state.armor[armorSlot] = nil
        end
    end
end

-- Weapons the current DarkRP job hands out through `weapons = {...}` must never
-- be stripped by the inventory (e.g. handcuffs that are both a job weapon and
-- an armory item).
local function isJobDefaultWeapon(ply, weaponClass)
    if not IsValid(ply) or not isstring(weaponClass) then return false end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()] or nil
    if not istable(job) or not istable(job.weapons) then return false end
    for _, class in ipairs(job.weapons) do
        if class == weaponClass then return true end
    end
    return false
end

-- -------------------------------------------------------------------------
-- Armor
-- -------------------------------------------------------------------------
local function armorConfig()
    return istable(C.Armor) and C.Armor or {}
end

local function isArmorEquipped(state, uid)
    for _, armorUID in pairs(state.armor or {}) do
        if armorUID == uid then return true end
    end
    return false
end

-- Sum of every worn piece. Returns a table of totals plus the visual list.
function INV.GetArmorTotals(ply, state)
    state = state or INV.GetState(ply)
    local totals = { armor = 0, health = 0, damageReduction = 0, carry = 0, visuals = {} }
    if not state or armorConfig().Enabled == false then return totals end

    for _, slot in ipairs(armorConfig().Slots or {}) do
        local uid = state.armor and state.armor[slot.ID]
        local item = uid and findItemByUID(state, uid) or nil
        local def = item and INV.GetItemDefinition(item.id) or nil
        if def then
            totals.armor = totals.armor + math.max(0, tonumber(def.Armor) or 0)
            totals.health = totals.health + math.max(0, tonumber(def.Health) or 0)
            totals.damageReduction = totals.damageReduction + math.max(0, tonumber(def.DamageReduction) or 0)
            totals.carry = totals.carry + (tonumber(def.CarryWeight) or 0)
            if isstring(def.Model) and def.Model ~= "" then
                totals.visuals[#totals.visuals + 1] = {
                    s = slot.ID,
                    m = def.Model,
                    k = tonumber(def.Skin) or 0,
                    b = istable(def.Bodygroups) and def.Bodygroups or nil,
                }
            end
        end
    end

    totals.damageReduction = math.Clamp(totals.damageReduction, 0, math.Clamp(tonumber(armorConfig().MaxDamageReduction) or 0.35, 0, 0.95))
    return totals
end

function INV.GetMaxWeight(ply, state)
    local base = tonumber(C.MaxWeight) or 100
    local totals = INV.GetArmorTotals(ply, state)
    return math.max(1, base + (totals.carry or 0))
end

local function armorAllowedForPlayer(ply, def)
    if not istable(def) then return false, "Unbekannte Rüstung." end
    local job = RPExtraTeams and RPExtraTeams[ply:Team()] or nil
    local command = istable(job) and tostring(job.command or "") or ""
    local category = istable(job) and tostring(job.category or "") or ""

    if istable(def.AllowedJobs) and next(def.AllowedJobs) ~= nil and not def.AllowedJobs[command] then
        if not (istable(def.AllowedCategories) and def.AllowedCategories[category]) then
            return false, "Dein Job darf diese Rüstung nicht tragen."
        end
    elseif istable(def.AllowedCategories) and next(def.AllowedCategories) ~= nil and not def.AllowedCategories[category] then
        return false, "Dein Job darf diese Rüstung nicht tragen."
    end

    local hookResult = hook.Run("GRNInventoryCanWearArmor", ply, def)
    if hookResult == false then return false, "Du kannst diese Rüstung gerade nicht anlegen." end
    return true
end

-- Shows / hides the armor bodygroups of the job model: worn slot = "On",
-- empty slot = "Off" (C.Armor.Bodygroups). Models without a profile stay untouched.
function INV.ApplyArmorBodygroups(ply, state)
    if not IsValid(ply) or not isfunction(INV.ResolveArmorBodygroups) then return end
    state = state or INV.GetState(ply)
    if not state then return end
    local groups = INV.ResolveArmorBodygroups(ply)
    if not groups then return end

    -- Worn pieces: slot -> definition, item id -> definition.
    local bySlot, byID = {}, {}
    if armorConfig().Enabled ~= false then
        for armorSlot, uid in pairs(state.armor or {}) do
            local item = findItemByUID(state, uid)
            local def = item and INV.GetItemDefinition(item.id)
            if def then
                bySlot[armorSlot] = def
                byID[item.id] = def
            end
        end
    end

    for key, group in pairs(groups) do
        local def
        if group.slot then def = bySlot[group.slot] end
        if not def and group.items then
            for id in pairs(group.items) do
                if byID[id] then def = byID[id] break end
            end
        end
        if def and group.requires and not bySlot[group.requires] then def = nil end

        local value = group.off
        if def then
            -- An item may use its own "on" value (e.g. jetpack = backpack 2).
            local override = istable(def.PlayerBodygroups) and tonumber(def.PlayerBodygroups[key]) or nil
            value = override or group.on
            if override and override >= ply:GetBodygroupCount(group.index) then value = group.on end
        end
        if value >= 0 and value < ply:GetBodygroupCount(group.index) and ply:GetBodygroup(group.index) ~= value then
            ply:SetBodygroup(group.index, value)
        end
    end
end

-- Applies the summed armor stats to the player.
-- Job PlayerSpawn functions set MaxArmor/MaxHealth to absolute values. We
-- remember the value we wrote; if it changed in the meantime the job has
-- reset it, so the bonus is applied again on top of the new base and the
-- bonus is filled into current armor/health (fresh spawn or job change).
function INV.ApplyArmor(ply)
    if not IsValid(ply) then return end
    local state = INV.GetState(ply)
    if not state then return end

    -- Drop pieces the current job is not allowed to wear.
    for armorSlot, uid in pairs(state.armor or {}) do
        local item = findItemByUID(state, uid)
        local def = item and INV.GetItemDefinition(item.id)
        if not def or not armorAllowedForPlayer(ply, def) then
            state.armor[armorSlot] = nil
        end
    end

    local totals = INV.GetArmorTotals(ply, state)
    local applied = ply.GRNArmorApplied or { armor = 0, health = 0, maxArmor = -1, maxHealth = -1 }

    if ply:Alive() then
        -- Armor -----------------------------------------------------------
        local curMaxArmor = ply:GetMaxArmor()
        local reset = curMaxArmor ~= applied.maxArmor
        local baseArmor = reset and curMaxArmor or (curMaxArmor - applied.armor)
        local newMaxArmor = math.max(0, baseArmor + totals.armor)
        ply:SetMaxArmor(newMaxArmor)
        if reset then
            ply:SetArmor(math.min(newMaxArmor, ply:Armor() + totals.armor))
        elseif ply:Armor() > newMaxArmor then
            ply:SetArmor(newMaxArmor)
        end

        -- Health ----------------------------------------------------------
        local curMaxHealth = ply:GetMaxHealth()
        local resetH = curMaxHealth ~= applied.maxHealth
        local baseHealth = resetH and curMaxHealth or (curMaxHealth - applied.health)
        local newMaxHealth = math.max(1, baseHealth + totals.health)
        ply:SetMaxHealth(newMaxHealth)
        if resetH then
            ply:SetHealth(math.min(newMaxHealth, ply:Health() + totals.health))
        elseif ply:Health() > newMaxHealth then
            ply:SetHealth(newMaxHealth)
        end

        ply.GRNArmorApplied = { armor = totals.armor, health = totals.health, maxArmor = newMaxArmor, maxHealth = newMaxHealth }
    end

    ply.GRNArmorDamageReduction = totals.damageReduction
    ply:SetNW2String("GRNArmorVisual", #totals.visuals > 0 and (util.TableToJSON(totals.visuals, false) or "") or "")
    INV.ApplyArmorBodygroups(ply, state)
end

function INV.EquipArmorUID(ply, uid, armorSlot)
    local state = INV.GetState(ply)
    if not state then return false, "Inventar nicht verfügbar." end
    if armorConfig().Enabled == false then return false, "Das Rüstungssystem ist deaktiviert." end

    local item = findItemByUID(state, uid)
    if not item then return false, "Gegenstand nicht gefunden." end
    local def = INV.GetItemDefinition(item.id)
    local expected = INV.GetArmorSlotForDefinition(def)
    if not expected then return false, "Dieser Gegenstand ist keine Rüstung." end
    armorSlot = armorSlot or expected
    if expected ~= armorSlot then return false, "Diese Rüstung passt nicht in diesen Slot." end

    local ok, reason = armorAllowedForPlayer(ply, def)
    if not ok then return false, reason end

    state.armor = state.armor or {}
    if state.armor[armorSlot] == uid then return true, "Bereits angelegt." end
    state.armor[armorSlot] = uid

    INV.ApplyArmor(ply)
    INV.SavePlayer(ply)
    return true, tostring(def.Name or item.id) .. " angelegt."
end

function INV.UnequipArmorSlot(ply, armorSlot)
    local state = INV.GetState(ply)
    if not state or not state.armor or not state.armor[armorSlot] then
        return false, "Dieser Rüstungsslot ist bereits leer."
    end
    state.armor[armorSlot] = nil
    INV.ApplyArmor(ply)
    INV.SavePlayer(ply)
    return true, "Rüstung abgelegt."
end

-- Used by the armory: wears a freshly issued armor piece if its slot is still
-- empty. Returns true when the piece was put on.
function INV.AutoEquipArmorItem(ply, itemID)
    if armorConfig().AutoEquipFromArmory == false then return false end
    local state = INV.GetState(ply)
    if not state then return false end

    local def = INV.GetItemDefinition(itemID)
    local armorSlot = INV.GetArmorSlotForDefinition(def)
    if not armorSlot or (state.armor and state.armor[armorSlot]) then return false end

    for _, item in ipairs(state.items) do
        if item.id == itemID and not isArmorEquipped(state, item.uid) then
            return (INV.EquipArmorUID(ply, item.uid, armorSlot)) == true
        end
    end
    return false
end

local function weaponStillEquipped(state, weaponClass, exceptUID)
    for slotName, uid in pairs(state.equipment) do
        if uid and uid ~= exceptUID then
            local item = findItemByUID(state, uid)
            local def = item and INV.GetItemDefinition(item.id)
            if def and def.Type == "weapon" and def.WeaponClass == weaponClass then
                return true
            end
        end
    end
    return false
end

local function stripManagedWeapon(ply, state, item)
    if not IsValid(ply) or not item then return end
    local def = INV.GetItemDefinition(item.id)
    if not def or def.Type ~= "weapon" or not isstring(def.WeaponClass) then return end
    if weaponStillEquipped(state, def.WeaponClass, item.uid) then return end
    if isJobDefaultWeapon(ply, def.WeaponClass) then return end
    if ply:HasWeapon(def.WeaponClass) then
        ply:StripWeapon(def.WeaponClass)
    end
end

function INV.UnequipUID(ply, uid, silent)
    local state = INV.GetState(ply)
    if not state then return false end
    local item = findItemByUID(state, uid)
    if not item then return false end

    local changed = false
    for slotName in pairs(INV.ValidEquipSlots) do
        if state.equipment[slotName] == uid then
            state.equipment[slotName] = nil
            changed = true
        end
    end

    if changed then
        stripManagedWeapon(ply, state, item)
        INV.SavePlayer(ply)
        if not silent then notify(ply, "Gegenstand abgelegt.") end
    end
    return changed
end

local function giveEquippedWeapon(ply, state, item)
    local def = INV.GetItemDefinition(item.id)
    if not def or def.Type ~= "weapon" then return true end
    if not isstring(def.WeaponClass) or def.WeaponClass == "" then return false, "Für diese Waffe ist keine gültige SWEP-Klasse konfiguriert." end

    local weapon = ply:GetWeapon(def.WeaponClass)
    if not IsValid(weapon) then
        weapon = ply:Give(def.WeaponClass, true)
    end
    if not IsValid(weapon) then
        return false, "Die konfigurierte SWEP-Klasse konnte nicht vergeben werden: " .. def.WeaponClass
    end

    local ammo = math.max(0, math.floor(tonumber(def.GiveAmmoOnEquip) or 0))
    if ammo > 0 and isstring(def.AmmoType) and not item.ammoGranted then
        ply:GiveAmmo(ammo, def.AmmoType, true)
        item.ammoGranted = true
    end
    return true
end

function INV.EquipUID(ply, uid, requestedSlot, silent)
    local state = INV.GetState(ply)
    if not state then return false end
    if not INV.ValidEquipSlots[requestedSlot] then return false, "Ungültiger Ausrüstungsslot." end

    local item = findItemByUID(state, uid)
    if not item then return false, "Gegenstand nicht gefunden." end
    local def = INV.GetItemDefinition(item.id)
    local expected = INV.GetEquipSlotForDefinition(def)
    if expected ~= requestedSlot then
        return false, "Dieser Gegenstand passt nicht in diesen Slot."
    end

    local oldUID = state.equipment[requestedSlot]
    if oldUID == uid then return true end

    if oldUID then
        local oldItem = findItemByUID(state, oldUID)
        state.equipment[requestedSlot] = nil
        if oldItem then stripManagedWeapon(ply, state, oldItem) end
    end

    state.equipment[requestedSlot] = uid
    local ok, err = giveEquippedWeapon(ply, state, item)
    if not ok then
        state.equipment[requestedSlot] = nil
        return false, err
    end

    INV.SavePlayer(ply)
    if not silent then notify(ply, (def.Name or item.id) .. " ausgerüstet.") end
    return true
end

function INV.ApplyEquipment(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    local state = INV.GetState(ply)
    if not state then return end

    for slotName, uid in pairs(state.equipment) do
        if uid then
            local item = findItemByUID(state, uid)
            local def = item and INV.GetItemDefinition(item.id)
            if not item or INV.GetEquipSlotForDefinition(def) ~= slotName then
                state.equipment[slotName] = nil
            else
                giveEquippedWeapon(ply, state, item)
            end
        end
    end
    INV.SavePlayer(ply)
end

function INV.AddItem(ply, id, quantity, preferredSlot)
    if not IsValid(ply) then return 0, "Ungültiger Spieler." end
    if INV.IsMoneyID(id) then
        local amount = math.max(0, math.floor(tonumber(quantity) or 0))
        if amount <= 0 then return 0, "Ungültige Menge." end
        INV.AddDarkRPMoney(ply, amount)
        return amount
    end

    local def = INV.GetItemDefinition(id)
    if not def then return 0, "Unbekannter Gegenstand: " .. tostring(id) end

    quantity = math.max(0, math.floor(tonumber(quantity) or 0))
    if quantity <= 0 then return 0, "Ungültige Menge." end

    local state = INV.GetState(ply)
    if not state then return 0, "Inventar nicht verfügbar." end

    local perWeight = math.max(0, tonumber(def.Weight) or 0)
    if perWeight > 0 then
        local remainingWeight = math.max(0, INV.GetMaxWeight(ply, state) - currentWeight(state))
        quantity = math.min(quantity, math.floor((remainingWeight + 0.00001) / perWeight))
        if quantity <= 0 then return 0, "Das Gewichtslimit des Inventars ist erreicht." end
    end

    local stackMax = math.max(1, math.floor(tonumber(def.Stack) or 1))
    local left = quantity
    local added = 0

    for _, item in ipairs(state.items) do
        if left <= 0 then break end
        if item.id == id and item.qty < stackMax then
            local can = math.min(left, stackMax - item.qty)
            item.qty = item.qty + can
            left = left - can
            added = added + can
        end
    end

    while left > 0 do
        local slot = findFreeSlot(state, def, preferredSlot)
        preferredSlot = nil
        if not slot then break end

        local amount = math.min(left, stackMax)
        state.items[#state.items + 1] = {
            uid = INV.NewUID(),
            id = id,
            qty = amount,
            slot = slot,
            ammoGranted = false
        }
        left = left - amount
        added = added + amount
    end

    if added > 0 then INV.SavePlayer(ply) end
    if added < quantity then
        return added, "Nicht genug Platz im Inventar."
    end
    return added
end

local function removeQuantity(ply, state, item, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if quantity > item.qty then quantity = item.qty end

    item.qty = item.qty - quantity
    if item.qty <= 0 then
        local def = INV.GetItemDefinition(item.id)
        if def and def.JobEquipment == true and isstring(def.WeaponClass) and def.WeaponClass ~= "" then
            if ply:HasWeapon(def.WeaponClass) and not weaponStillEquipped(state, def.WeaponClass, item.uid) and not isJobDefaultWeapon(ply, def.WeaponClass) then
                ply:StripWeapon(def.WeaponClass)
            end
        end
        local equipped = false
        for slotName in pairs(INV.ValidEquipSlots) do
            if state.equipment[slotName] == item.uid then
                equipped = true
                break
            end
        end
        if equipped then
            INV.UnequipUID(ply, item.uid, true)
        end
        local wasArmor = isArmorEquipped(state, item.uid)
        table.RemoveByValue(state.items, item)
        removeUIDFromEquipment(state, item.uid)
        if wasArmor then INV.ApplyArmor(ply) end
    end
    INV.SavePlayer(ply)
    return quantity
end

function INV.RemoveItem(ply, id, quantity)
    local state = INV.GetState(ply)
    if not state then return 0 end
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local removed = 0

    for i = #state.items, 1, -1 do
        if removed >= quantity then break end
        local item = state.items[i]
        if item.id == id then
            local take = math.min(item.qty, quantity - removed)
            removeQuantity(ply, state, item, take)
            removed = removed + take
        end
    end
    return removed
end

function INV.HasItem(ply, id, quantity)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if INV.IsMoneyID(id) then return INV.GetDarkRPMoney(ply) >= quantity end
    local state = INV.GetState(ply)
    if not state then return false end
    local count = 0
    for _, item in ipairs(state.items) do
        if item.id == id then count = count + item.qty end
    end
    return count >= quantity
end

local function seedStartingInventory(ply, state)
    if ply:GetPData(C.StartedKey, "0") == "1" then return end
    ply:SetPData(C.StartedKey, "1")

    for _, grant in ipairs(C.StartingItems or {}) do
        INV.AddItem(ply, grant.ID, grant.Quantity or 1, grant.PreferredSlot)
    end

    for slotName, itemID in pairs(C.StartingEquipment or {}) do
        if itemID and INV.ValidEquipSlots[slotName] then
            for _, item in ipairs(state.items) do
                if item.id == itemID and INV.GetEquipSlotForDefinition(INV.GetItemDefinition(item.id)) == slotName then
                    state.equipment[slotName] = item.uid
                    break
                end
            end
        end
    end
    INV.SavePlayer(ply)
end

function INV.LoadPlayer(ply)
    if not IsValid(ply) then return end
    local raw = ply:GetPData(C.SaveKey, "")
    local decoded = raw ~= "" and util.JSONToTable(raw) or nil
    local state = normalizeState(decoded)
    INV.PlayerStates[ply] = state
    seedStartingInventory(ply, state)

    -- First load since the server (re)started: no weapons.
    if ply:GetPData(SESSION_KEY, "") ~= INV.ServerSession then
        ply:SetPData(SESSION_KEY, INV.ServerSession)
        if respawnConfig().RemoveWeaponsOnServerRestart ~= false then
            INV.RemoveWeapons(ply)
        end
    end
    return state
end

local function payloadForPlayer(ply)
    local state = INV.GetState(ply)
    if not state then return nil end

    local list = {}
    for _, item in ipairs(state.items) do
        local def = INV.GetItemDefinition(item.id)
        if def then
            list[#list + 1] = {
                slot = item.slot,
                uid = item.uid,
                id = item.id,
                name = def.Name or item.id,
                icon = def.Icon or "fa-box",
                iconURL = def.IconURL or "",
                qty = item.qty,
                weight = tonumber(def.Weight) or 0,
                rarity = def.Rarity or "common",
                type = def.Type or "generic",
                desc = def.Description or "",
                equipSlot = INV.GetEquipSlotForDefinition(def),
                armorSlot = INV.GetArmorSlotForDefinition(def),
                armorStats = def.Type == "armor" and {
                    armor = tonumber(def.Armor) or 0,
                    health = tonumber(def.Health) or 0,
                    dr = math.Round((tonumber(def.DamageReduction) or 0) * 100, 1),
                    carry = tonumber(def.CarryWeight) or 0,
                } or nil,
                jobEquipment = INV.IsArmoryEquipment(item.id, def),
                usable = def.Type == "ammo" or def.Type == "healing" or def.Type == "consumable" or isfunction(def.OnUse) or def.Type == "weapon" or def.Type == "utility",
                sizeW = select(1, INV.GetItemSize(def)),
                sizeH = select(2, INV.GetItemSize(def))
            }
        end
    end

    local money = INV.GetDarkRPMoney(ply)
    local md = C.MoneyItem
    list[#list + 1] = {
        slot = state.moneySlot,
        uid = "__money",
        id = md.ID,
        name = md.Name,
        icon = md.Icon or "fa-coins",
        iconURL = md.IconURL or "",
        qty = money,
        weight = tonumber(md.Weight) or 0,
        rarity = md.Rarity or "uncommon",
        type = "money",
        desc = md.Description or "",
        equipSlot = nil,
        usable = false,
        virtualMoney = true,
        sizeW = select(1, INV.GetItemSize(md)),
        sizeH = select(2, INV.GetItemSize(md))
    }

    local totals = INV.GetArmorTotals(ply, state)
    local armorSlots = {}
    for _, slot in ipairs((C.Armor and C.Armor.Enabled ~= false and C.Armor.Slots) or {}) do
        armorSlots[#armorSlots + 1] = { id = slot.ID, label = slot.Label or slot.ID, side = slot.Side or "left", icon = slot.Icon or "fa-shield-halved", hint = slot.Hint or "" }
    end

    return {
        items = list,
        equipment = state.equipment,
        armor = state.armor or {},
        armorEnabled = not (C.Armor and C.Armor.Enabled == false),
        armorSlots = armorSlots,
        stats = {
            health = math.max(0, ply:Health()),
            maxHealth = math.max(1, ply:GetMaxHealth()),
            armor = math.max(0, ply:Armor()),
            maxArmor = math.max(1, ply:GetMaxArmor()),
            bonusArmor = totals.armor,
            bonusHealth = totals.health,
            damageReduction = math.Round(totals.damageReduction * 100, 1),
            carry = totals.carry,
            visualAllowed = INV.ArmorVisualAllowed(ply:GetModel()) or INV.GetArmorBodygroupProfile(ply:GetModel()) ~= nil,
        },
        currentWeight = math.Round(currentWeight(state), 2),
        maxWeight = INV.GetMaxWeight(ply, state),
        gridColumns = INV.GetGridColumns(),
        gridRows = INV.GetGridRows(),
        slotCount = INV.GetInventorySlotCount(),
        character = {
            name = ply:Nick(),
            balance = INV.FormatMoney(ply)
        }
    }
end

function INV.Sync(ply)
    if not IsValid(ply) then return end
    local payload = payloadForPlayer(ply)
    if not payload then return end
    local json = util.TableToJSON(payload, false) or "{}"
    net.Start("GRNINV_Sync")
    net.WriteString(json)
    net.Send(ply)
end

local function moveSlots(ply, from, to)
    local state = INV.GetState(ply)
    from = INV.ClampSlot(from)
    to = INV.ClampSlot(to)
    if not state or not from or not to or from == to then return false, "Ungültiges Ziel." end

    local moneyFrom = state.moneySlot == from
    local sourceItem = moneyFrom and nil or findItemBySlot(state, from)
    if not moneyFrom and not sourceItem then
        -- Be tolerant if the client sends one of the cells covered by a large item.
        sourceItem = findItemCoveringSlot(state, from)
        if sourceItem then from = sourceItem.slot end
    end

    if moneyFrom then
        local targetItem = findItemCoveringSlot(state, to)
        local oldMoney = state.moneySlot
        local oldTarget = targetItem and targetItem.slot or nil

        state.moneySlot = to
        if targetItem then targetItem.slot = from end

        if layoutValid(state) then
            INV.SavePlayer(ply)
            return true, "Credits verschoben."
        end

        state.moneySlot = oldMoney
        if targetItem then targetItem.slot = oldTarget end
        return false, "Dort ist nicht genug Platz."
    end

    if not sourceItem then return false, "In diesem Slot liegt kein Gegenstand." end

    local targetItem = findItemCoveringSlot(state, to)
    if targetItem and targetItem.uid == sourceItem.uid then
        targetItem = nil
    end

    local oldSource = sourceItem.slot
    local oldTarget = targetItem and targetItem.slot or nil
    sourceItem.slot = to
    if targetItem then targetItem.slot = oldSource end

    if layoutValid(state) then
        INV.SavePlayer(ply)
        return true, "Gegenstand verschoben."
    end

    sourceItem.slot = oldSource
    if targetItem then targetItem.slot = oldTarget end
    return false, "Der Gegenstand passt nicht in den gewählten Slot."
end

local function useSlot(ply, slot)
    local state = INV.GetState(ply)
    slot = INV.ClampSlot(slot)
    if not state or not slot then return false, "Ungültiger Slot." end
    if state.moneySlot == slot then return false, "Credits kann man so nicht benutzen." end

    local item = findItemBySlot(state, slot)
    if not item then return false, "Leerer Inventarslot." end
    local def = INV.GetItemDefinition(item.id)
    if not def then return false, "Unbekannter Gegenstand." end

    if def.Type == "weapon" then
        local equipSlot = INV.GetEquipSlotForDefinition(def)
        if not equipSlot then return false, "Der Ausrüstungsslot dieser Waffe ist nicht konfiguriert." end
        if state.equipment[equipSlot] ~= item.uid then
            return INV.EquipUID(ply, item.uid, equipSlot, true)
        end
        if def.WeaponClass and ply:HasWeapon(def.WeaponClass) then
            local cfg = backpackSettings()
            if ply.GRNInventoryOpen and cfg.Enabled ~= false and ply.GRNInventoryBackpackActive then
                -- Keep the backpack viewmodel visible while the inventory is open.
                -- The requested weapon becomes active immediately after the close
                -- animation finishes.
                ply.GRNInventoryBackpackDesiredWeapon = def.WeaponClass
                return true, "Waffe wird nach dem Schließen des Inventars gezogen."
            end

            ply:SelectWeapon(def.WeaponClass)
            return true, "Waffe gezogen."
        end
        return false, "Die Waffe ist nicht verfügbar."
    end

    if def.Type == "ammo" then
        local ammoType = tostring(def.AmmoType or "")
        local amount = math.max(0, math.floor(tonumber(def.AmmoAmount) or 0))
        if ammoType == "" or amount <= 0 then return false, "Die Munition ist nicht richtig konfiguriert." end
        ply:GiveAmmo(amount, ammoType, true)
        removeQuantity(ply, state, item, 1)
        return true, "Reservemunition geladen."
    end

    if def.Type == "healing" then
        if not ply:Alive() then return false, "Du musst am Leben sein, um das zu benutzen." end
        local maxHealth = math.max(1, ply:GetMaxHealth())
        if ply:Health() >= maxHealth then return false, "Deine Gesundheit ist bereits voll." end
        local heal = math.max(1, math.floor(tonumber(def.Heal) or 1))
        ply:SetHealth(math.min(maxHealth, ply:Health() + heal))
        removeQuantity(ply, state, item, 1)
        return true, "Medizinischen Gegenstand benutzt."
    end

    if isfunction(def.OnUse) then
        local ok, result = pcall(def.OnUse, ply, item, def)
        if not ok then
            ErrorNoHalt("[GRN Inventory] OnUse error for " .. tostring(item.id) .. ": " .. tostring(result) .. "\n")
            return false, "Dieser Gegenstand konnte nicht benutzt werden."
        end
        if result ~= false then
            removeQuantity(ply, state, item, 1)
            return true, "Gegenstand benutzt."
        end
        return false, "Dieser Gegenstand kann gerade nicht benutzt werden."
    end

    if def.Type == "utility" then
        local equipSlot = INV.GetEquipSlotForDefinition(def)
        if equipSlot then return INV.EquipUID(ply, item.uid, equipSlot, true) end
    end

    return false, "Dieser Gegenstand kann nicht benutzt werden."
end

function INV.SpawnDroppedItem(ply, id, quantity)
    local def = INV.GetItemDefinition(id)
    if not def or quantity <= 0 then return nil end

    local ent = ents.Create("grn_inventory_drop")
    if not IsValid(ent) then return nil end
    ent:SetItemID(id)
    ent:SetItemQuantity(quantity)

    local tr = ply:GetEyeTrace()
    local forward = ply:GetAimVector()
    local pos = ply:EyePos() + forward * 54
    if tr.Hit and tr.HitPos:DistToSqr(ply:EyePos()) < (90 * 90) then
        pos = tr.HitPos + tr.HitNormal * 8
    end

    ent:SetPos(pos)
    ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
    ent.GRNDropOwner = ply
    ent.GRNPickupLockedUntil = CurTime() + (C.DropPickupDelay or 0.75)
    ent:Spawn()
    ent:Activate()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:SetVelocity(forward * 80 + Vector(0, 0, 35))
    end
    return ent
end

local function dropSlot(ply, slot, quantity)
    local state = INV.GetState(ply)
    slot = INV.ClampSlot(slot)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if not state or not slot then return false, "Ungültiger Slot." end

    if state.moneySlot == slot then
        local money = INV.GetDarkRPMoney(ply)
        quantity = math.min(quantity, money)
        if quantity <= 0 then return false, "Du hast keine Credits zum Fallenlassen." end
        if not INV.AddDarkRPMoney(ply, -quantity) then return false, "Das DarkRP-Geld konnte nicht aktualisiert werden." end
        local ent = INV.SpawnDroppedItem(ply, C.MoneyItem.ID, quantity)
        if not IsValid(ent) then
            INV.AddDarkRPMoney(ply, quantity)
            return false, "Die Credits konnten nicht fallen gelassen werden."
        end
        return true, INV.FormatNumber(quantity) .. " Credits fallen gelassen."
    end

    local item = findItemBySlot(state, slot)
    if not item then return false, "Leerer Inventarslot." end

    local itemDef = INV.GetItemDefinition(item.id)
    if itemDef and INV.IsArmoryEquipment(item.id, itemDef) then
        return false, "Waffenkammer-Ausrüstung kann nicht fallen gelassen werden. Nutze ZURÜCK IN DIE WAFFENKAMMER."
    end

    quantity = math.min(quantity, item.qty)

    local equipped = false
    for slotName in pairs(INV.ValidEquipSlots) do
        if state.equipment[slotName] == item.uid then equipped = true break end
    end
    if equipped and not C.AllowDropEquippedItems then
        return false, "Lege den Gegenstand erst ab, bevor du ihn fallen lässt."
    end

    if quantity >= item.qty and equipped then
        INV.UnequipUID(ply, item.uid, true)
    end

    local ent = INV.SpawnDroppedItem(ply, item.id, quantity)
    if not IsValid(ent) then return false, "Der Gegenstand konnte nicht fallen gelassen werden." end
    removeQuantity(ply, state, item, quantity)
    return true, "Gegenstand fallen gelassen."
end

function INV.PickupWorldEntity(ply, ent)
    if not IsValid(ply) or not IsValid(ent) or ent:GetClass() ~= "grn_inventory_drop" then return end
    local id = ent:GetItemID()
    local quantity = math.max(1, ent:GetItemQuantity())

    if INV.IsMoneyID(id) then
        INV.AddDarkRPMoney(ply, quantity)
        ent:Remove()
        notify(ply, INV.FormatNumber(quantity) .. " Credits aufgehoben.")
        INV.Sync(ply)
        return
    end

    local added, reason = INV.AddItem(ply, id, quantity)
    if added <= 0 then
        notify(ply, reason or "Das Inventar ist voll.")
        return
    end

    if added >= quantity then
        ent:Remove()
    else
        ent:SetItemQuantity(quantity - added)
    end

    notify(ply, tostring(added) .. "x " .. ((INV.GetItemDefinition(id) or {}).Name or id) .. " aufgehoben.")
    INV.Sync(ply)
end

local function handleAction(ply, action, data)
    local state = INV.GetState(ply)
    if not state then return false, "Inventar nicht verfügbar." end

    if action == "move" then
        return moveSlots(ply, data.from, data.to)
    end

    if action == "equip" then
        local slot = INV.ClampSlot(data.slot)
        if not slot or state.moneySlot == slot then return false, "Dieser Gegenstand kann nicht ausgerüstet werden." end
        local item = findItemBySlot(state, slot)
        if not item then return false, "Gegenstand nicht gefunden." end
        return INV.EquipUID(ply, item.uid, tostring(data.equipSlot or ""), true)
    end

    if action == "equipArmor" then
        local slot = INV.ClampSlot(data.slot)
        if not slot or state.moneySlot == slot then return false, "Dieser Gegenstand kann nicht angelegt werden." end
        local item = findItemBySlot(state, slot) or findItemCoveringSlot(state, slot)
        if not item then return false, "Gegenstand nicht gefunden." end
        local armorSlot = tostring(data.armorSlot or "")
        if armorSlot == "" then armorSlot = nil end
        return INV.EquipArmorUID(ply, item.uid, armorSlot)
    end

    if action == "unequipArmor" then
        local armorSlot = tostring(data.armorSlot or "")
        if not INV.ArmorSlotByID[armorSlot] then return false, "Ungültiger Rüstungsslot." end
        return INV.UnequipArmorSlot(ply, armorSlot)
    end

    if action == "unequip" then
        local equipSlot = tostring(data.equipSlot or "")
        if not INV.ValidEquipSlots[equipSlot] then return false, "Ungültiger Ausrüstungsslot." end
        local uid = state.equipment[equipSlot]
        if not uid then return false, "Dieser Slot ist bereits leer." end
        INV.UnequipUID(ply, uid, true)
        return true, "Gegenstand abgelegt."
    end

    if action == "store" then
        local slot = INV.ClampSlot(data.slot)
        if not slot or state.moneySlot == slot then return false, "Dieser Gegenstand kann nicht in die Waffenkammer zurückgegeben werden." end
        local item = findItemBySlot(state, slot)
        if not item then return false, "Gegenstand nicht gefunden." end
        local def = INV.GetItemDefinition(item.id)
        if not def or not INV.IsArmoryEquipment(item.id, def) then
            return false, "Nur Ausrüstung aus der Waffenkammer kann so zurückgegeben werden."
        end

        INV.UnequipUID(ply, item.uid, true)
        if def.Type == "weapon" and isstring(def.WeaponClass) and def.WeaponClass ~= "" and ply:HasWeapon(def.WeaponClass) then
            ply:StripWeapon(def.WeaponClass)
        end

        local itemID = item.id
        local displayName = tostring(def.Name or itemID)
        local removed = INV.RemoveItem(ply, itemID, 1)
        if removed <= 0 then return false, "Der Gegenstand konnte nicht in die Waffenkammer zurückgegeben werden." end

        if GRNStore and isfunction(GRNStore.MarkArmoryItemStored) then
            GRNStore.MarkArmoryItemStored(ply, itemID, 1)
        end

        return true, displayName .. " in die Waffenkammer zurückgegeben."
    end

    if action == "use" then
        return useSlot(ply, data.slot)
    end

    if action == "drop" then
        return dropSlot(ply, data.slot, data.quantity)
    end

    return false, "Unbekannte Inventaraktion."
end

net.Receive("GRNINV_BackpackState", function(_, ply)
    if not IsValid(ply) then return end
    if ply.GRNInventoryNextBackpackState and ply.GRNInventoryNextBackpackState > CurTime() then return end
    ply.GRNInventoryNextBackpackState = CurTime() + 0.05

    local opening = net.ReadBool()
    if opening then
        INV.StartBackpackAnimation(ply)
    else
        INV.StopBackpackAnimation(ply, false)
    end
end)

net.Receive("GRNINV_RequestSync", function(_, ply)
    ply.GRNInventoryOpen = true
    INV.Sync(ply)
end)

net.Receive("GRNINV_ClientClosed", function(_, ply)
    ply.GRNInventoryOpen = false
    -- Fallback cleanup in case a custom UI closes without sending the dedicated
    -- animation state message. StopBackpackAnimation is intentionally idempotent.
    INV.StopBackpackAnimation(ply, false)
end)

net.Receive("GRNINV_Action", function(_, ply)
    if not IsValid(ply) then return end
    if ply.GRNInventoryNextAction and ply.GRNInventoryNextAction > CurTime() then return end
    ply.GRNInventoryNextAction = CurTime() + 0.04

    local action = net.ReadString()
    local json = net.ReadString()
    local data = util.JSONToTable(json or "") or {}
    local ok, message = handleAction(ply, action, data)
    if message then notify(ply, message) end
    INV.Sync(ply)
end)

hook.Add("PlayerInitialSpawn", "GRNInventory_Load", function(ply)
    timer.Simple(0.5, function()
        if not IsValid(ply) then return end
        INV.LoadPlayer(ply)
        INV.ApplyArmor(ply)
    end)
end)

-- -------------------------------------------------------------------------
-- Death / respawn / revive / character change
-- -------------------------------------------------------------------------
local function isArmoryWeaponItem(ply, item)
    local def = item and INV.GetItemDefinition(item.id)
    if not def or def.Type ~= "weapon" then return false end
    if INV.IsArmoryEquipment(item.id, def) then return true end
    local issued = ply.GRNArmoryIssuedItems
    return istable(issued) and (tonumber(issued[item.id]) or 0) > 0
end

local function isRemovableWeaponItem(ply, item)
    local def = item and INV.GetItemDefinition(item.id)
    if not def or def.Type ~= "weapon" then return false end
    if respawnConfig().RemoveAllWeapons ~= false then return true end
    return isArmoryWeaponItem(ply, item)
end

-- Removes the weapons (equipped or stored) from the inventory and takes the
-- SWEPs away. Job default weapons, armor and all other items are kept.
function INV.RemoveWeapons(ply)
    local state = INV.GetState(ply)
    if not state then return 0 end

    local removed = 0
    for i = #state.items, 1, -1 do
        local item = state.items[i]
        if item and isRemovableWeaponItem(ply, item) then
            local def = INV.GetItemDefinition(item.id)
            if istable(ply.GRNArmoryIssuedItems) then
                ply.GRNArmoryIssuedItems[item.id] = nil
            end
            removed = removed + removeQuantity(ply, state, item, item.qty)

            local class = def and def.WeaponClass
            if isstring(class) and class ~= "" and ply:HasWeapon(class)
                and not weaponStillEquipped(state, class) and not isJobDefaultWeapon(ply, class) then
                ply:StripWeapon(class)
            end
        end
    end

    if removed > 0 then
        INV.SavePlayer(ply)
        if ply.GRNInventoryOpen then INV.Sync(ply) end
    end
    return removed
end
INV.RemoveArmoryWeapons = INV.RemoveWeapons

-- Revive addons may call this before or right after ply:Spawn() to make sure
-- the spawn is treated as a revive (player keeps the armory weapons).
function INV.MarkRevived(ply)
    if IsValid(ply) then ply.GRNForceRevive = CurTime() end
end

local function isReviveSpawn(ply, death)
    if ply.GRNForceRevive and CurTime() - ply.GRNForceRevive <= 5 then return true end

    local override = hook.Run("GRNInventory_IsRevive", ply, death)
    if override ~= nil then return override == true end

    local cfg = respawnConfig()
    local maxTime = tonumber(cfg.ReviveMaxTime) or 180
    local maxDist = tonumber(cfg.ReviveMaxDistance) or 250
    if maxTime <= 0 or maxDist <= 0 then return false end
    if CurTime() - death.time > maxTime then return false end
    return ply:GetPos():DistToSqr(death.pos) <= maxDist * maxDist
end

-- Called once after a spawn that followed a real death.
local function resolveDeath(ply)
    local death = ply.GRNPendingDeath
    if not death then return end
    local revived = isReviveSpawn(ply, death)
    ply.GRNPendingDeath = nil
    ply.GRNForceRevive = nil

    if revived then return end
    if respawnConfig().RemoveArmoryWeaponsOnRespawn == false then return end
    INV.RemoveWeapons(ply)
end

-- Revive integrations. Krakens Medical (KMS) never kills a downed player, so
-- a medic revive does not go through PlayerDeath and the weapons stay anyway.
hook.Add("JLTS_PlayerRevived", "GRNInventory_MarkRevived", function(ply)
    INV.MarkRevived(ply)
end)

-- KMS admin revive (dead player is respawned) counts as a revive as well.
local function wrapKMSAdminHeal()
    if not istable(KMS) or not isfunction(KMS.AdminHeal) or KMS.GRNInventoryWrapped then return end
    local original = KMS.AdminHeal
    KMS.AdminHeal = function(actor, name, revive, ...)
        INV.AdminReviveActive = revive == true
        local ok, err = pcall(original, actor, name, revive, ...)
        INV.AdminReviveActive = false
        if not ok then ErrorNoHalt("[GRN Inventory] KMS.AdminHeal error: " .. tostring(err) .. "\n") end
    end
    KMS.GRNInventoryWrapped = true
end
hook.Add("InitPostEntity", "GRNInventory_KMSCompat", wrapKMSAdminHeal)
wrapKMSAdminHeal()

-- Character change: switching to another character means no weapons. The
-- last character is stored, so re-selecting the same one after a reconnect
-- keeps the weapons (a server restart removes them anyway).
local function onCharacterSelected(ply, charID)
    if not IsValid(ply) then return end
    charID = tostring(charID or "")
    if charID == "" then return end

    local last = ply:GetPData(CHARACTER_KEY, "")
    ply:SetPData(CHARACTER_KEY, charID)
    if last == charID then return end
    if respawnConfig().RemoveWeaponsOnCharacterChange == false then return end

    ply.GRNPendingDeath = nil
    INV.RemoveWeapons(ply)
end

hook.Add("symchars_selectedcharacter", "GRNInventory_CharacterChange", function(ply, char)
    onCharacterSelected(ply, ply.symchars_charid or (istable(char) and char.id))
end)

hook.Add("VoidChar.CharacterSelected", "GRNInventory_CharacterChange", function(ply, character)
    onCharacterSelected(ply, istable(character) and character.id)
end)

hook.Add("PlayerDeath", "GRNInventory_BackpackDeathCleanup", function(ply)
    ply.GRNInventoryOpen = false
    INV.StopBackpackAnimation(ply, true)

    -- Armory weapons are only removed once we know the next spawn is a real
    -- respawn and not a revive.
    ply.GRNPendingDeath = { time = CurTime(), pos = ply:GetPos() }
end)

hook.Add("PlayerSpawn", "GRNInventory_Reapply", function(ply)
    -- A respawn must never inherit the temporary inventory animation weapon.
    INV.StopBackpackAnimation(ply, true)

    if INV.AdminReviveActive then INV.MarkRevived(ply) end

    -- Fresh spawn: the job sets new base armor/health, re-apply armor bonus on top.
    ply.GRNArmorApplied = nil
    timer.Simple(0.6, function()
        if IsValid(ply) and ply:Alive() then INV.ApplyArmor(ply) end
    end)
    -- Character/model addons may set the model or bodygroups a bit later.
    timer.Simple(2.5, function()
        if IsValid(ply) and ply:Alive() then INV.ApplyArmorBodygroups(ply) end
    end)

    -- Decide revive vs. respawn before the equipment is handed out again.
    local checkDelay = math.max(0, tonumber(respawnConfig().CheckDelay) or 0.5)
    if ply.GRNPendingDeath then
        timer.Simple(checkDelay, function()
            if IsValid(ply) and ply:Alive() then resolveDeath(ply) end
        end)
    end

    if not C.ReapplyEquipmentOnSpawn then return end
    timer.Simple(math.max(1.0, checkDelay + 0.2), function()
        if IsValid(ply) and ply:Alive() then INV.ApplyEquipment(ply) end
    end)
end)

hook.Add("OnPlayerChangedTeam", "GRNInventory_ArmorJobChange", function(ply)
    timer.Simple(0.5, function()
        if IsValid(ply) then
            INV.ApplyArmor(ply)
            if ply.GRNInventoryOpen then INV.Sync(ply) end
        end
    end)
end)

hook.Add("EntityTakeDamage", "GRNInventory_ArmorDamageReduction", function(target, dmg)
    if not IsValid(target) or not target:IsPlayer() then return end
    local reduction = tonumber(target.GRNArmorDamageReduction) or 0
    if reduction <= 0 then return end
    local ignore = tonumber(C.Armor and C.Armor.IgnoreDamageTypes) or 0
    if ignore ~= 0 and bit.band(dmg:GetDamageType(), ignore) ~= 0 then return end
    dmg:ScaleDamage(1 - reduction)
end)

hook.Add("PlayerDisconnected", "GRNInventory_Save", function(ply)
    -- Leaving while dead (or before the revive check ran) counts as a respawn.
    if ply.GRNPendingDeath and respawnConfig().RemoveArmoryWeaponsOnRespawn ~= false then
        ply.GRNPendingDeath = nil
        INV.RemoveWeapons(ply)
    end
    INV.SavePlayer(ply)
    INV.PlayerStates[ply] = nil
end)

hook.Add("ShutDown", "GRNInventory_SaveAll", function()
    for _, ply in ipairs(player.GetAll()) do INV.SavePlayer(ply) end
end)

hook.Add("PlayerCanDropWeapon", "GRNInventory_BlockEngineDrop", function(ply, weapon)
    if not IsValid(ply) or not IsValid(weapon) then return end
    if weapon:GetClass() == backpackClass() then return false end
    local state = INV.GetState(ply)
    if not state then return end
    for _, uid in pairs(state.equipment) do
        local item = uid and findItemByUID(state, uid) or nil
        local def = item and INV.GetItemDefinition(item.id)
        if def and def.Type == "weapon" and def.WeaponClass == weapon:GetClass() then
            return false
        end
    end
end)

-- Keep an open inventory reasonably current if money changes elsewhere in DarkRP.
timer.Create("GRNInventory_OpenSync", 1, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        if ply.GRNInventoryOpen then INV.Sync(ply) end
    end
end)

-- Public API ---------------------------------------------------
function INV.Open(ply)
    if IsValid(ply) then
        ply:ConCommand("grn_inventory_open")
    end
end

-- Admin / development helper:
-- grn_inv_give <player name or SteamID64> <item_id> <quantity>
concommand.Add("grn_inv_give", function(executor, _, args)
    if IsValid(executor) and not executor:IsAdmin() then return end
    local targetArg = tostring(args[1] or "")
    local itemID = tostring(args[2] or "")
    local qty = math.max(1, math.floor(tonumber(args[3]) or 1))

    local target
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == targetArg or string.find(string.lower(ply:Nick()), string.lower(targetArg), 1, true) then
            target = ply
            break
        end
    end

    if not IsValid(target) then
        if IsValid(executor) then notify(executor, "Spieler nicht gefunden.") else print("[GRN Inventory] Player not found.") end
        return
    end

    local added, reason = INV.AddItem(target, itemID, qty)
    INV.Sync(target)
    local msg = "Gegeben: " .. tostring(added) .. "x " .. itemID .. " an " .. target:Nick() .. "."
    if reason then msg = msg .. " " .. reason end
    if IsValid(executor) then notify(executor, msg) else print("[GRN Inventory] " .. msg) end
end)

-- Lists the bodygroups of a player model (needed to link armor slots to
-- bodygroups). Usage: grn_armor_bodygroups [name]  (other players: superadmin)
concommand.Add("grn_armor_bodygroups", function(executor, _, args)
    local target = IsValid(executor) and executor or nil
    local search = string.lower(table.concat(args or {}, " "))
    if search ~= "" and (not IsValid(executor) or executor:IsSuperAdmin()) then
        target = nil
        for _, ply in ipairs(player.GetAll()) do
            if string.find(string.lower(ply:Nick()), search, 1, true) then target = ply break end
        end
    end

    local function out(line)
        if IsValid(executor) then executor:PrintMessage(HUD_PRINTCONSOLE, line) else print(line) end
    end

    if not IsValid(target) then out("[GRN Inventory] Kein Spieler gefunden.") return end
    local job = RPExtraTeams and RPExtraTeams[target:Team()] or nil
    out("[GRN Inventory] " .. target:Nick() .. " | Job: " .. tostring(istable(job) and job.command or "?"))
    out("Model: " .. tostring(target:GetModel()) .. " | Skin: " .. tostring(target:GetSkin()))
    for i = 0, target:GetNumBodyGroups() - 1 do
        out(string.format("  [%d] %s = %d  (Werte 0-%d)", i, tostring(target:GetBodygroupName(i)), target:GetBodygroup(i), math.max(0, target:GetBodygroupCount(i) - 1)))
    end

    local profile = INV.GetArmorBodygroupProfile(target:GetModel())
    if not profile then out("Kein Rüstungs-Profil für dieses Model (C.Armor.Bodygroups.Profiles).") return end
    out("Rüstungs-Profil: " .. tostring(profile.Name or "?"))
    local groups = INV.ResolveArmorBodygroups(target) or {}
    for key in pairs(profile.Values or {}) do
        local g = groups[key]
        out(g and string.format("  %s -> [%d] %s (an %d / aus %d, Slot %s)", key, g.index, tostring(target:GetBodygroupName(g.index)), g.on, g.off, tostring(g.slot))
            or ("  " .. key .. " -> NICHT GEFUNDEN (Index in der Config eintragen)"))
    end
end)
