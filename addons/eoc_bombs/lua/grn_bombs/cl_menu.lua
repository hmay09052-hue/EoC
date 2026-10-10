GRN_Bombs = GRN_Bombs or {}

local PANEL

local function jsonEscape(str)
    return util.TableToJSON({v = str}):sub(7, -3)
end

function GRN_Bombs.OpenMenu()
    if IsValid(PANEL) then PANEL:Remove() end

    PANEL = vgui.Create('DFrame')
    PANEL:SetTitle('')
    PANEL:SetSize(ScrW(), ScrH())
    PANEL:SetPos(0, 0)
    PANEL:ShowCloseButton(false)
    PANEL:SetDraggable(false)
    PANEL:MakePopup()
    PANEL.Paint = function() surface.SetDrawColor(0,0,0,220) surface.DrawRect(0,0,PANEL:GetWide(),PANEL:GetTall()) end

    local browser = vgui.Create('DHTML', PANEL)
    browser:Dock(FILL)
    browser:SetAllowLua(true)
    browser.OnDocumentReady = function(self)
        self:QueueJavascript('window.receiveBombs(' .. util.TableToJSON(GRN_Bombs.ClientBombs or {}) .. ');')
        self:QueueJavascript("window.setCurrentLang('" .. string.JavascriptSafe(tostring(GRN_Bombs.ClientLang or GRN_Bombs.Config.DefaultLanguage or 'en')) .. "');")
    end
    local page = GRN_Bombs.MenuHTML or '<html><body>Missing HTML.</body></html>'
    if SYMUI then page = SYMUI.ThemeHTML(page, { css = GRN_Bombs.SymCSS }) end
    browser:SetHTML(page)

    browser:AddFunction('gmod', 'CloseMenu', function()
        if IsValid(PANEL) then PANEL:Remove() end
    end)

    browser:AddFunction('gmod', 'SaveBomb', function(payload)
        local tbl = util.JSONToTable(payload or '{}') or {}
        net.Start('grn_bombs_save')
            net.WriteTable(tbl)
        net.SendToServer()
    end)

    browser:AddFunction('gmod', 'DeleteBomb', function(payload)
        local tbl = util.JSONToTable(payload or '{}') or {}
        net.Start('grn_bombs_delete')
            net.WriteUInt(tonumber(tbl.id) or 0, 16)
        net.SendToServer()
    end)

    browser:AddFunction('gmod', 'SpawnBomb', function(payload)
        local tbl = util.JSONToTable(payload or '{}') or {}
        net.Start('grn_bombs_spawn')
            net.WriteUInt(tonumber(tbl.id) or 0, 16)
        net.SendToServer()
    end)

    browser:AddFunction('gmod', 'SetLang', function(payload)
        local tbl = util.JSONToTable(payload or '{}') or {}
        local lang = tostring(tbl.lang or '')
        if lang == 'en' or lang == 'es' or lang == 'fr' then
            GRN_Bombs.ClientLang = lang
        end
    end)

    GRN_Bombs.MenuPanel = PANEL
    GRN_Bombs.MenuBrowser = browser
end

net.Receive('grn_bombs_open_menu', function()
    GRN_Bombs.OpenMenu()
end)

net.Receive('grn_bombs_sync', function()
    GRN_Bombs.ClientBombs = net.ReadTable() or {}
    local focusId = net.ReadUInt(16)
    if IsValid(GRN_Bombs.MenuBrowser) then
        GRN_Bombs.MenuBrowser:QueueJavascript('window.receiveBombs(' .. util.TableToJSON(GRN_Bombs.ClientBombs or {}) .. ');')
        if focusId > 0 then
            timer.Simple(0.1, function()
                if IsValid(GRN_Bombs.MenuBrowser) then
                    GRN_Bombs.MenuBrowser:QueueJavascript('window.openBombById(' .. focusId .. ');')
                end
            end)
        end
    end
end)

net.Receive('grn_bombs_notify', function()
    local msg = net.ReadString()
    notification.AddLegacy(msg, NOTIFY_GENERIC, 4)
    surface.PlaySound('buttons/button15.wav')
end)


if not GRN_Bombs.ClientLang then GRN_Bombs.ClientLang = GRN_Bombs.Config.DefaultLanguage or 'en' end
