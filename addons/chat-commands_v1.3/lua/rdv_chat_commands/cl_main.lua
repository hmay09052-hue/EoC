-- SymChars-Design: abgerundete Boxen werden zu abgeschrägten Platten (ohne SymChars wie bisher)
local function SY_RoundedBox(...) if SYMUI then return SYMUI.RoundedBox(...) end return draw.RoundedBox(...) end
local function SY_RoundedBoxEx(...) if SYMUI then return SYMUI.RoundedBoxEx(...) end return draw.RoundedBoxEx(...) end
surface.CreateFont("RDV_CHATCOMANDS_LABEL", {
	font = SYMUI and SYMUI.FontFace("head") or "Bebas Neue",
	extended = false,
	size = ScrW() * 0.0135,
})

local function CreateDivider(PANEL, SP, TEXT)
	local w, h = PANEL:GetSize()

    local TLABEL = SP:Add("DLabel")
    TLABEL:Dock(TOP)
    TLABEL:DockMargin(w * 0.02, h * 0.02, w * 0.02, h * 0.02)
    TLABEL:SetText(TEXT)
    TLABEL:SetFont("RDV_CHATCOMANDS_LABEL")
    TLABEL:SetTextColor(COL_1)
	TLABEL:SetMouseInputEnabled(true)
end

local function CREATE_COMMAND_LINK(UID, DUPLICATED)
    local DATA = {}

    if RDV.CHAT_COMMANDS.LIST[UID] then
        DATA = table.Copy(RDV.CHAT_COMMANDS.LIST[UID])
    else
        DATA = {
            COMMAND = nil,
            STEAMS = {},
            LINK = nil,
            RANKS = {},
        }
    end

    if DUPLICATED then
        DATA.COMMAND = DATA.COMMAND.."_COPY"
    end

    local F = vgui.Create("PIXEL.Frame")
    if SYMUI then SYMUI.HookPixel() SYMUI.AutoStyle(F) end
    F:SetSize(ScrW() * 0.3, ScrH() * 0.6)
    F:Center()
    F:MakePopup(true)
    F:SetTitle(RDV.LIBRARY.GetLang(nil, "CHAT_commandTitle"))
    
    local w, h = F:GetSize()

    local S = vgui.Create("PIXEL.ScrollPanel", F)
    S:DockMargin(w * 0.01, h * 0.01, w * 0.01, h * 0.01)
    S:Dock(FILL)


    --[[
    -- Command
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_commandLabel").."*")

    local COMMAND = S:Add("DTextEntry")
    COMMAND:Dock(TOP)

    if DATA and DATA.COMMAND then
        COMMAND:SetValue(DATA.COMMAND)
    end

    --[[
    -- Open Link
    --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_openLinkLabel").."*")

        local LINK = S:Add("DTextEntry")
        LINK:Dock(TOP)

        if DATA and DATA.LINK then
            LINK:SetValue(DATA.LINK)
        end

    --[[
    -- Team Restriction
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_teamRestrictLabel"))

    local LABEL = vgui.Create("DLabel", S)
    LABEL:SetText("")
    LABEL:SetHeight(h * 0.3)
    LABEL:Dock(TOP)
    LABEL:SetMouseInputEnabled(true)

    
    local S_TEAM = vgui.Create("DListView", LABEL)
    S_TEAM:Dock(FILL)
    S_TEAM:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_nameLabel"), 1 )
    S_TEAM.OnRowRightClick = function(sm, ID, LINE)
        LINE:SetSelected(false)
    end

    for k, v in ipairs(team.GetAllTeams()) do
        local L = S_TEAM:AddLine(v.Name)
        L.TEAM = v.Name
        
        if DATA.STEAMS and DATA.STEAMS[v.Name] then L:SetSelected(true) end
    end

    --[[
    -- Rank Restriction
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_rankRestrict"))

    local BRANCH
    local RANK
    local S_RANK

    local LABEL = S:Add("DLabel")
    LABEL:Dock(TOP)
    LABEL:SetTall(LABEL:GetTall() * 1.5)
    LABEL:SetText("")
    LABEL:SetMouseInputEnabled(true)
    
    local ADD = LABEL:Add("DButton", LABEL)
    ADD:SetImage("icon16/add.png")
    ADD:Dock(LEFT)
    ADD:SetText("")
    ADD:SetWide(ADD:GetWide() * 0.4)
    ADD.DoClick = function(s)
        local BR = BRANCH:GetValue()
        local RA = tonumber(RANK:GetValue())

        if ( !BR or BR == "" ) or ( !RA or RA == "" ) then return end

        local LINE = S_RANK:AddLine(BR, RA)
        LINE.BRANCH = BR
        LINE.RANK = RA
    end

    BRANCH = vgui.Create("DTextEntry", LABEL)
    BRANCH:Dock(LEFT)
    BRANCH:SetKeyboardInputEnabled(true)
    BRANCH:SetPlaceholderText(RDV.LIBRARY.GetLang(nil, "CHAT_branchLabel"))
    BRANCH:SetWide(BRANCH:GetWide() * 2)

    RANK = vgui.Create("DTextEntry", LABEL)
    RANK:Dock(LEFT)
    RANK:SetKeyboardInputEnabled(true)
    RANK:SetPlaceholderText(RDV.LIBRARY.GetLang(nil, "CHAT_rankLabel"))
    RANK:SetWide(RANK:GetWide() * 2)
    RANK:SetNumeric(true)

    local LABEL = vgui.Create("DLabel", S)
    LABEL:SetText("")
    LABEL:SetHeight(h * 0.3)
    LABEL:Dock(TOP)
    LABEL:SetMouseInputEnabled(true)

    S_RANK = vgui.Create("DListView", LABEL)
    S_RANK:Dock(FILL)
    S_RANK:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_branchLabel"), 1 )
    S_RANK:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_rankLabel"), 2 )

    S_RANK.OnRowRightClick = function(sm, ID, LINE)
        local BR = LINE.BRANCH

        if DATA.RANKS[BR] then
            DATA.RANKS[BR] = nil
        end

        S_RANK:RemoveLine(ID)
    end

    if DATA.RANKS then
        for k, v in pairs(DATA.RANKS) do
            local LINE = S_RANK:AddLine(k, v)
            LINE.BRANCH = k
            LINE.RANK = v
        end
    end

    --[[
    -- Confirm
    --]]

    local CONFIRM = vgui.Create("PIXEL.TextButton", F)
    CONFIRM:Dock(BOTTOM)
    CONFIRM:SetText(RDV.LIBRARY.GetLang(nil, "CHAT_confirmLabel"))
    CONFIRM.DoClick = function(s)
        DATA.STEAMS = DATA.STEAMS or {}
        DATA.COMMAND = COMMAND:GetText()
        DATA.LINK = LINK:GetText()
        DATA.RANKS = DATA.RANKS or {}

        if ( !DATA.LINK or DATA.LINK == "" ) or ( !DATA.COMMAND or DATA.COMMAND == "" ) then
            chat.AddText(Color(255,0,0), "[COMMANDS] ", color_white, RDV.LIBRARY.GetLang(nil, "CHAT_missingContent"))
            return
        end

        for k, v in ipairs(S_TEAM:GetSelected()) do
            DATA.STEAMS[v.TEAM] = true 
        end

        for k, v in ipairs(S_RANK:GetLines()) do
            DATA.RANKS[v.BRANCH] = v.RANK
        end

        local COMPRESS = util.Compress(util.TableToJSON(DATA))

        local BYTES = #COMPRESS

        net.Start( "RDV_CHAT_COMMANDS_CREATE" )
            net.WriteUInt( BYTES, 16 )
            net.WriteData( COMPRESS, BYTES )
        net.SendToServer()

        F:Remove()
    end
end

local function CREATE_COMMAND(UID, DUPLICATED)
    local DATA = {}

    if RDV.CHAT_COMMANDS.LIST[UID] then
        DATA = table.Copy(RDV.CHAT_COMMANDS.LIST[UID])
    else
        DATA = {
            COMMAND = nil,
            Prefix = nil,
            Prefix_Color = nil,
            Text_Color = nil,
            GLOBAL = true,
            RADIUS = nil,
            DISPLAY_NAME = true,
            SOUND = nil,
            ALIVE = true,
            NoTeamSee = false,
            DisWithRelay = true,
            DELAY = 1,
            STEAMS = {},
            RANKS = {},
        }
    end

    if DUPLICATED then
        DATA.COMMAND = DATA.COMMAND.."_COPY"
    end

    local F = vgui.Create("PIXEL.Frame")
    if SYMUI then SYMUI.HookPixel() SYMUI.AutoStyle(F) end
    F:SetSize(ScrW() * 0.3, ScrH() * 0.6)
    F:Center()
    F:MakePopup(true)
    F:SetTitle(RDV.LIBRARY.GetLang(nil, "CHAT_commandTitle"))
    
    local w, h = F:GetSize()

    local S = vgui.Create("PIXEL.ScrollPanel", F)
    S:DockMargin(w * 0.01, h * 0.01, w * 0.01, h * 0.01)
    S:Dock(FILL)

    --[[
    -- Prefix
    --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_prefixLabel").."*")

        local NAME = S:Add("DTextEntry")
        NAME:Dock(TOP)

        if DATA and DATA.Prefix then
            NAME:SetValue(DATA.Prefix)
        end

    --[[
    -- Command
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_commandLabel").."*")

    local COMMAND = S:Add("DTextEntry")
    COMMAND:Dock(TOP)

    if DATA and DATA.COMMAND then
        COMMAND:SetValue(DATA.COMMAND)
    end

    --[[
    -- Command Sound
    --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_soundLabel"))

        local SOUND = S:Add("DTextEntry")
        SOUND:Dock(TOP)

        if DATA and DATA.SOUND then
            SOUND:SetValue(DATA.SOUND)
        end

    --[[
    -- MSG Delay
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_delayLabel"))

    local DELAY = S:Add("DNumSlider")
    DELAY:Dock(TOP)
    DELAY:SetMax(200000)
    DELAY:SetDecimals(0)
    DELAY:DockMargin(0, 0, 0, h * 0.025)

    if DATA and DATA.DELAY then
        DELAY:SetValue(DATA.DELAY)
    end

    --[[
    -- Radius
    --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_radiusLabel"))

        local RADIUS = S:Add("DNumSlider")
        RADIUS:Dock(TOP)
        RADIUS:SetMax(200000)
        RADIUS:SetDecimals(0)
        RADIUS:DockMargin(0, 0, 0, h * 0.025)
        RADIUS.PaintOver = function(S, W, H)
            if DATA.GLOBAL then
                SY_RoundedBox(0, 0, 0, W, H, Color(55,55,55, 200))

                S:GetTextArea():SetEditable(false)
                S:SetValue(0)
            else
                S:GetTextArea():SetEditable(true)
            end
        end

        if DATA and DATA.RADIUS then
            RADIUS:SetValue(DATA.RADIUS)
        end

        --[[
        -- Global Command
        --]]
        
        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_commandGlobalLabel"))

        local LABEL = vgui.Create("DLabel", S)
        LABEL:SetText("")
        LABEL:SetHeight(h * 0.1)
        LABEL:Dock(TOP)
        LABEL:DockMargin(w * 0.025, 0, w * 0.025, h * 0.025)
        LABEL:SetMouseInputEnabled(true)

        local CHECK_L = vgui.Create("DLabel", LABEL)
        CHECK_L:SetMouseInputEnabled(true)
        CHECK_L:Dock(RIGHT)
        CHECK_L:SetText("")


        local CHECK = vgui.Create("DCheckBox", CHECK_L)
        CHECK:Center()
        CHECK.OnChange = function(s, val)
            DATA.GLOBAL = val
        end

        if DATA.GLOBAL then
            CHECK:SetChecked(true)
        end

    --[[
    -- Team Restriction
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_teamRestrictLabel"))

    local LABEL = vgui.Create("DLabel", S)
    LABEL:SetText("")
    LABEL:SetHeight(h * 0.3)
    LABEL:Dock(TOP)
    LABEL:SetMouseInputEnabled(true)

    
    local S_TEAM = vgui.Create("DListView", LABEL)
    S_TEAM:Dock(FILL)
    S_TEAM:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_nameLabel"), 1 )
    S_TEAM.OnRowRightClick = function(sm, ID, LINE)
        LINE:SetSelected(false)
    end

    for k, v in ipairs(team.GetAllTeams()) do
        local L = S_TEAM:AddLine(v.Name)
        L.TEAM = v.Name
        
        if DATA.STEAMS and DATA.STEAMS[v.Name] then L:SetSelected(true) end
    end

    --[[
    -- Rank Restriction
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_rankRestrict"))

    local BRANCH
    local RANK
    local S_RANK

    local LABEL = S:Add("DLabel")
    LABEL:Dock(TOP)
    LABEL:SetTall(LABEL:GetTall() * 1.5)
    LABEL:SetText("")
    LABEL:SetMouseInputEnabled(true)
    
    local ADD = LABEL:Add("DButton", LABEL)
    ADD:SetImage("icon16/add.png")
    ADD:Dock(LEFT)
    ADD:SetText("")
    ADD:SetWide(ADD:GetWide() * 0.4)
    ADD.DoClick = function(s)
        local BR = BRANCH:GetValue()
        local RA = tonumber(RANK:GetValue())

        if ( !BR or BR == "" ) or ( !RA or RA == "" ) then return end

        local LINE = S_RANK:AddLine(BR, RA)
        LINE.BRANCH = BR
        LINE.RANK = RA
    end

    BRANCH = vgui.Create("DTextEntry", LABEL)
    BRANCH:Dock(LEFT)
    BRANCH:SetKeyboardInputEnabled(true)
    BRANCH:SetPlaceholderText(RDV.LIBRARY.GetLang(nil, "CHAT_branchLabel"))
    BRANCH:SetWide(BRANCH:GetWide() * 2)

    RANK = vgui.Create("DTextEntry", LABEL)
    RANK:Dock(LEFT)
    RANK:SetKeyboardInputEnabled(true)
    RANK:SetPlaceholderText(RDV.LIBRARY.GetLang(nil, "CHAT_rankLabel"))
    RANK:SetWide(RANK:GetWide() * 2)
    RANK:SetNumeric(true)

    local LABEL = vgui.Create("DLabel", S)
    LABEL:SetText("")
    LABEL:SetHeight(h * 0.3)
    LABEL:Dock(TOP)
    LABEL:SetMouseInputEnabled(true)

    S_RANK = vgui.Create("DListView", LABEL)
    S_RANK:Dock(FILL)
    S_RANK:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_branchLabel"), 1 )
    S_RANK:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_rankLabel"), 2 )

    S_RANK.OnRowRightClick = function(sm, ID, LINE)
        local BR = LINE.BRANCH

        if DATA.RANKS[BR] then
            DATA.RANKS[BR] = nil
        end

        S_RANK:RemoveLine(ID)
    end

    if DATA.RANKS then
        for k, v in pairs(DATA.RANKS) do
            local LINE = S_RANK:AddLine(k, v)
            LINE.BRANCH = k
            LINE.RANK = v
        end
    end

    --[[
    -- No Permission (Read Only?)
    --]]

    CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_notInTeamSee"))

    local LABEL = vgui.Create("DLabel", S)
    LABEL:SetText("")
    LABEL:SetHeight(h * 0.1)
    LABEL:Dock(TOP)
    LABEL:DockMargin(w * 0.025, 0, w * 0.025, h * 0.025)
    LABEL:SetMouseInputEnabled(true)

    local CHECK_L = vgui.Create("DLabel", LABEL)
    CHECK_L:SetMouseInputEnabled(true)
    CHECK_L:Dock(RIGHT)
    CHECK_L:SetText("")


    local CHECK = vgui.Create("DCheckBox", CHECK_L)
    CHECK:Center()
    CHECK.OnChange = function(s, val)
        DATA.NoTeamSee = val
    end

    if DATA.NoTeamSee then
        CHECK:SetChecked(true)
    end

    --[[
    -- Display Player Name
    --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_displayPlayerLabel"))

        local LABEL = vgui.Create("DLabel", S)
        LABEL:SetText("")
        LABEL:SetHeight(h * 0.1)
        LABEL:Dock(TOP)
        LABEL:DockMargin(w * 0.025, 0, w * 0.025, h * 0.025)
        LABEL:SetMouseInputEnabled(true)

        local CHECK_L = vgui.Create("DLabel", LABEL)
        CHECK_L:SetMouseInputEnabled(true)
        CHECK_L:Dock(RIGHT)
        CHECK_L:SetText("")

        local CHECK = vgui.Create("DCheckBox", CHECK_L)
        CHECK:Center()
        CHECK.OnChange = function(s, val)
            DATA.DISPLAY_NAME = val
        end

        if DATA.DISPLAY_NAME then
            CHECK:SetChecked(true)
        end

        --[[
        -- Require Player to be alive?
        --]]
        
        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_requireAliveLabel"))

        local LABEL = vgui.Create("DLabel", S)
        LABEL:SetText("")
        LABEL:SetHeight(h * 0.1)
        LABEL:Dock(TOP)
        LABEL:DockMargin(w * 0.025, 0, w * 0.025, h * 0.025)
        LABEL:SetMouseInputEnabled(true)

        local CHECK_L = vgui.Create("DLabel", LABEL)
        CHECK_L:SetMouseInputEnabled(true)
        CHECK_L:Dock(RIGHT)
        CHECK_L:SetText("")

        local CHECK = vgui.Create("DCheckBox", CHECK_L)
        CHECK:Center()
        CHECK.OnChange = function(s, val)
            DATA.ALIVE = val
        end

        if DATA.ALIVE then
            CHECK:SetChecked(true)
        end

        --[[
        -- Disable with Relay
        --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_disableRelay"))

        local LABEL = vgui.Create("DLabel", S)
        LABEL:SetText("")
        LABEL:SetHeight(h * 0.1)
        LABEL:Dock(TOP)
        LABEL:DockMargin(w * 0.025, 0, w * 0.025, h * 0.025)
        LABEL:SetMouseInputEnabled(true)

        local CHECK_L = vgui.Create("DLabel", LABEL)
        CHECK_L:SetMouseInputEnabled(true)
        CHECK_L:Dock(RIGHT)
        CHECK_L:SetText("")

        local CHECK = vgui.Create("DCheckBox", CHECK_L)
        CHECK:Center()
        CHECK.OnChange = function(s, val)
            DATA.DisWithRelay = val
        end

        if DATA.DisWithRelay then
            CHECK:SetChecked(true)
        end

        
        --[[
        -- Prefix Color
        --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_prefixColorLabel"))

        local P_COLOR = vgui.Create("DColorMixer", S)
        P_COLOR:Dock(TOP)

        if DATA.Prefix_Color then
            P_COLOR:SetColor(DATA.Prefix_Color)
        else
            P_COLOR:SetColor(Color(255,0,0))
        end

        --[[
        -- Text Color
        --]]

        CreateDivider(F, S, RDV.LIBRARY.GetLang(nil, "CHAT_textColorLabel"))

        local T_COLOR = vgui.Create("DColorMixer", S)
        T_COLOR:Dock(TOP)

        if DATA.Text_Color then
            T_COLOR:SetColor(DATA.Text_Color)
        else
            T_COLOR:SetColor(Color(255,255,255))
        end

    --[[
    -- Confirm
    --]]

    local CONFIRM = vgui.Create("PIXEL.TextButton", F)
    CONFIRM:Dock(BOTTOM)
    CONFIRM:SetText(RDV.LIBRARY.GetLang(nil, "CHAT_confirmLabel"))
    CONFIRM.DoClick = function(s)
        DATA.Prefix = NAME:GetText()
        DATA.Prefix_Color = P_COLOR:GetColor()
        DATA.Text_Color = T_COLOR:GetColor()
        DATA.RADIUS = RADIUS:GetValue()
        DATA.SOUND = SOUND:GetText()
        DATA.STEAMS = DATA.STEAMS or {}
        DATA.RANKS = DATA.RANKS or {}
        DATA.COMMAND = COMMAND:GetText()
        DATA.DELAY = ( DELAY:GetValue() or 1 )

        if ( !DATA.Prefix or DATA.Prefix == "" ) or ( !DATA.COMMAND or DATA.COMMAND == "" ) then
            chat.AddText(Color(255,0,0), "[COMMANDS] ", color_white, RDV.LIBRARY.GetLang(nil, "CHAT_missingContent"))
            return
        end
        
        for k, v in ipairs(S_TEAM:GetSelected()) do
            DATA.STEAMS[v.TEAM] = true 
        end

        for k, v in ipairs(S_RANK:GetLines()) do
            DATA.RANKS[v.BRANCH] = v.RANK
        end

        local COMPRESS = util.Compress(util.TableToJSON(DATA))

        local BYTES = #COMPRESS

        net.Start( "RDV_CHAT_COMMANDS_CREATE" )
            net.WriteUInt( BYTES, 16 )
            net.WriteData( COMPRESS, BYTES )
        net.SendToServer()

        F:Remove()
    end
end 

net.Receive("RDV_CHAT_COMMANDS_CREATE", function()
    local BYTES = net.ReadUInt( 16 )
    local DATA = net.ReadData(BYTES)

    local DECOMPRESSED = util.Decompress(DATA)
    local TAB = util.JSONToTable(DECOMPRESSED)

    RDV.CHAT_COMMANDS.LIST[TAB.COMMAND] = TAB
end )

net.Receive("RDV_CHAT_COMMANDS_NETWORK", function()
    local BYTES = net.ReadUInt( 16 )
    local DATA = net.ReadData(BYTES)

    local DECOMPRESSED = util.Decompress(DATA)
    local TAB = util.JSONToTable(DECOMPRESSED)

    RDV.CHAT_COMMANDS.LIST = TAB
end )

net.Receive("RDV_CHAT_COMMANDS_ADMIN", function()
    local F = vgui.Create("PIXEL.Frame")
    if SYMUI then SYMUI.HookPixel() SYMUI.AutoStyle(F) end
    F:SetSize(ScrW() * 0.3, ScrH() * 0.6)
    F:Center()
    F:MakePopup(true)
    F:SetTitle(RDV.LIBRARY.GetLang(nil, "CHAT_commandTitle"))

    local STATS = F:CreateSidebar("statsMenu", nil)

    local MENU = vgui.Create("DPanel", F)
    MENU:Dock(FILL)
    MENU.Paint = function() end

    --[[ Analytics

    STATS:AddItem("statsMenu", "Analytics", nil, function()
        local CONT = MENU

        if IsValid(CONT) then CONT:Clear() end

        local STATS = vgui.Create("DScrollPanel")
        STATS:Dock(FILL)
    end )
    --]]

    STATS:AddItem("statsMenu", RDV.LIBRARY.GetLang(nil, "CHAT_chatCommandsLabel"), "tumnJ2l", function()
        local CONT = MENU

        if IsValid(CONT) then CONT:Clear() end

        local LABEL = CONT:Add("DLabel")
        LABEL:Dock(TOP)
        LABEL:SetTall(LABEL:GetTall() * 1.5)
        LABEL:SetText("")
        LABEL:SetMouseInputEnabled(true)


        local ADD = LABEL:Add("DButton", LABEL)
        ADD:SetImage("icon16/add.png")
        ADD:Dock(LEFT)
        ADD:SetText("")
        ADD:SetWide(ADD:GetWide() * 0.4)
        
        local LIST

        local function REFRESH()
            LIST:Clear()

            for k, v in pairs(RDV.CHAT_COMMANDS.LIST) do
                local NAME = "Unknown"

                local TYPE = ( v.LINK and "Link" ) or "Chat"

                if v.CREATOR then
                    steamworks.RequestPlayerInfo( LocalPlayer():SteamID64(), function( steamName )
                        local LINE = LIST:AddLine(k, TYPE, (steamName or "Unknown") )
                        LINE.UID = k
                    end )
                else
                    local LINE = LIST:AddLine(k, TYPE, "Unknown" )
                    LINE.UID = k
                end
            end
        end

        local B_REFRESH = LABEL:Add("DButton", LABEL)
        B_REFRESH:SetImage("icon16/arrow_refresh.png")
        B_REFRESH:Dock(LEFT)
        B_REFRESH:SetText("")
        B_REFRESH:SetWide(B_REFRESH:GetWide() * 0.4)
        B_REFRESH.DoClick = function(s)
            REFRESH()
        end

        ADD.DoClick = function(s)
            local MenuButtonOptions = DermaMenu()

            MenuButtonOptions:AddOption(RDV.LIBRARY.GetLang(nil, "CHAT_addChatCommandLabel"), function()
                CREATE_COMMAND()
            end)

            MenuButtonOptions:AddOption(RDV.LIBRARY.GetLang(nil, "CHAT_addLinkCommandLabel"), function()
                CREATE_COMMAND_LINK()
            end)

            MenuButtonOptions:Open()
        end

        LIST = vgui.Create("DListView", CONT)
        LIST:Dock(FILL)
        LIST:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_commandLabel"), 1 )
        LIST:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_typeLabel"), 2 )
        LIST:AddColumn( RDV.LIBRARY.GetLang(nil, "CHAT_creatorLabel"), 3 )

        LIST.OnRowRightClick = function(_, ID, LINE)
            local MenuButtonOptions = DermaMenu()

            MenuButtonOptions:AddOption(RDV.LIBRARY.GetLang(nil, "CHAT_editLabel"), function()
                local DATA = RDV.CHAT_COMMANDS.LIST[LINE.UID]

                if DATA and DATA.LINK then
                    CREATE_COMMAND_LINK(LINE.UID)
                else
                    CREATE_COMMAND(LINE.UID)
                end
            end)

            MenuButtonOptions:AddOption(RDV.LIBRARY.GetLang(nil, "CHAT_duplicateLabel"), function()
                local DATA = RDV.CHAT_COMMANDS.LIST[LINE.UID]

                if DATA and DATA.LINK then
                    CREATE_COMMAND_LINK(LINE.UID, true)
                else
                    CREATE_COMMAND(LINE.UID, true)
                end
            end)

            MenuButtonOptions:AddOption(RDV.LIBRARY.GetLang(nil, "CHAT_deleteLabel"), function()
                net.Start("RDV_CHAT_COMMANDS_DELETE")
                    net.WriteString(LINE.UID)
                net.SendToServer()
            end)

            MenuButtonOptions:Open()
        end

        REFRESH()
    end )
end )

net.Receive("RDV_CHAT_COMMANDS_DELETE", function()
    local UID = net.ReadString()

    if RDV.CHAT_COMMANDS.LIST and RDV.CHAT_COMMANDS.LIST[UID] then
        RDV.CHAT_COMMANDS.LIST[UID] = nil
    end
end )

net.Receive("RDV_CHAT_COMMANDS_SendMSG", function()
    local CMD = net.ReadString()
    local MSG = net.ReadString()
    local SND = Entity(net.ReadUInt(8))

    if !RDV.CHAT_COMMANDS.LIST[CMD] or !IsValid(SND) then return end
    
    local DATA = RDV.CHAT_COMMANDS.LIST[CMD]
    local PC = DATA.Prefix_Color
    local TC = DATA.Text_Color

    local STAG = false

    if SND.SCB_GetTag and SND:SCB_GetTag() ~= nil then
        STAG = true
    end


    if DATA.LINK then
        gui.OpenURL( DATA.LINK )
        return
    end

    if DATA.DISPLAY_NAME then
        if STAG then
            chat.AddText( SND:SCB_GetTag(), Color(PC.r, PC.g, PC.b), DATA.Prefix.." ", team.GetColor(SND:Team()), SND:Name()..": ", Color(TC.r, TC.g, TC.b), MSG)
        else
            chat.AddText( Color(PC.r, PC.g, PC.b), DATA.Prefix.." ", team.GetColor(SND:Team()), SND:Name()..": ", Color(TC.r, TC.g, TC.b), MSG)
        end
    else
        chat.AddText( Color(PC.r, PC.g, PC.b), DATA.Prefix, Color(TC.r, TC.g, TC.b), " "..MSG)
    end

    if DATA.SOUND and DATA.SOUND ~= "" then
        surface.PlaySound(DATA.SOUND)
    else
        surface.PlaySound("common/talk.wav")
    end
end )