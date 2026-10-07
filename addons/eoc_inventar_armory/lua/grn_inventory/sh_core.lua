GRNInventory = GRNInventory or {}
local INV = GRNInventory
local C = INV.Config

INV.Version = "1.3.0"

function INV.GetGridColumns()
    return math.max(1, math.floor(tonumber(C.GridColumns) or 5))
end

function INV.GetGridRows()
    return math.max(1, math.floor(tonumber(C.GridRows) or math.ceil((tonumber(C.InventorySlots) or 25) / INV.GetGridColumns())))
end

function INV.GetInventorySlotCount()
    return INV.GetGridColumns() * INV.GetGridRows()
end

function INV.GetItemSize(defOrID)
    local def = isstring(defOrID) and INV.GetItemDefinition(defOrID) or defOrID
    local size = def and def.Size or nil
    local w = math.max(1, math.floor(tonumber(size and (size.W or size.w)) or 1))
    local h = math.max(1, math.floor(tonumber(size and (size.H or size.h)) or 1))
    w = math.min(w, INV.GetGridColumns())
    h = math.min(h, INV.GetGridRows())
    return w, h
end

function INV.SlotToGrid(slot)
    slot = math.floor(tonumber(slot) or 0)
    local cols = INV.GetGridColumns()
    if slot < 1 or slot > INV.GetInventorySlotCount() then return nil end
    local zero = slot - 1
    return (zero % cols) + 1, math.floor(zero / cols) + 1
end

function INV.GridToSlot(col, row)
    col = math.floor(tonumber(col) or 0)
    row = math.floor(tonumber(row) or 0)
    local cols, rows = INV.GetGridColumns(), INV.GetGridRows()
    if col < 1 or col > cols or row < 1 or row > rows then return nil end
    return (row - 1) * cols + col
end

function INV.GetFootprintSlots(slot, defOrID)
    local col, row = INV.SlotToGrid(slot)
    if not col then return nil end
    local w, h = INV.GetItemSize(defOrID)
    local cols, rows = INV.GetGridColumns(), INV.GetGridRows()
    if col + w - 1 > cols or row + h - 1 > rows then return nil end

    local out = {}
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            out[#out + 1] = INV.GridToSlot(col + x, row + y)
        end
    end
    return out
end

INV.ValidEquipSlots = {
    primary = true,
    secondary = true,
    specialized = true,
    utility = true
}

function INV.GetItemDefinition(id)
    if not id then return nil end
    if C.MoneyItem and id == C.MoneyItem.ID then
        return C.MoneyItem
    end
    return C.Items[id]
end

function INV.GetEquipSlotForDefinition(def)
    if not def then return nil end
    if def.EquipSlot and INV.ValidEquipSlots[def.EquipSlot] then
        return def.EquipSlot
    end
    if def.Type == "healing" or def.Type == "utility" then
        return "utility"
    end
    return nil
end

function INV.IsMoneyID(id)
    return C.MoneyItem and id == C.MoneyItem.ID
end

function INV.ClampSlot(slot)
    slot = math.floor(tonumber(slot) or 0)
    if slot < 1 or slot > INV.GetInventorySlotCount() then return nil end
    return slot
end

function INV.NewUID()
    return tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999)) .. "_" .. tostring(SysTime())
end

function INV.DeepCopy(tbl)
    if not istable(tbl) then return tbl end
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = istable(v) and INV.DeepCopy(v) or v
    end
    return out
end

function INV.FormatNumber(n)
    n = math.floor(tonumber(n) or 0)
    local sign = n < 0 and "-" or ""
    local s = tostring(math.abs(n))
    while true do
        local changed
        s, changed = string.gsub(s, "^(%d+)(%d%d%d)", "%1,%2")
        if changed == 0 then break end
    end
    return sign .. s
end
