-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
hradio = hradio or {}

hradio.errorcatcher = hradio.errorcatcher or {}
hradio.errorcatcher.isOpen = false
hradio.errorcatcher.caughtErrors = hradio.errorcatcher.caughtErrors or {}
hradio.errorcatcher.startupErrors = hradio.errorcatcher.startupErrors or {}

if SERVER then
    util.AddNetworkString("HCS_ReportError")
    util.AddNetworkString("HCS_ReportStartupError")
    util.AddNetworkString("HCS_ServerError")
    util.AddNetworkString("HCS_ServerStartupError")

    hradio.errorcatcher._lastReport = hradio.errorcatcher._lastReport or {}

    local MAX_MSG_LEN = 300
    local REPORT_COOLDOWN = 5

    local function CanPlayerReport(ply)
        if not IsValid(ply) then return false end

        local id = ply:SteamID64()
        local last = hradio.errorcatcher._lastReport[id]

        if last and CurTime() - last < REPORT_COOLDOWN then
            return false
        end

        hradio.errorcatcher._lastReport[id] = CurTime()
        return true
    end

    local function SendToAdmins(netName, message)
        local recipients = {}

        for _, admin in ipairs(player.GetAll()) do
            if admin:IsAdmin() then
                recipients[#recipients + 1] = admin
            end
        end

        if #recipients == 0 then return end

        net.Start(netName)
        net.WriteString(string.sub(tostring(message or ""), 1, MAX_MSG_LEN))
        net.Send(recipients)
    end

    local function HandleClientReport(ply, message, startup)
        if not CanPlayerReport(ply) then return end

        message = string.sub(tostring(message or ""), 1, MAX_MSG_LEN)

        print(string.format(
            "[EOC Radio] %s (%s) reported: %s",
            ply:Name(),
            ply:SteamID(),
            message
        ))

        local prefix = startup and "[Startup] " or ""
        SendToAdmins("HCS_ServerError", "[Report from " .. ply:Name() .. "] " .. prefix .. message)
    end

    net.Receive("HCS_ReportError", function(_, ply)
        HandleClientReport(ply, net.ReadString(), false)
    end)

    net.Receive("HCS_ReportStartupError", function(_, ply)
        HandleClientReport(ply, net.ReadString(), true)
    end)

    function hradio.errorcatcher.Catch(errorMsg)
        errorMsg = tostring(errorMsg or "Unknown radio error")
        print("[EOC Radio] " .. errorMsg)
        SendToAdmins("HCS_ServerError", errorMsg)
    end

    function hradio.errorcatcher.CatchLater(errorMsg)
        errorMsg = tostring(errorMsg or "Unknown radio startup error")
        print("[EOC Radio] " .. errorMsg)
        SendToAdmins("HCS_ServerStartupError", errorMsg)
    end

    return
end

net.Receive("HCS_ServerStartupError", function()
    local msg = net.ReadString()
    hradio.errorcatcher.startupErrors[msg] = true
end)

net.Receive("HCS_ServerError", function()
    local msg = net.ReadString()

    if not hradio.errorcatcher.isOpen then
        hradio.errorcatcher.open()
    end

    hradio.errorcatcher.addError(msg)
end)

function hradio.errorcatcher.Catch(errorMsg)
    errorMsg = tostring(errorMsg or "Unknown radio error")

    if not hradio.errorcatcher.isOpen then
        hradio.errorcatcher.open()
    end

    if hradio.errorcatcher.caughtErrors[errorMsg] then return end

    net.Start("HCS_ReportError")
    net.WriteString(errorMsg)
    net.SendToServer()

    hradio.errorcatcher.addError(errorMsg)
end

function hradio.errorcatcher.CatchLater(errorMsg)
    errorMsg = tostring(errorMsg or "Unknown radio startup error")

    if hradio.errorcatcher.startupErrors[errorMsg] then return end

    net.Start("HCS_ReportStartupError")
    net.WriteString(errorMsg)
    net.SendToServer()

    hradio.errorcatcher.startupErrors[errorMsg] = true
end

local YELLOW = Color(252, 178, 73)
local WHITE = Color(244, 241, 233)
local SOFT = Color(166, 173, 183)
local MUTED = Color(99, 106, 116)
local PANEL = Color(7, 9, 12, 250)
local PANEL2 = Color(15, 19, 24, 250)
local LINE = Color(214, 220, 229, 35)
local RED = Color(225, 88, 88)

local function styleRichText(panel)
    function panel:PerformLayout()
        self:SetFontInternal("hRadio_Small")
        self:SetFGColor(SOFT)
    end
end

function hradio.errorcatcher.onClose()
    hradio.errorcatcher.caughtErrors = {}
    hradio.errorcatcher.isOpen = false
end

function hradio.errorcatcher.open()
    if hradio.errorcatcher.isOpen then return end

    local width = math.min(680, ScrW() - 40)
    local height = math.min(430, ScrH() - 40)

    local frame = vgui.Create("DFrame")
    frame:SetSize(width, height)
    frame:Center()
    frame:SetTitle("")
    frame:ShowCloseButton(false)
    frame:SetDraggable(true)
    frame:SetSizable(false)
    frame:MakePopup()
    if SYMUI then SYMUI.AutoStyle(frame) end

    frame.Paint = function(_, w, h)
        SY_RoundedBox(0, 0, 0, w, h, Color(214, 220, 229, 62))
        SY_RoundedBox(0, 1, 1, w - 2, h - 2, PANEL)
        SY_RoundedBox(0, 1, 1, w - 2, 2, YELLOW)
        SY_RoundedBox(0, 0, 54, w, 1, LINE)

        draw.SimpleText("EOC // RADIO DIAGNOSTICS", "hRadio_Tiny", 18, 12, YELLOW, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("COMMUNICATION SYSTEM", "hRadio_Title", 18, 25, WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    local close = vgui.Create("DButton", frame)
    close:SetSize(30, 30)
    close:SetPos(width - 42, 12)
    close:SetText("×")
    close:SetFont("hRadio_Main")
    close:SetTextColor(MUTED)

    close.Paint = function(self, w, h)
        local hover = self:IsHovered()
        SY_RoundedBox(0, 0, 0, w, h, hover and Color(252, 178, 73, 18) or Color(255, 255, 255, 4))
        surface.SetDrawColor(hover and Color(252, 178, 73, 95) or LINE)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        self:SetTextColor(hover and YELLOW or MUTED)
    end

    close.DoClick = function()
        frame:Close()
    end

    local tabs = vgui.Create("DPanel", frame)
    tabs:SetPos(14, 66)
    tabs:SetSize(width - 28, 34)
    tabs.Paint = nil

    local content = vgui.Create("DPanel", frame)
    content:SetPos(14, 105)
    content:SetSize(width - 28, height - 119)

    content.Paint = function(_, w, h)
        SY_RoundedBox(0, 0, 0, w, h, PANEL2)
        surface.SetDrawColor(LINE)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
    end

    local runtimeList = vgui.Create("DScrollPanel", content)
    runtimeList:Dock(FILL)
    runtimeList:DockMargin(8, 8, 8, 8)

    local startupList = vgui.Create("DScrollPanel", content)
    startupList:Dock(FILL)
    startupList:DockMargin(8, 8, 8, 8)
    startupList:SetVisible(false)

    local activeTab = "runtime"

    local function setTab(name)
        activeTab = name
        runtimeList:SetVisible(name == "runtime")
        startupList:SetVisible(name == "startup")
    end

    local function makeTab(text, x, name)
        local button = vgui.Create("DButton", tabs)
        button:SetPos(x, 0)
        button:SetSize(116, 30)
        button:SetText(string.upper(text))
        button:SetFont("hRadio_Tiny")
        button:SetTextColor(SOFT)

        button.Paint = function(self, w, h)
            local active = activeTab == name
            local hover = self:IsHovered()

            SY_RoundedBox(0, 0, 0, w, h, active and Color(252, 178, 73, 18) or Color(255, 255, 255, hover and 8 or 3))
            surface.SetDrawColor(active and Color(252, 178, 73, 110) or LINE)
            surface.DrawOutlinedRect(0, 0, w, h, 1)

            if active then
                SY_RoundedBox(0, 0, h - 2, w, 2, YELLOW)
            end

            self:SetTextColor(active and YELLOW or (hover and WHITE or SOFT))
        end

        button.DoClick = function()
            setTab(name)
        end

        return button
    end

    makeTab("Runtime", 0, "runtime")
    makeTab("Startup", 122, "startup")

    local function addRow(parent, text, startup)
        local row = vgui.Create("DPanel", parent)
        row:Dock(TOP)
        row:SetTall(58)
        row:DockMargin(0, 0, 0, 5)

        row.Paint = function(_, w, h)
            SY_RoundedBox(0, 0, 0, w, h, Color(8, 11, 15, 235))
            surface.SetDrawColor(LINE)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
            SY_RoundedBox(0, 0, 0, 2, h, startup and YELLOW or RED)
        end

        local label = vgui.Create("RichText", row)
        label:Dock(FILL)
        label:DockMargin(10, 8, 10, 8)
        label:SetText(text)
        styleRichText(label)
    end

    function hradio.errorcatcher.addError(errorMsg)
        errorMsg = tostring(errorMsg or "Unknown radio error")

        if hradio.errorcatcher.caughtErrors[errorMsg] then return end

        hradio.errorcatcher.caughtErrors[errorMsg] = true
        addRow(runtimeList, errorMsg, false)
    end

    for errorMsg in pairs(hradio.errorcatcher.startupErrors) do
        addRow(startupList, errorMsg, true)
    end

    frame.OnClose = function()
        hradio.errorcatcher.onClose()
    end

    hradio.errorcatcher.isOpen = true
end
