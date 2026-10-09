GRNArcCW = GRNArcCW or {}
local M = GRNArcCW
local C = M.Config

M.Frame = M.Frame or nil
M.HTMLPanel = M.HTMLPanel or nil
M.Weapon = M.Weapon or nil
M.HTMLReady = false
M.LastJSON = nil

local iconCache = {}

local function translate(key)
    if ArcCW and isfunction(ArcCW.GetTranslation) then
        local ok, res = pcall(ArcCW.GetTranslation, key)
        if ok and isstring(res) then return res end
    end
end

local function tryTranslate(str)
    if not isstring(str) then return "" end
    if ArcCW and isfunction(ArcCW.TryTranslation) then
        local ok, res = pcall(ArcCW.TryTranslation, str)
        if ok and isstring(res) then return res end
    end
    return str
end

local function attName(name)
    local tbl = ArcCW and ArcCW.AttachmentTable[name]
    if not tbl then return tostring(name or "") end
    return translate("name." .. name) or tbl.PrintName or name
end

-- ArcCW speichert Icons als IMaterial. Für das HTML brauchen wir die PNG-Datei.
local function iconURL(mat)
    if not mat or type(mat) ~= "IMaterial" or mat:IsError() then return nil end
    local key = mat:GetName()
    if iconCache[key] ~= nil then return iconCache[key] or nil end

    local candidates = { key }
    local tex = mat:GetTexture("$basetexture")
    if tex and not tex:IsError() then
        local tn = tex:GetName()
        candidates[#candidates + 1] = tn
        candidates[#candidates + 1] = string.gsub(tn, "0001010$", "")
        candidates[#candidates + 1] = string.gsub(tn, "%d%d%d%d%d%d%d$", "")
    end

    for _, c in ipairs(candidates) do
        c = string.gsub(string.gsub(c, "\\", "/"), "^/+", "")
        local path = string.EndsWith(c, ".png") and c or (c .. ".png")
        if file.Exists("materials/" .. path, "GAME") then
            local url = "asset://garrysmod/materials/" .. path
            iconCache[key] = url
            return url
        end
    end
    iconCache[key] = false
    return nil
end

local function slotIcon(slotName)
    if istable(slotName) then slotName = slotName[1] end
    slotName = string.lower(tostring(slotName or ""))
    if C.SlotIcons[slotName] then return C.SlotIcons[slotName] end
    for _, pair in ipairs(C.SlotIconPatterns or {}) do
        if string.find(slotName, pair[1], 1, true) then return pair[2] end
    end
    return "fa-puzzle-piece"
end

local function prosCons(wep, atttbl)
    if not (ArcCW and isfunction(ArcCW.GetProsCons) and atttbl) then return {}, {}, {} end
    local ok, pros, cons, infos = pcall(ArcCW.GetProsCons, ArcCW, wep, atttbl)
    if not ok then return {}, {}, {} end
    return pros or {}, cons or {}, infos or {}
end

local function describe(atttbl)
    if not atttbl then return "" end
    local desc = atttbl.Description
    if istable(desc) then desc = table.concat(desc, " ") end
    return tryTranslate(desc or "")
end

-- Kampfwerte mit Trend gegenüber der unbestückten Waffe.
local function buildStats(wep)
    local rows = {}
    local function safe(fn, ...)
        local ok, v = pcall(fn, ...)
        if ok and isnumber(v) then return v end
    end
    local function add(label, cur, base, fmt, higherBetter, barMax)
        if not cur then return end
        base = base or cur
        local trend = 0
        if math.abs(cur - base) > 0.001 * math.max(1, math.abs(base)) then
            trend = (cur > base) == higherBetter and 1 or -1
        end
        rows[#rows + 1] = {
            label = label,
            value = string.format(fmt, cur),
            trend = trend,
            bar = barMax and math.Clamp(cur / barMax * 100, 0, 100) or nil
        }
    end

    local stored = weapons.GetStored(wep:GetClass()) or {}
    add("Schaden", safe(wep.GetDamage, wep, 0), (stored.Damage or wep.Damage or 0) * math.max(1, stored.Num or wep.Num or 1), "%d", true, 150)
    local delay = safe(wep.GetFiringDelay, wep)
    add("Kadenz (RPM)", delay and delay > 0 and (60 / delay) or nil, (wep.Delay and wep.Delay > 0) and (60 / wep.Delay) or nil, "%d", true, 1200)
    add("Magazin", safe(wep.GetCapacity, wep), wep.Primary and wep.Primary.ClipSize, "%d", true, 150)
    add("Reichweite (m)", safe(wep.GetBuff, wep, "Range"), wep.Range, "%d", true, 300)
    add("Rückstoß", safe(wep.GetBuff, wep, "Recoil"), wep.Recoil, "%.2f", false, nil)
    add("Streuung (MOA)", safe(wep.GetBuff, wep, "AccuracyMOA"), wep.AccuracyMOA, "%.1f", false, nil)
    return rows
end

function M.BuildState(wep)
    local data = { weapon = {}, slots = {}, stats = {}, date = os.date("%d / %m / %Y") }
    if not IsValid(wep) or not wep.Attachments then return data end

    local wname = translate("name." .. wep:GetClass()) or wep.PrintName or wep:GetClass()
    data.weapon = {
        name = string.upper(tostring(wname)),
        kicker = "AUFSATZ-WERKBANK · " .. string.upper(tostring(wep.Trivia_Class or wep.Category or "WAFFE")),
        serial = "",
        wear = {}
    }
    hook.Run("GRNArcCW_DecorateWeapon", wep, data.weapon)

    local ply = LocalPlayer()
    for i, slot in SortedPairs(wep.Attachments) do
        if isnumber(i) and istable(slot) and slot.PrintName and not slot.Hidden and not slot.Blacklisted and not slot.Integral then
            local options = {}
            for _, opt in ipairs(M.GetSlotOptions(wep, i)) do
                local atttbl = ArcCW.AttachmentTable[opt.att]
                local show, _, blocked = true, false, false
                if isfunction(wep.ValidateAttachment) then
                    local ok, s, _, b = pcall(wep.ValidateAttachment, wep, opt.att, nil, opt.slot)
                    if ok then show, blocked = s ~= false, b == true end
                end
                if show and atttbl then
                    local pros, cons, infos = prosCons(wep, atttbl)
                    options[#options + 1] = {
                        att = opt.att,
                        slot = opt.slot,
                        name = attName(opt.att),
                        short = atttbl.AbbrevName or "",
                        desc = describe(atttbl),
                        icon = iconURL(atttbl.Icon),
                        pros = pros, cons = cons, infos = infos,
                        blocked = blocked or not ArcCW:PlayerCanAttach(ply, wep, opt.att, opt.slot, false),
                        sort = atttbl.SortOrder or 0
                    }
                end
            end
            table.sort(options, function(a, b)
                if a.sort ~= b.sort then return a.sort > b.sort end
                return a.name < b.name
            end)

            -- Installiert ist das Teil im Slot selbst oder in einem seiner Merge-Slots.
            local installed = slot.Installed
            local installedSlot = i
            if not installed then
                for _, ms in ipairs(slot.MergeSlots or {}) do
                    local s2 = wep.Attachments[ms]
                    if istable(s2) and s2.Installed then installed, installedSlot = s2.Installed, ms break end
                end
            end
            if installed and installed == (wep.Attachments[installedSlot] or {}).EmptyFallback then installed = nil end

            local entry = {
                index = i,
                name = string.upper(tryTranslate(slot.PrintName)),
                fa = slotIcon(slot.Slot),
                options = options,
                installed = installed,
                canDetach = installed ~= nil and not (wep.Attachments[installedSlot] or {}).Internal
            }
            if installed then
                local atttbl = ArcCW.AttachmentTable[installed]
                entry.installedName = attName(installed)
                entry.installedIcon = { icon = atttbl and iconURL(atttbl.Icon) or nil }
                entry.installedDesc = describe(atttbl)
                entry.installedPros, entry.installedCons, entry.installedInfos = prosCons(wep, atttbl)
            else
                local def
                if isfunction(wep.GetBuff_Hook) then
                    local ok, res = pcall(wep.GetBuff_Hook, wep, "Hook_GetDefaultAttName", i, true)
                    if ok then def = res end
                end
                entry.installedName = isstring(def) and tryTranslate(def) or (slot.DefaultAttName and tryTranslate(slot.DefaultAttName)) or nil
            end

            -- Slots ohne freigegebene Aufsätze und ohne verbautes Teil blenden wir aus.
            if #options > 0 or installed then
                data.slots[#data.slots + 1] = entry
            end
        end
    end

    data.stats = buildStats(wep)
    return data
end

local function push(force)
    if not IsValid(M.HTMLPanel) or not M.HTMLReady then return end
    local wep = M.Weapon
    if not IsValid(wep) then return end
    local json = util.TableToJSON(M.BuildState(wep), false) or "{}"
    if not force and json == M.LastJSON then return end
    M.LastJSON = json
    M.HTMLPanel:QueueJavascript("if(window.GRNAttUI)GRNAttUI.setData(" .. json .. ");")
end

function M.Refresh(force)
    push(force)
end

local function playSound(kind)
    if GRNInventory and isfunction(GRNInventory.PlayUISound) then GRNInventory.PlayUISound(kind) end
end

function M.CloseMenu(fromWeapon)
    if M.Closing then return end
    M.Closing = true
    local wep = M.Weapon

    if IsValid(M.Frame) then M.Frame:Remove() end
    M.Frame, M.HTMLPanel, M.HTMLReady, M.LastJSON = nil, nil, false, nil
    timer.Remove("GRNArcCW_Refresh")

    if not fromWeapon and IsValid(wep) and wep.ArcCW and ArcCW and wep:GetState() == ArcCW.STATE_CUSTOMIZE then
        net.Start("arccw_togglecustomize")
            net.WriteBool(false)
        net.SendToServer()
        wep:ToggleCustomizeHUD(false)
    end
    M.Weapon = nil
    M.Closing = false
end

function M.OpenMenu(wep)
    if not IsValid(wep) then return end
    if IsValid(M.Frame) then M.Frame:Remove() end
    M.Weapon = wep
    M.HTMLReady = false
    M.LastJSON = nil

    local frame = vgui.Create("EditablePanel")
    frame:SetSize(ScrW(), ScrH())
    frame:SetPos(0, 0)
    frame:MakePopup()
    frame:SetKeyboardInputEnabled(true)
    frame:SetMouseInputEnabled(true)

    local html = vgui.Create("DHTML", frame)
    html:Dock(FILL)
    html:SetAllowLua(false)

    html:AddFunction("grnAtt", "ready", function()
        M.HTMLReady = true
        push(true)
    end)
    html:AddFunction("grnAtt", "close", function() M.CloseMenu(false) end)
    html:AddFunction("grnAtt", "uiSound", function(kind) playSound(kind) end)
    html:AddFunction("grnAtt", "attach", function(slotIndex, realSlot, att)
        local w = M.Weapon
        if not IsValid(w) then return end
        slotIndex, realSlot, att = tonumber(slotIndex), tonumber(realSlot), tostring(att or "")
        if not realSlot or not w.Attachments[realSlot] then return end
        if not M.IsAllowed(att, LocalPlayer()) then
            html:QueueJavascript("GRNAttUI.toast('Dieser Aufsatz ist auf dem Server nicht freigegeben.')")
            return
        end
        if not ArcCW:PlayerCanAttach(LocalPlayer(), w, att, realSlot, false) then
            playSound("error")
            return
        end
        -- Bei Merge-Slots erst den belegten Nachbarslot räumen (wie ArcCW).
        if realSlot ~= slotIndex and isfunction(w.DetachAllMergeSlots) then
            w:DetachAllMergeSlots(slotIndex, true)
        end
        w:Attach(realSlot, att)
        timer.Simple(0.05, function() push(true) end)
        timer.Simple(0.4, function() push(false) end)
    end)
    html:AddFunction("grnAtt", "detach", function(slotIndex)
        local w = M.Weapon
        slotIndex = tonumber(slotIndex)
        if not IsValid(w) or not slotIndex or not w.Attachments[slotIndex] then return end
        if isfunction(w.DetachAllMergeSlots) then
            w:DetachAllMergeSlots(slotIndex)
        else
            w:Detach(slotIndex)
        end
        timer.Simple(0.05, function() push(true) end)
        timer.Simple(0.4, function() push(false) end)
    end)

    local page = string.Replace(M.HTML, "__SIDE__", tostring(math.Round((C.SidePanelWidth or 0.27) * 100, 1)))
    html:SetHTML(page)
    html.OnDocumentReady = function()
        timer.Simple(0.05, function()
            if IsValid(html) then
                M.HTMLReady = true
                push(true)
            end
        end)
    end

    M.Frame, M.HTMLPanel = frame, html
    playSound("Open")

    -- Server kann Aufsätze ablehnen oder nachreichen: regelmäßig abgleichen.
    timer.Create("GRNArcCW_Refresh", 0.5, 0, function()
        if not IsValid(M.Frame) then timer.Remove("GRNArcCW_Refresh") return end
        local w = M.Weapon
        local ply = LocalPlayer()
        if not IsValid(w) or not IsValid(ply) or not ply:Alive() or ply:GetActiveWeapon() ~= w
                or w:GetState() ~= ArcCW.STATE_CUSTOMIZE then
            M.CloseMenu(true)
            return
        end
        push(false)
    end)
end

-- ---------------------------------------------------------
-- ArcCW-Menü ersetzen
-- ---------------------------------------------------------
local function openHook(self)
    if self.GetPriorityAnim and self:GetPriorityAnim() then return end
    if IsValid(ArcCW.InvHUD) then ArcCW.InvHUD:Remove() end
    M.OpenMenu(self)
end

local function closeHook(self)
    if IsValid(M.Frame) and M.Weapon == self then
        M.CloseMenu(true)
        playSound("Close")
    end
end

local function patchTable(t)
    if not istable(t) or t.GRNArcCWPatched then return end
    t.GRNArcCWPatched = true
    t.OpenCustomizeHUD = openHook
    t.CloseCustomizeHUD = closeHook
end

local function isArcCW(class)
    return class == "arccw_base" or weapons.IsBasedOn(class, "arccw_base")
end

function M.PatchArcCW()
    if not C.ReplaceCustomizeMenu then return end
    for _, t in ipairs(weapons.GetList()) do
        local class = t.ClassName
        if class and isArcCW(class) then patchTable(weapons.GetStored(class)) end
    end
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:IsWeapon() and ent.ArcCW then patchTable(ent:GetTable()) end
    end
end

hook.Add("InitPostEntity", "GRNArcCW_Patch", function() timer.Simple(0, M.PatchArcCW) end)
hook.Add("OnReloaded", "GRNArcCW_Patch", function() timer.Simple(0, M.PatchArcCW) end)
hook.Add("OnEntityCreated", "GRNArcCW_Patch", function(ent)
    if not C.ReplaceCustomizeMenu then return end
    timer.Simple(0, function()
        if IsValid(ent) and ent:IsWeapon() and ent.ArcCW then patchTable(ent:GetTable()) end
    end)
end)
